import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../browser/notifications.dart';
import '../storage/action_template_store.dart';
import '../storage/last_result_store.dart';
import '../storage/session_prefs.dart';
import 'session_provider.dart';

/// Overridden in `main()` with the awaited instance — reading it before that
/// override is applied is a programming error.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final sessionPrefsProvider = Provider<SessionPrefs>(
  (ref) => SessionPrefs(ref.watch(sharedPreferencesProvider)),
);

final actionTemplateStoreProvider = Provider<ActionTemplateStore>(
  (ref) => ActionTemplateStore(ref.watch(sharedPreferencesProvider)),
);

final lastResultStoreProvider = Provider<LastResultStore>(
  (ref) => LastResultStore(ref.watch(sharedPreferencesProvider)),
);

final browserNotificationsProvider = Provider<BrowserNotifications>(
  (ref) => const BrowserNotifications(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final creds = ref.watch(sessionProvider);
  final client = ApiClient(
    baseUrl: creds.normalizedServerUrl,
    apiKey: creds.apiKey.isEmpty ? null : creds.apiKey,
  );
  ref.onDispose(client.close);
  return client;
});
