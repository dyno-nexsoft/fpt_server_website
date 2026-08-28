import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One decoded SSE frame: the `event:` name plus its JSON `data:` payload.
typedef SseFrame = ({String type, Map<String, dynamic> data});

/// Thin wrapper over the browser's native `EventSource` (via `package:web`).
///
/// Transport only — it knows event *names*, never what any of them mean, so
/// both the job log viewer and the action-progress stream reuse it instead
/// of each hand-rolling the same `addEventListener` + JSON-decode +
/// readyState dance. The browser handles reconnect and `Last-Event-ID` on
/// its own; callers only need [frames] and [connectionErrors].
class SseClient {
  SseClient({required this.eventTypes});

  /// The `event:` names to subscribe to. `EventSource` delivers a named
  /// event only to a listener registered for that exact name — there is no
  /// wildcard — so this list is what decides which frames arrive at all.
  final List<String> eventTypes;

  web.EventSource? _source;
  final _frames = StreamController<SseFrame>.broadcast();
  final _connectionErrors = StreamController<void>.broadcast();

  Stream<SseFrame> get frames => _frames.stream;

  /// Fires only once the browser has actually given up (`readyState ==
  /// CLOSED`) — not on the transient drops it retries by itself.
  Stream<void> get connectionErrors => _connectionErrors.stream;

  void connect(String url) {
    final source = web.EventSource(url);
    for (final type in eventTypes) {
      source.addEventListener(
        type,
        ((web.Event event) => _handle(type, event)).toJS,
      );
    }
    source.onerror = ((web.Event event) {
      // The browser's EventSource retries transient drops on its own
      // (`readyState` goes back to CONNECTING); `onerror` fires on every one
      // of those too, not just fatal ones. Only a `CLOSED` state means the
      // browser has given up — e.g. the response wasn't `text/event-stream`
      // — and it's actually time for the caller to fall back.
      if (source.readyState != web.EventSource.CLOSED) return;
      if (!_connectionErrors.isClosed) _connectionErrors.add(null);
    }).toJS;
    _source = source;
  }

  void _handle(String type, web.Event event) {
    if (!event.isA<web.MessageEvent>()) return;
    final rawData = (event as web.MessageEvent).data;
    if (rawData.isUndefinedOrNull) return;
    final text = (rawData as JSString).toDart;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (!_frames.isClosed) _frames.add((type: type, data: json));
    } catch (_) {
      // Malformed frame — ignore rather than crash whatever is rendering it.
    }
  }

  void close() {
    _source?.close();
    _source = null;
    unawaited(_frames.close());
    unawaited(_connectionErrors.close());
  }
}
