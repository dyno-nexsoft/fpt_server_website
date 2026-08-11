import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_key_info.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';

/// `null` means either there is no stored key to check with, or the
/// connected key cannot reach the action (missing scope) — either way,
/// screens hide the section rather than show an error. `/actions` is
/// public and unfiltered (see `ApiRouter._isPublic`), so its presence in
/// the catalogue says nothing about *this* session's own access.
final apiKeysProvider = FutureProvider.autoDispose<List<ApiKeyInfo>?>((
  ref,
) async {
  if (!ref.watch(sessionProvider).hasKey) return null;
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.apiKeys.list') == null) return null;
  final api = ref.watch(apiClientProvider);
  final body = await api.postJson('/actions/admin.apiKeys.list');
  return (body['keys'] as List<dynamic>? ?? [])
      .map((e) => ApiKeyInfo.fromJson(e as Map<String, dynamic>))
      .toList();
});

final logsTailProvider = FutureProvider.autoDispose<List<String>?>((ref) async {
  if (!ref.watch(sessionProvider).hasKey) return null;
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.logs.tail') == null) return null;
  final api = ref.watch(apiClientProvider);
  final body = await api.postJson('/actions/admin.logs.tail', {'lines': 200});
  return (body['lines'] as List<dynamic>? ?? []).cast<String>();
});
