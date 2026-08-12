part of 'log_viewer.dart';

/// The line-number column, held outside the horizontally scrolling content so
/// it is always in view — the way a code editor keeps its gutter regardless of
/// how long the line you are reading is.
///
/// It deliberately does *not* live inside the list. Putting it in each row and
/// sliding it right to compensate for the scroll offset also keeps it in view,
/// but then the log text scrolls *underneath* it — and a gutter has only a
/// divider, no fill, so the text showed straight through it and swallowed the
/// numbers. Giving it an opaque background would mean hardcoding a colour that
/// has to match whatever the pane is sitting on. Out here there is nothing to
/// paint over: the content's viewport simply starts to the right of it.
///
/// The cost is that this column has to place the numbers itself rather than
/// letting a viewport do it. That is exact rather than approximate, because
/// `itemExtent` fixes every row's height: row `i` sits at
/// `i * rowHeight - scrollOffset`, which is the same arithmetic the list's own
/// viewport does.
class _PinnedGutter extends StatelessWidget {
  const _PinnedGutter({
    required this.controller,
    required this.rowCount,
    required this.rowHeight,
    required this.style,
  });

  final ScrollController controller;
  final int rowCount;
  final double rowHeight;
  final _LogRowStyle style;

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Being outside the list also means the list's own gestures don't reach
      // here, so a wheel over the numbers would do nothing without this —
      // and to a reader this column is part of the log.
      onPointerSignal: _onPointerSignal,
      // Sized explicitly, because what is inside is a Stack of nothing but
      // positioned children: it has no opinion of its own about how wide it
      // should be and would collapse to nothing. The width deducts back down
      // to exactly [_LogRowStyle.gutterWidth] for the numbers themselves once
      // the two gaps and the divider are taken out.
      child: SizedBox(
        width: style.gutterTotalWidth,
        child: Padding(
          // Outside the border, so the gap between the divider and the log
          // text is fixed rather than scrolling away with the content.
          padding: const EdgeInsets.only(right: _LogRowStyle.gap),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: _LogRowStyle.gap),
            decoration: BoxDecoration(border: style.gutterBorder),
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: controller,
                builder: (context, _) => _numbers(constraints.maxHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Only the numbers that can actually be seen, placed against the list's
  /// current scroll offset. One extra row is built beyond the visible height
  /// so the partially-scrolled row at the bottom edge is not missing.
  Widget _numbers(double height) {
    final offset = controller.hasClients ? controller.offset : 0.0;
    final first = math.max(0, (offset / rowHeight).floor());
    final last = math.min(rowCount, first + (height / rowHeight).ceil() + 1);
    return Stack(
      children: [
        for (var i = first; i < last; i++)
          Positioned(
            top: i * rowHeight - offset,
            left: 0,
            right: 0,
            height: rowHeight,
            child: Text(
              '${i + 1}',
              textAlign: TextAlign.right,
              style: style.gutterStyle,
              strutStyle: style.strutStyle,
            ),
          ),
      ],
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !controller.hasClients) return;
    controller.position.pointerScroll(event.scrollDelta.dy);
  }
}
