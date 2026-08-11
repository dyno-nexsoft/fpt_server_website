import 'package:shared_preferences/shared_preferences.dart';

/// Persists the pasted API key and server URL in `localStorage` — the key
/// *is* the session, there is no server-side login/cookie to mirror.
class SessionPrefs {
  SessionPrefs(this._prefs);

  static const _keyServerUrl = 'server_url';
  static const _keyApiKey = 'api_key';

  final SharedPreferences _prefs;

  String? get serverUrl => _prefs.getString(_keyServerUrl);
  String? get apiKey => _prefs.getString(_keyApiKey);

  Future<void> save({required String serverUrl, required String apiKey}) =>
      Future.wait([
        _prefs.setString(_keyServerUrl, serverUrl),
        _prefs.setString(_keyApiKey, apiKey),
      ]);

  Future<void> clear() =>
      Future.wait([_prefs.remove(_keyServerUrl), _prefs.remove(_keyApiKey)]);
}
