import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/system_status.dart';
import '../sse/status_event_source.dart';
import 'core_providers.dart';

const _pollInterval = Duration(seconds: 5);

/// Drives the queue sidebar from `GET /status/events` (SSE), falling back to
/// polling `GET /status` on any stream error — the same live-with-fallback
/// shape as [JobLogController], so a build started from Discord or another
/// client shows up here without this tab having to ask on a timer.
///
/// [refreshNow] stays for callers that want to force an immediate refetch
/// right after their own action (submit/promote/cancel/retry) rather than
/// wait for the server's push, which still has request/response latency of
/// its own.
class StatusController extends AsyncNotifier<SystemStatus?> {
  StatusEventSource? _sse;
  Timer? _pollTimer;

  @override
  FutureOr<SystemStatus?> build() {
    ref.onDispose(() {
      _sse?.close();
      _pollTimer?.cancel();
    });
    unawaited(_connect());
    return null;
  }

  Future<void> _connect() async {
    final api = ref.read(apiClientProvider);
    final source = StatusEventSource()..connect('${api.baseUrl}/status/events');
    _sse = source;
    source.statuses.listen(
      (json) => state = AsyncData(SystemStatus.fromJson(json)),
    );
    source.connectionErrors.listen((_) => _fallbackToPolling());
  }

  void _fallbackToPolling() {
    if (_pollTimer != null) return; // already polling
    _sse?.close();
    _sse = null;
    unawaited(_poll());
  }

  Future<void> _poll() async {
    _pollTimer?.cancel();
    final api = ref.read(apiClientProvider);
    try {
      final status = SystemStatus.fromJson(await api.getJson('/status'));
      state = AsyncData(status);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
    _pollTimer = Timer(_pollInterval, _poll);
  }

  void refreshNow() {
    if (_sse == null) {
      unawaited(_poll());
      return;
    }
    // SSE is connected and will push its own update anyway, but that has
    // request/response latency of its own — a caller invoking this right
    // after submitting/promoting/cancelling a job wants the sidebar to move
    // now, not on the next server round trip.
    unawaited(_refreshOnceOverSse());
  }

  Future<void> _refreshOnceOverSse() async {
    try {
      final json = await ref.read(apiClientProvider).getJson('/status');
      state = AsyncData(SystemStatus.fromJson(json));
    } catch (_) {
      // Best-effort — the SSE connection is still the source of truth.
    }
  }
}

final statusControllerProvider =
    AsyncNotifierProvider<StatusController, SystemStatus?>(
      StatusController.new,
    );
