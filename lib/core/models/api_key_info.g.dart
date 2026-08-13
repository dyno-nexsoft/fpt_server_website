// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiKeyInfo _$ApiKeyInfoFromJson(Map<String, dynamic> json) => _ApiKeyInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  keyHash: json['key_hash'] as String,
  scopes: (json['scopes'] as List<dynamic>).map((e) => e as String).toList(),
  discordUserId: _discordUserIdFromJson(json['discord_user_id']),
);

Map<String, dynamic> _$ApiKeyInfoToJson(_ApiKeyInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'key_hash': instance.keyHash,
      'scopes': instance.scopes,
      'discord_user_id': ?instance.discordUserId,
    };
