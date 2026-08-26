import 'package:flutter/material.dart';

import '../../../core/browser/browser_utils.dart';

/// Result of a mutation action, shown as a full-screen dialog rather than
/// a toast whenever there's something worth a closer look: a link to what
/// was created (mirrors Discord's "View Review"/"View MR" buttons), or
/// warnings about the data itself (e.g. `gitlab.translateArb`'s duplicate
/// arb key findings and per-file breakdown) that a passing toast — or a
/// small centered dialog, for a module with many locales/warnings — would
/// be too easy to miss or too cramped to read.
class ActionResultDialog extends StatelessWidget {
  const ActionResultDialog({
    super.key,
    required this.message,
    this.details = const [],
    this.warnings = const [],
    this.link,
  });

  final String message;

  /// Informational lines worth their own list, but not a warning — e.g.
  /// `gitlab.translateArb`'s per-file key counts.
  final List<String> details;
  final List<String> warnings;

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
