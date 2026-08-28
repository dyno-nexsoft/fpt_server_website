import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/toast/app_toast.dart';
import 'admin_actions_controller.dart';
import 'settings_providers.dart';

/// `admin.apiKeys.add`/`.remove` — owns the invoke/invalidate/self-delete
/// logout logic previously duplicated inline in [ApiKeysSection]'s methods.
class ApiKeysController {
  ApiKeysController(this._ref);

  final Ref _ref;

  /// Deletes [key]. If it's the key this session is signed in with, signs
  /// out and routes to `/login` instead of invalidating [apiKeysProvider] —
  /// once the credential is gone, every further authed call 401s, so there's
  /// nothing left here worth refetching.
  Future<void> delete(BuildContext context, ApiKeyInfo key) async {
    // Read before the delete call, not after: once the key that's actually
    // signed in is gone, every subsequent request (including whatever
    // myKeyInfoProvider would refetch) 401s.
    final isSelf = _ref.read(myKeyInfoProvider).value?.id == key.id;

    final body = await _ref.read(adminActionsControllerProvider).run(
      'admin.apiKeys.remove',
      {'id': key.id},
    );
    if (body == null) return;

    if (isSelf) {
      await _ref.read(connectionControllerProvider.notifier).logout();
      if (context.mounted) const LoginRoute().go(context);
      return;
    }
    _ref.invalidate(apiKeysProvider);
    _ref.read(appToastProvider.notifier).show('Key deleted.');
  }

  /// Creates a key named [name] and returns its one-time secret, or `null`
  /// after the error toast was already shown.
  Future<String?> create(String name) async {
    final body = await _ref.read(adminActionsControllerProvider).run(
      'admin.apiKeys.add',
      {'name': name},
    );
    if (body == null) return null;
    _ref.invalidate(apiKeysProvider);
    return body['secret'] as String?;
  }

  /// Replaces [key]'s scopes with [scopes] — admin-only server-side (see
  /// `ApiKeySetScopesAction`'s doc comment for why this isn't self-service
  /// like create/delete).
  Future<bool> setScopes(ApiKeyInfo key, List<String> scopes) async {
    final body = await _ref.read(adminActionsControllerProvider).run(
      'admin.apiKeys.setScopes',
      {'id': key.id, 'scopes': scopes},
    );
    if (body == null) return false;
    _ref.invalidate(apiKeysProvider);
    _ref.read(appToastProvider.notifier).show('Scopes updated.');
    return true;
  }
}

final apiKeysControllerProvider = Provider<ApiKeysController>(
  ApiKeysController.new,
);
