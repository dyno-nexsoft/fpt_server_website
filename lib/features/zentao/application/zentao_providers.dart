import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/action_invoker.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/toast/app_toast.dart';

/// `zentao.status`, merged with the mutations that change it (account
/// link/unlink, the server-wide project/execution) into one `AsyncNotifier`
/// — a separate read provider plus a plain controller class invalidating it
/// has no way to edit `state` directly the way `_run` below does:
/// optimistic (the change appears immediately, not after a round trip) and
/// rolled back to whatever `state` held before if the call fails.
///
/// `null` means there is nothing to ask about: no stored key, or a server
/// whose catalogue has no such action. A key that exists but is not bound to
/// a Discord account is a different case entirely — the action answers with
/// `zentao.no_identity`, which surfaces as an error here rather than as a
/// silently empty screen, because the fix (bind the key) is something the
/// reader can act on.
class ZentaoStatusController extends AsyncNotifier<ZentaoStatus?> {
  @override
  Future<ZentaoStatus?> build() async {
    if (!ref.watch(sessionProvider).hasKey) return null;
    final actions = await ref.watch(actionsProvider.future);
    if (findAction(actions, 'zentao.status') == null) return null;
    final api = ref.watch(apiClientProvider);
    final body = await api.decodeMap(
      api.endpoints.invokeAction('zentao.status', api.encodeBody(const {})),
    );
    return ZentaoStatus.fromJson(body);
  }

  Future<void> link({required String account, required String password}) =>
      _run(
        'zentao.link',
        {'account': account, 'password': password},
        apply: (s) => s.copyWith(linked: true, account: account),
      );

  Future<void> unlink() => _run(
    'zentao.unlink',
    const {},
    apply: (s) =>
        s.copyWith(linked: false, account: null, todayTaskId: null),
  );

  Future<void> setProject(int id) => _run(
    'zentao.config.setProject',
    {'project_id': id},
    apply: (s) => s.copyWith(projectId: id),
  );

  Future<void> setExecution(int id) => _run(
    'zentao.config.setExecution',
    {'execution_id': id},
    apply: (s) => s.copyWith(executionId: id),
  );

  /// Not optimistic like the mutations above — the new task's id is
  /// generated server-side, so there is nothing to apply before the
  /// response arrives. Still saves a second round trip once it does:
  /// patching `todayTaskId` directly rather than waiting on a full
  /// `zentao.status` refetch to notice it changed.
  Future<void> startReport(String description) async {
    final body = await ref.read(actionInvokerProvider).run(
      'zentao.report.start',
      {'description': description},
    );
    if (body == null) return;
    final taskId = body['task_id'] as int?;
    if (taskId != null) {
      if (state.value case final current?) {
        state = AsyncData(current.copyWith(todayTaskId: taskId));
      }
    }
    ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
  }

  Future<void> _run(
    String actionName,
    Map<String, dynamic> params, {
    required ZentaoStatus Function(ZentaoStatus current) apply,
  }) async {
    final previous = state;
    if (previous.value case final current?) {
      state = AsyncData(apply(current));
    }

    final body = await ref.read(actionInvokerProvider).run(actionName, params);
    if (body == null) {
      state = previous;
      return;
    }
    ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
  }
}

final zentaoStatusProvider =
    AsyncNotifierProvider.autoDispose<ZentaoStatusController, ZentaoStatus?>(
      ZentaoStatusController.new,
    );

/// `zentao.report.get`/`.edit`/`.finish`/`.close` for one task id, merged
/// into one `AsyncNotifier` per task per the same optimistic/rollback
/// reasoning as [ZentaoStatusController].
///
/// A family keyed by task id rather than a provider for "today": the detail
/// request is the same whichever task is being looked at, and today's id
/// comes from [zentaoStatusProvider] anyway.
///
/// `finish`/`close` only ever flip [DailyTask.status] between the exact
/// values [DailyTask.availableActions] already derives client-side from that
/// same field (`doing` -> `done` -> `closed`) — that getter is not a second
/// copy of server logic to keep in step, so optimistically setting `status`
/// here cannot drift from what the buttons that appear next actually allow.
class ZentaoTaskController extends AsyncNotifier<DailyTask> {
  ZentaoTaskController(this.taskId);

  final int taskId;

  @override
  Future<DailyTask> build() async {
    final api = ref.watch(apiClientProvider);
    final body = await api.decodeMap(
      api.endpoints.invokeAction(
        'zentao.report.get',
        api.encodeBody({'task_id': taskId}),
      ),
    );
    return DailyTask.parseJson(body);
  }

  Future<void> edit(String description) => _run(
    'zentao.report.edit',
    {'task_id': taskId, 'description': description},
    apply: (task) => task.copyWith(description: description),
  );

  Future<void> finish() => _run(
    'zentao.report.finish',
    {'task_id': taskId},
    apply: (task) => task.copyWith(status: 'done'),
  );

  Future<void> close() => _run(
    'zentao.report.close',
    {'task_id': taskId},
    apply: (task) => task.copyWith(status: 'closed'),
  );

  Future<void> _run(
    String actionName,
    Map<String, dynamic> params, {
    required DailyTask Function(DailyTask current) apply,
  }) async {
    final previous = state;
    if (previous.value case final current?) {
      state = AsyncData(apply(current));
    }

    final body = await ref.read(actionInvokerProvider).run(actionName, params);
    if (body == null) {
      state = previous;
      return;
    }
    ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
  }
}

final zentaoTaskProvider = AsyncNotifierProvider.autoDispose
    .family<ZentaoTaskController, DailyTask, int>(ZentaoTaskController.new);
