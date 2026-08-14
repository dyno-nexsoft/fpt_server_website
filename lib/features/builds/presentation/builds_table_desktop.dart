import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../../../shared/widgets/job_state_chip.dart';
import 'job_row_widgets.dart';

const _columnLabels = [
  'Job',
  'Action',
  'Author',
  'Params',
  'State',
  'Started',
  'Duration',
  '',
];

/// Desktop builds list: a flexible `Table` whose Params column claims
/// leftover width instead of the fixed-width, horizontally-scrolling
/// `DataTable` a narrow screen needs — see [BuildsListMobile]'s doc comment
/// for why the two can't share one implementation.
class BuildsTableDesktop extends ConsumerWidget {
  const BuildsTableDesktop({super.key, required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No builds match this filter'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(160),
          1: FixedColumnWidth(110),
          2: FixedColumnWidth(120),
          3: FlexColumnWidth(),
          4: FixedColumnWidth(150),
          5: FixedColumnWidth(90),
          6: FixedColumnWidth(90),
          7: FixedColumnWidth(140),
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
          for (final job in jobs) _buildRow(context, job),
        ],
      ),
    );
  }

  TableRow _buildRow(BuildContext context, Job job) {
    final start = job.startedAt;
    final end = job.finishedAt;
    final duration = start != null
        ? formatDuration((end ?? DateTime.now()).difference(start))
        : null;

    Widget cell(Widget child) => TableRowInkWell(
      onTap: () => JobDetailRoute(job.id).go(context),
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
        cell(EllipsisText(job.actionName ?? job.command)),
        cell(Text(job.createdBy ?? '—')),
        cell(JobParamsCell(params: job.actionParams)),
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
          child: JobRowActions(job: job),
        ),
      ],
    );
  }
}
