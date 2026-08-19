import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';

/// One entry from `system.hive.list`'s `boxes` array.
class _HiveBoxInfo {
  const _HiveBoxInfo({required this.name, required this.entryCount});

  final String name;
  final int entryCount;
}

/// Lets an admin inspect and wipe any Hive storage box straight from the
/// browser — `system.hive.list`/`system.hive.clean`, REST/MCP-only
/// otherwise. Useful after a refactor changes what a box's records look
/// like: list first to see names and entry counts, then clean the specific
/// one that's now stale instead of needing shell access to the box files.
class HivePanel extends ConsumerStatefulWidget {
  const HivePanel({super.key});

  @override
  ConsumerState<HivePanel> createState() => _HivePanelState();
}

class _HivePanelState extends ConsumerState<HivePanel> {
  List<_HiveBoxInfo>? _boxes;

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final body = await api.decodeMap(
        api.endpoints.invokeAction(
          'system.hive.list',
          api.encodeBody(const {}),
        ),
      );
      final raw = body['boxes'] as List<dynamic>? ?? const [];
      final boxes = [
        for (final entry in raw.cast<Map<String, dynamic>>())
          _HiveBoxInfo(
            name: entry['name'] as String,
            entryCount: entry['entry_count'] as int,
          ),
      ];
      if (mounted) setState(() => _boxes = boxes);
    } on ApiException catch (e) {
      if (mounted) {
        ref.read(appToastProvider.notifier).show(e.message, isError: true);
      }
    }
  }

  Future<void> _clean(_HiveBoxInfo box) async {
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

    try {
      final api = ref.read(apiClientProvider);
      final body = await api.decodeMap(
        api.endpoints.invokeAction(
          'system.hive.clean',
          api.encodeBody({'box': box.name}),
        ),
      );
      if (!mounted) return;
      ref
          .read(appToastProvider.notifier)
          .show(body['message'] as String? ?? 'Done');
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ref.read(appToastProvider.notifier).show(e.message, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = _boxes;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.storage),
        title: const Text('Hive database'),
        subtitle: const Text('Inspect and clean storage boxes'),
        onExpansionChanged: (value) {
          if (value && boxes == null) _load();
        },
        children: [
          if (boxes == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (boxes.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: const Text('No boxes open.'),
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
                  onPressed: () => _clean(box),
                ),
              ),
        ],
      ),
    );
  }
}
