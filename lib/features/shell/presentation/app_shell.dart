import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/action_schema.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/utils/responsive.dart';

/// Persistent layout for every screen — Material 3's adaptive navigation
/// shape: a [NavigationRail] on desktop, a [NavigationBar] on mobile, a
/// running/queued status strip under the app bar either way, and the routed
/// screen filling the rest. Read is public — this renders the same with or
/// without a stored key, only the top-right Connect/Sign-out control changes.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  /// `/builds/:id` and the artifact browser nested under it count as
  /// "Builds" too, and `/settings/logs` counts as "Settings" — neither has
  /// its own destination, and leaving the nav unlit on those screens would
  /// be worse than crediting the section they actually belong to.
  static int _navIndexOf(String location) {
    if (location.startsWith('/builds')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  static const _navRoutes = ['/dashboard', '/builds', '/settings'];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _railExtended = true;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final navIndex = AppShell._navIndexOf(location);
    final actions = ref.watch(actionsProvider);
    final hasKey = ref.watch(sessionProvider).hasKey;
    final mobile = isMobileWidth(context);

    final connectControl = hasKey
        ? IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(connectionControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          )
        : IconButton(
            tooltip: 'Connect',
            icon: const Icon(Icons.login),
            onPressed: () => context.go('/login'),
          );

    void onNavSelected(int index) => context.go(AppShell._navRoutes[index]);

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        title: const Text('CI/CD'),
        leading: mobile
            ? null
            : IconButton(
                tooltip: _railExtended
                    ? 'Collapse navigation'
                    : 'Expand navigation',
                icon: const Icon(Icons.menu),
                onPressed: () => setState(() => _railExtended = !_railExtended),
              ),
        actions: [
          _StatusChipsBar(compact: mobile),
          const SizedBox(width: 8),
          connectControl,
        ],
      ),
      floatingActionButton: mobile
          ? actions.when(
              data: (data) => _BuildFab(actions: data, isExtended: false),
              loading: () => null,
              error: (_, _) => null,
            )
          : null,
      bottomNavigationBar: mobile
          ? NavigationBar(
              selectedIndex: navIndex,
              onDestinationSelected: onNavSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: 'Builds',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
      body: mobile
          ? widget.child
          : _buildDesktopBody(actions, navIndex, onNavSelected),
    );
  }

  Widget _buildDesktopBody(
    AsyncValue<List<ActionSchema>> actions,
    int navIndex,
    ValueChanged<int> onNavSelected,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigationRail(
          leading: actions.when(
            data: (data) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _BuildFab(actions: data, isExtended: _railExtended),
            ),
            loading: () => const SizedBox(height: 56),
            error: (_, _) => const SizedBox(height: 56),
          ),
          extended: _railExtended,
          // NavigationRail forbids a labelType once extended — the label
          // already sits beside the icon then, so a separate
          // "always/selected/never" mode has nothing left to control.
          labelType: _railExtended ? null : NavigationRailLabelType.all,
          selectedIndex: navIndex,
          onDestinationSelected: onNavSelected,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: Text('Builds'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// Jumps to [NewBuildScreen] to pick which action to run — hidden entirely
/// when this key has nothing it's allowed to invoke, since which actions
/// exist (and which this key may run) is dynamic, not a fixed route. Used
/// both as the desktop rail's leading widget and mobile's standard
/// [Scaffold.floatingActionButton].
class _BuildFab extends ConsumerWidget {
  const _BuildFab({required this.actions, this.isExtended = true});

  final List<ActionSchema> actions;
  final bool isExtended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myKey = ref.watch(myKeyInfoProvider).value;
    final invokable = visibleBuildMenuActions(actions, myKey);
    if (invokable.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      isExtended: isExtended,
      tooltip: 'New build',
      onPressed: () => context.go('/builds/new'),
      icon: const Icon(Icons.add),
      label: Text('New build'),
    );
  }
}

/// Running/queued counts, inline in the app bar's title — a
/// [NavigationRail]/[NavigationBar] has no room for them, and a dedicated
/// strip under the bar just added height back after shrinking it elsewhere.
/// Each chip jumps to the Builds list pre-filtered to its own state — the
/// count is otherwise just a number with nowhere to go look at it closer.
class _StatusChipsBar extends ConsumerWidget {
  const _StatusChipsBar({required this.compact});

  /// Icon-only (no label), for a phone-width app bar that has no room to
  /// spare next to the title and the Sign-out icon.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusControllerProvider);
    return status.maybeWhen(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: compact ? 0 : 12,
          children: [
            Badge.count(
              count: data.running.length,
              isLabelVisible: data.running.isNotEmpty,
              child: compact
                  ? IconButton(
                      tooltip: 'Running',
                      icon: const Icon(Icons.autorenew),
                      onPressed: () => context.go('/builds?state=running'),
                    )
                  : ActionChip(
                      avatar: const Icon(Icons.autorenew),
                      label: const Text('Running'),
                      onPressed: () => context.go('/builds?state=running'),
                    ),
            ),
            Badge.count(
              count: data.queued.length,
              isLabelVisible: data.queued.isNotEmpty,
              child: compact
                  ? IconButton(
                      tooltip: 'Queued',
                      icon: const Icon(Icons.schedule),
                      onPressed: () => context.go('/builds?state=queued'),
                    )
                  : ActionChip(
                      avatar: const Icon(Icons.schedule),
                      label: const Text('Queued'),
                      onPressed: () => context.go('/builds?state=queued'),
                    ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
