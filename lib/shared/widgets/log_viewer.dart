import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Monospace log text with a right-aligned line-number gutter, like a code
/// editor's — shared by the job log pane and the server logs screen so both
/// look and scroll the same way instead of drifting apart.
///
/// Two separate [SelectableText] blocks (gutter, content) sharing one
/// vertical scroll, with a border between them, rather than one blob with
/// numbers prefixed inline — that read as plain padded text, not a fixed
/// gutter column. Content gets its own horizontal scroll and never wraps: a
/// wrapped continuation line has no number of its own, which would desync
/// the gutter from the text — the same reason a real code editor scrolls
/// long lines sideways instead of wrapping them.
class LogViewer extends StatefulWidget {
  const LogViewer({
    super.key,
    required this.text,
    this.autoScrollToEnd = false,
    this.reverse = false,
    this.emptyMessage = '(no output yet)',
  });

  final String text;

  /// Jumps to the bottom whenever [text] grows — for a live build log that
  /// streams in place.
  final bool autoScrollToEnd;

  /// Anchors the initial scroll position at the bottom — for a static tail
  /// of a long buffer, where the newest lines are the ones worth seeing
  /// first.
  final bool reverse;

  final String emptyMessage;

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScrollToEnd && oldWidget.text.length != widget.text.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (widget.text.isEmpty) {
      return Center(
        child: Text(widget.emptyMessage, style: textTheme.bodySmall),
      );
    }

    final lines = widget.text.split('\n');
    final lineStyle = textTheme.bodySmall?.merge(AppTheme.monospaceTextStyle);
    // A named theme color (e.g. `colorScheme.outline`) can end up close
    // enough to body text in a given seed/brightness to read as "the same
    // color" — fading the actual text color guarantees a visible difference
    // regardless of theme.
    final gutterStyle = lineStyle?.copyWith(
      color: (lineStyle.color ?? Theme.of(context).colorScheme.onSurface)
          .withValues(alpha: 0.45),
    );
    final gutterText = [
      for (var i = 1; i <= lines.length; i++) '$i',
    ].join('\n');
    // `textAlign: right` only has visible effect once the gutter has a width
    // wider than its own text — an intrinsically-sized SelectableText has no
    // extra space to align *within*. Approximated from digit count rather
    // than measured, since every character is the same width in a monospace
    // font.
    final gutterWidth = '${lines.length}'.length * 8.0 + 4;

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        reverse: widget.reverse,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: SizedBox(
                width: gutterWidth,
                child: SelectableText(
                  gutterText,
                  textAlign: TextAlign.right,
                  style: gutterStyle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(widget.text, style: lineStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
