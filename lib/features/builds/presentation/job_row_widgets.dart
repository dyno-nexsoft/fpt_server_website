import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/jobs_api.dart';
import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/auth_guard.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/ellipsis_text.dart';
import '../application/job_log_controller.dart';
import '../application/jobs_providers.dart';

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
            onPressed: () => _act(
              context,
              ref,
              'Promoted',
              () => promoteJob(ref.read(apiClientProvider), job.id),
            ),
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
            onPressed: () => _act(
              context,
              ref,
              'Retried',
              () => retryJob(ref.read(apiClientProvider), job.id),
              onSuccess: (result) => _openIfNewJob(context, ref, result),
            ),
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
    if (!confirmed) return;
    if (!ref.read(sessionProvider).hasKey) {
      if (context.mounted) const LoginRoute().go(context);
      return;
    }
    try {
      await deleteJob(ref.read(apiClientProvider), job.id);
      ref.invalidate(jobsListProvider);
      ref.read(statusControllerProvider.notifier).refreshNow();
      ref.read(appToastProvider.notifier).show('Deleted');
    } on ApiException catch (e) {
      ref.read(appToastProvider.notifier).show(e.message, isError: true);
    }
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Cancel this build?',
      body: 'This deletes artifacts on the build server and cannot be undone.',
      confirmLabel: 'Cancel build',
      isDangerous: true,
    );
    if (!confirmed) return;
    await _act(
      context,
      ref,
      null,
      () => cancelJob(ref.read(apiClientProvider), job.id),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    String? fallbackMessage,
    Future<Job> Function() action, {
    void Function(Job result)? onSuccess,
  }) async {
    final result = await runAuthedJobAction(
      context,
      ref,
      fallbackMessage: fallbackMessage,
      action: action,
    );
    if (result != null) {
      ref.invalidate(jobsListProvider);
      ref.read(statusControllerProvider.notifier).refreshNow();
      onSuccess?.call(result);
    }
  }

  /// A retry either gets a genuinely new job id (see `JobRegistry.reopen`'s
  /// doc comment) or reuses this one's. New id: without this, the only trace
  /// of that new run is the warning toast `runAuthedJobAction` already
  /// showed, with no way to actually watch it happen from here. Same id: a
  /// job detail page already open for it is watching
  /// `jobLogControllerProvider`, whose SSE connection is still subscribed to
  /// the *old* `Job` instance's stream — `reopen` replaced it out from under
  /// that provider, and nothing else would ever tell it to reconnect.
  ///
  /// Calls the controller's own [JobLogController.refresh] rather than
  /// `ref.invalidate` — see `JobDetailPanel._openIfNewJob`'s doc comment:
  /// invalidating tore down and rebuilt the whole provider, and left that
  /// page stuck on a permanent loading spinner instead of reconnecting.
  void _openIfNewJob(BuildContext context, WidgetRef ref, Job result) {
    if (result.id != job.id) {
      if (context.mounted) JobDetailRoute(result.id).go(context);
      return;
    }
    ref.read(jobLogControllerProvider(job.id).notifier).refresh();
  }
}
