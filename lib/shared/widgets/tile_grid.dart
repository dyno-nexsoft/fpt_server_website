import 'package:flutter/material.dart';

/// Lays [children] out in as many equal-width columns as fit — one card per
/// tile, e.g. an owner, a log, a maintenance action.
///
/// A [Wrap] alone leaves each tile at its own intrinsic width, so two cards
/// on a wide screen sit pinned to the left with the rest of the row empty.
/// This instead measures the available width and divides it evenly among
/// however many columns fit at [minTileWidth] or wider, so a two-tile row
/// spans the full width on desktop and collapses to one column on mobile —
/// no per-page choice of "how many columns" needed.
class TileGrid extends StatelessWidget {
  const TileGrid({
    super.key,
    required this.children,
    this.minTileWidth = 360,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;

  /// A column narrower than this is judged too cramped for the content
  /// (typically a [ListTile] with a subtitle) — chosen empirically against
  /// [SystemPanel]'s longest description, the widest content any tile here
  /// carries.
  final double minTileWidth;

  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + spacing) / (minTileWidth + spacing))
                .floor()
                .clamp(1, children.length);
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
