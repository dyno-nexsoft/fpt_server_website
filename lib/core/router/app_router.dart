import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/artifacts/presentation/artifacts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/action_form/presentation/action_form_screen.dart';
import '../../features/builds/presentation/builds_screen.dart';
import '../../features/builds/presentation/job_detail_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../providers/connection_provider.dart';
import '../providers/session_provider.dart';

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
  /// `/actions/:name` (submitting a build/action form) forces `/login`,
  /// since that screen exists to POST something the server won't accept
  /// without one. Cancel/Promote/Retry buttons guard themselves the same
  /// way per-click (`runAuthedJobAction`) rather than through routing,
  /// since they live on an otherwise-public job detail page.
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
    final needsKey = state.matchedLocation.startsWith('/actions/');

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
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/builds',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const BuildsScreen()),
          ),
          GoRoute(
            path: '/jobs/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoTransitionPage(
                child: JobDetailScreen(key: ValueKey(id), jobId: id),
              );
            },
          ),
          GoRoute(
            path: '/actions/:name',
            pageBuilder: (context, state) {
              final name = state.pathParameters['name']!;
              return NoTransitionPage(
                child: ActionFormScreen(key: ValueKey(name), actionName: name),
              );
            },
          ),
          // The file server redirects `/<artifactKey>/` here — see
          // `ftp_handler.dart`'s `_redirectToArtifactBrowser`.
          GoRoute(
            path: '/artifacts/:key',
            pageBuilder: (context, state) {
              final key = state.pathParameters['key']!;
              return NoTransitionPage(
                child: ArtifactsScreen(key: ValueKey(key), artifactKey: key),
              );
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
