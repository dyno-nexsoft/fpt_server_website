import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

/// Turns on desktop notifications for a finished build or `gitlab.review`/
/// `translateArb` run — the one UI this needs at all, since
/// `Notification.requestPermission()` only does anything when called from a
/// user gesture like this button; there is nowhere else in the app a prompt
/// could come from.
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

    final (icon, subtitle, action) = switch (notifications.permission) {
      'granted' => (
        Icons.notifications_active_outlined,
        'On — a build or review finishing while this tab is in the '
            'background shows a notification.',
        null,
      ),
      'denied' => (
        Icons.notifications_off_outlined,
        'Blocked. Allow notifications for this site in the browser\'s own '
            'address-bar permissions to turn this back on.',
        null,
      ),
      _ => (
        Icons.notifications_none_outlined,
        'Off — get notified when a build or review finishes while this tab '
            'is in the background.',
        'Enable',
      ),
    };

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: const Text('Notifications'),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: action == null
            ? null
            : FilledButton.tonal(
                onPressed: () async {
                  await notifications.requestPermission();
                  // permission is read fresh on every build; nothing to
                  // store — the browser is already the source of truth.
                  if (mounted) setState(() {});
                },
                child: Text(action),
              ),
      ),
    );
  }
}
