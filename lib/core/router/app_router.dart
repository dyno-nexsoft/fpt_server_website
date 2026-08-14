import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/artifacts/presentation/artifacts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/action_form/presentation/action_form_screen.dart';
import '../../features/builds/presentation/builds_screen.dart';
import '../../features/builds/presentation/job_detail_screen.dart';
import '../../features/builds/presentation/new_build_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings/presentation/server_logs_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../providers/connection_provider.dart';
import '../providers/session_provider.dart';

part 'app_router.g.dart';

/// Bridges Riverpod state changes into `go_router`'s `Listenable`-based
/// refresh mechanism, and centralizes the auth redirect described in
/// `docs/web-ui-wireframe.md` "Auth flow".
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(connectionControllerProvider, (_, _) => notifyListeners());
    _ref.listen(sessionProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  /// Read is public, act requires a key — matching the server (see
  /// `ApiRouter._isPublic`). The dashboard, builds list, job detail, and
  /// artifact browser all work with no stored key at all; only
  /// `/builds/actions/:name` (submitting a build/action form) forces
  /// `/login`, since that screen exists to POST something the server won't
  /// accept without one. `/builds/actions` itself (picking which one to run)
  /// stays public — nothing there submits anything yet. Cancel/Promote/Retry
  /// buttons guard themselves the same way per-click
  /// (`runAuthedJobAction`) rather than through routing, since they live on
  /// an otherwise-public job detail page.
  ///
  /// The stored key going away — which `ConnectionController` does itself,
  /// and only on a 401 — is the only thing that forces a logged-in user off
  /// an action screen back to `/login` after the fact. A 503/network error
  /// while revalidating a persisted session leaves `creds.hasKey` true and
  /// this redirect a no-op, so a transient outage degrades in place (each
  /// screen's own provider shows its own error) instead of evicting a
  /// still-valid session.
  String? redirect(BuildContext context, GoRouterState state) {
    // There is no GoRoute for '/' itself — a user landing here directly
    // (typed URL, bookmark, or a hash-stripped bare origin) would otherwise
    // hit go_router's "no route found" error page instead of the app.
    if (state.matchedLocation == '/') return '/dashboard';

    final creds = _ref.read(sessionProvider);
    final loggingIn = state.matchedLocation == '/login';
    final needsKey = state.matchedLocation.startsWith('/builds/actions/');

    if (needsKey && !creds.hasKey) return '/login';

    final connection = _ref.read(connectionControllerProvider);
    if (loggingIn &&
        creds.hasKey &&
        connection.hasValue &&
        connection.value != null) {
      return '/dashboard';
    }
    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>(RouterNotifier.new);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: $appRoutes,
  );
});

// ─── Typed routes ──────────────────────────────────────────────────────────
//
// Each class below is both the route's *definition* (path, nesting, which
// screen it builds) and its *call site* — navigating is `const
// JobDetailRoute(id: job.id).go(context)` instead of
// `context.go('/builds/${job.id}')`, so a typo'd path or a mismatched
// parameter is a compile error instead of a dead link discovered by
// clicking it.

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}

@TypedShellRoute<AppShellRouteData>(
  routes: [
    TypedGoRoute<DashboardRoute>(path: '/dashboard'),
    TypedGoRoute<BuildsRoute>(
      path: '/builds',
      routes: [
        // Picking which action to run (`actions`) and filling in its form
        // (`actions/:name`) are both "starting a build", so they nest under
        // Builds together instead of the form living as an unrelated
        // top-level sibling route.
        TypedGoRoute<NewBuildRoute>(
          path: 'actions',
          routes: [TypedGoRoute<ActionFormRoute>(path: ':name')],
        ),
        // A specific build/job — nested so its URL reads as "the thing
        // under Builds it is", not a sibling of unrelated top level
        // sections. Artifacts nest one level deeper still: they are that
        // job's own output, not a separate top-level concept keyed by the
        // artifactKey directory name a reader has no reason to know.
        TypedGoRoute<JobDetailRoute>(
          path: ':id',
          routes: [TypedGoRoute<ArtifactsRoute>(path: 'artifacts')],
        ),
      ],
    ),
    TypedGoRoute<SettingsRoute>(
      path: '/settings',
      routes: [TypedGoRoute<ServerLogsRoute>(path: 'logs')],
    ),
  ],
)
class AppShellRouteData extends ShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) =>
      AppShell(child: navigator);
}

class DashboardRoute extends GoRouteData with $DashboardRoute {
  const DashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DashboardScreen();
}

class BuildsRoute extends GoRouteData with $BuildsRoute {
  const BuildsRoute({this.state});

  /// `?state=running`/`?state=queued` etc. — read by [BuildsScreen] itself
  /// off the ambient `GoRouterState` rather than as a constructor argument,
  /// so a filter chip tapped locally still works the same way regardless of
  /// whether this screen was reached via a typed route or a raw URL.
  final String? state;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BuildsScreen();
}

class NewBuildRoute extends GoRouteData with $NewBuildRoute {
  const NewBuildRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const NewBuildScreen();
}

class ActionFormRoute extends GoRouteData with $ActionFormRoute {
  const ActionFormRoute(this.name);

  final String name;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ActionFormScreen(key: ValueKey(name), actionName: name);
}

class JobDetailRoute extends GoRouteData with $JobDetailRoute {
  const JobDetailRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JobDetailScreen(key: ValueKey(id), jobId: id);
}

class ArtifactsRoute extends GoRouteData with $ArtifactsRoute {
  const ArtifactsRoute(this.id);

  /// Job id, inherited from the parent [JobDetailRoute] segment — the field
  /// name must match [JobDetailRoute.id] for go_router_builder to pull it
  /// from the shared `:id` path segment.
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ArtifactsScreen(key: ValueKey(id), jobId: id);
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

class ServerLogsRoute extends GoRouteData with $ServerLogsRoute {
  const ServerLogsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ServerLogsScreen();
}
