import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/browser/browser_utils.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/toast/app_toast.dart';
import '../application/settings_providers.dart';

/// `admin.apiKeys.list/add/remove` — self-service key management. Delete on
/// someone else's key is only offered when the local key holds `admin`,
/// mirroring the server's own enforcement instead of exposing a 403 button.
class ApiKeysSection extends ConsumerWidget {
  const ApiKeysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(apiKeysProvider);
    final myKey = ref.watch(myKeyInfoProvider).value;

    return keys.when(
      data: (list) {
        if (list == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            // Matches the Appearance card: a Column with
            // crossAxisAlignment.start otherwise shrink-wraps to the
            // DataTable's intrinsic width instead of the card stretching
            // full width like its siblings.
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(
                    'API keys',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Hash')),
                        DataColumn(label: Text('Scopes')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final key in list) _row(context, ref, key, myKey),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showCreateKeyFlow(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create key'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error'),
    );
  }

  DataRow _row(
    BuildContext context,
    WidgetRef ref,
    ApiKeyInfo key,
    ApiKeyInfo? myKey,
  ) {
    final isSelf = myKey != null && myKey.id == key.id;
    final canDelete = isSelf || (myKey?.isAdmin ?? false);
    return DataRow(
      cells: [
        DataCell(Text(key.name)),
        DataCell(Text(key.keyHash)),
        DataCell(Text(key.scopes.join(', '))),
        DataCell(
          canDelete
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, key),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ApiKeyInfo key,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API key?'),
        content: Text('This permanently removes "${key.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Read before the delete call, not after: once the key that's actually
    // signed in is gone, every subsequent request (including whatever
    // myKeyInfoProvider would refetch) 401s.
    final isSelf = ref.read(myKeyInfoProvider).value?.id == key.id;

    try {
      final api = ref.read(apiClientProvider);
      await api.decodeMap(
        api.endpoints.invokeAction(
          'admin.apiKeys.remove',
          api.encodeBody({'id': key.id}),
        ),
      );
      if (isSelf) {
        // The credential this session is signed in with no longer exists
        // server-side — every further authed call from here on 401s until
        // the user signs in again, so sign out now instead of leaving the
        // UI showing a now-invalid "connected" state.
        await ref.read(connectionControllerProvider.notifier).logout();
        if (context.mounted) const LoginRoute().go(context);
        return;
      }
      ref.invalidate(apiKeysProvider);
      ref.read(appToastProvider.notifier).show('Key deleted.');
    } on ApiException catch (e) {
      ref.read(appToastProvider.notifier).show(e.message, isError: true);
    }
  }

  Future<void> _showCreateKeyFlow(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create API key'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;

    try {
      final api = ref.read(apiClientProvider);
      final body = await api.decodeMap(
        api.endpoints.invokeAction(
          'admin.apiKeys.add',
          api.encodeBody({'name': name}),
        ),
      );
      ref.invalidate(apiKeysProvider);
      if (context.mounted) {
        await _showSecretDialog(context, body['secret'] as String);
      }
    } on ApiException catch (e) {
      ref.read(appToastProvider.notifier).show(e.message, isError: true);
    }
  }

  Future<void> _showSecretDialog(BuildContext context, String secret) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SecretDialog(secret: secret),
    );
  }
}

class _SecretDialog extends StatefulWidget {
  const _SecretDialog({required this.secret});

  final String secret;

  @override
  State<_SecretDialog> createState() => _SecretDialogState();
}

class _SecretDialogState extends State<_SecretDialog> {
  bool _revealed = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('API key created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Text(
            'This secret is shown once and gone forever after this dialog '
            'closes.',
          ),
          SelectableText(
            _revealed ? widget.secret : '•' * widget.secret.length,
          ),
          Row(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _revealed = !_revealed),
                icon: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
                label: Text(_revealed ? 'Hide' : 'Reveal'),
              ),
              TextButton.icon(
                onPressed: () {
                  copyToClipboard(widget.secret);
                  setState(() => _copied = true);
                },
                icon: const Icon(Icons.copy),
                label: Text(_copied ? 'Copied' : 'Copy'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
