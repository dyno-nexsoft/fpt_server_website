part of 'log_viewer.dart';

/// Everything the gutter and the rows need that is identical for all of them.
///
/// Resolved once per [LogViewer] build and handed down, rather than derived
/// inside the item builder: a border, a faded text style and a column width
/// are the same for every line, and rebuilding them per row is work paid once
/// per visible line for nothing.
@immutable
class _LogRowStyle {
  const _LogRowStyle({
    required this.lineStyle,
    required this.gutterStyle,
    required this.strutStyle,
    required this.gutterWidth,
    required this.contentWidth,
    required this.gutterBorder,
  });

  /// Gap on either side of the gutter's divider.
  static const gap = 8.0;

  final TextStyle lineStyle;
  final TextStyle gutterStyle;
  final StrutStyle strutStyle;

  /// Width of the line numbers themselves, wide enough for the highest one
  /// this log can show — `textAlign: right` only has visible effect once the
  /// column is wider than its own text.
  final double gutterWidth;

  final double contentWidth;
  final Border gutterBorder;

  /// Total width of the pinned column: a gap, the numbers, a gap, the divider,
  /// and a gap before the log text starts.
  ///
  /// [gutterBorder] is part of that measurement. A [Container]'s decoration
  /// border is layout, not just paint — it contributes its own thickness as
  /// padding around the child, so leaving it out costs exactly one pixel of
  /// misalignment.
  double get gutterTotalWidth =>
      gap * 3 + gutterWidth + gutterBorder.right.width;
}

/// The log lines. Plain text rows: the numbers beside them are drawn by
/// [_PinnedGutter], outside this list and outside the horizontal scroll.
class _LogRows extends StatelessWidget {
  const _LogRows({
    required this.lines,
    required this.pendingLine,
    required this.rowCount,
    required this.rowHeight,
    required this.style,
    required this.controller,
  });

  final List<String> lines;
  final String pendingLine;
  final int rowCount;
  final double rowHeight;
  final _LogRowStyle style;
  final ScrollController controller;

  /// The last row is [pendingLine] when there is one — it is deliberately not
  /// part of [lines], see [LogViewer.pendingLine].
  String _textAt(int index) =>
      index < lines.length ? lines[index] : pendingLine;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemExtent: rowHeight,
      itemCount: rowCount,
      itemBuilder: (context, index) =>
          _LogRow(text: _textAt(index), style: style),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.text, required this.style});

  final String text;
  final _LogRowStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style.lineStyle,
      softWrap: false,
      strutStyle: style.strutStyle,
    );
  }
}
