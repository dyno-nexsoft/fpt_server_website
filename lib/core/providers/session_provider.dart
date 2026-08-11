import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import 'core_providers.dart';

/// The pasted server URL + API key. This *is* the session — there is no
/// server-side login endpoint to mirror.
class SessionCredentials {
  const SessionCredentials({required this.serverUrl, required this.apiKey});

  final String serverUrl;
  final String apiKey;

  bool get hasKey => apiKey.isNotEmpty;

  /// Strips a trailing slash and ensures the `/api/v1` suffix so screens can
  /// store/display the bare host while requests still hit the right prefix.
  String get normalizedServerUrl {
    var url = serverUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (url.endsWith('/api/v1')) return url;
    return '$url/api/v1';
  }
}

class SessionNotifier extends Notifier<SessionCredentials> {
  @override
  SessionCredentials build() {
    final prefs = ref.watch(sessionPrefsProvider);
    final defaultServerUrl = AppEnv.defaultServerUrl.isNotEmpty
        ? AppEnv.defaultServerUrl
        : Uri.base.origin;
    return SessionCredentials(
      serverUrl: prefs.serverUrl ?? defaultServerUrl,
      apiKey: prefs.apiKey ?? AppEnv.defaultApiKeyTest,
    );
  }

  Future<void> setCredentials({
    required String serverUrl,
    required String apiKey,
  }) async {
    await ref
        .read(sessionPrefsProvider)
        .save(serverUrl: serverUrl, apiKey: apiKey);
    state = SessionCredentials(serverUrl: serverUrl, apiKey: apiKey);
  }

  Future<void> clear() async {
    await ref.read(sessionPrefsProvider).clear();
    state = SessionCredentials(serverUrl: state.serverUrl, apiKey: '');
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionCredentials>(
  SessionNotifier.new,
);
