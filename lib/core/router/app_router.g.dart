// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$loginRoute, $appShellRouteData];

RouteBase get $loginRoute => GoRouteData.$route(
  path: '/login',
  hasOverriddenOnExit: false,
  factory: $LoginRoute._fromState,
);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRouteData => ShellRouteData.$route(
  factory: $AppShellRouteDataExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/dashboard',
      hasOverriddenOnExit: false,
      factory: $DashboardRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/builds',
      hasOverriddenOnExit: false,
      factory: $BuildsRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'actions',
          hasOverriddenOnExit: false,
          factory: $NewBuildRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':name',
              hasOverriddenOnExit: false,
              factory: $ActionFormRoute._fromState,
            ),
          ],
        ),
        GoRouteData.$route(
          path: ':id',
          hasOverriddenOnExit: false,
          factory: $JobDetailRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'artifacts',
              hasOverriddenOnExit: false,
              factory: $ArtifactsRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    GoRouteData.$route(
      path: '/settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'logs',
          hasOverriddenOnExit: false,
          factory: $ServerLogsRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $AppShellRouteDataExtension on AppShellRouteData {
  static AppShellRouteData _fromState(GoRouterState state) =>
      const AppShellRouteData();
}

mixin $DashboardRoute on GoRouteData {
  static DashboardRoute _fromState(GoRouterState state) =>
      const DashboardRoute();

  @override
  String get location => GoRouteData.$location('/dashboard');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BuildsRoute on GoRouteData {
  static BuildsRoute _fromState(GoRouterState state) =>
      BuildsRoute(state: state.uri.queryParameters['state']);

  BuildsRoute get _self => this as BuildsRoute;

  @override
  String get location => GoRouteData.$location(
    '/builds',
    queryParams: {if (_self.state != null) 'state': _self.state},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NewBuildRoute on GoRouteData {
  static NewBuildRoute _fromState(GoRouterState state) => const NewBuildRoute();

  @override
  String get location => GoRouteData.$location('/builds/actions');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ActionFormRoute on GoRouteData {
  static ActionFormRoute _fromState(GoRouterState state) =>
      ActionFormRoute(state.pathParameters['name']!);

  ActionFormRoute get _self => this as ActionFormRoute;

  @override
  String get location => GoRouteData.$location(
    '/builds/actions/${Uri.encodeComponent(_self.name)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JobDetailRoute on GoRouteData {
  static JobDetailRoute _fromState(GoRouterState state) =>
      JobDetailRoute(state.pathParameters['id']!);

  JobDetailRoute get _self => this as JobDetailRoute;

  @override
  String get location =>
      GoRouteData.$location('/builds/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ArtifactsRoute on GoRouteData {
  static ArtifactsRoute _fromState(GoRouterState state) =>
      ArtifactsRoute(state.pathParameters['id']!);

  ArtifactsRoute get _self => this as ArtifactsRoute;

  @override
  String get location => GoRouteData.$location(
    '/builds/${Uri.encodeComponent(_self.id)}/artifacts',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ServerLogsRoute on GoRouteData {
  static ServerLogsRoute _fromState(GoRouterState state) =>
      const ServerLogsRoute();

  @override
  String get location => GoRouteData.$location('/settings/logs');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
