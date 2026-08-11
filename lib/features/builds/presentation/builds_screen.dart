import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/jobs_api.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/auth_guard.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../application/jobs_providers.dart';

const _filters = <(String label, String? value, IconData icon)>[
  ('All', null, Icons.apps),
  ('Running', 'running', Icons.autorenew),
  ('Queued', 'queued', Icons.schedule),
  ('Succeeded', 'succeeded', Icons.check_circle_outline),
  ('Failed', 'failed', Icons.error_outline),
  ('Cancelled', 'cancelled', Icons.block),
];

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
            spacing: 8,
            children: [
              const Icon(Icons.list_alt_outlined),
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
            runSpacing: 8,
            children: [
              for (final (label, value, icon) in _filters)
                ChoiceChip(
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                  selected: _stateFilter == value,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _stateFilter = value),
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
              (job.actionName ?? job.command).toLowerCase().contains(query) ||
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
    // Two-axis scroll: DataTable has no intrinsic horizontal scrolling of its
    // own, so on a narrow screen the seven columns need their own scroll
    // view nested inside the vertical one, or they'd overflow instead of
    // scrolling.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
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
        DataCell(Text(job.actionName ?? job.command)),
        DataCell(_ParamsCell(summary: _paramsSummary(job))),
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
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
}

/// A single truncated line instead of the raw `key=value, ...` dump
/// wrapping across the row — the full value is still one hover away.
class _ParamsCell extends StatelessWidget {
  const _ParamsCell({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const Text('—');
    return Tooltip(
      message: summary,
      child: SizedBox(
        width: 260,
        child: Text(summary, overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    );
  }
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
            onPressed: () => _act(
              context,
              ref,
              'Promoted',
              () => promoteJob(ref.read(apiClientProvider), job.id),
            ),
          ),
        if (canCancel)
          IconButton(
            tooltip: 'Cancel — deletes artifacts on the build server',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () => _act(
              context,
              ref,
              null,
              () => cancelJob(ref.read(apiClientProvider), job.id),
            ),
          ),
        if (canRetry)
          IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.replay),
            onPressed: () => _act(
              context,
              ref,
              'Retried',
              () => retryJob(ref.read(apiClientProvider), job.id),
            ),
          ),
      ],
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    String? fallbackMessage,
    Future<Job> Function() action,
  ) async {
    final result = await runAuthedJobAction(
      context,
      ref,
      fallbackMessage: fallbackMessage,
      action: action,
    );
    if (result != null) {
      ref.invalidate(jobsListProvider);
      ref.read(statusControllerProvider.notifier).refreshNow();
    }
  }
}
