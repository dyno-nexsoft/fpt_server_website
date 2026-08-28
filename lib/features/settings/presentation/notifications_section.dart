import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/notification_preferences_provider.dart';

/// Desktop notifications for a finished build/review, or a teammate's
/// activity — see `BrowserNotifications` and `TeamActivityWatcher`.
///
/// The permission row is the one thing that needs a user gesture
/// (`Notification.requestPermission()` only does anything called from one),
/// so it's always visible; the per-category switches only matter once
/// permission is actually granted, so they're hidden until then rather than
/// shown disabled for a setting granting it wouldn't yet do anything.
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key});

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(browserNotificationsProvider);
    if (!notifications.isSupported) return const SizedBox.shrink();

    final granted = notifications.permission == 'granted';
    final (icon, subtitle) = switch (notifications.permission) {
      'granted' => (Icons.notifications_active_outlined, 'On'),
      'denied' => (Icons.notifications_off_outlined, 'Blocked by the browser'),
      _ => (Icons.notifications_none_outlined, 'Off'),
    };

    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: const Text('Notifications'),
        subtitle: Text(subtitle),
        children: [
          ListTile(
            title: const Text('Browser permission'),
            subtitle: Text(switch (notifications.permission) {
              'granted' => 'Granted — this tab can show desktop notifications.',
              'denied' =>
                'Blocked. Allow notifications for this site in the '
                    "browser's own address-bar permissions to turn this "
                    'back on.',
              _ =>
                'Get notified when a build or review finishes, or a '
                    'teammate starts one, while this tab is in the '
                    'background.',
            }),
            isThreeLine: true,
            trailing: granted || notifications.permission == 'denied'
                ? null
                : FilledButton.tonal(
                    onPressed: () async {
                      await notifications.requestPermission();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Enable'),
                  ),
          ),
          if (granted) ...[
            const Divider(height: 1),
            const _PreferenceSwitches(),
          ],
        ],
      ),
    );
  }
}

class _PreferenceSwitches extends ConsumerWidget {
  const _PreferenceSwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    return Column(
      children: [
        SwitchListTile(
          title: const Text('My activity'),
          subtitle: const Text(
            'A build, review, or translation you started finishing',
          ),
          value: prefs.myActivity,
          onChanged: notifier.setMyActivity,
        ),
        SwitchListTile(
          title: const Text('Teammate started a build'),
          value: prefs.teamStarted,
          onChanged: notifier.setTeamStarted,
        ),
        SwitchListTile(
          title: const Text('Teammate\'s build finished'),
          value: prefs.teamFinished,
          onChanged: notifier.setTeamFinished,
        ),
      ],
    );
  }
}
