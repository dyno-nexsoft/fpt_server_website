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
/// Only [ProgressKind.status] frames are subscribed to: a `log` frame would
/// be raw process output, which no mutation produces today and which the
/// job log viewer already renders properly when one does.
class ActionProgressSource {
  ActionProgressSource() : _client = SseClient(eventTypes: const ['status']);

  static final _random = Random();

  /// Random rather than sequential: this id is the only thing guarding the
  /// (unauthenticated, header-less) `EventSource` route, so it must not be
  /// guessable from another one. See `ApiRouter._streamPath`'s comment.
  static String generateId() {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1679616).toRadixString(36).padLeft(4, '0');
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
