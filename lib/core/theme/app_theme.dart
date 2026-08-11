import 'package:flutter/material.dart';

/// Every visual choice for the app lives here — widgets must rely on
/// [ThemeData] defaults rather than inline `style:`/`color:` overrides.
abstract final class AppTheme {
  /// The one legitimate style override in the app: the job log viewer needs
  /// a monospace font and Material has no dedicated text-theme slot for it.
  static const monospaceTextStyle = TextStyle(fontFamily: 'monospace');

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    navigationRailTheme: const NavigationRailThemeData(
      labelType: NavigationRailLabelType.all,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      labelType: NavigationRailLabelType.all,
    ),
  );
}
