import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/action_invoker.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/toast/app_toast.dart';

/// `admin.owners.list` — the Discord accounts holding bot ownership.
///
/// `null` for the same reasons as [apiKeysProvider]: no stored key, or a key
/// without the `admin` scope this action needs. The section hides itself
/// rather than showing an error either way.
///
/// Ids are strings all the way through, never parsed to `int` — a Discord
/// snowflake exceeds what a browser's number type can hold exactly (see
/// `OwnerListResult`).
final ownersProvider = FutureProvider.autoDispose<List<String>?>((ref) async {
  if (!ref.watch(sessionProvider).hasKey) return null;
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.owners.list') == null) return null;
  final api = ref.watch(apiClientProvider);
  final body = await api.decodeMap(
    api.endpoints.invokeAction('admin.owners.list', api.encodeBody(const {})),
  );
  return (body['ids'] as List<dynamic>? ?? []).cast<String>();
});

/// `admin.owners.add`/`.remove`.
class OwnersController {
  OwnersController(this._ref);

  final Ref _ref;

  Future<void> add(String userId) => _run('admin.owners.add', userId);

  Future<void> remove(String userId) => _run('admin.owners.remove', userId);

  /// Both calls differ only in the action name: same single string param,
  /// same refetch, and the server answers both with a `message` that already
  /// distinguishes "added" from "already an owner".
  Future<void> _run(String actionName, String userId) async {
    final body = await _ref.read(actionInvokerProvider).run(actionName, {
      'user_id': userId,
    });
    if (body == null) return;
    _ref.invalidate(ownersProvider);
    _ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
  }
}

final ownersControllerProvider = Provider<OwnersController>(
  OwnersController.new,
);
