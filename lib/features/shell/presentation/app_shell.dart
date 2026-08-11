import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/action_schema.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/job_state_chip.dart';

/// Persistent layout for every screen once connected: top nav generated from
/// the `/actions` catalogue, a queue sidebar fed by polled `GET /status`,
/// and the routed screen filling the remaining space.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final actions = ref.watch(actionsProvider);
    final myKey = ref.watch(myKeyInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CI/CD'),
        actions: [
          _NavButton(
            label: 'Dashboard',
            selected: location == '/dashboard',
            onPressed: () => context.go('/dashboard'),
          ),
          _NavButton(
            label: 'Builds',
            selected: location == '/builds',
            onPressed: () => context.go('/builds'),
          ),
          actions.when(
            data: (data) => _ActionsMenu(actions: data),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          myKey.maybeWhen(
            data: (info) => info == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(child: Text(info.name)),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(connectionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 300, child: _QueueSidebar()),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton.tonal(onPressed: onPressed, child: Text(label))
        : TextButton(onPressed: onPressed, child: Text(label));
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.actions});

  final List<ActionSchema> actions;

  @override
  Widget build(BuildContext context) {
    final invokable = actions
        .where((a) => a.kind == ActionKind.job || a.kind == ActionKind.mutation)
        .toList();
    if (invokable.isEmpty) return const SizedBox.shrink();

    return MenuAnchor(
      builder: (context, controller, child) => TextButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.add),
        label: const Text('New build'),
      ),
      menuChildren: [
        for (final action in invokable)
          MenuItemButton(
            leadingIcon: Icon(
              action.isDangerous ? Icons.warning_amber : Icons.bolt,
            ),
            onPressed: () => context.go('/actions/${action.name}'),
            child: Text(action.name),
          ),
      ],
    );
  }
}

class _QueueSidebar extends ConsumerWidget {
  const _QueueSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: status.when(
        data: (data) {
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = [...data.running, ...data.queued];
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text(
                  'Running x${data.running.length}  '
                  'queued x${data.queued.length}',
                ),
              ),
              const Divider(),
              for (final job in jobs) _QueueJobTile(job: job),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dns),
                title: Text(data.hostname),
                subtitle: Text('up ${data.uptime} · Dart ${data.dartVersion}'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListTile(
          leading: const Icon(Icons.error_outline),
          title: const Text('Status unavailable'),
          subtitle: Text('$error'),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(statusControllerProvider.notifier).refreshNow(),
          ),
        ),
      ),
    );
  }
}

class _QueueJobTile extends StatelessWidget {
  const _QueueJobTile({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final duration = job.runningDuration;
    return ListTile(
      dense: true,
      leading: JobStateChip(state: job.state),
      title: Text(job.actionName),
      subtitle: duration != null
          ? Text(formatDuration(duration))
          : const Text('queued'),
      onTap: () => context.go('/jobs/${job.id}'),
    );
  }
}
