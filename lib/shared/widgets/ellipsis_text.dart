import 'package:flutter/material.dart';

/// One line, ellipsized, full text on hover — for a cell or label whose
/// content can run arbitrarily long (a raw shell command, a joined params
/// list) and would otherwise wrap and blow out its row's height.
class EllipsisText extends StatelessWidget {
  const EllipsisText(this.text, {super.key, this.tooltip, this.maxWidth});

  final String text;

  /// Defaults to [text] itself; pass a different string when the hover
  /// tooltip should format the same content differently (e.g. one entry per
  /// line instead of the comma-joined line the cell shows).
  final String? tooltip;

  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final child = Text(text, overflow: TextOverflow.ellipsis, maxLines: 1);
    return Tooltip(
      message: tooltip ?? text,
      child: maxWidth != null ? SizedBox(width: maxWidth, child: child) : child,
    );
  }
}
