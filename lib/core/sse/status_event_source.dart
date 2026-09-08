import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Thin wrapper over the browser's native `EventSource` for `GET
/// /status/events` — the browser handles reconnect on its own; callers only
/// need [statuses] and [connectionErrors]. Mirrors [JobEventSource] but for a
/// single `status` event carrying a full status JSON payload rather than a
/// typed job lifecycle event.
class StatusEventSource {
  web.EventSource? _source;
  final _statuses = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionErrors = StreamController<void>.broadcast();

  Stream<Map<String, dynamic>> get statuses => _statuses.stream;
  Stream<void> get connectionErrors => _connectionErrors.stream;

  void connect(String url) {
    final source = web.EventSource(url);
    source.addEventListener(
      'status',
      ((web.Event event) => _handle(event)).toJS,
    );
    source.onerror = ((web.Event event) {
      // The browser's EventSource retries transient drops on its own
      // (`readyState` goes back to CONNECTING); `onerror` fires on every one
      // of those too, not just fatal ones. Only a `CLOSED` state means the
      // browser has given up — e.g. the response wasn't `text/event-stream`
      // — and it's actually time to fall back to polling.
      if (source.readyState != web.EventSource.CLOSED) return;
      if (!_connectionErrors.isClosed) _connectionErrors.add(null);
    }).toJS;
    _source = source;
  }

  void _handle(web.Event event) {
    if (!event.isA<web.MessageEvent>()) return;
    final rawData = (event as web.MessageEvent).data;
    if (rawData.isUndefinedOrNull) return;
    final text = (rawData as JSString).toDart;
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (!_statuses.isClosed) _statuses.add(json);
    } catch (_) {
      // Malformed frame — ignore rather than crash the sidebar.
    }
  }

  void close() {
    _source?.close();
    _source = null;
    unawaited(_statuses.close());
    unawaited(_connectionErrors.close());
  }
}
