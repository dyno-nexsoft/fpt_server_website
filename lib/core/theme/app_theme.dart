import 'package:flutter/material.dart';

/// Every visual choice for the app lives here — widgets must rely on
/// [ThemeData] defaults rather than inline `style:`/`color:` overrides.
abstract final class AppTheme {
  /// The one legitimate style override in the app: the job log viewer needs
  /// a monospace font and Material has no dedicated text-theme slot for it.
  static const monospaceTextStyle = TextStyle(fontFamily: 'monospace');

  /// The other legitimate override: a filled action button (Cancel a build,
  /// Clear history, `ci.clean`) that deletes something. Every other button
  /// in the app stays on Material's plain primary-color default — this
  /// exists so the handful of genuinely irreversible-ish actions read as
  /// visually distinct from routine ones, not as decoration.
  static ButtonStyle destructiveButtonStyle(ColorScheme colorScheme) =>
      FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      );

  /// Icon-only counterpart, for a bare [IconButton] sitting beside other
  /// (non-destructive) icon actions in the same row — tints just the icon
  /// rather than filling a background, so it doesn't visually outweigh its
  /// neighbors the way a filled button would in that context.
  static ButtonStyle destructiveIconButtonStyle(ColorScheme colorScheme) =>
      IconButton.styleFrom(foregroundColor: colorScheme.error);

  /// Filled, fully-rounded fields (a "pill" search bar, and every other
  /// TextField in the app along with it) instead of Material's default
  /// underline — set once here rather than per-field.
  static const _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static final _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      for (final e in TargetPlatform.values)
        e: PredictiveBackPageTransitionsBuilder(),
    },
  );

  static final _expansionTileTheme = ExpansionTileThemeData(
    shape: LinearBorder.none,
    collapsedShape: LinearBorder.none,
  );

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: _inputDecorationTheme,
    pageTransitionsTheme: _pageTransitionsTheme,
    expansionTileTheme: _expansionTileTheme,
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.dark,
    ),
    inputDecorationTheme: _inputDecorationTheme,
    pageTransitionsTheme: _pageTransitionsTheme,
    expansionTileTheme: _expansionTileTheme,
  );
}
