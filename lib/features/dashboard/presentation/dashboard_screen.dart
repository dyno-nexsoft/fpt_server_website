import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/job.dart';
import '../../../core/models/system_status.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../../builds/application/jobs_providers.dart';

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
            _ActiveJobTile(job: job, positionLabel: null),
          for (final entry in data.queued.asMap().entries)
            _ActiveJobTile(
              job: entry.value,
              positionLabel: '#${entry.key + 1} (queued)',
            ),
        ],
      ),
    );
  }
}

class _ActiveJobTile extends StatelessWidget {
  const _ActiveJobTile({required this.job, required this.positionLabel});

  final Job job;
  final String? positionLabel;

  @override
  Widget build(BuildContext context) {
    final duration = job.runningDuration;
    final subtitle =
        positionLabel ??
        (duration != null ? formatDuration(duration) : 'queued');
    return ListTile(
      leading: JobStateIcon(state: job.state),
      title: Text(job.actionName ?? job.command),
      subtitle: Text(subtitle),
      onTap: () => context.go('/builds/${job.id}'),
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
        children: [for (final job in jobs) _RecentJobTile(job: job)],
      ),
    );
  }
}

class _RecentJobTile extends StatelessWidget {
  const _RecentJobTile({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final start = job.startedAt;
    final end = job.finishedAt;
    final duration = start != null && end != null
        ? formatDuration(end.difference(start))
        : null;
    return ListTile(
      leading: JobStateIcon(state: job.state),
      title: Text(job.actionName ?? job.command),
      subtitle: Text(formatRelativeTimestamp(job.createdAt)),
      trailing: duration != null ? Text(duration) : null,
      onTap: () => context.go('/builds/${job.id}'),
    );
  }
}
