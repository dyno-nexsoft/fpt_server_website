import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

const _myActivityKey = 'notifications_my_activity';
const _teamStartedKey = 'notifications_team_started';
const _teamFinishedKey = 'notifications_team_finished';

/// Which local-notification categories (see `BrowserNotifications`) are on.
/// Independent of the browser's own permission — that's the master switch;
/// these decide what gets sent once it's granted.
class NotificationPreferences {
  const NotificationPreferences({
    this.myActivity = true,
    this.teamStarted = false,
    this.teamFinished = false,
  });

  /// A build, review, or translation *you* started finishing. On by
  /// default — this is the whole reason the feature exists, and matches
  /// what it already did before there was a setting for it at all.
  final bool myActivity;

  /// Someone else starting a build.
  final bool teamStarted;

  /// Someone else's build finishing (whatever the outcome).
  ///
  /// Both team categories are off by default: unlike [myActivity], these
  /// notify about other people's actions, which is a much easier thing to
  /// find noisy — better to have it discovered and opted into than sprung
  /// on a solo user the moment they grant permission.
  final bool teamFinished;

  NotificationPreferences copyWith({
    bool? myActivity,
    bool? teamStarted,
    bool? teamFinished,
  }) => NotificationPreferences(
    myActivity: myActivity ?? this.myActivity,
    teamStarted: teamStarted ?? this.teamStarted,
    teamFinished: teamFinished ?? this.teamFinished,
  );
}

/// Persisted in `localStorage`, like the theme choice — mirrors
/// [ThemeModeNotifier]'s shape.
class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return NotificationPreferences(
      myActivity: prefs.getBool(_myActivityKey) ?? true,
      teamStarted: prefs.getBool(_teamStartedKey) ?? false,
      teamFinished: prefs.getBool(_teamFinishedKey) ?? false,
    );
  }

  Future<void> setMyActivity(bool value) async {
    state = state.copyWith(myActivity: value);
    await ref.read(sharedPreferencesProvider).setBool(_myActivityKey, value);
  }

  Future<void> setTeamStarted(bool value) async {
    state = state.copyWith(teamStarted: value);
    await ref.read(sharedPreferencesProvider).setBool(_teamStartedKey, value);
  }

  Future<void> setTeamFinished(bool value) async {
    state = state.copyWith(teamFinished: value);
    await ref.read(sharedPreferencesProvider).setBool(_teamFinishedKey, value);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      NotificationPreferencesNotifier.new,
    );
