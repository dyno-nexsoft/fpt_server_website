import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_key_info.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';

/// `null` means the connected key cannot reach the action at all (missing
/// scope) — screens use that to hide the section rather than show an error.
final apiKeysProvider = FutureProvider.autoDispose<List<ApiKeyInfo>?>((
  ref,
) async {
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.apiKeys.list') == null) return null;
  final api = ref.watch(apiClientProvider);
  final body = await api.postJson('/actions/admin.apiKeys.list');
  return (body['keys'] as List<dynamic>? ?? [])
      .map((e) => ApiKeyInfo.fromJson(e as Map<String, dynamic>))
      .toList();
});

final logsTailProvider = FutureProvider.autoDispose<List<String>?>((ref) async {
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.logs.tail') == null) return null;
  final api = ref.watch(apiClientProvider);
  final body = await api.postJson('/actions/admin.logs.tail', {'lines': 200});
  return (body['lines'] as List<dynamic>? ?? []).cast<String>();
});
