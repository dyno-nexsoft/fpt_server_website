// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActionSchema _$ActionSchemaFromJson(Map<String, dynamic> json) =>
    _ActionSchema(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      kind: const ActionKindConverter().fromJson(json['kind'] as String),
      permission: json['permission'] as String,
      params:
          (json['params'] as List<dynamic>?)
              ?.map((e) => ActionParam.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ActionParam>[],
    );

Map<String, dynamic> _$ActionSchemaToJson(_ActionSchema instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'kind': const ActionKindConverter().toJson(instance.kind),
      'permission': instance.permission,
      'params': instance.params.map((e) => e.toJson()).toList(),
    };

_ActionParam _$ActionParamFromJson(Map<String, dynamic> json) => _ActionParam(
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  type: const ActionParamTypeConverter().fromJson(json['type'] as String),
  required: json['required'] as bool? ?? false,
  choices:
      (json['choices'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  defaultValue: json['default'],
  isBranchRef: json['is_branch_ref'] as bool? ?? false,
);

Map<String, dynamic> _$ActionParamToJson(_ActionParam instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'type': const ActionParamTypeConverter().toJson(instance.type),
      'required': instance.required,
      'choices': instance.choices,
      'default': ?instance.defaultValue,
      'is_branch_ref': instance.isBranchRef,
    };
