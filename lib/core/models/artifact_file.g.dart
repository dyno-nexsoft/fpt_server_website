// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ArtifactFile _$ArtifactFileFromJson(Map<String, dynamic> json) =>
    _ArtifactFile(
      name: json['name'] as String,
      isDirectory: json['is_directory'] as bool? ?? false,
      size: (json['size'] as num?)?.toInt(),
      modified: DateTime.parse(json['modified'] as String),
    );

Map<String, dynamic> _$ArtifactFileToJson(_ArtifactFile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'is_directory': instance.isDirectory,
      'size': ?instance.size,
      'modified': instance.modified.toIso8601String(),
    };

_ArtifactListing _$ArtifactListingFromJson(Map<String, dynamic> json) =>
    _ArtifactListing(
      key: json['key'] as String,
      files:
          (json['files'] as List<dynamic>?)
              ?.map((e) => ArtifactFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ArtifactFile>[],
      job: json['job'] == null
          ? null
          : Job.fromJson(json['job'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ArtifactListingToJson(_ArtifactListing instance) =>
    <String, dynamic>{
      'key': instance.key,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'job': ?instance.job?.toJson(),
    };
