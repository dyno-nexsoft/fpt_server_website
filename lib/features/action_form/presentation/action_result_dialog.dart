import 'package:flutter/material.dart';

import '../../../core/browser/browser_utils.dart';

/// Result of a mutation action, shown as a dialog rather than a toast
/// whenever there's something worth a closer look: a link to what was
/// created (mirrors Discord's "View Review"/"View MR" buttons), or
/// warnings about the data itself (e.g. `gitlab.translateArb`'s duplicate
/// arb key findings) that a passing toast would be too easy to miss.
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
    return AlertDialog(
      icon: Icon(
        warnings.isEmpty ? Icons.check_circle_outline : Icons.warning_amber,
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(message),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (link != null)
          FilledButton(
            onPressed: () {
              openInNewTab(link!.url);
              Navigator.of(context).pop();
            },
            child: Text(link!.label),
          ),
      ],
    );
  }
}

/// One collapsible-by-scroll list inside [ActionResultDialog] — a header
/// row naming the section, then each item as its own tile.
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
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        ListTile(dense: true, leading: Icon(icon), title: Text(title)),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in items)
                ListTile(leading: Icon(itemIcon), title: Text(item)),
            ],
          ),
        ),
      ],
    );
  }
}
