import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/jobs_api.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../application/jobs_providers.dart';

const _filters = <String, String?>{
  'All': null,
  'Running': 'running',
  'Queued': 'queued',
  'Succeeded': 'succeeded',
  'Failed': 'failed',
  'Cancelled': 'cancelled',
};

/// `GET /jobs?state=&limit=` — a live wire-screen of what the API returns;
/// row actions are derived from each job's own field values so the button
/// availability never drifts from the server's own 409 rules.
class BuildsScreen extends ConsumerStatefulWidget {
  const BuildsScreen({super.key});

  @override
  ConsumerState<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends ConsumerState<BuildsScreen> {
  String? _stateFilter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final jobs = ref.watch(
      jobsListProvider(JobsQuery(state: _stateFilter, limit: 100)),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              Text('Builds', style: textTheme.headlineSmall),
              const Spacer(),
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search action or job id',
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in _filters.entries)
                ChoiceChip(
                  label: Text(entry.key),
                  selected: _stateFilter == entry.value,
                  onSelected: (_) => setState(() => _stateFilter = entry.value),
                ),
            ],
          ),
          Expanded(
            child: jobs.when(
              data: (list) => _JobsTable(jobs: _applySearch(list)),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
            ),
          ),
        ],
      ),
    );
  }

  List<Job> _applySearch(List<Job> jobs) {
    if (_search.trim().isEmpty) return jobs;
    final query = _search.trim().toLowerCase();
    return jobs
        .where(
          (job) =>
              job.actionName.toLowerCase().contains(query) ||
              job.id.toLowerCase().contains(query),
        )
        .toList();
  }
}

class _JobsTable extends ConsumerWidget {
  const _JobsTable({required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No builds match this filter'));
    }
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Job')),
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('Params')),
          DataColumn(label: Text('State')),
          DataColumn(label: Text('Started')),
          DataColumn(label: Text('Duration')),
          DataColumn(label: Text('')),
        ],
        rows: [for (final job in jobs) _buildRow(context, ref, job)],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Job job) {
    final start = job.startedAt;
    final end = job.finishedAt;
    final duration = start != null
        ? formatDuration((end ?? DateTime.now()).difference(start))
        : null;
    return DataRow(
      onSelectChanged: (_) => context.go('/jobs/${job.id}'),
      cells: [
        DataCell(Text(job.id)),
        DataCell(Text(job.actionName)),
        DataCell(Text(_paramsSummary(job))),
        DataCell(JobStateChip(state: job.state)),
        DataCell(
          Text(
            job.startedAt != null
                ? formatRelativeTimestamp(job.startedAt!)
                : '',
          ),
        ),
        DataCell(Text(duration ?? '')),
        DataCell(_RowActions(job: job)),
      ],
    );
  }

  String _paramsSummary(Job job) => job.actionParams.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel =
        job.state == JobState.queued || job.state == JobState.running;
    final canPromote = job.state == JobState.queued && !job.promoted;
    final canRetry = job.isTerminal;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canPromote)
          IconButton(
            tooltip: 'Promote',
            icon: const Icon(Icons.upgrade),
            onPressed: () => _run(
              ref,
              'Promoted',
              () => promoteJob(ref.read(apiClientProvider), job.id),
            ),
          ),
        if (canCancel)
          IconButton(
            tooltip: 'Cancel — deletes artifacts on the build server',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () => _run(
              ref,
              null,
              () => cancelJob(ref.read(apiClientProvider), job.id),
            ),
          ),
        if (canRetry)
          IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.replay),
            onPressed: () => _run(
              ref,
              'Retried',
              () => retryJob(ref.read(apiClientProvider), job.id),
            ),
          ),
      ],
    );
  }

  Future<void> _run(
    WidgetRef ref,
    String? fallbackMessage,
    Future<Job> Function() action,
  ) async {
    try {
      final result = await action();
      ref
          .read(appToastProvider.notifier)
          .show(result.message ?? fallbackMessage ?? 'Done');
      ref.invalidate(jobsListProvider);
      ref.read(statusControllerProvider.notifier).refreshNow();
    } on ApiException catch (e) {
      ref.read(appToastProvider.notifier).show(e.message, isError: true);
    }
  }
}
