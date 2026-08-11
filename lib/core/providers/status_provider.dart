import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/system_status.dart';
import 'core_providers.dart';

const _pollInterval = Duration(seconds: 5);

/// Polls `GET /status` every 5s while a job is running/queued, and pauses
/// once the queue drains. Call [refreshNow] after submitting a build or
/// re-entering the dashboard to resume polling immediately.
class StatusController extends AsyncNotifier<SystemStatus?> {
  Timer? _timer;

  @override
  FutureOr<SystemStatus?> build() {
    ref.onDispose(() => _timer?.cancel());
    unawaited(_fetch());
    return null;
  }

  Future<void> _fetch() async {
    _timer?.cancel();
    final api = ref.read(apiClientProvider);
    try {
      final status = SystemStatus.fromJson(await api.getJson('/status'));
      state = AsyncData(status);
      if (status.hasActiveJobs) {
        _timer = Timer(_pollInterval, _fetch);
      }
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  void refreshNow() {
    unawaited(_fetch());
  }
}

final statusControllerProvider =
    AsyncNotifierProvider<StatusController, SystemStatus?>(
      StatusController.new,
    );
