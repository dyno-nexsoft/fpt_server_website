import 'dart:async';

import 'sse_client.dart';

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

/// The job log viewer's typed view of [SseClient] — decodes each frame into
/// a [JobStreamEvent]. The transport (reconnect, `Last-Event-ID`, JSON
/// decoding, giving-up detection) lives in [SseClient], shared with the
/// action-progress stream.
class JobEventSource {
  JobEventSource() : _client = SseClient(eventTypes: jobStreamEventTypes);

  final SseClient _client;

  Stream<JobStreamEvent> get events => _client.frames.map(
    (frame) => JobStreamEvent.fromJson(frame.type, frame.data),
  );

  Stream<void> get connectionErrors => _client.connectionErrors;

  void connect(String url) => _client.connect(url);

  void close() => _client.close();
}
