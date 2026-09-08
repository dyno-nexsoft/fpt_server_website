import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/browser/browser_utils.dart';
import '../../../shared/utils/format.dart';
import '../application/zentao_controller.dart';
import '../application/zentao_providers.dart';
import 'report_description_dialog.dart';

/// Today's daily report: `zentao.report.start` when there isn't one yet,
/// then `get`/`edit`/`finish`/`close` on the task once there is.
///
/// Which of those are offered comes from [DailyTask.availableActions] — a
/// server-side domain rule, so this cannot drift from what the Discord
/// buttons allow.
class ZentaoReportTile extends ConsumerWidget {
  const ZentaoReportTile({super.key, required this.status});

  final ZentaoStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskId = status.todayTaskId;
    if (taskId == null) return const _StartReportTile();

    final task = ref.watch(zentaoTaskProvider(taskId));
    return task.when(
      data: (data) => _TaskDetail(task: data),
      loading: () => const ListTile(
        leading: Icon(Icons.assignment_outlined),
        title: Text('Loading task…'),
        trailing: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text('Task #$taskId could not be loaded'),
        subtitle: Text('$error'),
        trailing: IconButton(
          tooltip: 'Retry',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(zentaoTaskProvider(taskId)),
        ),
      ),
    );
  }
}

class _StartReportTile extends ConsumerWidget {
  const _StartReportTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.assignment_outlined),
      title: const Text('No report started today'),
      subtitle: const Text('Creates today\'s task in Zentao and starts it'),
      trailing: FilledButton.icon(
        onPressed: () => _start(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final description = await ReportDescriptionDialog.show(
      context,
      title: 'Start today\'s report',
      confirmLabel: 'Start',
    );
    if (description == null) return;
    await ref.read(zentaoControllerProvider).startReport(description);
  }
}

class _TaskDetail extends ConsumerWidget {
  const _TaskDetail({required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = task.availableActions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.assignment_turned_in_outlined),
          title: Text(task.name),
          subtitle: Text(
            '#${task.id} · ${task.status} · ${task.assignee} · edited '
            '${formatRelativeTimestamp(task.lastEdited)}',
          ),
          trailing: IconButton(
            tooltip: 'Open in Zentao',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => openInNewTab(task.url),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              // Markdown, rendered as plain text on purpose: the description
              // is round-tripped through this screen's own edit dialog, and
              // showing it as anything other than the exact text that will be
              // sent back would make an edit look like it changed something
              // it did not.
              SelectionArea(
                child: Text(
                  task.description.isEmpty
                      ? 'No content yet.'
                      : task.description,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (actions.contains(DailyTaskAction.edit))
                    FilledButton.tonalIcon(
                      onPressed: () => _edit(context, ref),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  if (actions.contains(DailyTaskAction.finish))
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(zentaoControllerProvider)
                          .finishReport(task.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Finish'),
                    ),
                  if (actions.contains(DailyTaskAction.close))
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(zentaoControllerProvider)
                          .closeReport(task.id),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Close'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final description = await ReportDescriptionDialog.show(
      context,
      title: 'Edit report #${task.id}',
      confirmLabel: 'Save',
      initialValue: task.description,
    );
    if (description == null) return;
    await ref.read(zentaoControllerProvider).editReport(task.id, description);
  }
}
