import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A named snapshot of the field values a user last typed into an action's
/// form — e.g. a `ci.build` with `tbchat`/`database`/modules already filled
/// in, so a recurring build no longer means retyping the same branches every
/// time.
class ActionTemplate {
  const ActionTemplate({required this.name, required this.params});

  factory ActionTemplate.fromJson(Map<String, dynamic> json) => ActionTemplate(
    name: json['name'] as String,
    params: Map<String, Object?>.from(json['params'] as Map),
  );

  final String name;
  final Map<String, Object?> params;

  Map<String, Object?> toJson() => {'name': name, 'params': params};
}

/// Persists per-action form templates in `localStorage`.
///
/// Keyed by action name so `ci.build`, `ci.gen`, etc. each keep their own
/// list — a saved `ci.build` template has fields that mean nothing to
/// `ci.clean`. Purely a client-side convenience: nothing here goes through
/// `ActionRunner`, since saving a form preset invokes no capability.
class ActionTemplateStore {
  ActionTemplateStore(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String actionName) => 'action_templates.$actionName';

  List<ActionTemplate> list(String actionName) {
    final raw = _prefs.getString(_key(actionName));
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => ActionTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds [template], replacing any existing one with the same name.
  Future<void> save(String actionName, ActionTemplate template) {
    final templates = list(
      actionName,
    ).where((t) => t.name != template.name).toList()..add(template);
    return _persist(actionName, templates);
  }

  Future<void> delete(String actionName, String templateName) {
    final templates = list(
      actionName,
    ).where((t) => t.name != templateName).toList();
    return _persist(actionName, templates);
  }

  Future<void> _persist(String actionName, List<ActionTemplate> templates) =>
      _prefs.setString(
        _key(actionName),
        jsonEncode([for (final t in templates) t.toJson()]),
      );
}
