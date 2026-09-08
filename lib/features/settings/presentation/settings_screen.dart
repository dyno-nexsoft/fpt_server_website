import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/browser/browser_utils.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/format.dart';
import 'api_keys_section.dart';
import 'appearance_section.dart';
import 'hive_panel.dart';
import 'notifications_section.dart';
import 'system_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isAdmin = ref.watch(myKeyInfoProvider).value?.isAdmin ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.settings_outlined),
              Text('Settings', style: textTheme.headlineSmall),
            ],
          ),
          const AppearanceSection(),
          const NotificationsSection(),
          const _ConnectionCard(),
          const ApiKeysSection(),
          if (isAdmin) const _LogsCard(),
          if (isAdmin) const SystemPanel(),
          if (isAdmin) const HivePanel(),
        ],
      ),
    );
  }
}

/// The server-side logs `admin.logs.tail` can read, one entry each.
///
/// Both open the same viewer, told apart by the action's own `source`. Admin
/// only, so the caller decides whether to show it at all.
class _LogsCard extends StatelessWidget {
  const _LogsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.article_outlined),
        title: const Text('Logs'),
        subtitle: const Text('Server and remote desktop'),
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server Logs'),
            subtitle: const Text('View the tail of server.log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ServerLogsRoute().go(context),
          ),
          ListTile(
            leading: const Icon(Icons.desktop_windows_outlined),
            title: const Text('Remote Desktop Logs'),
            subtitle: const Text('View the tail of the noVNC service log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ServerLogsRoute(source: 'novnc').go(context),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard();

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
        children: [
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(creds.serverUrl),
            // No subtitle here: it would just repeat the header's, which is
            // already visible collapsed — this row exists to show the URL
            // and host the refresh button, not to restate the summary.
            // On this row rather than the ExpansionTile's own `trailing`,
            // which holds the expand arrow — replacing that would cost the
            // only affordance saying the card opens at all.
            trailing: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(
                healthCheckProvider(creds.normalizedServerUrl),
              ),
            ),
          ),
          if (health.value?.remoteDesktopUrl case final url?)
            _RemoteDesktopTile(url: url),
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

/// Opens the build machine's noVNC session in a new tab.
///
/// [url] comes from `GET /health`, which this card already fetches — the port
/// and the client path belong to the server's configuration, and rebuilding
/// them client-side is how the two quietly drift apart. The caller omits this
/// tile entirely when the server sends no address, so an older server (or one
/// with no remote desktop) degrades quietly rather than showing a dead button.
///
/// Shown as the subtitle so it is readable and obvious where the button leads.
class _RemoteDesktopTile extends StatelessWidget {
  const _RemoteDesktopTile({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.desktop_windows_outlined),
      title: const Text('Remote desktop'),
      subtitle: Text(url),
      trailing: FilledButton.tonalIcon(
        onPressed: () => openInNewTab(url),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open'),
      ),
    );
  }
}
