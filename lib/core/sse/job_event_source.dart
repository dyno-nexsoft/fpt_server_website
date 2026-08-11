import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// One parsed SSE frame from `/jobs/{id}/events?raw=1`. Every frame — raw
/// build output included — arrives as a JSON `data:` payload; `type` is
/// both the SSE `event:` name and the `type` field inside the JSON.
class JobStreamEvent {
  const JobStreamEvent({required this.type, this.seq, this.at, this.raw});

  factory JobStreamEvent.fromJson(String type, Map<String, dynamic> json) =>
      JobStreamEvent(
        type: type,
        seq: json['seq'] as int?,
        at: (json['at'] as String?) != null
            ? DateTime.tryParse(json['at'] as String)
            : null,
        raw: json,
      );

  final String type;
  final int? seq;
  final DateTime? at;
  final Map<String, dynamic>? raw;

  String? get chunk => raw?['chunk'] as String?;
  String? get line => raw?['line'] as String?;
  String? get message => raw?['message'] as String?;
  String? get state => raw?['state'] as String?;
  int? get exitCode => raw?['exit_code'] as int?;
}

const jobStreamEventTypes = [
  'queued',
  'started',
  'promoted',
  'status',
  'log',
  'error',
  'finished',
];

/// Thin wrapper over the browser's native `EventSource` (via `package:web`)
/// for the job log viewer. The browser handles reconnect + `Last-Event-ID`
/// on its own; callers only need [events] and [connectionErrors].
class JobEventSource {
  web.EventSource? _source;
  final _events = StreamController<JobStreamEvent>.broadcast();
  final _connectionErrors = StreamController<void>.broadcast();

  Stream<JobStreamEvent> get events => _events.stream;
  Stream<void> get connectionErrors => _connectionErrors.stream;

  void connect(String url) {
    final source = web.EventSource(url);
    for (final type in jobStreamEventTypes) {
      source.addEventListener(
        type,
        ((web.Event event) => _handle(type, event)).toJS,
      );
    }
    source.onerror = ((web.Event event) {
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
      if (!_events.isClosed) {
        _events.add(JobStreamEvent.fromJson(type, json));
      }
    } catch (_) {
      // Malformed frame — ignore rather than crash the viewer.
    }
  }

  void close() {
    _source?.close();
    _source = null;
    unawaited(_events.close());
    unawaited(_connectionErrors.close());
  }
}
