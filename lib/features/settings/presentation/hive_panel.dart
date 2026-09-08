import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/confirm_dialog.dart';
import '../application/hive_boxes_controller.dart';

/// Lets an admin inspect and wipe any Hive storage box straight from the
/// browser — `system.hive.list`/`system.hive.clean`, REST/MCP-only
/// otherwise. Useful after a refactor changes what a box's records look
/// like: list first to see names and entry counts, then clean the specific
/// one that's now stale instead of needing shell access to the box files.
class HivePanel extends ConsumerWidget {
  const HivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boxes = ref.watch(hiveBoxesControllerProvider);
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.storage),
        title: const Text('Hive database'),
        subtitle: const Text('Inspect and clean storage boxes'),
        onExpansionChanged: (value) {
          if (value && boxes == null) {
            ref.read(hiveBoxesControllerProvider.notifier).load();
          }
        },
        children: [
          if (boxes == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (boxes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No boxes open.'),
            )
          else
            for (final box in boxes)
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(box.name),
                subtitle: Text(
                  '${box.entryCount} '
                  'entr${box.entryCount == 1 ? 'y' : 'ies'}',
                ),
                trailing: IconButton(
                  tooltip: 'Clean this box',
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _clean(context, ref, box),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _clean(
    BuildContext context,
    WidgetRef ref,
    HiveBoxInfo box,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Clean "${box.name}"?',
      body:
          'Deletes all ${box.entryCount} '
          'entr${box.entryCount == 1 ? 'y' : 'ies'} in this box. '
          'This cannot be undone.',
      confirmLabel: 'Clean box',
      isDangerous: true,
    );
    if (!confirmed) return;
    await ref.read(hiveBoxesControllerProvider.notifier).clean(box.name);
  }
}
