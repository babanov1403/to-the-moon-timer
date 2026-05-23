import 'package:flutter/material.dart';

/// Raw color/size tokens for the default red-focus dark theme.
abstract final class AppThemeTokens {
  // ── Background ──────────────────────────────────────────────────────────────
  static const Color backgroundDeep = Color(0xFF1A1A2E);
  static const Color sheetBackground = Color(0xFF1C1C1E);
  static const Color surfaceSubtle = Color(0xFF2C2C2E);

  // ── Accent ──────────────────────────────────────────────────────────────────
  static const Color primaryRed = Color(0xFFE53935);
  static const Color iosBlue = Color(0xFF0A84FF);
  static const Color iosOrange = Color(0xFFFF9F0A);

  // ── Text / icon ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color divider = Color(0xFF3A3A3C);

  // ── Seed for MaterialApp theme ───────────────────────────────────────────────
  static const Color seedColor = primaryRed;
}
