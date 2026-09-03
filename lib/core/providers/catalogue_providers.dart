import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import 'core_providers.dart';
import 'session_provider.dart';

/// Action name prefixes this dashboard never exposes: `zentao.*` (daily
/// reports) and `admin.owners.*` (Discord bot ownership) are real API
/// capabilities but neither belongs on a CI/CD build dashboard. `gitlab.*`
/// used to be hidden here too, but code review is close enough to "build"
/// that it now shows in the New Build menu (see [isBuildMenuAction]).
const _hiddenActionPrefixes = ['zentao.', 'admin.owners.'];

/// The action catalogue drives navigation and every generated form — see
/// `docs/web-ui-wireframe.md`. It is refetched whenever the session changes.
///
/// Sorted dangerous-last, then by name: every list built from this provider
/// (New Build, ...) inherits the same order instead of each screen
/// re-deriving its own routine/dangerous split.
final actionsProvider = FutureProvider<List<ActionSchema>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final list = await api.decodeList(
    api.endpoints.listActions(),
    listKey: 'actions',
  );
  final actions = list
      .map((e) => ActionSchema.fromJson(e as Map<String, dynamic>))
      .where((action) => !_hiddenActionPrefixes.any(action.name.startsWith))
      .toList();
  actions.sort((a, b) {
    if (a.isDangerous != b.isDangerous) return a.isDangerous ? 1 : -1;
    return a.name.compareTo(b.name);
  });
  return actions;
});

ActionSchema? findAction(List<ActionSchema> actions, String name) {
  for (final action in actions) {
    if (action.name == name) return action;
  }
  return null;
}

/// The "New build" nav menu is for CI and GitLab actions — `ci.*`,
/// `gitlab.*`, and the one other job/mutation action the wireframe
/// explicitly calls out (`cron.run`). `admin.apiKeys.add/remove` are
/// job/mutation-kind too but already have dedicated controls in Settings;
/// listing them here as well would let a menu meant for builds trigger key
/// or (if ever un-hidden) owner management instead.
bool isBuildMenuAction(ActionSchema action) =>
    action.name.startsWith('ci.') ||
    action.name.startsWith('gitlab.') ||
    action.name == 'cron.run';

/// [isBuildMenuAction] entries the connected key can actually call.
///
/// `myKey == null` (no key, or resolution still loading/failed) shows every
/// routine action rather than nothing — an anonymous visitor was always
/// going to hit a 401 on submit regardless, and hiding those for them would
/// be a regression, not a permission fix. Dangerous ones (`ci.clean`,
/// `cron.run`, ...) are the exception: they stay hidden until a key actually
/// resolves with `invokeDangerous` (or `admin`), so a build-menu browse
/// doesn't casually surface "wipe the build cache" to whoever happens to be
/// looking, logged in or not. Once a key resolves, every action is filtered
/// by its real scopes either way, so a routine action a lesser key can't
/// call never gets a chance to show its "requires elevated permission"
/// warning after the fact.
///
/// [actions] is expected to already be [actionsProvider]'s dangerous-last
/// order — filtering here preserves it rather than re-deriving it.
List<ActionSchema> visibleBuildMenuActions(
  List<ActionSchema> actions,
  ApiKeyInfo? myKey,
) => actions
    .where(isBuildMenuAction)
    .where(
      (action) => myKey == null
          ? !action.isDangerous
          : myKey.can(action.permission),
    )
    .toList();

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
  // Only need to match a short prefix of the full hash the server now
  // returns — no need to recompute and compare the whole thing.
  for (final key in keys) {
    if (key.keyHash.startsWith(hash)) return key;
  }
  return null;
});
