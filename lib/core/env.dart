/// Compile-time configuration, passed via `--dart-define` at build time.
/// Never put the API key here — it would ship in the public JS bundle.
/// See README.md for the build command.
abstract final class AppEnv {
  /// Prefills the login screen's Server URL field. Falls back to the page's
  /// own origin (`Uri.base.origin`) when unset, which is correct whenever
  /// this app is served from the same host as the API.
  static const defaultServerUrl = String.fromEnvironment('API_BASE_URL');

  /// Prefills the API key field for local dev only — pass a disposable test
  /// key, never a real one, since `--dart-define` values ship in the public
  /// JS bundle of any build that used them.
  static const defaultApiKeyTest = String.fromEnvironment('API_KEY_TEST');
}
