import 'package:freezed_annotation/freezed_annotation.dart';

import 'job.dart';

part 'system_status.freezed.dart';
part 'system_status.g.dart';

/// `GET /status` — powers the queue sidebar. Field names on this endpoint
/// are camelCase on the wire, unlike every other action in the API.
@freezed
abstract class SystemStatus with _$SystemStatus {
  const SystemStatus._();

  const factory SystemStatus({
    required String dartVersion,
    required String hostname,
    required int uptimeSeconds,
    required String uptime,
    required String workingDirectory,
    @Default(<Job>[]) List<Job> running,
    @Default(<Job>[]) List<Job> queued,
  }) = _SystemStatus;

  factory SystemStatus.fromJson(Map<String, dynamic> json) =>
      _$SystemStatusFromJson(json);

  bool get hasActiveJobs => running.isNotEmpty || queued.isNotEmpty;
}
