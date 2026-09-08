import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/confirm_dialog.dart';
import '../application/hive_boxes_controller.dart';

/// Lets an admin inspect and wipe any Hive storage box straight from the
/// browser — `system.hive.list`/`system.hive.clean`, REST/MCP-only
/// otherwise. Useful after a refactor changes what a box's records look
/// like: list first to see names and entry counts, then clean the specific
/// one that's now stale instead of needing shell access to the box files.
///
/// The other group of tiles within [AdminScreen]'s Operations tab, alongside
/// [SystemPanel] — loads its own data on first build rather than waiting for
/// an expand event, since there is no longer a collapsed state to expand
/// from.
class HivePanel extends ConsumerStatefulWidget {
  const HivePanel({super.key});

  @override
  ConsumerState<HivePanel> createState() => _HivePanelState();
}

class _HivePanelState extends ConsumerState<HivePanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(hiveBoxesControllerProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boxes = ref.watch(hiveBoxesControllerProvider);
    if (boxes == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (boxes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No boxes open.'),
      );
    }
    return Column(
      children: [
        for (final box in boxes)
          Card(
            child: ListTile(
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
          ),
      ],
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
