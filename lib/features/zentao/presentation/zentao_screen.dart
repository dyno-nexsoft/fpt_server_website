import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../application/zentao_providers.dart';
import 'zentao_account_card.dart';
import 'zentao_config_card.dart';
import 'zentao_report_card.dart';

/// Daily-report management, previously reachable only through Discord's
/// `/zentao` commands and the buttons on the report message it posts.
class ZentaoScreen extends ConsumerWidget {
  const ZentaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final status = ref.watch(zentaoStatusProvider);
    final canConfigure =
        ref.watch(myKeyInfoProvider).value?.can(Permission.invokeDangerous) ??
        false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.assignment_outlined),
              Text('Zentao', style: textTheme.headlineSmall),
            ],
          ),
          switch (status) {
            AsyncValue(:final error?) => _ZentaoUnavailable(error: '$error'),
            AsyncValue(:final value?) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                ZentaoAccountCard(status: value),
                if (value.linked) ZentaoReportCard(status: value),
                if (canConfigure) ZentaoConfigCard(status: value),
              ],
            ),
            // A resolved `null` means there is no key to ask with; still
            // loading looks the same to this screen, and a spinner is the
            // honest rendering of both.
            _ => const Card(
              child: ListTile(
                leading: Icon(Icons.vpn_key_off_outlined),
                title: Text('Sign in with an API key to manage Zentao.'),
              ),
            ),
          },
        ],
      ),
    );
  }
}

/// Why the screen has nothing to show.
///
/// Worth its own rendering rather than a bare error string: by far the most
/// likely cause is a key with no `discord_user_id`, and Zentao work is
/// per-user, so that is a configuration answer rather than a fault.
class _ZentaoUnavailable extends StatelessWidget {
  const _ZentaoUnavailable({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text('Zentao is unavailable for this key'),
        subtitle: Text(error),
      ),
    );
  }
}
