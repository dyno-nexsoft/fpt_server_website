import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/action_schema.dart';
import '../models/api_key_info.dart';
import '../models/health.dart';
import 'core_providers.dart';
import 'session_provider.dart';

/// Action name prefixes this dashboard never exposes: `attendance.*`
/// (personal/HR), `gitlab.*` (code review), `zentao.*` (daily reports), and
/// `admin.owners.*` (Discord bot ownership) are all real API capabilities
/// but none belong on a CI/CD build dashboard.
const _hiddenActionPrefixes = [
  'attendance.',
  'gitlab.',
  'zentao.',
  'admin.owners.',
];

/// The action catalogue drives navigation and every generated form — see
/// `docs/web-ui-wireframe.md`. It is refetched whenever the session changes.
final actionsProvider = FutureProvider<List<ActionSchema>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final list = await api.decodeList(
    api.endpoints.listActions(),
    listKey: 'actions',
  );
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

/// The "New build" nav menu is for CI actions only — `ci.*` and the one
/// other job/mutation action the wireframe explicitly calls out
/// (`cron.run`). `admin.apiKeys.add/remove` are job/mutation-kind too but
/// already have dedicated controls in Settings; listing them here as well
/// would let a menu meant for builds trigger key or (if ever un-hidden)
/// owner management instead.
bool isBuildMenuAction(ActionSchema action) =>
    action.name.startsWith('ci.') || action.name == 'cron.run';

/// [isBuildMenuAction] entries the connected key can actually call.
///
/// `myKey == null` (no key, or resolution still loading/failed) shows
/// everything rather than nothing — an anonymous visitor was always going to
/// hit a 401 on submit regardless, and hiding the whole menu for them would
/// be a regression, not a permission fix. Once a key resolves, an action
/// whose permission the key's scopes don't cover (e.g. `ci.clean` needs
/// `invokeDangerous`, an `invoke`-only key doesn't have it) never gets a
/// chance to show its "requires elevated permission" warning after the fact.
List<ActionSchema> visibleBuildMenuActions(
  List<ActionSchema> actions,
  ApiKeyInfo? myKey,
) {
  final visible = actions
      .where(isBuildMenuAction)
      .where((action) => myKey == null || myKey.can(action.permission));
  // Everyday build actions first, then the ones that warn on the way in
  // (ci.clean, cron.run) — grouped at the bottom instead of interleaved by
  // whatever order the server happens to register them in.
  final routine = visible.where((action) => !action.isDangerous);
  final dangerous = visible.where((action) => action.isDangerous);
  return [...routine, ...dangerous];
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
    return Health.fromJson(await client.decodeMap(client.endpoints.health()));
  } finally {
    client.close();
  }
});

/// `GET /autocomplete/branches?repo=&query=` — key-gated (like
/// `stream-token`), so an anonymous visitor just gets no suggestions rather
/// than an error; the plain text field underneath still works either way.
final branchAutocompleteProvider = FutureProvider.autoDispose
    .family<List<String>, (String repo, String query)>((ref, args) async {
      if (!ref.watch(sessionProvider).hasKey) return const [];
      final (repo, query) = args;
      final api = ref.watch(apiClientProvider);
      final list = await api.decodeList(
        api.endpoints.autocompleteBranches(repo, query),
        listKey: 'branches',
      );
      return list.cast<String>();
    });

/// Resolves the connected key's own name/scopes by matching its truncated
/// SHA-256 hash against `admin.apiKeys.list` — the endpoint has no
/// "who am I" shortcut, and `admin.apiKeys.list` itself requires `invoke`.
///
/// `/actions` is public and unfiltered (see `ApiRouter._isPublic`), so
/// `findAction` finding this action proves nothing about whether *this*
/// session can call it — an anonymous visitor has no key to resolve at all.
final myKeyInfoProvider = FutureProvider<ApiKeyInfo?>((ref) async {
  final creds = ref.watch(sessionProvider);
  if (!creds.hasKey) return null;

  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'admin.apiKeys.list') == null) return null;

  final api = ref.watch(apiClientProvider);
  final body = await api.decodeMap(
    api.endpoints.invokeAction('admin.apiKeys.list', api.encodeBody(const {})),
  );
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
