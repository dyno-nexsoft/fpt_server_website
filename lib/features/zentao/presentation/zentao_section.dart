import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../application/zentao_providers.dart';
import 'zentao_account_tile.dart';
import 'zentao_config_tiles.dart';
import 'zentao_report_tile.dart';

/// Daily-report management, previously reachable only through Discord's
/// `/zentao` commands and the buttons on the report message it posts.
///
/// One card rather than a screen of its own: everything here is either an
/// account binding or a server-wide setting, which is what the rest of this
/// page is. The report itself lives here too because it is the thing that
/// binding exists for — splitting it onto another screen would separate a
/// two-click action from the account it acts as.
class ZentaoSection extends ConsumerWidget {
  const ZentaoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(zentaoStatusProvider);
    final canConfigure =
        ref.watch(myKeyInfoProvider).value?.can(Permission.invokeDangerous) ??
        false;

    // Nothing to ask with: no stored key, or a server whose catalogue has no
    // Zentao at all. Hidden rather than shown-empty, matching every other
    // key-gated section on this page.
    if (status.value == null && !status.hasError) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ExpansionTile(
        // Without this, collapsing tears down the report tile beneath —
        // the last watcher on zentaoStatusProvider/zentaoTaskProvider
        // (both `.autoDispose`) goes away, Riverpod discards their state,
        // and re-expanding starts a brand-new fetch with nothing to show
        // while it runs instead of the report that was already loaded.
        maintainState: true,
        leading: Icon(_icon(status)),
        title: const Text('Zentao'),
        subtitle: Text(_summary(status)),
        // `.when` over a hand-matched `switch`: both `skip*` flags default
        // to what a first load needs, but this provider also *reloads* on
        // anything `myKeyInfoProvider`/the session depend on, and a `switch`
        // checking `error?` before `value?` (as this used to) shows the
        // error tile even when a still-good previous value is sitting right
        // there in `.value` — exactly the case a refresh/reload hitting a
        // transient failure produces.
        children: status.when(
          skipLoadingOnReload: true,
          skipError: true,
          // `value` is technically nullable (`ZentaoStatus?`) since that's
          // what the provider itself returns for "nothing to ask about" —
          // but the early return above already sent that case back as
          // `SizedBox.shrink()`, so it can never actually reach here.
          data: (value) => value == null
              ? const []
              : [
                  ZentaoAccountTile(status: value),
                  if (value.linked) ZentaoReportTile(status: value),
                  if (canConfigure) ...zentaoConfigTiles(ref, value),
                ],
          error: (error, _) => [
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Unavailable for this key'),
              subtitle: Text('$error'),
            ),
          ],
          loading: () => const [LinearProgressIndicator()],
        ),
      ),
    );
  }

  // Value checked before error in both helpers below — a transient failure
  // on a reload/refresh that still has a previous value in `.value` should
  // keep reading like the last-known-good state, not flip to "unavailable"
  // out from under whatever was already showing.
  IconData _icon(AsyncValue<ZentaoStatus?> status) => switch (status) {
    AsyncValue(:final value?) when value.linked =>
      Icons.assignment_turned_in_outlined,
    AsyncValue(hasValue: true) => Icons.assignment_outlined,
    AsyncValue(hasError: true) => Icons.error_outline,
    _ => Icons.assignment_outlined,
  };

  /// Collapsed, this card is a status line — the link state and whether
  /// today's report exists are the two things worth knowing without
  /// expanding, since they decide whether there is anything to do here.
  String _summary(AsyncValue<ZentaoStatus?> status) => switch (status) {
    AsyncValue(:final value?) when !value.linked => 'No account linked',
    AsyncValue(:final value?) =>
      value.todayTaskId == null
          ? '${value.account} · no report today'
          : '${value.account} · report #${value.todayTaskId}',
    AsyncValue(hasError: true) => 'Unavailable for this key',
    _ => 'Checking…',
  };
}
