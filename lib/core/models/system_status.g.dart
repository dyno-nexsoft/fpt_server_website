// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SystemStatus _$SystemStatusFromJson(Map<String, dynamic> json) =>
    _SystemStatus(
      dartVersion: json['dart_version'] as String,
      hostname: json['hostname'] as String,
      uptimeSeconds: (json['uptime_seconds'] as num).toInt(),
      uptime: json['uptime'] as String,
      workingDirectory: json['working_directory'] as String,
      running:
          (json['running'] as List<dynamic>?)
              ?.map((e) => Job.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Job>[],
      queued:
          (json['queued'] as List<dynamic>?)
              ?.map((e) => Job.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Job>[],
    );

Map<String, dynamic> _$SystemStatusToJson(_SystemStatus instance) =>
    <String, dynamic>{
      'dart_version': instance.dartVersion,
      'hostname': instance.hostname,
      'uptime_seconds': instance.uptimeSeconds,
      'uptime': instance.uptime,
      'working_directory': instance.workingDirectory,
      'running': instance.running.map((e) => e.toJson()).toList(),
      'queued': instance.queued.map((e) => e.toJson()).toList(),
    };
