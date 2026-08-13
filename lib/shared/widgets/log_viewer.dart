import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'log_viewer_gutter.dart';
part 'log_viewer_metrics.dart';
part 'log_viewer_pan.dart';
part 'log_viewer_row.dart';

/// Monospace log text with a pinned, right-aligned line-number gutter, like a
/// code editor's — shared by the job log pane and the server logs screen so
/// both look and scroll the same way instead of drifting apart.
///
/// Takes a [lines] list rather than a joined string: the caller (typically
/// `JobLogController`) already owns discrete, `\n`-normalized lines as they
/// stream in, so this widget never re-splits a growing blob of text.
///
/// Rendered with [ListView.builder] — one row per line — instead of a column
/// of hundreds/thousands of eagerly-built [Text] widgets, so only the rows
/// actually on screen get built and a log of thousands of lines stays as
/// cheap as one with a dozen. Every row is forced to the same height by a
/// `forceStrutHeight` strut, which lets `itemExtent` hand that height to the
/// list: scroll offsets come from the index instead of from laying out every
/// preceding row.
///
/// A live build log rebuilds this widget every time a chunk arrives, so
/// anything O(number of lines) in [build] is really O(lines × chunks) over
/// the life of a build. [_LogMetrics] is what keeps that budget: measurements
/// are cached per text style and extended only over lines that are new.
///
/// `doc/log-viewer.md` covers that budget, the append-only contract with
/// `JobLogController`, and the four scrolling bugs this structure exists to
/// avoid.
class LogViewer extends StatefulWidget {
  const LogViewer({
    super.key,
    required this.lines,
    this.pendingLine = '',
    this.autoScrollToEnd = false,
    this.startAtBottom = false,
    this.emptyMessage = '(no output yet)',
    this.verticalController,
  });

  /// The complete, `\n`-terminated lines to render.
  ///
  /// Treated as **append-only**: a caller streaming a live log hands back the
  /// *same* list instance grown in place, and that identity is the signal
  /// that everything already measured still holds. Handing back a different
  /// instance is equally correct — it just re-measures from scratch, which is
  /// what a one-shot fetch or a manual refresh wants.
  final List<String> lines;

  /// A trailing line not yet terminated by `\n`, rendered as one more row
  /// after [lines]. Kept a separate parameter rather than appended by the
  /// caller so a streaming log never copies its whole line list just to show
  /// a half-arrived line.
  final String pendingLine;

  /// Follows the tail of the log as it grows — for a live build log.
  ///
  /// Only while the view is *already* at the bottom: once the reader scrolls
  /// up to look at something, new output stops yanking them back down, and
  /// scrolling back to the bottom resumes following.
  final bool autoScrollToEnd;

  /// Anchors the initial scroll position at the bottom — for a static tail of
  /// a long buffer, where the newest lines are the ones worth seeing first.
  final bool startAtBottom;

  final String emptyMessage;

  /// Drives vertical scrolling instead of an internally-created controller —
  /// for a caller that needs this list to scroll as the *body* of a
  /// [NestedScrollView] (sharing one continuous drag gesture with a header
  /// above it) rather than as its own independent scrollable competing with
  /// the page around it for the same gesture.
  final ScrollController? verticalController;

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  /// How near the bottom still counts as "following the tail" — a fraction of
  /// a row, so a pixel of scroll-physics overshoot doesn't read as the reader
  /// having deliberately scrolled away.
  static const _bottomSlack = 8.0;

  ScrollController? _ownedVerticalController;
  ScrollController get _verticalController =>
      widget.verticalController ?? _ownedVerticalController!;
  final _horizontalController = ScrollController();
  final _metrics = _LogMetrics();

  int _lastRowCount = 0;
  bool _stickToBottom = true;
  bool _scrollScheduled = false;

  int get _rowCount =>
      widget.lines.length + (widget.pendingLine.isEmpty ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.verticalController == null) {
      _ownedVerticalController = ScrollController();
    }
    _lastRowCount = _rowCount;
    if (widget.startAtBottom) _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(covariant LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compared against a count this State kept rather than against
    // `oldWidget.lines.length`: a streaming caller grows a single list in
    // place, so both widgets read the same (new) length and growth would
    // never be detected. A pending line merely getting longer needs no
    // scroll — it changes the row's width, not the list's extent.
    final rowCount = _rowCount;
    final grew = rowCount != _lastRowCount;
    _lastRowCount = rowCount;
    if (grew && widget.autoScrollToEnd && _stickToBottom) {
      _scheduleScrollToEnd();
    }
  }

  @override
  void dispose() {
    _ownedVerticalController?.dispose();
    _horizontalController.dispose();
    _metrics.dispose();
    super.dispose();
  }

  /// Coalesced to one jump per frame: several appends can land between two
  /// paints, and each would otherwise queue its own callback to scroll to the
  /// same place.
  void _scheduleScrollToEnd() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_verticalController.hasClients) return;
      final position = _verticalController.position;
      // Derived from the row count rather than read off
      // `position.maxScrollExtent`, which is still the *previous* frame's
      // value here — a post-frame callback runs before the grown viewport has
      // published its new content dimensions. Jumping to it left the newest
      // line one row below the fold on every single append.
      //
      // Sound to compute because `itemExtent` fixes every row's height, so
      // the extent is exactly this. If the arithmetic ever lands a hair past
      // the real end, [ScrollPosition] pulls an out-of-range offset back
      // in-bounds on the next layout — which is the bottom, i.e. where this
      // was headed anyway.
      _verticalController.jumpTo(
        math.max(
          0.0,
          _rowCount * _metrics.rowHeight - position.viewportDimension,
        ),
      );
    });
  }

  static bool _isVertical(ScrollNotification notification) =>
      notification.metrics.axis == Axis.vertical;

  /// Tracks whether the reader is still parked at the tail. Reads position
  /// from the notification rather than polling the controller so an
  /// auto-jump — which lands exactly at the bottom, keeping the flag set —
  /// and a deliberate scroll away are indistinguishable to handle.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      _stickToBottom = metrics.pixels >= metrics.maxScrollExtent - _bottomSlack;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowCount = _rowCount;
    if (rowCount == 0) {
      return Center(
        child: Text(widget.emptyMessage, style: theme.textTheme.bodySmall),
      );
    }

    final rowStyle = _resolveRowStyle(context, theme, rowCount);

    // The vertical scrollbar sits outermost so its box is the whole pane. It
    // used to be nested inside the horizontal scroll view, wrapping the
    // full-content-width box — a scrollbar paints along the edge of its own
    // box, so its thumb was drawn at the right edge of the widest line in the
    // log and was simply not on screen unless you happened to scroll all the
    // way right.
    return Scrollbar(
      controller: _verticalController,
      // Out here the list's notifications have already bubbled through the
      // horizontal Scrollable, so their depth is 1 and the default depth == 0
      // predicate would drop every one of them, leaving the thumb frozen.
      // Axis is the property that actually identifies them.
      notificationPredicate: _isVertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PinnedGutter(
            controller: _verticalController,
            rowCount: rowCount,
            rowHeight: _metrics.rowHeight,
            style: rowStyle,
          ),
          Expanded(child: _content(rowCount, rowStyle)),
        ],
      ),
    );
  }

  /// The scrolling half: everything to the right of the gutter.
  Widget _content(int rowCount, _LogRowStyle rowStyle) => Scrollbar(
    controller: _horizontalController,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          // Stretched to the pane when the log is narrower than it, rather
          // than left at its content width: the rows are the only thing that
          // scrolls vertically, so a content-sized box left the area to its
          // right inert — a wheel or a drag over most of the pane did nothing
          // at all on a log of short lines.
          width: math.max(rowStyle.contentWidth, constraints.maxWidth),
          child: SelectionArea(
            child: _HorizontalTouchPan(
              controller: _horizontalController,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: _LogRows(
                  lines: widget.lines,
                  pendingLine: widget.pendingLine,
                  rowCount: rowCount,
                  rowHeight: _metrics.rowHeight,
                  style: rowStyle,
                  controller: _verticalController,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// Resolves the styles and column widths every row shares, bringing
  /// [_metrics] up to date on the way.
  _LogRowStyle _resolveRowStyle(
    BuildContext context,
    ThemeData theme,
    int rowCount,
  ) {
    final lineStyle = (theme.textTheme.bodySmall ?? const TextStyle()).merge(
      AppTheme.monospaceTextStyle,
    );
    // Forces every row to the same height regardless of what glyphs its own
    // line happens to contain, which is what `itemExtent` depends on.
    final strutStyle = StrutStyle.fromTextStyle(
      lineStyle,
      forceStrutHeight: true,
    );
    _metrics.sync(
      lines: widget.lines,
      pendingLine: widget.pendingLine,
      style: lineStyle,
      strutStyle: strutStyle,
      // Measured with the same scaling the rows will actually be rendered
      // with; a TextPainter does no scaling of its own, so leaving this out
      // under-measures every column as soon as the reader zooms.
      textScaler: MediaQuery.textScalerOf(context),
    );

    return _LogRowStyle(
      lineStyle: lineStyle,
      // A named theme color (e.g. `colorScheme.outline`) can end up close
      // enough to body text in a given seed/brightness to read as "the same
      // color" — fading the actual text color guarantees a visible difference
      // regardless of theme.
      gutterStyle: lineStyle.copyWith(
        color: (lineStyle.color ?? theme.colorScheme.onSurface).withValues(
          alpha: 0.45,
        ),
      ),
      strutStyle: strutStyle,
      gutterWidth: _metrics.columnWidth('$rowCount'.length),
      contentWidth: _metrics.contentWidth,
      gutterBorder: Border(right: BorderSide(color: theme.dividerColor)),
    );
  }
}
