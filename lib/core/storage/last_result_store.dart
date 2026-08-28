import 'dart:convert';

import 'package:fpt_server_shared/fpt_server_shared.dart';
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

  /// Round-trips findings through [ReviewIssue]'s own `toJson`/`fromJson`
  /// rather than a hand-written copy of its fields. Stored entries outlive
  /// deploys, so a field this file spelled differently from the model would
  /// come back missing from a result saved by an older build — with no error
  /// anywhere, just a finding that quietly lost its line number.
  Map<String, Object?> _toJson(ActionResultView result) => {
    'message': result.message,
    'details': result.details,
    'warnings': result.warnings,
    'issues': [for (final issue in result.issues) issue.toJson()],
    'link': result.link == null
        ? null
        : {'label': result.link!.label, 'url': result.link!.url},
  };

  List<String> _stringList(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

  List<ReviewIssue> _issueList(Object? raw) {
    if (raw is! List) return const [];
    final issues = <ReviewIssue>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      try {
        issues.add(ReviewIssue.fromJson(entry));
      } catch (_) {
        // A single unreadable entry (written by an older build, say) drops
        // out; the rest of the saved result still opens.
      }
    }
    return issues;
  }

  ({String label, String url})? _link(Map<String, dynamic> json) {
    final label = json['label'];
    final url = json['url'];
    if (label is! String || url is! String) return null;
    return (label: label, url: url);
  }
}
