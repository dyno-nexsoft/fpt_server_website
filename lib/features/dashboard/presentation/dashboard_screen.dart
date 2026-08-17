import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../../builds/application/jobs_providers.dart';
import 'build_stats_card.dart';

/// `key=value` entries for a job's params, used in the active-jobs tiles.
Iterable<String> _paramEntries(Map<String, dynamic> params) => params.entries
    .where((entry) => entry.value != null)
    .map((entry) => '${entry.key}=${entry.value}');

/// Drops trailing seconds once a build has run a minute or more.
String _compactDuration(Duration duration) {
  if (duration.inSeconds < 60) return '${duration.inSeconds}s';
  if (duration.inMinutes < 60) return '${duration.inMinutes} min';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
}

/// Aggregates `GET /status` (polled) and `GET /jobs?limit=100` (full history).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final status = ref.watch(statusControllerProvider);
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
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.autorenew),
              Text('Running / queued', style: textTheme.titleMedium),
            ],
          ),
          status.when(
            data: (data) => _ActiveJobsCard(status: data),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => ErrorListTile(error: error),
          ),
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.analytics),
              Text('Build stats', style: textTheme.titleMedium),
            ],
          ),
          Expanded(
            child: all.when(
              data: (jobs) => _BuildStatsSection(jobs: jobs),
              loading: () => const LinearProgressIndicator(),
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

class _ActiveJobsCard extends StatelessWidget {
  const _ActiveJobsCard({required this.status});

  final SystemStatus? status;

  @override
  Widget build(BuildContext context) {
    final data = status;
    if (data == null || (data.running.isEmpty && data.queued.isEmpty)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No active jobs'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final job in data.running)
            _JobTile(
              job: job,
              trailingText: job.runningDuration != null
                  ? _compactDuration(job.runningDuration!)
                  : 'queued',
            ),
          for (final entry in data.queued.asMap().entries)
            _JobTile(
              job: entry.value,
              trailingText: '#${entry.key + 1} (queued)',
            ),
        ],
      ),
    );
  }
}

/// One row for an active job — state icon, action name, author/params subtitle,
/// running duration or queue position on the right.
class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.trailingText});

  final Job job;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    final paramEntries = _paramEntries(job.actionParams).toList();
    final author = job.createdBy;
    final detailParts = [
      if (author != null) 'by $author',
      if (paramEntries.isNotEmpty) paramEntries.join(', '),
    ];
    final tooltipParts = [if (author != null) 'by $author', ...paramEntries];
    return ListTile(
      leading: JobStateIcon(state: job.state),
      title: Text(job.actionName ?? job.command),
      subtitle: detailParts.isEmpty
          ? null
          : EllipsisText(
              detailParts.join(' • '),
              tooltip: tooltipParts.join('\n'),
            ),
      trailing: trailingText.isEmpty
          ? null
          : Text(trailingText, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => JobDetailRoute(job.id).go(context),
    );
  }
}
