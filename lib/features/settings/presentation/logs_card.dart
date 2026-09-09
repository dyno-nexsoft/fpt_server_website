import 'package:flutter/material.dart';

import '../../../core/router/app_router.dart';

/// The server-side logs `admin.logs.tail` can read, one entry each. A tab of
/// [AdminScreen].
///
/// Both open the same viewer, told apart by the action's own `source`. A
/// plain list, not [TileGrid] — these are two navigation rows to a full
/// viewer, and read better stacked full-width like every other settings
/// list than as a pair of side-by-side cards.
class LogsCard extends StatelessWidget {
  const LogsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server Logs'),
            subtitle: const Text('View the tail of server.log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ServerLogsRoute().go(context),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.desktop_windows_outlined),
            title: const Text('Remote Desktop Logs'),
            subtitle: const Text('View the tail of the noVNC service log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ServerLogsRoute(source: 'novnc').go(context),
          ),
        ),
      ],
    );
  }
}
