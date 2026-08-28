import 'dart:async';
import 'dart:math';

import '../../../core/sse/sse_client.dart';

/// Live progress for one in-flight `mutation` call, over
/// `GET /invocations/{id}/events`.
///
/// The id is generated here, client-side, and opened *before* the action is
/// submitted — the invocation does not exist yet, so there is nothing the
/// server could have handed out to address it by. The same id then travels
/// with the request as `X-Invocation-Id`.
///
/// Subscribes to `status` and `error`, the two kinds a `mutation` reports:
/// a named SSE event reaches only a listener registered for that exact name,
/// so a kind missing here is silently dropped. `log` is deliberately left
/// out — that is raw process output, which belongs in the job log viewer,
/// and `queued`/`started`/`finished` are job lifecycle a mutation never
/// emits (its completion is the POST response itself).
class ActionProgressSource {
  ActionProgressSource()
    : _client = SseClient(eventTypes: const ['status', 'error']);

  /// `Random.secure()`, not `Random()`: this id is the only thing guarding
  /// the (unauthenticated, header-less) `EventSource` route, and the server
  /// opens a feed for whatever id it is handed. A seeded PRNG plus a
  /// timestamp is guessable within a narrow window — enough to read another
  /// user's review status lines, and enough that a hundred guesses exhaust
  /// `ProgressFeedRegistry`'s open-feed cap and block everyone's progress
  /// for two minutes. See `ApiRouter._streamPath`'s comment.
  static final _random = Random.secure();

  static String generateId() {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    // 60 bits of secure entropy, in two draws because `nextInt`'s own
    // argument caps at 2^32.
    final salt = List.generate(
      2,
      (_) => _random.nextInt(1 << 30).toRadixString(36).padLeft(6, '0'),
    ).join();
    return 'i-$micros$salt';
  }

  final SseClient _client;

  /// The latest status line, as the server reports it.
  Stream<String> get status => _client.frames
      .map((frame) => frame.data['text'] as String?)
      .where((text) => text != null && text.isNotEmpty)
      .cast<String>();

  void connect({required String baseUrl, required String invocationId}) {
    final origin = Uri.parse(baseUrl).origin;
    _client.connect('$origin/api/v1/invocations/$invocationId/events');
  }

  void close() => _client.close();
}
