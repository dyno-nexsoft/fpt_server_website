import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Monospace log text with a right-aligned line-number gutter, like a code
/// editor's — shared by the job log pane and the server logs screen so both
/// look and scroll the same way instead of drifting apart.
///
/// Takes a [lines] list rather than a joined string: the caller (typically
/// [JobLogController]) already owns discrete, `\n`-normalized lines as they
/// stream in, so this widget never re-splits a growing blob of text.
///
/// Rendered with [ListView.builder] — one row per line, each holding its
/// gutter number and content side by side in a single [Row] — instead of
/// two independent columns of hundreds/thousands of eagerly-built [Text]
/// widgets. Two benefits over the old blob-of-text approach:
///
/// * **Lazy building.** Only the rows actually on screen get built, so a
///   log with thousands of lines stays as cheap to render as one with a
///   dozen.
/// * **Structural alignment.** A gutter number and its line used to live in
///   two separate columns, each sized to its own intrinsic height — a line
///   with a glyph that needs a taller fallback font (an emoji, CJK text)
///   could grow taller than its neighbour's plain-ASCII gutter number and
///   push every row below it out of sync for the rest of the log. Putting
///   both in the same [Row] means they're laid out together: whatever
///   height that row ends up being, both children share it, every time.
///
/// [SelectionArea] wraps the whole list so dragging across lines still
/// selects continuously, but each gutter number is wrapped in
/// [SelectionContainer.disabled] — copying a selection only ever yields the
/// log text itself, the way a real code editor's gutter is never part of
/// what you copy.
class LogViewer extends StatefulWidget {
  const LogViewer({
    super.key,
    required this.lines,
    this.autoScrollToEnd = false,
    this.reverse = false,
    this.emptyMessage = '(no output yet)',
  });

  final List<String> lines;

  /// Jumps to the bottom whenever [lines] grows (or its last entry keeps
  /// changing, for a still-streaming unterminated line) — for a live build
  /// log that streams in place.
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
  final _verticalController = ScrollController();
  final _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.reverse) _jumpToEnd();
  }

  @override
  void didUpdateWidget(covariant LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final grew = oldWidget.lines.length != widget.lines.length;
    final lastLineChanged =
        widget.lines.isNotEmpty &&
        oldWidget.lines.isNotEmpty &&
        oldWidget.lines.last != widget.lines.last;
    if (widget.autoScrollToEnd && (grew || lastLineChanged)) _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verticalController.hasClients) return;
      _verticalController.jumpTo(_verticalController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (widget.lines.isEmpty) {
      return Center(
        child: Text(widget.emptyMessage, style: textTheme.bodySmall),
      );
    }

    final lines = widget.lines;
    final lineStyle = textTheme.bodySmall?.merge(AppTheme.monospaceTextStyle);
    // A named theme color (e.g. `colorScheme.outline`) can end up close
    // enough to body text in a given seed/brightness to read as "the same
    // color" — fading the actual text color guarantees a visible difference
    // regardless of theme.
    final gutterStyle = lineStyle?.copyWith(
      color: (lineStyle.color ?? Theme.of(context).colorScheme.onSurface)
          .withValues(alpha: 0.45),
    );
    // Forces every row to the same height regardless of what glyphs its own
    // line happens to contain — see the class doc for why that matters once
    // gutter and content share a Row instead of two parallel columns.
    final strutStyle = lineStyle == null
        ? null
        : StrutStyle.fromTextStyle(lineStyle, forceStrutHeight: true);
    // `textAlign: right` only has visible effect once the gutter has a width
    // wider than its own text. Approximated from digit count rather than
    // measured, since every character is the same width in a monospace font.
    final gutterWidth = '${lines.length}'.length * 8.0 + 4;
    final contentWidth = _widestLineWidth(lines, lineStyle, strutStyle);
    // Every row is forced to this exact height by `strutStyle` above, so
    // `itemExtent` can hand it to ListView.builder directly — that lets the
    // list compute scroll offsets/max extent straight from the index
    // instead of laying out every prior item to find out how tall it is,
    // which matters once a log runs into the thousands of lines.
    final rowHeight = _lineHeight(lineStyle, strutStyle);
    final dividerColor = Theme.of(context).dividerColor;

    return Scrollbar(
      controller: _horizontalController,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: gutterWidth + 16 + contentWidth,
          child: Scrollbar(
            controller: _verticalController,
            child: SelectionArea(
              child: ListView.builder(
                controller: _verticalController,
                itemExtent: rowHeight,
                itemCount: lines.length,
                itemBuilder: (context, index) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectionContainer.disabled(
                      child: Container(
                        padding: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: dividerColor),
                          ),
                        ),
                        // The width belongs to this inner SizedBox, not the
                        // Container itself — a width set directly on the
                        // Container would get eaten by its own padding,
                        // leaving the number less space than gutterWidth
                        // actually reserved for it.
                        child: SizedBox(
                          width: gutterWidth,
                          child: Text(
                            '${index + 1}',
                            textAlign: TextAlign.right,
                            style: gutterStyle,
                            strutStyle: strutStyle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: contentWidth,
                      child: Text(
                        lines[index],
                        style: lineStyle,
                        softWrap: false,
                        strutStyle: strutStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The widest line's rendered width, so every row can share one fixed
  /// content column and scroll horizontally as a single unit. Only the
  /// longest-by-character-count line needs an actual [TextPainter] layout —
  /// safe to assume it's also the widest, since every character in a
  /// monospace font is the same width.
  double _widestLineWidth(
    List<String> lines,
    TextStyle? style,
    StrutStyle? strutStyle,
  ) {
    var widest = '';
    for (final line in lines) {
      if (line.length > widest.length) widest = line;
    }
    if (widest.isEmpty) return 0;
    final painter = TextPainter(
      text: TextSpan(text: widest, style: style),
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// The height every row is forced to by `strutStyle`, measured once from
  /// a single throwaway line rather than assumed — the strut's own metrics
  /// (leading, font fallback) aren't worth hand-deriving.
  double _lineHeight(TextStyle? style, StrutStyle? strutStyle) {
    final painter = TextPainter(
      text: TextSpan(text: '0', style: style),
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.height;
  }
}
