import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/connection_provider.dart';
import '../../../core/providers/session_provider.dart';
import 'api_keys_section.dart';
import 'appearance_section.dart';
import 'logs_section.dart';
import 'system_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
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
          const _ConnectionCard(),
          const ApiKeysSection(),
          const LogsSection(),
          const SystemPanel(),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Text(
                  'Connection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(
                    healthCheckProvider(creds.normalizedServerUrl),
                  ),
                ),
              ],
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dns_outlined),
              title: Text(creds.serverUrl),
              subtitle: health.when(
                data: (data) =>
                    Text('${data.hostname} · uptime ${data.uptimeSeconds}s'),
                loading: () => const Text('Checking…'),
                error: (error, _) => Text('Unreachable: $error'),
              ),
            ),
            if (creds.hasKey)
              myKey.when(
                data: (info) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: Text(info?.name ?? 'Unnamed key'),
                  subtitle: Text(info?.scopes.join(' · ') ?? 'scopes unknown'),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              )
            else
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.vpn_key_off_outlined),
                title: Text('Not connected'),
                subtitle: Text(
                  'Browsing read-only — no key stored. Run '
                  '/admin api-key-add in Discord to get one.',
                ),
              ),
            if (creds.hasKey)
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(connectionControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              )
            else
              FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }
}
