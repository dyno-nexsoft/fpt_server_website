import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import 'core_providers.dart';
import 'session_provider.dart';

/// `full` = the key has `read` and `/status` answered directly.
/// `limited` = `/status` came back `403` (invoke-only key), but `/actions`
/// worked, so the key is still usable — just for fewer screens.
enum ConnectionLevel { full, limited }

class ConnectionResult {
  const ConnectionResult(this.level);

  final ConnectionLevel level;
}

/// Drives the login screen's Connect button and the background revalidation
/// of a persisted key. See `docs/web-ui-wireframe.md` "Auth flow" for the
/// exact error-code -> UI mapping this mirrors.
class ConnectionController extends AsyncNotifier<ConnectionResult?> {
  @override
  FutureOr<ConnectionResult?> build() {
    final creds = ref.read(sessionProvider);
    if (!creds.hasKey) return null;
    return _check();
  }

  Future<ConnectionResult> _check() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.getJson('/status');
      return const ConnectionResult(ConnectionLevel.full);
    } on ApiException catch (e) {
      if (e.isForbidden) {
        await api.getJson('/actions');
        return const ConnectionResult(ConnectionLevel.limited);
      }
      rethrow;
    }
  }

  Future<void> connect({
    required String serverUrl,
    required String apiKey,
  }) async {
    await ref
        .read(sessionProvider.notifier)
        .setCredentials(serverUrl: serverUrl, apiKey: apiKey);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_check);
    final error = state.error;
    if (error is ApiException && error.isUnauthorized) {
      await ref.read(sessionProvider.notifier).clear();
    }
  }

  Future<void> logout() async {
    await ref.read(sessionProvider.notifier).clear();
    state = const AsyncData(null);
  }
}

final connectionControllerProvider =
    AsyncNotifierProvider<ConnectionController, ConnectionResult?>(
      ConnectionController.new,
    );
