import 'package:flutter/material.dart';

import '../../../shared/widgets/section_title.dart';
import 'hive_panel.dart';
import 'logs_card.dart';
import 'owners_section.dart';
import 'system_panel.dart';

/// Everything gated on the `admin` scope, off its own screen rather than
/// buried among the self-service cards on [SettingsScreen] — reached from
/// there through a single entry point instead of four collapsed cards a
/// non-admin never sees anyway.
///
/// Tabs, not [ExpansionTile]s: this screen is nothing *but* admin content, so
/// there is no shorter "collapsed" state worth having, and a tab switch reads
/// better than scrolling past whichever section isn't the one being used.
/// Operations and Hive share a tab — both are server maintenance, and three
/// tabs read better than four for a set this size.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              spacing: 8,
              children: [
                const Icon(Icons.admin_panel_settings_outlined),
                Text('Admin', style: textTheme.headlineSmall),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shield_outlined), text: 'Access'),
              Tab(icon: Icon(Icons.build_circle_outlined), text: 'Operations'),
              Tab(icon: Icon(Icons.article_outlined), text: 'Logs'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [OwnersSection(), _OperationsTab(), LogsCard()],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsTab extends StatelessWidget {
  const _OperationsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: const [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [SectionTitle('System'), SystemPanel()],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [SectionTitle('Hive database'), HivePanel()],
          ),
        ],
      ),
    );
  }
}
