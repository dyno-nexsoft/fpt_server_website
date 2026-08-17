import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A single data point for [BarChart].
class BarChartData {
  const BarChartData({required this.label, required this.value, this.color});

  final String label;
  final int value;

  /// Falls back to the theme's primary colour when null, so callers can opt in
  /// to per-bar colouring without being forced to provide one.
  final Color? color;
}

/// A zero-dependency vertical bar chart drawn with [CustomPaint].
///
/// Bars animate from zero height to their target on first appearance using a
/// staggered [CurvedAnimation] — each bar starts slightly after the previous
/// one so the reveal feels sequential rather than a single flat pop.
///
/// Skips the canvas when [data] is empty or every bar is zero so the caller's
/// "No data yet" placeholder shows instead of a blank axes frame.
class BarChart extends StatefulWidget {
  const BarChart({
    super.key,
    required this.data,
    this.height = 260,
    this.barBorderRadius = 4,
    this.showValues = true,
    this.showGrid = true,
    this.animationDuration = const Duration(milliseconds: 700),
  });

  final List<BarChartData> data;
  final double height;

  /// Radius for the rounded top corners of each bar.
  final double barBorderRadius;

  /// Whether to draw the count label above each bar.
  final bool showValues;

  /// Whether to draw horizontal grid lines.
  final bool showGrid;

  /// Total duration of the grow-in animation (stagger adds ~30 % on top).
  final Duration animationDuration;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // One curved animation per bar so bars stagger.
  late List<Animation<double>> _barAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Give the controller a slightly longer range so each bar's window fits.
      duration:
          widget.animationDuration +
          Duration(
            milliseconds: (widget.data.length * _staggerMs).clamp(0, 400),
          ),
    );
    _buildAnimations();
    _controller.forward();
  }

  /// Each bar's animation window is offset by [_staggerMs] relative to the
  /// previous bar, then eased with an [ElasticOutCurve] for a satisfying
  /// overshoot-and-settle feel.
  static const _staggerMs = 60;
  static const _barWindow = 0.65; // fraction of total duration each bar uses

  void _buildAnimations() {
    final n = widget.data.length;
    final totalMs = _controller.duration!.inMilliseconds.toDouble();

    _barAnimations = List.generate(n, (i) {
      final startFrac = (i * _staggerMs) / totalMs;
      final endFrac = (startFrac + _barWindow).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(startFrac, endFrac, curve: Curves.easeOutCubic),
      );
    });
  }

  @override
  void didUpdateWidget(BarChart old) {
    super.didUpdateWidget(old);
    // Re-run the animation when the data set changes (e.g. live refresh).
    if (old.data != widget.data) {
      _buildAnimations();
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || widget.data.every((d) => d.value == 0)) {
      return SizedBox(height: widget.height);
    }
    final theme = Theme.of(context);

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _BarChartPainter(
            data: widget.data,
            barProgressValues: List.generate(
              widget.data.length,
              (i) => _barAnimations[i].value,
            ),
            theme: theme,
            barBorderRadius: widget.barBorderRadius,
            showValues: widget.showValues,
            showGrid: widget.showGrid,
            gridProgress: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.data,
    required this.barProgressValues,
    required this.theme,
    required this.barBorderRadius,
    required this.showValues,
    required this.showGrid,
    required this.gridProgress,
  });

  final List<BarChartData> data;

  /// Per-bar animation progress (0.0 → 1.0), same length as [data].
  final List<double> barProgressValues;

  final ThemeData theme;
  final double barBorderRadius;
  final bool showValues;
  final bool showGrid;
  final double gridProgress;

  // Vertical space reserved below the bars for the x-axis labels.
  static const _labelAreaHeight = 24.0;

  // Vertical space reserved above the bars for the value labels.
  static const _valueLabelHeight = 18.0;

  // Fraction of each slot that the bar occupies (the rest is inter-bar gap).
  static const _barWidthFraction = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.map((d) => d.value).reduce(math.max);
    if (maxVal == 0) return;

    final chartTop = _valueLabelHeight;
    final chartBottom = size.height - _labelAreaHeight;
    final chartHeight = chartBottom - chartTop;
    final slotWidth = size.width / data.length;
    final barWidth = slotWidth * _barWidthFraction;

    _drawGrid(canvas, size, chartTop, chartBottom, maxVal);

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final progress = barProgressValues[i];
      final fullBarHeight = (d.value / maxVal) * chartHeight;
      final barHeight = fullBarHeight * progress;

      final left = i * slotWidth + (slotWidth - barWidth) / 2;
      final top = chartBottom - barHeight;

      // Don't draw a degenerate rect when the bar hasn't started growing yet.
      if (barHeight < 1) {
        _drawLabel(canvas, d.label, left + barWidth / 2, chartBottom + 4, size);
        continue;
      }

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        topLeft: Radius.circular(barBorderRadius),
        topRight: Radius.circular(barBorderRadius),
      );

      final barColor = d.color ?? theme.colorScheme.primary;
      final paint = Paint()
        ..color = barColor.withValues(alpha: progress.clamp(0.3, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);

      _drawLabel(canvas, d.label, left + barWidth / 2, chartBottom + 4, size);

      // Show value label only once the bar is mostly grown (avoids flicker
      // when the label would appear outside the canvas at small progress).
      if (showValues && d.value > 0 && progress > 0.6) {
        _drawValue(
          canvas,
          d.value.toString(),
          left + barWidth / 2,
          top - 2,
          // Fade the label in from 60 % progress to avoid a hard pop.
          opacity: ((progress - 0.6) / 0.4).clamp(0.0, 1.0),
        );
      }
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double chartTop,
    double chartBottom,
    int maxVal,
  ) {
    if (!showGrid) return;

    const gridLines = 4;
    final gridPaint = Paint()
      ..color = theme.colorScheme.outlineVariant.withValues(
        alpha: 0.5 * gridProgress,
      )
      ..strokeWidth = 1;

    for (var i = 0; i <= gridLines; i++) {
      final y = chartBottom - (i / gridLines) * (chartBottom - chartTop);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawLabel(Canvas canvas, String text, double cx, double y, Size size) {
    final span = TextSpan(
      text: text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width / data.length);

    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  void _drawValue(
    Canvas canvas,
    String text,
    double cx,
    double y, {
    required double opacity,
  }) {
    final span = TextSpan(
      text: text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: opacity),
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height));
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.barProgressValues != barProgressValues ||
      old.data != data ||
      old.theme != theme ||
      old.gridProgress != gridProgress;
}
