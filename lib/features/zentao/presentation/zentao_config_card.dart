import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../application/zentao_controller.dart';

/// `zentao.config.setProject` / `setExecution` — server-wide, not per-user.
///
/// Shown only to a key holding `invokeDangerous`, which is what the actions
/// require: changing either silently redirects *everyone's* next report, so
/// the confirmation says so rather than treating it as a personal setting.
class ZentaoConfigCard extends ConsumerWidget {
  const ZentaoConfigCard({super.key, required this.status});

  final ZentaoStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune),
        title: const Text('Server-wide Zentao config'),
        subtitle: Text(
          'Project ${status.projectId} · execution ${status.executionId}',
        ),
        children: [
          _IdTile(
            icon: Icons.folder_outlined,
            label: 'Project',
            value: status.projectId,
            onSubmit: (id) => ref.read(zentaoControllerProvider).setProject(id),
          ),
          _IdTile(
            icon: Icons.timeline_outlined,
            label: 'Execution',
            value: status.executionId,
            onSubmit: (id) =>
                ref.read(zentaoControllerProvider).setExecution(id),
          ),
        ],
      ),
    );
  }
}

class _IdTile extends StatelessWidget {
  const _IdTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSubmit,
  });

  final IconData icon;
  final String label;
  final int value;
  final Future<void> Function(int id) onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text('$value'),
      trailing: IconButton(
        tooltip: 'Change $label',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _prompt(context),
      ),
    );
  }

  Future<void> _prompt(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    final entered = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '$label ID',
            helperText: 'Applies to everyone\'s next report.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Parsed here rather than server-side-only so a typo is a no-op instead
    // of a validation round trip: the action takes an integer, and anything
    // that isn't one was never going to be accepted.
    final id = int.tryParse(entered ?? '');
    if (id == null || id == value) return;
    await onSubmit(id);
  }
}
