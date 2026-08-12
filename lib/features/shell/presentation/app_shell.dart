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
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/job_state_chip.dart';

/// Persistent layout for every screen: top nav generated from the
/// `/actions` catalogue, a queue sidebar fed by polled `GET /status`, and
/// the routed screen filling the remaining space. Read is public — this
/// renders the same with or without a stored key, only the top-right
/// Connect/Sign-out control changes.
///
/// Below [kMobileBreakpoint] the fixed 300px queue column (which would
/// otherwise leave no room for the routed screen) moves into a leading
/// [Drawer], opened by Scaffold's automatic hamburger button — matching where
/// it sits as the permanent left sidebar on desktop. The nav row (which would
/// otherwise overflow the app bar) moves into a [Scaffold.endDrawer] on the
/// right instead, matching where its buttons sit in the app bar's trailing
/// `actions` on desktop.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final actions = ref.watch(actionsProvider);
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
        elevation: 5,
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
          ],
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
          connectControl,
          // Last action, at the trailing corner — matching where Scaffold
          // would put its own auto-generated endDrawer button, had one not
          // been supplied explicitly here. On desktop the nav row is already
          // in this same trailing position, so this (and the endDrawer it
          // opens) sits where a desktop user would expect it.
          if (mobile)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.apps),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      drawer: mobile ? const Drawer(width: 300, child: _QueueSidebar()) : null,
      endDrawer: mobile
          ? _NavDrawer(location: location, actions: actions)
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
class _NavDrawer extends ConsumerWidget {
  const _NavDrawer({required this.location, required this.actions});

  final String location;
  final AsyncValue<List<ActionSchema>> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myKey = ref.watch(myKeyInfoProvider).value;
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
                final invokable = visibleBuildMenuActions(data, myKey);
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
    final colorScheme = Theme.of(context).colorScheme;
    // Always the same button type/padding — only the background color
    // changes with selection, so toggling never resizes or shifts
    // neighboring buttons the way swapping TextButton for FilledButton did.
    return TextButton.icon(
      style: selected
          ? TextButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            )
          : null,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ActionsMenu extends ConsumerWidget {
  const _ActionsMenu({required this.actions});

  final List<ActionSchema> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myKey = ref.watch(myKeyInfoProvider).value;
    final invokable = visibleBuildMenuActions(actions, myKey);
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
    final myKey = ref.watch(myKeyInfoProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: status.when(
        data: (data) {
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = [...data.running, ...data.queued];
          // Column + Expanded, not one scrolling ListView — the connection
          // footer (host, connected key) belongs pinned at the bottom of the
          // sidebar regardless of how many/few job rows are above it, not
          // sitting wherever the job list happens to end.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Badge.count(
                    count: data.running.length,
                    child: const Chip(
                      avatar: Icon(Icons.autorenew),
                      label: Text('Running'),
                    ),
                  ),
                  Badge.count(
                    count: data.queued.length,
                    child: const Chip(
                      avatar: Icon(Icons.schedule),
                      label: Text('Queued'),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: jobs.isEmpty
                    ? const ListTile(dense: true, title: Text('—'))
                    : ListView(
                        children: [
                          for (final job in jobs) _QueueJobTile(job: job),
                        ],
                      ),
              ),
              const Divider(),
              ListTile(
                dense: true,
                leading: const Icon(Icons.dns),
                title: Text(data.hostname),
                subtitle: Text(
                  'up ${data.uptime} · Dart ${formatDartVersion(data.dartVersion)}',
                ),
              ),
              myKey.maybeWhen(
                data: (info) => info == null
                    ? const SizedBox.shrink()
                    : ListTile(
                        dense: true,
                        leading: const Icon(Icons.vpn_key_outlined),
                        title: Text(info.name),
                        subtitle: const Text('Connected key'),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorListTile(
          error: error,
          title: 'Status unavailable',
          onRetry: () =>
              ref.read(statusControllerProvider.notifier).refreshNow(),
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
      leading: JobStateIcon(state: job.state),
      title: Text(job.actionName ?? job.command),
      subtitle: duration != null
          ? Text(formatDuration(duration))
          : const Text('queued'),
      onTap: () => context.go('/builds/${job.id}'),
    );
  }
}
