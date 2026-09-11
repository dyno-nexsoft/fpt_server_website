import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/catalogue_providers.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/session_provider.dart';

/// The tail of one of the server's logs, keyed by `admin.logs.tail`'s own
/// `source` value — `server` for the bot, `novnc` for the remote desktop.
///
/// A family rather than a provider per log: the request, the key gate and the
/// decoding are identical, and the action already distinguishes them.
final logsTailProvider = FutureProvider.autoDispose
    .family<List<String>?, String>((ref, source) async {
      if (!ref.watch(sessionProvider).hasKey) return null;
      final actions = await ref.watch(actionsProvider.future);
      if (findAction(actions, 'admin.logs.tail') == null) return null;
      final api = ref.watch(apiClientProvider);
      final body = await api.decodeMap(
        api.endpoints.invokeAction(
          'admin.logs.tail',
          api.encodeBody({'lines': 200, 'source': source}),
        ),
      );
      return (body['lines'] as List<dynamic>? ?? []).cast<String>();
    });
