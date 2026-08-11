/// One entry from `GET /actions` / `GET /actions/{name}`. Forms and nav
/// menus are generated from this instead of being hand-written per action,
/// so the UI cannot drift from what the server actually accepts.
class ActionSchema {
  const ActionSchema({
    required this.name,
    required this.description,
    required this.kind,
    required this.permission,
    required this.params,
  });

  factory ActionSchema.fromJson(Map<String, dynamic> json) => ActionSchema(
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    kind: ActionKind.fromWire(json['kind'] as String),
    permission: json['permission'] as String,
    params: (json['params'] as List<dynamic>? ?? [])
        .map((p) => ActionParam.fromJson(p as Map<String, dynamic>))
        .toList(),
  );

  final String name;
  final String description;
  final ActionKind kind;
  final String permission;
  final List<ActionParam> params;

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

class ActionParam {
  const ActionParam({
    required this.name,
    required this.description,
    required this.type,
    required this.required,
    this.choices = const [],
    this.defaultValue,
    this.isBranchRef = false,
  });

  factory ActionParam.fromJson(Map<String, dynamic> json) => ActionParam(
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    type: ActionParamType.fromWire(json['type'] as String),
    required: json['required'] as bool? ?? false,
    choices: (json['choices'] as List<dynamic>?)?.cast<String>() ?? const [],
    defaultValue: json['default'],
    isBranchRef: json['is_branch_ref'] as bool? ?? false,
  );

  final String name;
  final String description;
  final ActionParamType type;
  final bool required;
  final List<String> choices;
  final dynamic defaultValue;

  /// Whether this string param is a git branch name — see
  /// `ParamSpec.isBranchRef` on the server. `name` doubles as the repo key
  /// for `GET /autocomplete/branches?repo={name}`.
  final bool isBranchRef;
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
