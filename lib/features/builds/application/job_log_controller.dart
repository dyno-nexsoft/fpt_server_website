import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/jobs_api.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/job_seed_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/sse/job_event_source.dart';

enum LogConnectionMode { connecting, live, polling, static }

class JobLogState {
  const JobLogState({
    this.job,
    this.lines = const [],
    this.pendingLine = '',
    this.mode = LogConnectionMode.connecting,
    this.jobMissing = false,
    this.resumedJob,
    this.actionError,
  });

  final Job? job;

  /// Complete, newline-terminated lines received so far.
  ///
  /// **Append-only and mutated in place.** A chatty build emits hundreds of
  /// chunks; rebuilding this list on each one would copy every line already
  /// received, making a whole build O(lines × chunks) in list copies for a
  /// result that is only ever a few lines longer than the last. The
  /// controller appends to one list instead, and consumers still rebuild
  /// because [copyWith] hands out a new [JobLogState].
  ///
  /// Two consequences: never `select` on this list or compare it for
  /// equality (it is `identical` to the previous state's), and never mutate
  /// it from outside the controller. [LogViewer] relies on exactly this
  /// contract to re-measure only the lines it just gained.
  final List<String> lines;

  /// The tail end of the buffer that hasn't seen a `\n` yet — a build tool
  /// can flush mid-line, and holding it back out of [lines] until it's
  /// terminated keeps every committed line final instead of getting
  /// silently rewritten in place on the next chunk. Rendered as a trailing
  /// row by [LogViewer] so a still-streaming last line stays visible before
  /// its `\n` arrives, without anyone having to copy [lines] to append it.
  final String pendingLine;

  final LogConnectionMode mode;
  final bool jobMissing;
  final Job? resumedJob;
  final String? actionError;

  JobLogState copyWith({
    Job? job,
    List<String>? lines,
    String? pendingLine,
    LogConnectionMode? mode,
    bool? jobMissing,
    Job? resumedJob,
    String? actionError,
  }) => JobLogState(
    job: job ?? this.job,
    lines: lines ?? this.lines,
    pendingLine: pendingLine ?? this.pendingLine,
    mode: mode ?? this.mode,
    jobMissing: jobMissing ?? this.jobMissing,
    resumedJob: resumedJob ?? this.resumedJob,
    actionError: actionError,
  );
}

/// Drives the job detail / log viewer screen: fetches the job, tries the SSE
/// stream, and falls back to polling `GET /jobs/{id}/log?offset=` on any SSE
/// error — both paths append to the same [JobLogState.lines] via
/// [_appendRaw] so rendering never has to know which transport is active.
class JobLogController extends Notifier<JobLogState> {
  JobLogController(this.jobId);

  final String jobId;

  /// How long appended output is held before it reaches the UI. Long enough
  /// to fold a burst of chunks into one rebuild, short enough that a live
  /// log still reads as live.
  static const _flushInterval = Duration(milliseconds: 50);

  JobEventSource? _sse;
  Timer? _pollTimer;
  Timer? _flushTimer;
  int _nextOffset = 0;
  bool _disposed = false;
  Job? _seed;
  String _buffer = '';

  /// The one list [JobLogState.lines] ever points at — see the contract
  /// there. Replaced (not cleared) by [refresh], so the viewer sees a new
  /// identity and drops what it had measured.
  var _lines = <String>[];

  /// Normalizes `\r` (build tools routinely use a bare `\r` to overwrite a
  /// progress line on a real terminal) to `\n`, then peels off every
  /// complete line into [JobLogState.lines], leaving any unterminated
  /// remainder in [_buffer] to be published as [JobLogState.pendingLine].
  void _appendRaw(String raw) {
    if (_disposed || raw.isEmpty) return;
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final combined = _buffer + normalized;
    final parts = combined.split('\n');
    _buffer = parts.removeLast();
    _lines.addAll(parts);
    _scheduleFlush();
  }

  /// Publishes appended output on the next tick instead of immediately: SSE
  /// chunks arrive far faster than the screen can paint (a build tool
  /// flushing progress lines pushes dozens per frame), and each emission
  /// rebuilds the whole job detail screen. Coalescing them costs at most
  /// [_flushInterval] of latency and saves most of those rebuilds.
  void _scheduleFlush() {
    _flushTimer ??= Timer(_flushInterval, _flush);
  }

  /// The only writer of [JobLogState.lines] / [JobLogState.pendingLine]. An
  /// unrelated emission in between (a job or mode change) therefore carries
  /// the last *published* pending line rather than the newest one — a
  /// difference of one partial line, corrected by the flush already queued.
  void _flush() {
    _flushTimer = null;
    if (_disposed) return;
    state = state.copyWith(lines: _lines, pendingLine: _buffer);
  }

  /// Publishes immediately — for the points where no further chunk is
  /// coming (the log finished, or was fetched in one shot) and waiting out
  /// [_flushInterval] would leave the last lines briefly missing.
  void _flushNow() {
    _flushTimer?.cancel();
    _flush();
  }

  @override
  JobLogState build() {
    ref.onDispose(() {
      _disposed = true;
      _sse?.close();
      _pollTimer?.cancel();
      _flushTimer?.cancel();
    });
    final pendingSeed = ref.read(pendingJobSeedProvider);
    if (pendingSeed != null && pendingSeed.id == jobId) {
      _seed = pendingSeed;
      // Not a direct call: Riverpod forbids one provider modifying another
      // while it is still building, and this runs inside `build()`.
      // Deferring to a microtask runs it right after this build finishes.
      Future.microtask(() {
        if (_disposed) return;
        ref.read(pendingJobSeedProvider.notifier).clear();
      });
    }
    unawaited(_start());
    return JobLogState(lines: _lines);
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

  /// A 404 here means the server restarted mid-build and re-invoked the
  /// recorded action under a new id — see docs/rest-api.md "Restart
  /// mid-build". `resumed_from` on the new job is the exact, unambiguous
  /// pointer back to this one; matching on `action_name`/`action_params`
  /// instead would risk a false positive whenever the same action legitimately
  /// runs more than once (a cron job, or a manual re-run).
  ///
  /// Filtered server-side by `?resumed_from=` rather than fetching the most
  /// recent jobs and scanning client-side — enough other builds between the
  /// restart and whoever opens this page would push the resumed job outside
  /// any fixed-size recent-jobs window, turning a real resume into a dead
  /// end with no way to reach it.
  Future<void> _handleMissingJob() async {
    final api = ref.read(apiClientProvider);
    state = state.copyWith(jobMissing: true);
    try {
      final matches = await fetchJobs(api, resumedFrom: jobId, limit: 1);
      if (matches.isNotEmpty) {
        state = state.copyWith(resumedJob: matches.first);
      }
    } catch (_) {
      // Best-effort only — the missing-job banner still renders without it.
    }
  }

  void _setJob(Job job) {
    if (_disposed) return;
    final merged = job.copyWith(
      logUrl: job.logUrl ?? _seed?.logUrl,
      warnings: job.warnings.isNotEmpty
          ? job.warnings
          : _seed?.warnings ?? job.warnings,
    );
    state = state.copyWith(job: merged);
  }

  Future<void> _fetchLogOnce() async {
    final api = ref.read(apiClientProvider);
    final response = await api.rawText(api.endpoints.getJobLog(jobId, 0));
    _appendRaw(response.body ?? '');
    _flushNow();
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
      case 'started':
        // Without this, a job opened while still `queued` never visibly
        // moves to `running` — nothing else updates `state` until
        // `finished`, which jumps straight to succeeded/failed.
        final job = state.job;
        if (job != null) {
          _setJob(
            job.copyWith(
              state: JobState.running,
              startedAt: event.at ?? DateTime.now(),
            ),
          );
        }
      case 'promoted':
        final job = state.job;
        if (job != null) _setJob(job.copyWith(promoted: true));
      case 'log':
        if (event.chunk != null) {
          _appendRaw(event.chunk!);
        }
      case 'status':
        if (event.line != null) {
          _appendRaw('${event.line}\n');
        }
      case 'error':
        if (event.message != null) {
          _appendRaw('[error] ${event.message}\n');
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
    _flushNow();
    final job = state.job;
    if (job != null) {
      _setJob(
        job.copyWith(
          state: JobState.fromWire(event.state ?? 'succeeded'),
          finishedAt: DateTime.now(),
          exitCode: event.exitCode,
          lastSeq: event.seq ?? job.lastSeq,
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
      final response = await api.rawText(
        api.endpoints.getJobLog(jobId, _nextOffset),
      );
      _appendRaw(response.body ?? '');
      final nextOffsetHeader = response.headers['x-log-next-offset'];
      if (nextOffsetHeader != null) {
        _nextOffset = int.tryParse(nextOffsetHeader) ?? _nextOffset;
      }
      final job = await fetchJob(api, jobId);
      _setJob(job);
      if (job.isTerminal) {
        _flushNow();
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
    _flushTimer?.cancel();
    _flushTimer = null;
    _buffer = '';
    // A fresh list rather than `_lines.clear()`: the viewer keys its cached
    // measurements on this list's identity, so reusing the instance would
    // leave it thinking a shorter log is still as wide as the old one.
    _lines = <String>[];
    state = JobLogState(lines: _lines);
    await _start();
  }
}

final jobLogControllerProvider =
    NotifierProvider.family<JobLogController, JobLogState, String>(
      JobLogController.new,
    );
