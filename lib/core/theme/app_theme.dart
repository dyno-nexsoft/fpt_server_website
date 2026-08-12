import 'package:flutter/material.dart';

/// Every visual choice for the app lives here — widgets must rely on
/// [ThemeData] defaults rather than inline `style:`/`color:` overrides.
abstract final class AppTheme {
  /// The one legitimate style override in the app: the job log viewer needs
  /// a monospace font and Material has no dedicated text-theme slot for it.
  static const monospaceTextStyle = TextStyle(fontFamily: 'monospace');

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

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.light(),
    inputDecorationTheme: _inputDecorationTheme,
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.dark(),
    inputDecorationTheme: _inputDecorationTheme,
  );
}
