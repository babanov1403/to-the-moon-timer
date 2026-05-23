import 'package:flutter/material.dart';

/// Retro arcade color palette for the spaceship scene.
abstract final class SpacePalette {
  static const Color spaceBg = Color(0xFF070015);
  static const Color spaceBgAlt = Color(0xFF13002F);
  static const Color nebulaPurple = Color(0xFF7A1BFF);
  static const Color nebulaMagenta = Color(0xFFFF2BD6);
  static const Color nebulaBlue = Color(0xFF00D7FF);
  static const Color starDim = Color(0xFF4F4A78);
  static const Color starBright = Color(0xFFE9E5FF);
  static const Color starHot = Color(0xFFFFF05A);
  static const Color starCold = Color(0xFF53F4FF);

  static const Color shipBody = Color(0xFF00E5FF);
  static const Color shipAccent = Color(0xFFFFFF2E);
  static const Color shipDark = Color(0xFF006BFF);

  static const Color exhaustOrange = Color(0xFFFF3D00);
  static const Color exhaustWhite = Color(0xFFFFFFFF);
  static const Color exhaustPlasma = Color(0xFFFF2BD6);

  /// One "pixel" in logical pixels.
  static const double px = 3.0;
}
