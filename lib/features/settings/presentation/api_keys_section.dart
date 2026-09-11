import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpt_server_website/shared/utils/responsive.dart';

import '../../../core/browser/browser_utils.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../application/api_keys_controller.dart';

/// `admin.apiKeys.list/add/remove` — self-service key management. Delete on
/// someone else's key is only offered when the local key holds `admin`,
/// mirroring the server's own enforcement instead of exposing a 403 button.
class ApiKeysSection extends ConsumerWidget {
  const ApiKeysSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(apiKeysProvider);
    final myKey = ref.watch(myKeyInfoProvider).value;

    // Same ambiguity as ZentaoSection's status check: `keys.value` is null
    // both before the first load resolves and when it resolves to an actual
    // null (no stored key, or the catalogue has no such action) — both cases
    // hide the card the same way, so there's nothing to tell apart.
    if (keys.value == null && !keys.hasError) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.vpn_key_outlined),
        title: const Text('API keys'),
        subtitle: Text(_summary(keys)),
        // `.when` with both skip flags, not a hand-matched `switch` checking
        // `error?` before `value?` (as this used to) — the latter shows the
        // error tile even when a still-good previous list is sitting right
        // in `.value`, which is exactly what a reload/refresh hitting a
        // transient failure produces.
        children: keys.when(
          skipLoadingOnReload: true,
          skipError: true,
          error: (error, _) => [
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Unable to load API keys'),
              subtitle: Text('$error'),
            ),
          ],
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          ],
          // `value` is technically nullable (no stored key, or the catalogue
          // has no such action) — but the early return above already sent
          // that case back as `SizedBox.shrink()`, so it can't reach here.
          data: (value) => value == null
              ? const []
              : [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    // Matches the Appearance card: a Column with
                    // crossAxisAlignment.start otherwise shrink-wraps to the
                    // table's intrinsic width instead of stretching full
                    // width like every other expanded child here.
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          // DataTable2 fills the available width by
                          // distributing it across columns by relative
                          // [ColumnSize] instead of sizing each to its
                          // content and scrolling horizontally once they
                          // overflow — which is what the plain DataTable
                          // this replaced did, given Hash's 64 hex
                          // characters. It still needs a bounded height from
                          // somewhere (it lays out its body as its own
                          // scrollable), which this ExpansionTile's child
                          // list doesn't provide on its own.
                          SizedBox(
                            height: _tableHeight(value.length),
                            child: DataTable2(
                              minWidth: kTabletBreakpoint,
                              columnSpacing: 16,
                              horizontalMargin: 0,
                              columns: const [
                                DataColumn2(
                                  label: Text('Name'),
                                  fixedWidth: 150,
                                ),
                                DataColumn2(
                                  label: Text('Hash'),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Text('Scopes'),
                                  fixedWidth: 150,
                                ),
                                DataColumn2(
                                  label: Text('Last used'),
                                  fixedWidth: 150,
                                ),
                                DataColumn2(
                                  label: Text('Actions'),
                                  fixedWidth: 150,
                                ),
                              ],
                              rows: [
                                for (final key in value)
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
      ),
    );
  }

  /// Collapsed, this card is a status line — same convention as every other
  /// card on this page. Value checked before error, same reasoning as
  /// [ZentaoSection]'s `_summary`/`_icon`.
  String _summary(AsyncValue<List<ApiKeyInfo>?> keys) => switch (keys) {
    AsyncValue(:final value?) => '${value.length} key(s)',
    AsyncValue(hasError: true) => 'Unable to load',
    _ => 'Checking…',
  };

  /// [DataTable2]'s body scrolls itself and so needs a bounded height from
  /// its parent — sized to fit every row up to a point, then capped so a
  /// long key list scrolls in place instead of pushing the rest of this
  /// card (and the "Create key" button below it) off no matter how tall.
  double _tableHeight(int rowCount) {
    const headingHeight = 56.0, rowHeight = 52.0, maxHeight = 400.0;
    return (headingHeight + rowCount * rowHeight).clamp(
      headingHeight + rowHeight,
      maxHeight,
    );
  }

  DataRow2 _row(
    BuildContext context,
    WidgetRef ref,
    ApiKeyInfo key,
    ApiKeyInfo? myKey,
  ) {
    final isSelf = myKey != null && myKey.id == key.id;
    final isAdmin = myKey?.isAdmin ?? false;
    final canDelete = isSelf || isAdmin;
    final lastUsed = key.lastUsedAt;
    return DataRow2(
      cells: [
        DataCell(Text(key.name)),
        DataCell(EllipsisText(key.keyHash)),
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
    await ref.read(apiKeysProvider.notifier).setScopes(key, scopes);
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
    await ref.read(apiKeysProvider.notifier).delete(context, key);
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

    final secret = await ref.read(apiKeysProvider.notifier).create(name);
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
