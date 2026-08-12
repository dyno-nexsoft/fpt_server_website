import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/toast/app_toast.dart';
import '../../builds/application/jobs_providers.dart';

/// `system.restart` and `system.hotReload` are `admin`-only but, like
/// `admin.logs.tail`, are exposed over REST — see `SystemAction`'s doc
/// comment for why that residual risk is accepted. Only `system.shutdown`
/// is actually withheld from REST entirely (`Action.exposedOverRest` is
/// false there — an unattended `exit(0)` has no automatic recovery), so it's
/// the only one still listed as unavailable rather than actionable.
/// Admin-only display: nobody else's key could call these even if shown.
class SystemPanel extends ConsumerWidget {
  const SystemPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myKey = ref.watch(myKeyInfoProvider).value;
    if (myKey == null || !myKey.isAdmin) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('System', style: Theme.of(context).textTheme.titleMedium),
            _ActionTile(
              icon: Icons.refresh,
              name: 'system.hotReload',
              description: 'Pull the latest code and hot reload — no restart.',
              confirmTitle: 'Hot reload?',
              confirmBody: 'Pulls the latest code and hot reloads the bot.',
            ),
            _ActionTile(
              icon: Icons.restart_alt,
              name: 'system.restart',
              description:
                  'Pull code, install dependencies, and restart — briefly '
                  'offline.',
              confirmTitle: 'Restart the server?',
              confirmBody:
                  'Pulls code, installs dependencies, and restarts the bot. '
                  'It will be briefly unreachable.',
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.block),
              title: Text('system.shutdown'),
              subtitle: Text('Unavailable in browser — use Discord.'),
            ),
            _ActionTile(
              icon: Icons.delete_sweep_outlined,
              name: 'system.clearHistory',
              description:
                  'Delete all finished build history. Running/queued jobs '
                  'are untouched.',
              confirmTitle: 'Clear all build history?',
              confirmBody:
                  'Permanently deletes every finished job from history. '
                  'This cannot be undone.',
              onSuccess: () => ref.invalidate(jobsListProvider),
              isDangerous: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends ConsumerWidget {
  const _ActionTile({
    required this.icon,
    required this.name,
    required this.description,
    required this.confirmTitle,
    required this.confirmBody,
    this.onSuccess,
    this.isDangerous = false,
  });

  final IconData icon;
  final String name;
  final String description;
  final String confirmTitle;
  final String confirmBody;

  /// Called after the action succeeds — lets a caller refresh whatever it
  /// just changed (e.g. the builds list after clearing history) without every
  /// tile needing to know about that provider.
  final VoidCallback? onSuccess;

  /// Deletes something with no undo (clearing history) rather than just
  /// restarting/reloading — gets the same visual weight as Cancel elsewhere
  /// in the app instead of the same tonal button every other tile here uses.
  final bool isDangerous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDangerous ? colorScheme.error : null),
      title: Text(
        name,
        style: isDangerous ? TextStyle(color: colorScheme.error) : null,
      ),
      subtitle: Text(description),
      onTap: () => _confirmAndRun(context, ref),
    );
  }

  Future<void> _confirmAndRun(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Run'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      final body = await api.postJson('/actions/$name');
      ref
          .read(appToastProvider.notifier)
          .show(body['message'] as String? ?? 'Done');
      onSuccess?.call();
    } on ApiException catch (e) {
      ref.read(appToastProvider.notifier).show(e.message, isError: true);
    }
  }
}
