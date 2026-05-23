import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'space_palette.dart';

/// Draws a pixel-art starfield onto [canvas].
///
/// [drift] works like a camera offset: when it changes, stars wrap around the
/// viewport and create the feeling that the ship is moving through space.
void drawStars(
  Canvas canvas,
  Size size,
  double twinklePhase, {
  Offset drift = Offset.zero,
  bool dimmed = false,
}) {
  final rng = math.Random(42);
  final paint = Paint()..style = PaintingStyle.fill;

  for (int i = 0; i < 92; i++) {
    final baseX = rng.nextDouble() * size.width;
    final baseY = rng.nextDouble() * size.height;
    final x = _wrap(baseX + drift.dx * (0.45 + (i % 3) * 0.25), size.width);
    final y = _wrap(baseY + drift.dy * (0.45 + (i % 4) * 0.2), size.height);
    final twinkle = math.sin(twinklePhase * math.pi * 2 + i * 0.7);
    final bright = i % 5 == 0;
    final hot = i % 17 == 0;
    final cold = i % 13 == 0;
    final alpha = dimmed
        ? (bright ? 0.22 : 0.12)
        : (0.42 + twinkle * 0.34).clamp(0.12, 1.0);
    final color = hot
        ? SpacePalette.starHot
        : cold
            ? SpacePalette.starCold
            : bright
                ? SpacePalette.starBright
                : SpacePalette.starDim;
    paint.color = color.withValues(alpha: alpha);
    final r = bright ? SpacePalette.px * 0.85 : SpacePalette.px * 0.42;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y), width: r, height: r),
      paint,
    );

    if (!dimmed && i % 29 == 0) {
      paint.color = color.withValues(alpha: alpha * 0.42);
      canvas.drawRect(
        Rect.fromLTWH(x - r * 2.2, y, r * 1.7, SpacePalette.px * 0.36),
        paint,
      );
    }
  }

  if (!dimmed) _drawPixelComet(canvas, size, twinklePhase, drift);
}

void _drawPixelComet(Canvas canvas, Size size, double phase, Offset drift) {
  const px = SpacePalette.px;
  const visibleCyclePortion = 0.62;
  const headExitPadding = px * 14;
  const tailExitPadding = px * 16;

  final cycleT = phase % 1.0;
  if (cycleT > visibleCyclePortion) return;

  final p = Paint()..style = PaintingStyle.fill;
  final travelT = Curves.easeInOutSine.transform(cycleT / visibleCyclePortion);
  final orbit = travelT * math.pi * 2;
  final head = Offset(
    -tailExitPadding +
        travelT * (size.width + headExitPadding + tailExitPadding),
    size.height * 0.18 + math.sin(orbit) * size.height * 0.08 + drift.dy * 0.08,
  );
  final colors = [
    SpacePalette.starBright.withValues(alpha: 0.95),
    SpacePalette.nebulaMagenta.withValues(alpha: 0.62),
    SpacePalette.nebulaBlue.withValues(alpha: 0.38),
  ];

  for (var i = 0; i < 8; i++) {
    p.color = colors[(i / 3).floor().clamp(0, colors.length - 1)];
    final center = Offset(head.dx - i * px * 1.35, head.dy + i * px * 0.34);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: math.max(px * 0.7, px * (1.25 - i * 0.08)),
        height: math.max(px * 0.45, px * (1.0 - i * 0.07)),
      ),
      p,
    );
  }
}

double _wrap(double value, double max) {
  final wrapped = value % max;
  return wrapped < 0 ? wrapped + max : wrapped;
}
