import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

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

  /// How long a status line is guaranteed to stay on screen before another
  /// can replace it.
  ///
  /// Matched to [SubmittingIndicator]'s own 300ms cross-fade with room to
  /// spare: a line replaced mid-fade is one the reader never sees resolve,
  /// which reads as flickering rather than as progress.
  static const _minDisplayTime = Duration(milliseconds: 900);

  /// The latest status line, as the server reports it.
  ///
  /// Throttled with `trailing: true`, not debounced. Debouncing holds every
  /// line until the stream goes quiet, which for steady progress means
  /// showing nothing for the whole run — the exact impression the status line
  /// exists to dispel. This emits the first line at once, then at most one
  /// per window, and the window's last line is the one that gets shown.
  ///
  /// Smoothing is done here rather than server-side on purpose: the feed is
  /// a shared wire contract, and dropping frames there would take the choice
  /// away from every other client. The server paces only what it has an
  /// actual rate limit on (Discord edits).
  Stream<String> get status => _client.frames
      .map((frame) => frame.data['text'] as String?)
      .where((text) => text != null && text.isNotEmpty)
      .cast<String>()
      .throttleTime(_minDisplayTime, trailing: true);

  void connect({required String baseUrl, required String invocationId}) {
    final origin = Uri.parse(baseUrl).origin;
    _client.connect('$origin/api/v1/invocations/$invocationId/events');
  }

  void close() => _client.close();
}
