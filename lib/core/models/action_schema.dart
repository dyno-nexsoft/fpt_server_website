import 'package:freezed_annotation/freezed_annotation.dart';

part 'action_schema.freezed.dart';
part 'action_schema.g.dart';

/// One entry from `GET /actions` / `GET /actions/{name}`. Forms and nav
/// menus are generated from this instead of being hand-written per action,
/// so the UI cannot drift from what the server actually accepts.
@freezed
abstract class ActionSchema with _$ActionSchema {
  const ActionSchema._();

  const factory ActionSchema({
    required String name,
    @Default('') String description,
    @ActionKindConverter() required ActionKind kind,
    required String permission,
    @Default(<ActionParam>[]) List<ActionParam> params,
  }) = _ActionSchema;

  factory ActionSchema.fromJson(Map<String, dynamic> json) =>
      _$ActionSchemaFromJson(json);

  bool get isDangerous => permission == 'invokeDangerous';
}

enum ActionKind {
  query,
  mutation,
  job;

  static ActionKind fromWire(String wire) => switch (wire) {
    'query' => ActionKind.query,
    'mutation' => ActionKind.mutation,
    'job' => ActionKind.job,
    _ => ActionKind.mutation,
  };
}

class ActionKindConverter implements JsonConverter<ActionKind, String> {
  const ActionKindConverter();

  @override
  ActionKind fromJson(String json) => ActionKind.fromWire(json);

  @override
  String toJson(ActionKind object) => object.name;
}

@freezed
abstract class ActionParam with _$ActionParam {
  const factory ActionParam({
    required String name,
    @Default('') String description,
    @ActionParamTypeConverter() required ActionParamType type,
    @Default(false) bool required,
    @Default(<String>[]) List<String> choices,
    @JsonKey(name: 'default') dynamic defaultValue,

    /// Whether this string param is a git branch name — see
    /// `ParamSpec.isBranchRef` on the server. `name` doubles as the repo key
    /// for `GET /autocomplete/branches?repo={name}`.
    @Default(false) bool isBranchRef,
  }) = _ActionParam;

  factory ActionParam.fromJson(Map<String, dynamic> json) =>
      _$ActionParamFromJson(json);
}

enum ActionParamType {
  string,
  integer,
  number,
  boolean,
  enumeration;

  static ActionParamType fromWire(String wire) => switch (wire) {
    'string' => ActionParamType.string,
    'integer' => ActionParamType.integer,
    'number' => ActionParamType.number,
    'boolean' => ActionParamType.boolean,
    'enumeration' => ActionParamType.enumeration,
    _ => ActionParamType.string,
  };
}

class ActionParamTypeConverter
    implements JsonConverter<ActionParamType, String> {
  const ActionParamTypeConverter();

  @override
  ActionParamType fromJson(String json) => ActionParamType.fromWire(json);

  @override
  String toJson(ActionParamType object) => object.name;
}
