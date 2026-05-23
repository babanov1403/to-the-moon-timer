import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'space_palette.dart';

/// Draws the pixel-art spaceship at [pos] rotated by [angle] (0 = pointing right).
void drawShip(Canvas canvas, Offset pos, double angle) {
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  canvas.rotate(angle);
  final p = Paint()..style = PaintingStyle.fill;
  const px = SpacePalette.px;
  const pixels = [
    (4, 0, SpacePalette.shipAccent),
    (3, 0, SpacePalette.shipBody),
    (2, -1, SpacePalette.shipBody),
    (1, -1, SpacePalette.shipAccent),
    (0, -1, SpacePalette.shipBody),
    (-1, -2, SpacePalette.shipBody),
    (-2, -2, SpacePalette.shipDark),
    (2, 1, SpacePalette.shipBody),
    (1, 1, SpacePalette.shipAccent),
    (0, 1, SpacePalette.shipBody),
    (-1, 2, SpacePalette.shipBody),
    (-2, 2, SpacePalette.shipDark),
    (2, 0, SpacePalette.shipBody),
    (1, 0, SpacePalette.shipBody),
    (0, 0, SpacePalette.shipAccent),
    (-1, 0, SpacePalette.shipBody),
    (-2, 0, SpacePalette.shipDark),
    (-3, 0, SpacePalette.shipDark),
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
void drawExhaust(Canvas canvas, Offset pos, double angle, double phase,
    {double intensity = 1.0}) {
  canvas.save();
  canvas.translate(pos.dx, pos.dy);
  canvas.rotate(angle);
  final rng = math.Random((phase * 100).toInt());
  final p = Paint()..style = PaintingStyle.fill;
  const px = SpacePalette.px;
  final count = (8 * intensity).round().clamp(3, 12);
  for (int i = 0; i < count; i++) {
    final t = i / count;
    final ex = -(px * 3 + t * px * 6 + rng.nextDouble() * px * 2);
    final ey = (rng.nextDouble() - 0.5) * px * 3;
    final c =
        Color.lerp(SpacePalette.exhaustWhite, SpacePalette.exhaustOrange, t)!
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
