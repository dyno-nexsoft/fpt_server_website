import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalogue_providers.dart';

const _unavailableActions = [
  'system.restart',
  'system.hotReload',
  'system.shutdown',
];

/// `system.restart`/`hotReload`/`shutdown` are deliberately not exposed over
/// REST (RCE risk on a public port) — see docs/rest-api.md "Not exposed".
/// This lists them as unavailable instead of letting an admin click into a
/// generated form that would just 404, and only shows for an admin key since
/// nobody else could reach these even if REST allowed it.
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
            for (final name in _unavailableActions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block),
                title: Text(name),
                subtitle: const Text('Unavailable in browser — use Discord.'),
              ),
          ],
        ),
      ),
    );
  }
}
