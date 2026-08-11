import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/action_schema.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/job_state_chip.dart';

/// Persistent layout for every screen: top nav generated from the
/// `/actions` catalogue, a queue sidebar fed by polled `GET /status`, and
/// the routed screen filling the remaining space. Read is public — this
/// renders the same with or without a stored key, only the top-right
/// Connect/Sign-out control changes.
///
/// Below [kMobileBreakpoint] the nav row (which would otherwise overflow the
/// app bar) moves into a leading [Drawer], and the fixed 300px queue column
/// (which would otherwise leave no room for the routed screen) moves into a
/// [Scaffold.endDrawer] opened from an app bar icon instead of staying
/// permanently on screen.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final actions = ref.watch(actionsProvider);
    final myKey = ref.watch(myKeyInfoProvider);
    final hasKey = ref.watch(sessionProvider).hasKey;
    final mobile = isMobileWidth(context);

    final connectControl = hasKey
        ? IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(connectionControllerProvider.notifier).logout(),
          )
        : IconButton(
            tooltip: 'Connect',
            icon: const Icon(Icons.login),
            onPressed: () => context.go('/login'),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('CI/CD'),
        actions: [
          if (!mobile) ...[
            _NavButton(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selected: location == '/dashboard',
              onPressed: () => context.go('/dashboard'),
            ),
            _NavButton(
              label: 'Builds',
              icon: Icons.list_alt_outlined,
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
          ],
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          connectControl,
          // Last action, at the trailing corner — matching where Scaffold
          // would put its own auto-generated endDrawer button, had one not
          // been supplied explicitly here. On desktop the queue is already
          // the permanent left sidebar below, so this (and the endDrawer it
          // opens) would just show the exact same content a second time.
          if (mobile)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Queue',
                icon: const Icon(Icons.list_alt),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      drawer: mobile ? _NavDrawer(location: location, actions: actions) : null,
      endDrawer: mobile
          ? const Drawer(width: 300, child: _QueueSidebar())
          : null,
      body: mobile
          ? child
          : Row(
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

/// Mobile-only replacement for the app bar's nav row — the same
/// Dashboard/Builds/New build controls, laid out as a list instead of
/// buttons that would otherwise overflow a phone-width app bar.
class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.location, required this.actions});

  final String location;
  final AsyncValue<List<ActionSchema>> actions;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: location == '/dashboard',
              onTap: () {
                Navigator.of(context).pop();
                context.go('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Builds'),
              selected: location == '/builds',
              onTap: () {
                Navigator.of(context).pop();
                context.go('/builds');
              },
            ),
            const Divider(),
            actions.when(
              data: (data) {
                final invokable = data.where(isBuildMenuAction).toList();
                return Column(
                  children: [
                    for (final action in invokable)
                      ListTile(
                        leading: Icon(
                          action.isDangerous ? Icons.warning_amber : Icons.bolt,
                        ),
                        title: Text(action.name),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/actions/${action.name}');
                        },
                      ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({required this.actions});

  final List<ActionSchema> actions;

  @override
  Widget build(BuildContext context) {
    final invokable = actions.where(isBuildMenuAction).toList();
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.autorenew),
                    label: Text('Running ${data.running.length}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.schedule),
                    label: Text('Queued ${data.queued.length}'),
                  ),
                ],
              ),
              const Divider(),
              for (final job in jobs) _QueueJobTile(job: job),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.dns),
                title: Text(data.hostname),
                subtitle: Text(
                  'up ${data.uptime} · Dart ${formatDartVersion(data.dartVersion)}',
                ),
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
