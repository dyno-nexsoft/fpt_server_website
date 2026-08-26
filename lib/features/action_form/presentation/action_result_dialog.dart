import 'package:flutter/material.dart';

import '../../../core/browser/browser_utils.dart';

/// One `gitlab.review` finding — mirrors the backend's `ReportedIssue`, kept
/// as loose fields (not a `fpt_server_shared` model) since it's parsed
/// ad hoc off the REST response the same way `details`/`warnings` already
/// are, not a proper wire-contract type.
typedef ReviewIssueView = ({
  String severity,
  String file,
  int lineStart,
  int? lineEnd,
  String description,
  String? url,
});

/// Result of a mutation action, shown as a full-screen dialog rather than
/// a toast whenever there's something worth a closer look: a link to what
/// was created (mirrors Discord's "View Review"/"View MR" buttons), findings
/// from `gitlab.review`, or warnings about the data itself (e.g.
/// `gitlab.translateArb`'s duplicate arb key findings and per-file
/// breakdown) that a passing toast — or a small centered dialog, for a
/// module with many locales/warnings — would be too easy to miss or too
/// cramped to read.
class ActionResultDialog extends StatelessWidget {
  const ActionResultDialog({
    super.key,
    required this.message,
    this.details = const [],
    this.warnings = const [],
    this.issues = const [],
    this.link,
  });

  final String message;

  /// Informational lines worth their own list, but not a warning — e.g.
  /// `gitlab.translateArb`'s per-file key counts.
  final List<String> details;
  final List<String> warnings;

  /// `gitlab.review`'s findings, in the same severity order already posted
  /// to the GitLab MR comment.
  final List<ReviewIssueView> issues;

  /// A link worth its own button — e.g. `{label: 'View MR', url: '...'}`.
  final ({String label, String url})? link;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Result'),
          actions: [
            if (link != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton(
                  onPressed: () => openInNewTab(link!.url),
                  child: Text(link!.label),
                ),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              dense: true,
              leading: Icon(
                warnings.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.warning_amber,
              ),
              title: Text(message),
            ),
            if (issues.isNotEmpty) ...[
              const Divider(),
              ListTile(
                dense: true,
                leading: const Icon(Icons.bug_report_outlined),
                title: Text('Issues (${issues.length})'),
              ),
              for (final issue in issues) _IssueTile(issue: issue),
            ],
            if (details.isNotEmpty)
              _ResultSection(
                icon: Icons.description_outlined,
                title: 'Keys per file (${details.length})',
                items: details,
                itemIcon: Icons.article_outlined,
              ),
            if (warnings.isNotEmpty)
              _ResultSection(
                icon: Icons.info_outline,
                title: 'Data quality warnings (${warnings.length})',
                items: warnings,
                itemIcon: Icons.error_outline,
              ),
          ],
        ),
      ),
    );
  }
}

/// One `gitlab.review` finding — severity as an icon (color only for `HIGH`,
/// via [ColorScheme.error] the same way every other destructive/dangerous
/// indicator in this app already does — never a hardcoded color) rather
/// than a custom badge, per this app's no-inline-styling rule.
class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final ReviewIssueView issue;

  IconData get _icon => switch (issue.severity) {
    'HIGH' => Icons.error_outline,
    'MEDIUM' => Icons.warning_amber_outlined,
    _ => Icons.info_outline,
  };

  /// `file:line` (or `file:start-end` for a multi-line finding) — just the
  /// file name for a synthetic pipeline notice, which has no real line to
  /// cite (see `ReportedIssue.fileUrl`'s doc comment).
  String get _location {
    if (issue.lineStart <= 0) return issue.file;
    final end = issue.lineEnd;
    return (end != null && end != issue.lineStart)
        ? '${issue.file}:${issue.lineStart}-$end'
        : '${issue.file}:${issue.lineStart}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        _icon,
        color: issue.severity == 'HIGH' ? colorScheme.error : null,
      ),
      title: Text('[${issue.severity}] $_location'),
      subtitle: Text(issue.description),
      trailing: issue.url == null
          ? null
          : IconButton(
              tooltip: 'Open in GitLab',
              icon: const Icon(Icons.open_in_new),
              onPressed: () => openInNewTab(issue.url!),
            ),
    );
  }
}

/// One section of [ActionResultDialog]'s body — a header row naming it,
/// then each item as its own tile.
class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.icon,
    required this.title,
    required this.items,
    required this.itemIcon,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final IconData itemIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        ListTile(dense: true, leading: Icon(icon), title: Text(title)),
        for (final item in items)
          ListTile(leading: Icon(itemIcon), title: Text(item)),
      ],
    );
  }
}
