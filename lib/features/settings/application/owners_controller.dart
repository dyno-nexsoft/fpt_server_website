import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/action_invoker.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/toast/app_toast.dart';

/// `admin.owners.list/add/remove` — the Discord accounts holding bot
/// ownership, merged with the mutations that change that list.
///
/// One `AsyncNotifier` rather than a separate read provider plus a plain
/// controller class: `add`/`remove` apply to `state` directly (optimistic —
/// the id appears/disappears immediately, not after a round trip) and roll
/// back to whatever `state` held before if the call fails, which only a
/// notifier that owns the list itself can do. A bare `Provider<OwnersController>`
/// invalidating a sibling `FutureProvider` has no way to touch its state
/// synchronously like this.
///
/// `null` state means: no stored key, or a key without the `admin` scope
/// this action needs. The section hides itself rather than showing an error
/// either way.
///
/// Ids are strings all the way through, never parsed to `int` — a Discord
/// snowflake exceeds what a browser's number type can hold exactly (see
/// `OwnerListResult`).
class OwnersController extends AsyncNotifier<List<String>?> {
  @override
  Future<List<String>?> build() async {
    if (!ref.watch(sessionProvider).hasKey) return null;
    final actions = await ref.watch(actionsProvider.future);
    if (findAction(actions, 'admin.owners.list') == null) return null;
    final api = ref.watch(apiClientProvider);
    final body = await api.decodeMap(
      api.endpoints.invokeAction(
        'admin.owners.list',
        api.encodeBody(const {}),
      ),
    );
    return (body['ids'] as List<dynamic>? ?? []).cast<String>();
  }

  Future<void> add(String userId) => _run(
    'admin.owners.add',
    userId,
    apply: (list) => list.contains(userId) ? list : [...list, userId],
  );

  Future<void> remove(String userId) => _run(
    'admin.owners.remove',
    userId,
    apply: (list) => list.where((id) => id != userId).toList(),
  );

  /// Both calls differ only in the action name and how they locally edit the
  /// list — same single string param, same "toast whatever the server says"
  /// finish, same rollback-on-failure.
  Future<void> _run(
    String actionName,
    String userId, {
    required List<String> Function(List<String> current) apply,
  }) async {
    final previous = state;
    state = AsyncData(apply(previous.value ?? const []));

    final body = await ref.read(actionInvokerProvider).run(actionName, {
      'user_id': userId,
    });
    if (body == null) {
      state = previous;
      return;
    }
    ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
    // Reconciles with the server's own truth in the background — covers
    // "already an owner" (a no-op the optimistic apply above still guards
    // against) and another admin's concurrent edit — without making the
    // caller wait on it the way a plain `invalidate` + re-`await` would.
    ref.invalidateSelf();
  }
}

final ownersProvider = AsyncNotifierProvider<OwnersController, List<String>?>(
  OwnersController.new,
);
