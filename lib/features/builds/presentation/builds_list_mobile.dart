import 'package:flutter/material.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../../../shared/widgets/job_state_chip.dart';
import 'job_row_widgets.dart';

/// Mobile builds list: one card per job instead of [BuildsTableDesktop]'s
/// table — a table only reads well once a row can spread across real
/// width, and on a phone that meant two-axis scrolling just to see the
/// state or duration of the job you're already looking at.
class BuildsListMobile extends StatelessWidget {
  const BuildsListMobile({super.key, required this.jobs});

  final List<Job> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No builds match this filter'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _JobCard(job: jobs[index]),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final start = job.startedAt;
    final end = job.finishedAt;
    final duration = start != null
        ? formatDuration((end ?? DateTime.now()).difference(start))
        : null;
    final detailParts = [
      job.id,
      if (job.createdBy != null) 'by ${job.createdBy}',
    ];

    return Card(
      child: InkWell(
        onTap: () => JobDetailRoute(job.id).go(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                spacing: 8,
                children: [
                  JobStateIcon(state: job.state),
                  Expanded(
                    child: Text(
                      job.actionName ?? job.command,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (job.startedAt != null)
                    Text(formatRelativeTimestamp(job.startedAt!)),
                ],
              ),
              EllipsisText(detailParts.join(' • ')),
              JobParamsCell(params: job.actionParams),
              Row(
                children: [
                  if (duration != null) Text(duration),
                  const Spacer(),
                  JobRowActions(job: job),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
