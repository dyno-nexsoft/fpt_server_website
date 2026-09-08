part of 'log_viewer.dart';

/// Everything [LogViewer] has to measure, and the cache that keeps measuring
/// proportional to what changed rather than to how much log there is.
///
/// Owned by the widget's [State], not rebuilt with it: [build] runs once per
/// arriving chunk, so a measurement repeated there is repeated thousands of
/// times over a build.
class _LogMetrics {
  /// Measured as a run rather than as one glyph: a single character's width
  /// carries enough rounding error to drift a visible amount once it is
  /// multiplied out across a 200-column line.
  static const _advanceSample = '0000000000';

  final _painter = TextPainter(textDirection: TextDirection.ltr);

  TextStyle? _style;
  TextScaler _textScaler = TextScaler.noScaling;

  /// Advance of one plain-ASCII character, and the height every row is
  /// forced to by the strut. Measured together on one throwaway layout — the
  /// strut's own contribution (leading, fallback-font ascent) is not worth
  /// hand-deriving.
  double _charWidth = 0;
  double rowHeight = 0;

  /// Widest line in `lines[0.._scannedCount)` of [_scannedList], in pixels.
  ///
  /// Cached in pixels rather than characters because a line is not always as
  /// wide as its character count suggests — see [_measure]. That makes the
  /// cache depend on the text style, so a style change throws it away.
  List<String>? _scannedList;
  int _scannedCount = 0;
  double _maxScannedWidth = 0;

  /// Brings every cached measurement up to date for the current style and
  /// the current contents. Cheap to call on every build: the common case is
  /// an unchanged style plus a handful of appended lines.
  void sync({
    required List<String> lines,
    required String pendingLine,
    required TextStyle style,
    required StrutStyle strutStyle,
    required TextScaler textScaler,
  }) {
    _syncStyle(style, strutStyle, textScaler);
    // A different list is a different log (a one-shot fetch, a manual
    // refresh); the same list can only have grown, because callers treat it
    // as append-only. So the maximum can only go up, and only the new tail
    // needs looking at.
    if (!identical(lines, _scannedList)) {
      _scannedList = lines;
      _scannedCount = 0;
      _maxScannedWidth = 0;
    }
    for (var i = _scannedCount; i < lines.length; i++) {
      _maxScannedWidth = math.max(_maxScannedWidth, _measure(lines[i]));
    }
    _scannedCount = lines.length;
    // The pending line is still growing, so it is measured fresh each build
    // and deliberately kept out of the cache until it is committed.
    _contentWidth = math.max(_maxScannedWidth, _measure(pendingLine));
  }

  double _contentWidth = 0;

  /// Width the content column has to reserve for the widest line in the log.
  double get contentWidth => _contentWidth.ceilToDouble() + 1;

  /// Width of a column holding [characters] plain-ASCII characters — the
  /// gutter, whose contents are always digits.
  ///
  /// Rounded up: a fractional advance multiplied out can land a hair short
  /// of the real ink and clip the last glyph, and over-reserving a pixel
  /// only makes the horizontal scroll extent a pixel longer.
  double columnWidth(int characters) =>
      (characters * _charWidth).ceilToDouble() + 1;

  void _syncStyle(TextStyle style, StrutStyle strutStyle, TextScaler scaler) {
    if (_style == style && _textScaler == scaler) return;
    _style = style;
    _textScaler = scaler;
    _painter
      ..textScaler = scaler
      ..strutStyle = strutStyle
      ..text = TextSpan(text: _advanceSample, style: style)
      ..layout();
    _charWidth = _painter.width / _advanceSample.length;
    rowHeight = _painter.height;
    // Cached widths were in the old style's pixels.
    _scannedList = null;
  }

  /// Width of one line.
  ///
  /// The fast path multiplies the character count by one character's
  /// advance, so no line's own string is laid out at all — sound for
  /// printable ASCII in a monospace font, which is what a build log almost
  /// entirely is. Anything else is measured for real: a tab has no
  /// predictable advance, and a CJK ideograph or an emoji is typically
  /// *double* width, so a line carrying them is wider than its length
  /// implies and would otherwise have its tail clipped off unreachably.
  double _measure(String line) {
    if (line.isEmpty) return 0;
    if (_isPlainAscii(line)) return line.length * _charWidth;
    _painter
      ..text = TextSpan(text: line, style: _style)
      ..layout();
    return _painter.width;
  }

  static bool _isPlainAscii(String line) {
    for (var i = 0; i < line.length; i++) {
      final unit = line.codeUnitAt(i);
      if (unit < 0x20 || unit > 0x7e) return false;
    }
    return true;
  }

  void dispose() => _painter.dispose();
}
