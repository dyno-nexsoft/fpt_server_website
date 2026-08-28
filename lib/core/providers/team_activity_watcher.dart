import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../api/jobs_api.dart';
import 'catalogue_providers.dart';
import 'core_providers.dart';
import 'notification_preferences_provider.dart';
import 'status_provider.dart';

/// Turns [statusControllerProvider]'s queue snapshots into "someone else
/// started/finished a build" notifications, per [NotificationPreferences].
///
/// A `void` [Notifier] with nothing watching its state — this exists purely
/// for [build]'s side effect (the [ref.listen] below), kept alive for the
/// app's whole lifetime by `AppShell` watching [teamActivityWatcherProvider]
/// once. Nothing else ever reads it.
class TeamActivityWatcher extends Notifier<void> {
  /// Ids of jobs active as of the last snapshot, tracked purely to diff the
  /// next one against — a job present now that wasn't a moment ago just
  /// started; one that was and now isn't just finished (successfully or
  /// not — `SystemStatus.running`/`queued` only ever holds *active* jobs, so
  /// a job's outcome isn't in this snapshot at all; [_notifyFinished] fetches
  /// it separately, and only when [NotificationPreferences.teamFinished] is
  /// actually on, since that fetch is the one part of this feature with a
  /// real request cost).
  Set<String> _activeIds = {};

  /// False until the first snapshot lands. That snapshot is whatever was
  /// *already* running/queued when this tab opened — not new arrivals — so
  /// it seeds [_activeIds] without notifying about any of it. Without this,
  /// every reconnect (a network blip, `StatusController` falling back to
  /// polling) would re-announce the entire queue as freshly started.
  bool _initialized = false;

  @override
  void build() {
    ref.listen(statusControllerProvider, (_, next) {
      final status = next.value;
      if (status != null) _onStatus(status);
    });
  }

  void _onStatus(SystemStatus status) {
    final jobs = [...status.running, ...status.queued];
    final currentIds = {for (final job in jobs) job.id};

    if (!_initialized) {
      _activeIds = currentIds;
      _initialized = true;
      return;
    }

    final prefs = ref.read(notificationPreferencesProvider);
    final myName = ref.read(myKeyInfoProvider).value?.name;

    if (prefs.teamStarted) {
      for (final job in jobs) {
        if (_activeIds.contains(job.id)) continue; // already known
        if (job.createdBy == myName) continue; // you already know
        ref
            .read(browserNotificationsProvider)
            .show('${job.createdBy} started ${job.actionName ?? 'a build'}');
      }
    }

    if (prefs.teamFinished) {
      for (final id in _activeIds.difference(currentIds)) {
        unawaited(_notifyFinished(id, myName));
      }
    }

    _activeIds = currentIds;
  }

  /// [id] just dropped out of the active list — fetches it to learn how it
  /// ended, since [SystemStatus] itself never carries a finished job.
  /// Best-effort: a job pruned from history in the moment between the two
  /// snapshots (unlikely, but not impossible) just means no notification
  /// for that one, not a crash.
  Future<void> _notifyFinished(String id, String? myName) async {
    try {
      final job = await fetchJob(ref.read(apiClientProvider), id);
      if (job.createdBy == myName) return;
      ref
          .read(browserNotificationsProvider)
          .show(
            '${job.createdBy}\'s ${job.actionName ?? 'build'} ${job.state.name}',
          );
    } catch (_) {
      // Best-effort — see doc comment.
    }
  }
}

final teamActivityWatcherProvider = NotifierProvider<TeamActivityWatcher, void>(
  TeamActivityWatcher.new,
);
