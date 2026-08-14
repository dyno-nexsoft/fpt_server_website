// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Health _$HealthFromJson(Map<String, dynamic> json) => _Health(
  ok: json['ok'] as bool,
  version: json['version'] as String,
  appVersion: json['app_version'] as String,
  uptimeSeconds: (json['uptime_seconds'] as num).toInt(),
  hostname: json['hostname'] as String,
);

Map<String, dynamic> _$HealthToJson(_Health instance) => <String, dynamic>{
  'ok': instance.ok,
  'version': instance.version,
  'app_version': instance.appVersion,
  'uptime_seconds': instance.uptimeSeconds,
  'hostname': instance.hostname,
};
