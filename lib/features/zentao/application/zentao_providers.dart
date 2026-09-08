import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpt_server_shared/fpt_server_shared.dart';
import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';

/// `zentao.status` — link state, the server-wide project/execution, and
/// today's report task id in one call.
///
/// `null` means there is nothing to ask about: no stored key, or a server
/// whose catalogue has no such action. A key that exists but is not bound to
/// a Discord account is a different case entirely — the action answers with
/// `zentao.no_identity`, which surfaces as an error here rather than as a
/// silently empty screen, because the fix (bind the key) is something the
/// reader can act on.
final zentaoStatusProvider = FutureProvider.autoDispose<ZentaoStatus?>((
  ref,
) async {
  if (!ref.watch(sessionProvider).hasKey) return null;
  final actions = await ref.watch(actionsProvider.future);
  if (findAction(actions, 'zentao.status') == null) return null;
  final api = ref.watch(apiClientProvider);
  final body = await api.decodeMap(
    api.endpoints.invokeAction('zentao.status', api.encodeBody(const {})),
  );
  return ZentaoStatus.fromJson(body);
});

/// `zentao.report.get` for one task id.
///
/// A family keyed by task id rather than a provider for "today": the detail
/// request is the same whichever task is being looked at, and today's id
/// comes from [zentaoStatusProvider] anyway.
final zentaoTaskProvider = FutureProvider.autoDispose.family<DailyTask, int>((
  ref,
  taskId,
) async {
  final api = ref.watch(apiClientProvider);
  final body = await api.decodeMap(
    api.endpoints.invokeAction(
      'zentao.report.get',
      api.encodeBody({'task_id': taskId}),
    ),
  );
  return DailyTask.parseJson(body);
});
