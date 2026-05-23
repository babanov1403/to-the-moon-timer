import 'package:flutter/material.dart';

/// Mindful cosmic color palette for the spaceship scene.
abstract final class SpacePalette {
  static const Color spaceBg = Color(0xFF071126);
  static const Color spaceBgAlt = Color(0xFF14224A);
  static const Color nebulaPurple = Color(0xFF5D52B8);
  static const Color nebulaMagenta = Color(0xFFAA5CB8);
  static const Color nebulaBlue = Color(0xFF3BAAC8);
  static const Color starDim = Color(0xFF59607F);
  static const Color starBright = Color(0xFFE7E7FF);
  static const Color starHot = Color(0xFFF1D76A);
  static const Color starCold = Color(0xFF8FD7E6);

  static const Color shipBody = Color(0xFF38BFD4);
  static const Color shipAccent = Color(0xFFF1D76A);
  static const Color shipDark = Color(0xFF356DCC);

  static const Color exhaustOrange = Color(0xFFE67D45);
  static const Color exhaustWhite = Color(0xFFF4F3FF);
  static const Color exhaustPlasma = Color(0xFFB778C9);

  /// One "pixel" in logical pixels.
  static const double px = 3.0;
}
