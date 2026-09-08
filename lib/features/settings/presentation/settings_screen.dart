import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalogue_providers.dart';
import 'api_keys_section.dart';
import 'appearance_section.dart';
import 'connection_card.dart';
import 'hive_panel.dart';
import 'logs_card.dart';
import 'notifications_section.dart';
import 'owners_section.dart';
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
          const ConnectionCard(),
          const ApiKeysSection(),
          if (isAdmin) const OwnersSection(),
          if (isAdmin) const LogsCard(),
          if (isAdmin) const SystemPanel(),
          if (isAdmin) const HivePanel(),
        ],
      ),
    );
  }
}
