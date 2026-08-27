import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/responsive.dart';
import 'connect_control.dart';
import 'status_chips_bar.dart';

/// One destination shared by mobile's [NavigationBar] and desktop's
/// [NavigationRail] — a single source for icon/label pairs that used to be
/// declared twice, with nothing to stop the two lists drifting apart if one
/// of the two got a new destination or a relabel and the other didn't.
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _navItems = [
  _NavItem(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavItem(
    icon: Icons.build_outlined,
    selectedIcon: Icons.build,
    label: 'Builds',
  ),
  _NavItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

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

  static const _navRoutes = [DashboardRoute(), BuildsRoute(), SettingsRoute()];

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
    final mobile = isMobileWidth(context);

    void onNavSelected(int index) {
      if (navIndex == index) return;
      AppShell._navRoutes[index].go(context);
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        title: GestureDetector(
          onTap: () => context.go('/'),
          child: const Text('CI/CD'),
        ),
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
          StatusChipsBar(compact: mobile),
          const SizedBox(width: 8),
          ConnectControl(compact: mobile),
          if (!mobile) const SizedBox(width: 8),
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
              destinations: [
                for (final item in _navItems)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            )
          : null,
      body: mobile
          ? widget.child
          : _DesktopShellBody(
              actions: actions,
              navIndex: navIndex,
              railExtended: _railExtended,
              onNavSelected: onNavSelected,
              child: widget.child,
            ),
    );
  }
}

/// Desktop/tablet body: a [NavigationRail] beside the routed screen — split
/// out of [_AppShellState] because a widget-returning method there would
/// rebuild on every [AppShell] change regardless of whether anything this
/// body actually reads changed; a proper widget lets Flutter skip work
/// `const` children of it don't need redone.
class _DesktopShellBody extends StatelessWidget {
  const _DesktopShellBody({
    required this.actions,
    required this.navIndex,
    required this.railExtended,
    required this.onNavSelected,
    required this.child,
  });

  final AsyncValue<List<ActionSchema>> actions;
  final int navIndex;
  final bool railExtended;
  final ValueChanged<int> onNavSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigationRail(
          leading: actions.when(
            data: (data) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _BuildFab(actions: data, isExtended: railExtended),
            ),
            loading: () => const SizedBox(height: 56),
            error: (_, _) => const SizedBox(height: 56),
          ),
          extended: railExtended,
          // NavigationRail forbids a labelType once extended — the label
          // already sits beside the icon then, so a separate
          // "always/selected/never" mode has nothing left to control.
          labelType: railExtended ? null : NavigationRailLabelType.all,
          selectedIndex: navIndex,
          onDestinationSelected: onNavSelected,
          destinations: [
            for (final item in _navItems)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
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
      onPressed: () => const NewBuildRoute().go(context),
      icon: const Icon(Icons.add),
      label: Text('New build'),
    );
  }
}
