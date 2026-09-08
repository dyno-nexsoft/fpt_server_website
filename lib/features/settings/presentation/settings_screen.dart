import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalogue_providers.dart';
import '../../../core/router/app_router.dart';
import '../../zentao/presentation/zentao_section.dart';
import 'api_keys_section.dart';
import 'appearance_section.dart';
import 'connection_card.dart';
import 'notifications_section.dart';

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
          const ConnectionCard(),
          const ZentaoSection(),
          const ApiKeysSection(),
          if (isAdmin) const _AdminEntryCard(),
        ],
      ),
    );
  }
}

/// Opens [AdminScreen] — the single entry point for everything gated on the
/// `admin` scope, kept off this screen entirely rather than as four more
/// collapsed cards a non-admin never even sees.
class _AdminEntryCard extends StatelessWidget {
  const _AdminEntryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings_outlined),
        title: const Text('Admin'),
        subtitle: const Text(
          'Owners, server operations, Hive database, and logs',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => const AdminRoute().go(context),
      ),
    );
  }
}
