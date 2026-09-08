import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/action_invoker.dart';
import '../../../shared/toast/app_toast.dart';
import 'zentao_providers.dart';

/// Every Zentao mutation the dashboard offers: account linking, the
/// server-wide config, and the daily report lifecycle.
///
/// One controller rather than three because they all reduce to the same
/// three steps — invoke by name, refetch [zentaoStatusProvider], toast the
/// server's own message — and splitting them would triplicate that without
/// separating anything a caller cares about.
class ZentaoController {
  ZentaoController(this._ref);

  final Ref _ref;

  Future<void> link({required String account, required String password}) =>
      _run('zentao.link', {'account': account, 'password': password});

  Future<void> unlink() => _run('zentao.unlink', const {});

  Future<void> setProject(int id) =>
      _run('zentao.config.setProject', {'project_id': id});

  Future<void> setExecution(int id) =>
      _run('zentao.config.setExecution', {'execution_id': id});

  Future<void> startReport(String description) =>
      _run('zentao.report.start', {'description': description});

  Future<void> finishReport(int taskId) =>
      _run('zentao.report.finish', {'task_id': taskId}, taskId: taskId);

  Future<void> closeReport(int taskId) =>
      _run('zentao.report.close', {'task_id': taskId}, taskId: taskId);

  Future<void> editReport(int taskId, String description) => _run(
    'zentao.report.edit',
    {'task_id': taskId, 'description': description},
    taskId: taskId,
  );

  /// Invokes [actionName], then refetches whatever it could have changed.
  ///
  /// [taskId] is passed only by the actions that act on an existing task, so
  /// that task's own detail is refetched too — the status call alone would
  /// still report the same id and leave a finished task rendering as
  /// unfinished.
  Future<void> _run(
    String actionName,
    Map<String, dynamic> params, {
    int? taskId,
  }) async {
    final body = await _ref.read(actionInvokerProvider).run(actionName, params);
    if (body == null) return;
    _ref.invalidate(zentaoStatusProvider);
    if (taskId != null) _ref.invalidate(zentaoTaskProvider(taskId));
    _ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
  }
}

final zentaoControllerProvider = Provider<ZentaoController>(
  ZentaoController.new,
);
