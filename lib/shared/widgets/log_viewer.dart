import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Monospace log text with a right-aligned line-number gutter, like a code
/// editor's — shared by the job log pane and the server logs screen so both
/// look and scroll the same way instead of drifting apart.
///
/// Takes a [lines] list rather than a joined string: the caller (typically
/// [JobLogController]) already owns discrete, `\n`-normalized lines as they
/// stream in, so this widget never re-splits a growing blob of text on every
/// rebuild. Each line is its own [Text] widget, built from the same `for`
/// loop as the gutter number next to it — not two giant blocks of
/// newline-joined text whose row counts have to be trusted to match. A
/// single [SelectableText] blob relies on `split('\n')` producing exactly as
/// many visual rows as the gutter counted, which silently breaks the moment
/// anything (an accidental soft-wrap, a stray control character) inserts a
/// visual line the count didn't see — the gutter then drifts out of sync
/// with the text underneath it for the rest of the log. Building line-by-line
/// with `softWrap: false` makes that structurally impossible: there are
/// always exactly as many content widgets as gutter widgets, and no line can
/// ever wrap into an extra row. [SelectionArea] wraps the whole tree so
/// selection still spans every line despite each being a separate widget.
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
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final grew = oldWidget.lines.length != widget.lines.length;
    final lastLineChanged =
        widget.lines.isNotEmpty &&
        oldWidget.lines.isNotEmpty &&
        oldWidget.lines.last != widget.lines.last;
    if (widget.autoScrollToEnd && (grew || lastLineChanged)) {
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
    // `textAlign: right` only has visible effect once the gutter has a width
    // wider than its own text — an intrinsically-sized Text has no extra
    // space to align *within*. Approximated from digit count rather than
    // measured, since every character is the same width in a monospace font.
    final gutterWidth = '${lines.length}'.length * 8.0 + 4;
    // A gutter number and its own log line are two separate Text widgets in
    // two separate Columns, each sized to its own intrinsic height — that
    // breaks the moment a single line's glyphs (an emoji, a CJK character,
    // anything needing a fallback font) measure taller than plain ASCII
    // digits do. One row's Text growing a few px taller than its gutter
    // number's Text shifts every line below it out of alignment for the
    // rest of the log. A strut forces every line — gutter and content alike
    // — to the same fixed height regardless of what glyphs it actually
    // contains, so no single line can ever push the rest out of step.
    final strutStyle = lineStyle == null
        ? null
        : StrutStyle.fromTextStyle(lineStyle, forceStrutHeight: true);

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        reverse: widget.reverse,
        child: SelectionArea(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 1; i <= lines.length; i++)
                        Text('$i', style: gutterStyle, strutStyle: strutStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines)
                        Text(
                          line,
                          style: lineStyle,
                          softWrap: false,
                          strutStyle: strutStyle,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
