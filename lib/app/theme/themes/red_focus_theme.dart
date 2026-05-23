import 'package:flutter/material.dart';
import '../app_theme_tokens.dart';

/// The default red-focus dark [ThemeData] for the app.
ThemeData buildRedFocusTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppThemeTokens.seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
