import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/action_schema.dart';
import '../models/api_key_info.dart';
import '../models/health.dart';
import 'core_providers.dart';
import 'session_provider.dart';

/// Action name prefixes this dashboard never exposes — `attendance.*` is a
/// personal/HR workflow and `gitlab.*` is a code-review workflow; neither
/// belongs on a CI/CD build dashboard, even though the API serves them.
const _hiddenActionPrefixes = ['attendance.', 'gitlab.'];

/// The action catalogue drives navigation and every generated form — see
/// `docs/web-ui-wireframe.md`. It is refetched whenever the session changes.
final actionsProvider = FutureProvider<List<ActionSchema>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final list = await api.getJsonList('/actions', listKey: 'actions');
  return list
      .map((e) => ActionSchema.fromJson(e as Map<String, dynamic>))
      .where((action) => !_hiddenActionPrefixes.any(action.name.startsWith))
      .toList();
});

ActionSchema? findAction(List<ActionSchema> actions, String name) {
  for (final action in actions) {
    if (action.name == name) return action;
  }
  return null;
}

/// One-off, unauthenticated health check against an arbitrary base URL —
/// used both to validate a server URL on the login screen and to refresh
/// the "Connection" card in Settings.
final healthCheckProvider = FutureProvider.family<Health, String>((
  ref,
  baseUrl,
) async {
  final client = ApiClient(baseUrl: baseUrl, apiKey: null);
  try {
    return Health.fromJson(await client.getJson('/health'));
  } finally {
    client.close();
  }
});

/// Resolves the connected key's own name/scopes by matching its truncated
/// SHA-256 hash against `admin.apiKeys.list` — the endpoint has no
/// "who am I" shortcut, and `admin.apiKeys.list` itself requires `invoke`.
final myKeyInfoProvider = FutureProvider<ApiKeyInfo?>((ref) async {
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.apiKeys.list') == null) return null;

  final api = ref.watch(apiClientProvider);
  final creds = ref.watch(sessionProvider);
  final body = await api.postJson('/actions/admin.apiKeys.list');
  final keys = (body['keys'] as List<dynamic>? ?? [])
      .map((e) => ApiKeyInfo.fromJson(e as Map<String, dynamic>))
      .toList();

  final hash = sha256
      .convert(utf8.encode(creds.apiKey))
      .toString()
      .substring(0, 8);
  // The server's key_hash sometimes carries a literal trailing "…" as part
  // of the string, not just the 8 hex chars the docs describe — match on
  // prefix rather than equality so that formatting quirk can't break this.
  for (final key in keys) {
    if (key.keyHash.startsWith(hash)) return key;
  }
  return null;
});
