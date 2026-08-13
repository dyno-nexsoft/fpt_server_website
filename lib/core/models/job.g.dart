// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Job _$JobFromJson(Map<String, dynamic> json) => _Job(
  id: json['id'] as String,
  state: const JobStateConverter().fromJson(json['state'] as String),
  command: json['command'] as String,
  actionName: json['action_name'] as String?,
  actionParams:
      json['action_params'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  environments:
      json['environments'] as Map<String, dynamic>? ??
      const <String, dynamic>{},
  createdBy: json['created_by'] as String?,
  artifactKey: (json['artifact_key'] as num?)?.toInt(),
  promoted: json['promoted'] as bool? ?? false,
  announce: json['announce'] as bool? ?? false,
  createdAt: DateTime.parse(json['created_at'] as String),
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  finishedAt: json['finished_at'] == null
      ? null
      : DateTime.parse(json['finished_at'] as String),
  exitCode: (json['exit_code'] as num?)?.toInt(),
  lastLine: json['last_line'] as String?,
  lastSeq: (json['last_seq'] as num?)?.toInt() ?? 0,
  discordChannelId:
      _readDiscordChannelId(json, 'discord_channel_id') as String?,
  discordMessageId:
      _readDiscordMessageId(json, 'discord_message_id') as String?,
  logUrl: json['log_url'] as String?,
  warnings:
      (json['warnings'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  message: json['message'] as String?,
  resumedFrom: json['resumed_from'] as String?,
);

Map<String, dynamic> _$JobToJson(_Job instance) => <String, dynamic>{
  'id': instance.id,
  'state': const JobStateConverter().toJson(instance.state),
  'command': instance.command,
  'action_name': ?instance.actionName,
  'action_params': instance.actionParams,
  'environments': instance.environments,
  'created_by': ?instance.createdBy,
  'artifact_key': ?instance.artifactKey,
  'promoted': instance.promoted,
  'announce': instance.announce,
  'created_at': instance.createdAt.toIso8601String(),
  'started_at': ?instance.startedAt?.toIso8601String(),
  'finished_at': ?instance.finishedAt?.toIso8601String(),
  'exit_code': ?instance.exitCode,
  'last_line': ?instance.lastLine,
  'last_seq': instance.lastSeq,
  'discord_channel_id': ?instance.discordChannelId,
  'discord_message_id': ?instance.discordMessageId,
  'log_url': ?instance.logUrl,
  'warnings': instance.warnings,
  'message': ?instance.message,
  'resumed_from': ?instance.resumedFrom,
};
