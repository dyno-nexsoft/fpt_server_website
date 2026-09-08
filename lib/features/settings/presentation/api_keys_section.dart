import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/browser/browser_utils.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../shared/utils/format.dart';
import '../application/api_keys_controller.dart';
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
          child: ExpansionTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('API keys'),
            subtitle: Text('${list.length} key(s)'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                // Matches the Appearance card: a Column with
                // crossAxisAlignment.start otherwise shrink-wraps to the
                // DataTable's intrinsic width instead of stretching full
                // width like every other expanded child here.
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Hash')),
                            DataColumn(label: Text('Scopes')),
                            DataColumn(label: Text('Last used')),
                            DataColumn(label: Text('')),
                          ],
                          rows: [
                            for (final key in list)
                              _row(context, ref, key, myKey),
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
            ],
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
    final isAdmin = myKey?.isAdmin ?? false;
    final canDelete = isSelf || isAdmin;
    final lastUsed = key.lastUsedAt;
    return DataRow(
      cells: [
        DataCell(Text(key.name)),
        DataCell(Text(key.keyHash)),
        DataCell(Text(key.scopes.join(', '))),
        DataCell(
          Text(lastUsed == null ? 'Never' : formatRelativeTimestamp(lastUsed)),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Scope changes are admin-only server-side (see
              // ApiKeySetScopesAction) — hidden rather than shown-disabled
              // for anyone else, since a non-admin can never make it work.
              if (isAdmin)
                IconButton(
                  tooltip: 'Edit scopes',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editScopes(context, ref, key),
                ),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, key),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editScopes(
    BuildContext context,
    WidgetRef ref,
    ApiKeyInfo key,
  ) async {
    final scopes = await showDialog<List<String>>(
      context: context,
      builder: (context) => _ScopesEditDialog(initialScopes: key.scopes),
    );
    if (scopes == null || !context.mounted) return;
    await ref.read(apiKeysControllerProvider).setScopes(key, scopes);
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
    if (confirmed != true || !context.mounted) return;
    await ref.read(apiKeysControllerProvider).delete(context, key);
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

    final secret = await ref.read(apiKeysControllerProvider).create(name);
    if (secret != null && context.mounted) {
      await _showSecretDialog(context, secret);
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

/// Checkbox per [Permission] value — resolves to the new scope list (Dart
/// enum-name strings, matching how scopes are already stored) or `null` on
/// cancel.
class _ScopesEditDialog extends StatefulWidget {
  const _ScopesEditDialog({required this.initialScopes});

  final List<String> initialScopes;

  @override
  State<_ScopesEditDialog> createState() => _ScopesEditDialogState();
}

class _ScopesEditDialogState extends State<_ScopesEditDialog> {
  late final Set<String> _selected = widget.initialScopes.toSet();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit scopes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final permission in Permission.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(permission.name),
              value: _selected.contains(permission.name),
              onChanged: (checked) => setState(() {
                if (checked ?? false) {
                  _selected.add(permission.name);
                } else {
                  _selected.remove(permission.name);
                }
              }),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
