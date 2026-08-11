import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  /// The *only* thing that forces a logged-in user back to `/login` is the
  /// stored key going away — which `ConnectionController` does itself, and
  /// only on a 401. A 503/network error while revalidating a persisted
  /// session leaves `creds.hasKey` true and this redirect a no-op, so a
  /// transient outage degrades in place (each screen's own provider shows
  /// its own error) instead of evicting a still-valid session.
  String? redirect(BuildContext context, GoRouterState state) {
    final creds = _ref.read(sessionProvider);
    final loggingIn = state.matchedLocation == '/login';

    if (!creds.hasKey) {
      return loggingIn ? null : '/login';
    }

    final connection = _ref.read(connectionControllerProvider);
    if (loggingIn && connection.hasValue && connection.value != null) {
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/builds',
            builder: (context, state) => const BuildsScreen(),
          ),
          GoRoute(
            path: '/jobs/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return JobDetailScreen(key: ValueKey(id), jobId: id);
            },
          ),
          GoRoute(
            path: '/actions/:name',
            builder: (context, state) {
              final name = state.pathParameters['name']!;
              return ActionFormScreen(key: ValueKey(name), actionName: name);
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
