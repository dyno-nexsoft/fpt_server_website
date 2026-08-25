import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/utils/responsive.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../../../shared/widgets/job_state_chip.dart';
import 'job_row_widgets.dart';

class BuildsTableDesktop extends ConsumerWidget {
  const BuildsTableDesktop({super.key, required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No builds match this filter'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: PaginatedDataTable2(
        minWidth: kTabletBreakpoint,
        columnSpacing: 16,
        horizontalMargin: 16,
        autoRowsToHeight: true,
        headingTextStyle: Theme.of(context).textTheme.titleMedium,
        columns: const [
          DataColumn2(label: Text('Job'), fixedWidth: 150),
          DataColumn2(label: Text('Action'), fixedWidth: 100),
          DataColumn2(label: Text('Author'), size: ColumnSize.S),
          DataColumn2(label: Text('Params'), size: ColumnSize.L),
          DataColumn2(label: Text('State'), fixedWidth: 150),
          DataColumn2(
            label: Text('Started'),
            fixedWidth: 120,
            headingRowAlignment: .center,
          ),
          DataColumn2(
            label: Text('Duration'),
            fixedWidth: 120,
            headingRowAlignment: .center,
          ),
          DataColumn2(label: Text('Actions'), fixedWidth: 120),
        ],
        source: _JobsDataSource(context: context, jobs: jobs),
      ),
    );
  }
}

class _JobsDataSource extends DataTableSource {
  _JobsDataSource({required this.context, required this.jobs});

  final BuildContext context;
  final List<Job> jobs;

  @override
  DataRow2 getRow(int index) {
    final job = jobs[index];
    final start = job.startedAt;
    var end = job.finishedAt;
    String? duration, startedAt;
    if (start != null) {
      end ??= DateTime.now();
      duration = formatDuration(end.difference(start));
      startedAt = formatRelativeTimestamp(start);
    }

    return DataRow2(
      key: ValueKey(job.id),
      onTap: () => JobDetailRoute(job.id).go(context),
      cells: [
        DataCell(Text(job.id)),
        DataCell(Text(job.actionName ?? job.command)),
        DataCell(EllipsisText(job.createdBy ?? '—')),
        DataCell(JobParamsCell(params: job.actionParams)),
        DataCell(JobStateChip(state: job.state)),
        DataCell(Center(child: Text(startedAt ?? '—'))),
        DataCell(Center(child: Text(duration ?? '—'))),
        DataCell(JobRowActions(job: job)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => jobs.length;

  @override
  int get selectedRowCount => 0;
}
