import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalogue_providers.dart';
import '../../../shared/widgets/error_card.dart';
import '../../../shared/widgets/tile_grid.dart';
import '../application/owners_controller.dart';

/// `admin.owners.list/add/remove` — the Discord accounts that hold bot
/// ownership regardless of API key scopes. One tab of [AdminScreen].
///
/// Ownership is granted by Discord user id, so that is all there is to show:
/// this dashboard never talks to Discord and cannot resolve an id to a
/// username.
class OwnersSection extends ConsumerWidget {
  const OwnersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owners = ref.watch(ownersProvider);
    final myDiscordId = ref.watch(myKeyInfoProvider).value?.discordUserId;

    return owners.when(
      data: (ids) {
        final list = ids ?? const [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              if (list.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('No owners stored.'),
                    subtitle: Text(
                      'OWNER_ID in the launch config still grants access.',
                    ),
                  ),
                )
              else
                TileGrid(
                  children: [
                    for (final id in list)
                      _OwnerTile(id: id, isSelf: id == myDiscordId),
                  ],
                ),
              FilledButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add owner'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(title: 'Unable to load owners', error: error),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add owner'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Discord user ID',
            helperText: 'Enable Developer Mode in Discord to copy an ID.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (id == null || id.isEmpty || !context.mounted) return;
    await ref.read(ownersControllerProvider).add(id);
  }
}

class _OwnerTile extends ConsumerWidget {
  const _OwnerTile({required this.id, required this.isSelf});

  final String id;

  /// Removing your own ownership is allowed but worth warning about, since
  /// nothing on this screen can grant it back afterwards.
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(id),
        subtitle: isSelf ? const Text('This is you') : null,
        trailing: IconButton(
          tooltip: 'Remove owner',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmRemove(context, ref),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove owner?'),
        content: Text(
          isSelf
              ? 'Removes your own ownership. You will not be able to grant it '
                    'back from here — only OWNER_ID in the launch config, or '
                    'another owner, can.'
              : 'Removes owner $id.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(ownersControllerProvider).remove(id);
  }
}
