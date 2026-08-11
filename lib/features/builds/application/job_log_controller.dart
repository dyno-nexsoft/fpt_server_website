import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/jobs_api.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/sse/job_event_source.dart';

enum LogConnectionMode { connecting, live, polling, static }

class JobLogState {
  const JobLogState({
    this.job,
    this.logText = '',
    this.mode = LogConnectionMode.connecting,
    this.jobMissing = false,
    this.resumedJob,
    this.actionError,
  });

  final Job? job;
  final String logText;
  final LogConnectionMode mode;
  final bool jobMissing;
  final Job? resumedJob;
  final String? actionError;

  JobLogState copyWith({
    Job? job,
    String? logText,
    LogConnectionMode? mode,
    bool? jobMissing,
    Job? resumedJob,
    String? actionError,
  }) => JobLogState(
    job: job ?? this.job,
    logText: logText ?? this.logText,
    mode: mode ?? this.mode,
    jobMissing: jobMissing ?? this.jobMissing,
    resumedJob: resumedJob ?? this.resumedJob,
    actionError: actionError,
  );
}

/// Drives the job detail / log viewer screen: fetches the job, tries the SSE
/// stream, and falls back to polling `GET /jobs/{id}/log?offset=` on any SSE
/// error — both paths append to the same [JobLogState.logText] so rendering
/// never has to know which transport is active.
class JobLogController extends Notifier<JobLogState> {
  JobLogController(this.jobId);

  final String jobId;

  JobEventSource? _sse;
  Timer? _pollTimer;
  int _nextOffset = 0;
  bool _disposed = false;

  @override
  JobLogState build() {
    ref.onDispose(() {
      _disposed = true;
      _sse?.close();
      _pollTimer?.cancel();
    });
    unawaited(_start());
    return const JobLogState();
  }

  Future<void> _start() async {
    final api = ref.read(apiClientProvider);
    try {
      final job = await fetchJob(api, jobId);
      _setJob(job);
      if (job.isTerminal) {
        await _fetchLogOnce();
        state = state.copyWith(mode: LogConnectionMode.static);
      } else {
        await _connectSse();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _handleMissingJob();
      } else {
        state = state.copyWith(actionError: e.message);
      }
    }
  }

  Future<void> _handleMissingJob() async {
    final api = ref.read(apiClientProvider);
    state = state.copyWith(jobMissing: true);
    try {
      final recent = await fetchJobs(api, limit: 20);
      for (final candidate in recent) {
        if (candidate.id != jobId) {
          state = state.copyWith(resumedJob: candidate);
          break;
        }
      }
    } catch (_) {
      // Best-effort only — the missing-job banner still renders without it.
    }
  }

  void _setJob(Job job) {
    if (_disposed) return;
    state = state.copyWith(job: job);
  }

  Future<void> _fetchLogOnce() async {
    final api = ref.read(apiClientProvider);
    final response = await api.getRaw('/jobs/$jobId/log', query: {'offset': 0});
    state = state.copyWith(logText: response.body);
  }

  Future<void> _connectSse() async {
    state = state.copyWith(mode: LogConnectionMode.connecting);
    final api = ref.read(apiClientProvider);
    try {
      final streamToken = await createStreamToken(api, jobId);
      final origin = Uri.parse(api.baseUrl).origin;
      final url = '$origin${streamToken.eventsUrl}';
      final source = JobEventSource()..connect(url);
      _sse = source;
      source.events.listen(_onEvent);
      source.connectionErrors.listen((_) => _fallbackToPolling());
      state = state.copyWith(mode: LogConnectionMode.live);
    } catch (_) {
      await _fallbackToPolling();
    }
  }

  void _onEvent(JobStreamEvent event) {
    if (_disposed) return;
    switch (event.type) {
      case 'log':
        if (event.chunk != null) {
          state = state.copyWith(logText: state.logText + event.chunk!);
        }
      case 'status':
        if (event.line != null) {
          state = state.copyWith(logText: '${state.logText}${event.line}\n');
        }
      case 'error':
        if (event.message != null) {
          state = state.copyWith(
            logText: '${state.logText}[error] ${event.message}\n',
          );
        }
      case 'finished':
        _onFinished(event);
      default:
        break;
    }
  }

  void _onFinished(JobStreamEvent event) {
    _sse?.close();
    _sse = null;
    final job = state.job;
    if (job != null) {
      _setJob(
        Job(
          id: job.id,
          state: JobState.fromWire(event.state ?? 'succeeded'),
          command: job.command,
          actionName: job.actionName,
          actionParams: job.actionParams,
          environments: job.environments,
          createdBy: job.createdBy,
          artifactKey: job.artifactKey,
          promoted: job.promoted,
          announce: job.announce,
          createdAt: job.createdAt,
          startedAt: job.startedAt,
          finishedAt: DateTime.now(),
          exitCode: event.exitCode,
          lastLine: job.lastLine,
          lastSeq: event.seq ?? job.lastSeq,
          discordChannelId: job.discordChannelId,
          discordMessageId: job.discordMessageId,
          logUrl: job.logUrl,
          warnings: job.warnings,
        ),
      );
    }
    state = state.copyWith(mode: LogConnectionMode.static);
    ref.read(statusControllerProvider.notifier).refreshNow();
  }

  Future<void> _fallbackToPolling() async {
    if (_disposed || state.mode == LogConnectionMode.polling) return;
    _sse?.close();
    _sse = null;
    state = state.copyWith(mode: LogConnectionMode.polling);
    await _pollOnce();
  }

  Future<void> _pollOnce() async {
    if (_disposed) return;
    final api = ref.read(apiClientProvider);
    try {
      final response = await api.getRaw(
        '/jobs/$jobId/log',
        query: {'offset': _nextOffset},
      );
      if (response.body.isNotEmpty) {
        state = state.copyWith(logText: state.logText + response.body);
      }
      final nextOffsetHeader = response.headers['x-log-next-offset'];
      if (nextOffsetHeader != null) {
        _nextOffset = int.tryParse(nextOffsetHeader) ?? _nextOffset;
      }
      final job = await fetchJob(api, jobId);
      _setJob(job);
      if (job.isTerminal) {
        state = state.copyWith(mode: LogConnectionMode.static);
        ref.read(statusControllerProvider.notifier).refreshNow();
        return;
      }
    } catch (_) {
      // Transient failure — keep retrying on the next tick.
    }
    if (!_disposed) {
      _pollTimer = Timer(const Duration(seconds: 2), _pollOnce);
    }
  }

  Future<void> refresh() async {
    _sse?.close();
    _sse = null;
    _pollTimer?.cancel();
    state = const JobLogState();
    await _start();
  }
}

final jobLogControllerProvider =
    NotifierProvider.family<JobLogController, JobLogState, String>(
      JobLogController.new,
    );
