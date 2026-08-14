import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
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

  /// True for the duration of an in-flight `GET /status` call — [_pollTimer]
  /// alone can't guard re-entry, since it's `null` for that entire window
  /// (cleared by [_poll]'s own first line, not re-set until the request
  /// resolves). Without this, [refreshNow] calling [_poll] directly while a
  /// timer-driven poll was already awaiting its response created two
  /// independent poll chains: each one's [_poll] call ends by overwriting
  /// [_pollTimer] with its own `Timer(_pollInterval, _poll)`, so the loser's
  /// timer object becomes orphaned — nothing holds a reference to cancel it,
  /// so it keeps firing forever on its own cadence. Repeat that every time an
  /// action (retry/promote/cancel/submit) calls [refreshNow] while a tab is
  /// already stuck in polling fallback, and the orphaned chains accumulate
  /// into bursts of several near-simultaneous `system.status` calls.
  bool _polling = false;

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
    if (_pollTimer != null || _polling) return; // already polling
    _sse?.close();
    _sse = null;
    unawaited(_poll());
  }

  Future<void> _poll() async {
    // A concurrent call — the timer-driven cycle and a `refreshNow` call
    // landed at the same time — is a no-op rather than a second chain: the
    // one already in flight will update `state` within moments regardless.
    if (_polling) return;
    _polling = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    final api = ref.read(apiClientProvider);
    try {
      final status = SystemStatus.fromJson(
        await api.decodeMap(api.endpoints.status()),
      );
      state = AsyncData(status);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    } finally {
      _polling = false;
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
      final api = ref.read(apiClientProvider);
      final json = await api.decodeMap(api.endpoints.status());
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
