import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/jobs_api.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/providers/status_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/action_template_store.dart';
import '../../../shared/auth_guard.dart';
import '../../../shared/toast/app_toast.dart';
import '../../../shared/widgets/name_template_dialog.dart';
import 'job_log_controller.dart';
import 'jobs_providers.dart';

/// The promote/cancel/retry/delete/save-as-template logic for one job —
/// previously duplicated almost byte-for-byte between [JobRowActions] and
/// [JobDetailPanel]. Both now only decide which buttons to show and forward
/// taps here; this owns the auth gate, the API call, the toast, and the
/// invalidate/refresh follow-up so the two surfaces can never drift.
class JobActionsController {
  JobActionsController(this._ref);

  final Ref _ref;

  Future<Job?> promote(BuildContext context, Job job) => _run(
    context,
    fallbackMessage: 'Promoted',
    action: () => promoteJob(_ref.read(apiClientProvider), job.id),
  );

  Future<Job?> retry(BuildContext context, Job job) => _run(
    context,
    fallbackMessage: 'Retried',
    action: () => retryJob(_ref.read(apiClientProvider), job.id),
  );

  Future<Job?> cancel(BuildContext context, Job job) => _run(
    context,
    fallbackMessage: null,
    action: () => cancelJob(_ref.read(apiClientProvider), job.id),
  );

  /// Not built on [runAuthedJobAction]: that helper inspects the returned
  /// [Job]'s own `warnings`/`message` fields, but `deleteJob` returns
  /// nothing — there's no delete-specific result to read, and reusing the
  /// deleted job's stale build warnings would show them as if they were
  /// about the deletion itself.
  Future<bool> delete(BuildContext context, Job job) async {
    if (!_ref.read(sessionProvider).hasKey) {
      if (context.mounted) const LoginRoute().go(context);
      return false;
    }
    try {
      await deleteJob(_ref.read(apiClientProvider), job.id);
      _ref.invalidate(jobsListProvider);
      _ref.read(statusControllerProvider.notifier).refreshNow();
      _ref.read(appToastProvider.notifier).show('Deleted');
      return true;
    } on ApiException catch (e) {
      _ref.read(appToastProvider.notifier).show(e.message, isError: true);
      return false;
    }
  }

  Future<Job?> _run(
    BuildContext context, {
    required String? fallbackMessage,
    required Future<Job> Function() action,
  }) async {
    final result = await runAuthedJobAction(
      context,
      _ref,
      fallbackMessage: fallbackMessage,
      action: action,
    );
    if (result != null) {
      _ref.invalidate(jobsListProvider);
      _ref.read(statusControllerProvider.notifier).refreshNow();
    }
    return result;
  }

  /// A retry either gets a genuinely new job id (see `JobRegistry.reopen`'s
  /// doc comment) or reuses this one's. New id: without this, the only trace
  /// of that new run is the warning toast [runAuthedJobAction] already
  /// showed, with no way to actually watch it happen from here. Same id: a
  /// job detail page already open for it is watching
  /// `jobLogControllerProvider`, whose SSE connection is still subscribed to
  /// the *old* [Job] instance's stream — `reopen` replaced it out from under
  /// that provider, and nothing else would ever tell it to reconnect. Calls
  /// [JobLogController.refresh] rather than `ref.invalidate`: invalidating
  /// tore down and rebuilt the whole provider, and left that page stuck on a
  /// permanent loading spinner instead of reconnecting.
  void handleRetryResult(BuildContext context, Job original, Job result) {
    if (result.id != original.id) {
      if (context.mounted) JobDetailRoute(result.id).go(context);
      return;
    }
    _ref.read(jobLogControllerProvider(original.id).notifier).refresh();
  }

  Future<void> saveAsTemplate(BuildContext context, Job job) async {
    final actionName = job.actionName;
    if (actionName == null) return;
    final store = _ref.read(actionTemplateStoreProvider);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => NameTemplateDialog(
        existingNames: store.list(actionName).map((t) => t.name).toSet(),
      ),
    );
    if (name == null || name.isEmpty) return;
    await store.save(
      actionName,
      ActionTemplate(name: name, params: job.actionParams),
    );
    _ref.read(appToastProvider.notifier).show('Saved as "$name"');
  }
}

final jobActionsControllerProvider = Provider<JobActionsController>(
  JobActionsController.new,
);
