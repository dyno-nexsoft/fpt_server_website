import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/jobs_api.dart';
import '../../../core/models/job.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/status_provider.dart';
import '../../../shared/auth_guard.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/job_state_chip.dart';
import '../application/jobs_providers.dart';

const _columnLabels = [
  'Job',
  'Action',
  'Params',
  'State',
  'Started',
  'Duration',
  '',
];

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
    // DataTable sizes every column to its own content and nothing more —
    // there is no way to make one column claim leftover space, which is why
    // Params sat capped at a fixed width with acres of blank table to its
    // right on a wide screen. A plain Table with FlexColumnWidth actually
    // stretches, but only works with a bounded parent width, which the
    // two-axis scroll a narrow screen needs cannot provide — so mobile keeps
    // the DataTable-based layout and desktop gets the flexible one.
    if (isMobileWidth(context)) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              for (final label in _columnLabels) DataColumn(label: Text(label)),
            ],
            rows: [for (final job in jobs) _buildRow(context, ref, job)],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(160),
          1: FixedColumnWidth(110),
          2: FlexColumnWidth(),
          3: FixedColumnWidth(150),
          4: FixedColumnWidth(90),
          5: FixedColumnWidth(90),
          6: FixedColumnWidth(140),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            children: [
              for (final label in _columnLabels)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
            ],
          ),
          for (final job in jobs) _buildFlexRow(context, ref, job),
        ],
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
      onSelectChanged: (_) => context.go('/builds/${job.id}'),
      cells: [
        DataCell(Text(job.id)),
        DataCell(Text(job.actionName ?? job.command)),
        DataCell(_ParamsCell(params: job.actionParams, maxWidth: 260)),
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

  TableRow _buildFlexRow(BuildContext context, WidgetRef ref, Job job) {
    final start = job.startedAt;
    final end = job.finishedAt;
    final duration = start != null
        ? formatDuration((end ?? DateTime.now()).difference(start))
        : null;

    Widget cell(Widget child) => TableRowInkWell(
      onTap: () => context.go('/builds/${job.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      children: [
        cell(Text(job.id)),
        cell(Text(job.actionName ?? job.command)),
        cell(_ParamsCell(params: job.actionParams)),
        cell(JobStateChip(state: job.state)),
        cell(
          Text(
            job.startedAt != null
                ? formatRelativeTimestamp(job.startedAt!)
                : '',
          ),
        ),
        cell(Text(duration ?? '')),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: _RowActions(job: job),
        ),
      ],
    );
  }
}

/// A single truncated `key=value, ...` line instead of the raw dump wrapping
/// across the row — the tooltip breaks the same entries one per line instead
/// of repeating that comma-joined line, since a hover has room a table cell
/// doesn't. Takes the raw [params] map rather than a pre-joined string, so
/// each representation is free to format the entries differently instead of
/// being stuck sharing one.
/// [maxWidth] caps it inside DataTable, which otherwise sizes the column to
/// the full line's length; the flexible desktop Table already bounds the
/// cell itself, so it's left unset there.
class _ParamsCell extends StatelessWidget {
  const _ParamsCell({required this.params, this.maxWidth});

  final Map<String, dynamic> params;
  final double? maxWidth;

  Iterable<String> get _entries => params.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}');

  @override
  Widget build(BuildContext context) {
    final entries = _entries.toList();
    if (entries.isEmpty) return const Text('—');
    final text = Text(
      entries.join(', '),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
    return Tooltip(
      message: entries.join('\n'),
      child: maxWidth != null ? SizedBox(width: maxWidth, child: text) : text,
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
