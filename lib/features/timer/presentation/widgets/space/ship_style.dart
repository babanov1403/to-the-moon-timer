import 'package:flutter/material.dart';

/// Mode-level styling for the spaceship renderer.
class ShipStyle {
  const ShipStyle({
    required this.bodyColor,
    required this.accentColor,
    required this.darkColor,
    required this.exhaustHotColor,
    required this.exhaustCoreColor,
    this.scale = 1.0,
  });

  final Color bodyColor;
  final Color accentColor;
  final Color darkColor;
  final Color exhaustHotColor;
  final Color exhaustCoreColor;
  final double scale;
}
