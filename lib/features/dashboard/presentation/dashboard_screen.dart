import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/error_view.dart';
import '../../builds/application/jobs_providers.dart';
import 'build_stats_card.dart';

/// Aggregates `GET /status` (polled) and `GET /jobs?limit=100` (full history).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final all = ref.watch(dashboardJobsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.dashboard_outlined),
              Text('Dashboard', style: textTheme.headlineSmall),
            ],
          ),
          Expanded(
            child: all.when(
              // Both default to true/false — set explicitly since this
              // provider re-fetches every time statusControllerProvider
              // changes (a `ref.watch`-triggered *reload*, not a manual
              // refresh), which `skipLoadingOnReload`/`skipError`'s
              // defaults don't cover: without them, every status push (or
              // a transient error while the server is mid-restart) would
              // otherwise blank the whole dashboard for whatever's already
              // on screen.
              skipLoadingOnReload: true,
              skipError: true,
              data: (jobs) => _BuildStatsSection(jobs: jobs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorListTile(error: error),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildStatsSection extends StatelessWidget {
  const _BuildStatsSection({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    return Flex(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      direction: isTabletWidth(context) ? Axis.vertical : Axis.horizontal,
      children: [
        Expanded(child: BuildsByStateCard(jobs: jobs)),
        Expanded(child: BuildsByDayCard(jobs: jobs)),
      ],
    );
  }
}
