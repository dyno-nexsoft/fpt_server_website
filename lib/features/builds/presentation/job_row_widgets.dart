import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../application/job_actions_controller.dart';

/// A single truncated `key=value, ...` line instead of the raw dump wrapping
/// across the row — the tooltip breaks the same entries one per line instead
/// of repeating that comma-joined line, since a hover has room a table cell
/// doesn't. Takes the raw [params] map rather than a pre-joined string, so
/// each representation is free to format the entries differently instead of
/// being stuck sharing one.
/// [maxWidth] caps it inside DataTable, which otherwise sizes the column to
/// the full line's length; the flexible desktop Table already bounds the
/// cell itself, so it's left unset there.
class JobParamsCell extends StatelessWidget {
  const JobParamsCell({super.key, required this.params, this.maxWidth});

  final Map<String, dynamic> params;
  final double? maxWidth;

  Iterable<String> get _entries => params.entries
      .where((entry) => entry.value != null)
      .map((entry) => '${entry.key}=${entry.value}');

  @override
  Widget build(BuildContext context) {
    final entries = _entries.toList();
    if (entries.isEmpty) return const Text('—');
    return EllipsisText(
      entries.join(', '),
      tooltip: entries.join('\n'),
      maxWidth: maxWidth,
    );
  }
}

/// Promote / Cancel / Retry for one job — shared by the desktop table row,
/// the mobile card, and the job detail panel, so the 409-driven
/// availability rules (`canCancel`/`canPromote`/`canRetry`) and the confirm
/// dialog never drift between surfaces.
class JobRowActions extends ConsumerWidget {
  const JobRowActions({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel =
        job.state == JobState.queued || job.state == JobState.running;
    final canPromote = job.state == JobState.queued && !job.promoted;
    final canRetry = job.isTerminal;
    // Deleting erases history everyone with read access can see, including
    // builds triggered by someone else — scoped to admin, same as the
    // server enforces (see ApiRouter._deleteJob's doc comment).
    final canDelete =
        job.isTerminal &&
        (ref.watch(myKeyInfoProvider).value?.isAdmin ?? false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canPromote)
          IconButton(
            tooltip: 'Promote',
            icon: const Icon(Icons.upgrade),
            onPressed: () =>
                ref.read(jobActionsControllerProvider).promote(context, job),
          ),
        if (canCancel)
          IconButton(
            style: AppTheme.destructiveIconButtonStyle(
              Theme.of(context).colorScheme,
            ),
            tooltip: 'Cancel — deletes artifacts on the build server',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () => _confirmCancel(context, ref),
          ),
        if (canRetry)
          IconButton(
            tooltip: 'Retry',
            icon: const Icon(Icons.replay),
            onPressed: () => _retry(context, ref),
          ),
        if (canDelete)
          IconButton(
            style: AppTheme.destructiveIconButtonStyle(
              Theme.of(context).colorScheme,
            ),
            tooltip: 'Delete — permanently removes this build from history',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete this build?',
      body: 'This permanently removes it from history and cannot be undone.',
      confirmLabel: 'Delete',
      isDangerous: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(jobActionsControllerProvider).delete(context, job);
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel this build?',
      body: 'This deletes artifacts on the build server and cannot be undone.',
      confirmLabel: 'Cancel build',
      isDangerous: true,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(jobActionsControllerProvider).cancel(context, job);
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(jobActionsControllerProvider);
    final result = await controller.retry(context, job);
    if (result != null && context.mounted) {
      controller.handleRetryResult(context, job, result);
    }
  }
}
