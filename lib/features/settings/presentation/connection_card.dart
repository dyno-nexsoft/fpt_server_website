import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/browser/browser_utils.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/format.dart';

class ConnectionCard extends ConsumerWidget {
  const ConnectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creds = ref.watch(sessionProvider);
    final health = ref.watch(healthCheckProvider(creds.normalizedServerUrl));
    final myKey = ref.watch(myKeyInfoProvider);

    // Collapsed, this card is a status line, so the reading goes in the
    // subtitle rather than being something you have to expand to see. Value
    // before error on purpose: a failed refresh keeps the last good reading,
    // and naming the host we still know beats reporting nothing.
    final (icon, summary) = switch (health) {
      AsyncValue(:final value?) => (
        Icons.cloud_done_outlined,
        '${value.hostname} · v${value.appVersion} · '
            'uptime ${formatUptime(value.uptimeSeconds)}',
      ),
      AsyncError(:final error) => (
        Icons.cloud_off_outlined,
        'Unreachable: $error',
      ),
      _ => (Icons.cloud_queue_outlined, 'Checking…'),
    };

    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: const Text('Connection'),
        subtitle: Text(summary),
        // The URL row this used to be is gone — expanding is itself the
        // signal to refresh, so there is nothing left for a dedicated row
        // (or its refresh button) to do.
        onExpansionChanged: (expanded) {
          if (expanded) {
            ref.invalidate(healthCheckProvider(creds.normalizedServerUrl));
          }
        },
        children: [
          if (health.value?.remoteDesktopUrl case final url?)
            ListTile(
              leading: const Icon(Icons.desktop_windows_outlined),
              title: const Text('Remote desktop'),
              subtitle: Text(url),
              trailing: FilledButton.tonalIcon(
                onPressed: () => openInNewTab(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ),
          if (health.value?.devToolsUrl case final url?)
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('DevTools'),
              subtitle: Text(url),
              trailing: FilledButton.tonalIcon(
                onPressed: () => openInNewTab(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
            ),
          if (creds.hasKey)
            myKey.when(
              data: (info) => ListTile(
                leading: const Icon(Icons.vpn_key_outlined),
                title: Text(info?.name ?? 'Unnamed key'),
                subtitle: Text(info?.scopes.join(' · ') ?? 'scopes unknown'),
                trailing: FilledButton.tonalIcon(
                  onPressed: () async {
                    await ref
                        .read(connectionControllerProvider.notifier)
                        .logout();
                    // Settings has no stored-key redirect of its own (it's a
                    // public-ish screen), unlike the background 401 eviction
                    // RouterNotifier handles — an explicit Sign out click
                    // needs its own navigation.
                    if (context.mounted) const LoginRoute().go(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            )
          else
            ListTile(
              leading: const Icon(Icons.vpn_key_off_outlined),
              title: const Text('Not connected'),
              subtitle: const Text(
                'Browsing read-only — no key stored. Run '
                '/admin api-key-add in Discord to get one.',
              ),
              trailing: FilledButton.icon(
                onPressed: () => const LoginRoute().go(context),
                icon: const Icon(Icons.login),
                label: const Text('Sign in'),
              ),
            ),
        ],
      ),
    );
  }
}
