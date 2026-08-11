import 'job.dart';

/// `GET /status` — powers the queue sidebar. Field names on this endpoint
/// are camelCase on the wire, unlike every other action in the API.
class SystemStatus {
  const SystemStatus({
    required this.dartVersion,
    required this.hostname,
    required this.uptimeSeconds,
    required this.uptime,
    required this.workingDirectory,
    required this.running,
    required this.queued,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) => SystemStatus(
    dartVersion: json['dartVersion'] as String,
    hostname: json['hostname'] as String,
    uptimeSeconds: json['uptimeSeconds'] as int,
    uptime: json['uptime'] as String,
    workingDirectory: json['workingDirectory'] as String,
    running: (json['running'] as List<dynamic>? ?? [])
        .map((j) => Job.fromJson(j as Map<String, dynamic>))
        .toList(),
    queued: (json['queued'] as List<dynamic>? ?? [])
        .map((j) => Job.fromJson(j as Map<String, dynamic>))
        .toList(),
  );

  final String dartVersion;
  final String hostname;
  final int uptimeSeconds;
  final String uptime;
  final String workingDirectory;
  final List<Job> running;
  final List<Job> queued;

  bool get hasActiveJobs => running.isNotEmpty || queued.isNotEmpty;
}
