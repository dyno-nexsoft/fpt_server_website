import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/action_invoker.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/toast/app_toast.dart';

/// `admin.apiKeys.list/add/remove/setScopes`, merged into one `AsyncNotifier`
/// so `delete`/`setScopes` can edit `state` directly (optimistic — the row
/// disappears/updates immediately, not after a round trip) and roll back to
/// whatever `state` held before if the call fails. A separate read provider
/// plus a plain controller class invalidating it has no way to touch state
/// synchronously like this.
///
/// `create` stays pessimistic: the new row's hash/scopes/id all come from the
/// server, so there's nothing real to show optimistically before the
/// response arrives anyway — the one-time-secret dialog it opens afterward
/// is already the feedback that matters here, not the table updating first.
///
/// `null` state means: no stored key, or a key without the `admin.apiKeys.list`
/// scope — the section hides itself rather than showing an error either way.
class ApiKeysController extends AsyncNotifier<List<ApiKeyInfo>?> {
  @override
  Future<List<ApiKeyInfo>?> build() async {
    if (!ref.watch(sessionProvider).hasKey) return null;
    final actions = await ref.watch(actionsProvider.future);
    if (findAction(actions, 'admin.apiKeys.list') == null) return null;
    final api = ref.watch(apiClientProvider);
    final body = await api.decodeMap(
      api.endpoints.invokeAction(
        'admin.apiKeys.list',
        api.encodeBody(const {}),
      ),
    );
    return (body['keys'] as List<dynamic>? ?? [])
        .map((e) => ApiKeyInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes [key]. If it's the key this session is signed in with, signs
  /// out and routes to `/login` instead of touching `state` — once the
  /// credential is gone, every further authed call 401s, so there's nothing
  /// left here worth showing.
  Future<void> delete(BuildContext context, ApiKeyInfo key) async {
    // Read before the delete call, not after: once the key that's actually
    // signed in is gone, every subsequent request (including whatever
    // myKeyInfoProvider would refetch) 401s.
    final isSelf = ref.read(myKeyInfoProvider).value?.id == key.id;
    if (isSelf) {
      final body = await ref.read(actionInvokerProvider).run(
        'admin.apiKeys.remove',
        {'id': key.id},
      );
      if (body == null) return;
      await ref.read(connectionControllerProvider.notifier).logout();
      if (context.mounted) const LoginRoute().go(context);
      return;
    }

    final previous = state;
    state = AsyncData(
      (previous.value ?? const []).where((k) => k.id != key.id).toList(),
    );
    final body = await ref.read(actionInvokerProvider).run(
      'admin.apiKeys.remove',
      {'id': key.id},
    );
    if (body == null) {
      state = previous;
      return;
    }
    ref.read(appToastProvider.notifier).show('Key deleted.');
  }

  /// Creates a key named [name] and returns its one-time secret, or `null`
  /// after the error toast was already shown.
  Future<String?> create(String name) async {
    final body = await ref.read(actionInvokerProvider).run(
      'admin.apiKeys.add',
      {'name': name},
    );
    if (body == null) return null;
    ref.invalidateSelf();
    return body['secret'] as String?;
  }

  /// Replaces [key]'s scopes with [scopes] — admin-only server-side (see
  /// `ApiKeySetScopesAction`'s doc comment for why this isn't self-service
  /// like create/delete).
  Future<bool> setScopes(ApiKeyInfo key, List<String> scopes) async {
    final previous = state;
    state = AsyncData([
      for (final k in previous.value ?? const <ApiKeyInfo>[])
        if (k.id == key.id) k.copyWith(scopes: scopes) else k,
    ]);

    final body = await ref.read(actionInvokerProvider).run(
      'admin.apiKeys.setScopes',
      {'id': key.id, 'scopes': scopes},
    );
    if (body == null) {
      state = previous;
      return false;
    }
    ref.read(appToastProvider.notifier).show('Scopes updated.');
    return true;
  }
}

final apiKeysProvider =
    AsyncNotifierProvider<ApiKeysController, List<ApiKeyInfo>?>(
      ApiKeysController.new,
    );
