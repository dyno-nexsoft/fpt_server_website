import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/models/system_status.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../../builds/application/jobs_providers.dart';

/// A single truncated `key=value, ...` summary of a job's params, shared by
/// the active and recent job tiles below — same rendering the builds table
/// uses for its own params column, just without that column's `maxWidth`
/// clamp since a `ListTile` subtitle is already width-bound by the tile.
String? _paramsSummary(Map<String, dynamic> params) {
  final entries = params.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}')
      .toList();
  return entries.isEmpty ? null : entries.join(', ');
}

/// Aggregates `GET /status` (polled) and `GET /jobs?limit=20`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final status = ref.watch(statusControllerProvider);
    final recent = ref.watch(recentJobsProvider);

    return SingleChildScrollView(
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
              const Icon(Icons.history),
              Text('Recent builds', style: textTheme.titleMedium),
            ],
          ),
          recent.when(
            data: (jobs) => _RecentBuildsCard(jobs: jobs),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => ErrorListTile(error: error),
          ),
        ],
      ),
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
                  ? formatDuration(job.runningDuration!)
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

class _RecentBuildsCard extends StatelessWidget {
  const _RecentBuildsCard({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No builds yet'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final job in jobs)
            _JobTile(
              job: job,
              trailingText: [
                formatRelativeTimestamp(job.createdAt),
                if (job.startedAt != null && job.finishedAt != null)
                  formatDuration(
                    job.finishedAt!.difference(job.startedAt!),
                  ),
              ].join(' • '),
            ),
        ],
      ),
    );
  }
}

/// One row shared by both dashboard cards — state chip, action name, then
/// author/params as a single truncated subtitle line, with [trailingText]
/// (a running duration, queue position, or — for recent builds — the
/// relative timestamp and elapsed build time) on the right. Kept as one
/// widget rather than two near-identical ones so the two lists can never
/// silently drift apart in layout again.
class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.trailingText});

  final Job job;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    final params = _paramsSummary(job.actionParams);
    final author = job.createdBy;
    final detailParts = [
      if (author != null) 'by $author',
      if (params != null) params,
    ];
    return ListTile(
      leading: JobStateChip(state: job.state),
      title: Text(job.actionName ?? job.command),
      subtitle: detailParts.isEmpty
          ? null
          : EllipsisText(detailParts.join(' • ')),
      trailing: trailingText.isEmpty
          ? null
          : Text(
              trailingText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => JobDetailRoute(job.id).go(context),
    );
  }
}
