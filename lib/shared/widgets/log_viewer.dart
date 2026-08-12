import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Monospace log text with a right-aligned line-number gutter, like a code
/// editor's — shared by the job log pane and the server logs screen so both
/// look and scroll the same way instead of drifting apart.
///
/// The gutter is plain padded text inside one [SelectableText.rich], not a
/// separate widget column: a real table layout would force per-line
/// selection, whereas this keeps the whole log selectable and copyable as
/// one block.
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
    if (widget.autoScrollToEnd &&
        oldWidget.text.length != widget.text.length) {
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
    final gutterDigits = '${lines.length}'.length;
    final lineStyle = textTheme.bodySmall?.merge(AppTheme.monospaceTextStyle);
    final gutterStyle = lineStyle?.copyWith(
      color: Theme.of(context).colorScheme.outline,
    );

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        reverse: widget.reverse,
        child: SelectableText.rich(
          TextSpan(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const TextSpan(text: '\n'),
                TextSpan(
                  text: '${i + 1}'.padLeft(gutterDigits),
                  style: gutterStyle,
                ),
                TextSpan(text: '  ${lines[i]}', style: lineStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
