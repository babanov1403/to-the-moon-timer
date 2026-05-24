import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ship_style.dart';
import 'space_palette.dart';

/// Draws the pixel-art spaceship at [pos] rotated by [angle] (0 = pointing right).
void drawShip(
  Canvas canvas,
  Offset pos,
  double angle, {
  ShipStyle style = const ShipStyle(
    bodyColor: SpacePalette.shipBody,
    accentColor: SpacePalette.shipAccent,
    darkColor: SpacePalette.shipDark,
    exhaustHotColor: SpacePalette.exhaustOrange,
    exhaustCoreColor: SpacePalette.exhaustWhite,
  ),
}) {
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  canvas.rotate(angle);
  final p = Paint()..style = PaintingStyle.fill;
  const px = SpacePalette.px * 1.12;
  final pixels = [
    (4, 0, style.accentColor),
    (3, 0, style.bodyColor),
    (2, -1, style.bodyColor),
    (1, -1, style.accentColor),
    (0, -1, style.bodyColor),
    (-1, -2, style.bodyColor),
    (-2, -2, style.darkColor),
    (2, 1, style.bodyColor),
    (1, 1, style.accentColor),
    (0, 1, style.bodyColor),
    (-1, 2, style.bodyColor),
    (-2, 2, style.darkColor),
    (2, 0, style.bodyColor),
    (1, 0, style.bodyColor),
    (0, 0, style.accentColor),
    (-1, 0, style.bodyColor),
    (-2, 0, style.darkColor),
    (-3, 0, style.darkColor),
  ];
  for (final (x, y, c) in pixels) {
    p.color = c;
    canvas.drawRect(
      Rect.fromLTWH(x * px - px / 2, y * px - px / 2, px, px),
      p,
    );
  }
  canvas.restore();
}

/// Draws exhaust particles behind the ship at [pos] rotated by [angle].
void drawExhaust(
  Canvas canvas,
  Offset pos,
  double angle,
  double phase, {
  double intensity = 1.0,
  ShipStyle style = const ShipStyle(
    bodyColor: SpacePalette.shipBody,
    accentColor: SpacePalette.shipAccent,
    darkColor: SpacePalette.shipDark,
    exhaustHotColor: SpacePalette.exhaustOrange,
    exhaustCoreColor: SpacePalette.exhaustWhite,
  ),
}) {
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  canvas.rotate(angle);
  final rng = math.Random((phase * 100).toInt());
  final p = Paint()..style = PaintingStyle.fill;
  const px = SpacePalette.px * 1.12;
  final count = (8 * intensity).round().clamp(3, 12);
  for (int i = 0; i < count; i++) {
    final t = i / count;
    final ex = -(px * 3 + t * px * 6 + rng.nextDouble() * px * 2);
    final ey = (rng.nextDouble() - 0.5) * px * 3;
    final c = Color.lerp(style.exhaustCoreColor, style.exhaustHotColor, t)!
        .withValues(alpha: (1.0 - t * 0.7) * intensity);
    p.color = c;
    final sz = px * (1.0 - t * 0.5);
    canvas.drawRect(
        Rect.fromCenter(center: Offset(ex, ey), width: sz, height: sz), p);
  }
  canvas.restore();
}

double lerpAngle(double a, double b, double t) {
  double diff = b - a;
  while (diff > math.pi) {
    diff -= 2 * math.pi;
  }
  while (diff < -math.pi) {
    diff += 2 * math.pi;
  }
  return a + diff * t;
}
