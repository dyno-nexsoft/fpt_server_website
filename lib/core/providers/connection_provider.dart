import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import 'core_providers.dart';
import 'session_provider.dart';

/// `full` = the key has `invoke` and could list its own info directly.
/// `limited` = that came back `403` (a `read`-only key), but `/actions`
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
    return _checkAndHandleAuth();
  }

  /// Probes `admin.apiKeys.list` (see `myKeyInfoProvider`, which reuses this
  /// same call to resolve the connected key's own name/scopes) rather than
  /// `GET /status` — `/status` is a public read route (`ApiRouter._isPublic`),
  /// so it answers 200 for *any* string typed into the API key field,
  /// including one that was never issued. Anything requiring `invoke` is the
  /// cheapest call that actually forces the server to check the key against
  /// its real ones.
  Future<ConnectionResult> _check() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.postJson('/actions/admin.apiKeys.list');
      return const ConnectionResult(ConnectionLevel.full);
    } on ApiException catch (e) {
      if (e.isForbidden) {
        await api.getJson('/actions');
        return const ConnectionResult(ConnectionLevel.limited);
      }
      rethrow;
    }
  }

  /// Wraps [_check] so a 401 clears the stored key regardless of whether the
  /// check ran from the login screen's Connect button or the silent
  /// background revalidation on app boot — "force logout only on 401, never
  /// on 403" from docs/web-ui-wireframe.md applies either way. Every other
  /// error (503, network) leaves the stored key alone: it may still be
  /// valid, so [RouterNotifier] must not bounce the user to the login screen
  /// over what could be a transient outage.
  Future<ConnectionResult> _checkAndHandleAuth() async {
    try {
      return await _check();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await ref.read(sessionProvider.notifier).clear();
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
    state = await AsyncValue.guard(_checkAndHandleAuth);
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
