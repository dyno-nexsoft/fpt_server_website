import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/action_form/presentation/action_result_dialog.dart';

/// Persists the last [ActionResultView] shown for each action in
/// `localStorage`, so a page refresh doesn't lose it — without this, "View
/// last result" only worked until the next reload, which is confusing right
/// after a `gitlab.review`/`gitlab.translateArb` run if the tab happens to
/// refresh (or the user just comes back later) before they've looked at it.
///
/// Keyed by action name, same reasoning as [ActionTemplateStore]: a stored
/// result only ever makes sense re-shown on the same action's own form.
class LastResultStore {
  LastResultStore(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String actionName) => 'last_result.$actionName';

  /// The saved result for [actionName], or `null` if none was ever saved or
  /// it failed to parse (a shape change between deploys, say) — either way
  /// there's nothing safe to show, not a crash.
  ActionResultView? load(String actionName) {
    final raw = _prefs.getString(_key(actionName));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final message = json['message'];
      if (message is! String) return null;
      final linkJson = json['link'] as Map<String, dynamic>?;
      return (
        message: message,
        details: _stringList(json['details']),
        warnings: _stringList(json['warnings']),
        issues: _issueList(json['issues']),
        link: linkJson == null ? null : _link(linkJson),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String actionName, ActionResultView result) =>
      _prefs.setString(_key(actionName), jsonEncode(_toJson(result)));

  Map<String, Object?> _toJson(ActionResultView result) => {
    'message': result.message,
    'details': result.details,
    'warnings': result.warnings,
    'issues': [
      for (final issue in result.issues)
        {
          'severity': issue.severity,
          'file': issue.file,
          'line_start': issue.lineStart,
          'line_end': issue.lineEnd,
          'description': issue.description,
          'url': issue.url,
        },
    ],
    'link': result.link == null
        ? null
        : {'label': result.link!.label, 'url': result.link!.url},
  };

  List<String> _stringList(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

  List<ReviewIssueView> _issueList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic> &&
            entry['severity'] is String &&
            entry['file'] is String &&
            entry['line_start'] is int &&
            entry['description'] is String)
          (
            severity: entry['severity'] as String,
            file: entry['file'] as String,
            lineStart: entry['line_start'] as int,
            lineEnd: entry['line_end'] as int?,
            description: entry['description'] as String,
            url: entry['url'] as String?,
          ),
    ];
  }

  ({String label, String url})? _link(Map<String, dynamic> json) {
    final label = json['label'];
    final url = json['url'];
    if (label is! String || url is! String) return null;
    return (label: label, url: url);
  }
}
