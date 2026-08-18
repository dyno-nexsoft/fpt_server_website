import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';

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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'System',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
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
          const _ActionTile(
            icon: Icons.block,
            name: 'system.shutdown',
            description: 'Unavailable in browser — use Discord.',
            confirmTitle: 'Shutdown the server?',
            confirmBody:
                'Shuts down the bot. It will not restart automatically. '
                'Use Discord to restart it.',
            isDangerous: true,
          ),
        ],
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
    this.isDangerous = false,
  });

  final IconData icon;
  final String name;
  final String description;
  final String confirmTitle;
  final String confirmBody;

  /// Deletes something with no undo rather than just restarting/reloading —
  /// gets the same visual weight as Cancel elsewhere in the app instead of
  /// the same tonal button every other tile here uses.
  final bool isDangerous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
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
    final Map<String, dynamic> params;
    // system.restart alone gets the when_idle choice — hotReload/shutdown
    // have no such param, and ConfirmDialog's plain yes/no covers them fine.
    if (name == 'system.restart') {
      final whenIdle = await _RestartConfirmDialog.show(context);
      if (whenIdle == null) return;
      params = {if (whenIdle) 'when_idle': true};
    } else {
      final confirmed = await ConfirmDialog.show(
        context,
        title: confirmTitle,
        body: confirmBody,
        confirmLabel: 'Run',
        isDangerous: isDangerous,
      );
      if (!confirmed) return;
      params = const {};
    }

    try {
      final api = ref.read(apiClientProvider);
      final body = await api.decodeMap(
        api.endpoints.invokeAction(name, api.encodeBody(params)),
      );
      ref
          .read(appToastProvider.notifier)
          .show(body['message'] as String? ?? 'Done');
    } on ApiException catch (e) {
      ref.read(appToastProvider.notifier).show(e.message, isError: true);
    }
  }
}

/// [ConfirmDialog] plus a "wait until idle" checkbox — `system.restart`'s
/// only param, so this doesn't warrant a generic extension to the shared
/// dialog every other confirmation here still uses unchanged.
///
/// Resolves `null` on cancel, otherwise the checkbox's value.
class _RestartConfirmDialog extends StatefulWidget {
  const _RestartConfirmDialog();

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (_) => const _RestartConfirmDialog(),
  );

  @override
  State<_RestartConfirmDialog> createState() => _RestartConfirmDialogState();
}

class _RestartConfirmDialogState extends State<_RestartConfirmDialog> {
  bool _whenIdle = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restart the server?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pulls code, installs dependencies, and restarts the bot. It '
            'will be briefly unreachable.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _whenIdle,
            onChanged: (value) => setState(() => _whenIdle = value ?? false),
            title: const Text('Wait until no builds are running or queued'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _whenIdle),
          child: const Text('Run'),
        ),
      ],
    );
  }
}
