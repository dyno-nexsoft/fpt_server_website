import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalogue_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/error_view.dart';

/// Where the "New build" control lands — picking a specific action to run
/// happens on its own page instead of a cramped dropdown/menu wherever the
/// control itself sits (app bar, nav rail, FAB), so it reads the same
/// regardless of where it was opened from.
class NewBuildScreen extends ConsumerWidget {
  const NewBuildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(actionsProvider);
    final myKey = ref.watch(myKeyInfoProvider).value;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.add_circle_outline),
              Text('New build', style: textTheme.headlineSmall),
            ],
          ),
          Expanded(
            child: actions.when(
              data: (data) {
                final invokable = visibleBuildMenuActions(data, myKey);
                if (invokable.isEmpty) {
                  return const Center(
                    child: Text('No runnable actions available for this key.'),
                  );
                }
                return ListView(
                  children: [
                    for (final action in invokable)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            action.isDangerous
                                ? Icons.warning_amber
                                : Icons.bolt,
                          ),
                          title: Text(action.name),
                          subtitle: action.description.isEmpty
                              ? null
                              : Text(action.description),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => ActionFormRoute(action.name).go(context),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(error: error),
            ),
          ),
        ],
      ),
    );
  }
}
