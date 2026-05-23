import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'planet_data.dart';
import 'space_palette.dart';

/// Draws a pixel-art planet centered at [center] with [alpha] opacity.
void drawPlanet(Canvas canvas, PlanetData planet, Offset center, double alpha) {
  if (alpha <= 0) return;

  final double r = planet.radius;
  final double px = SpacePalette.px;

  _drawAtmosphere(canvas, planet, center, alpha);
  if (planet.hasRings) _drawRings(canvas, planet, center, alpha, front: false);
  _drawPlanetBody(canvas, planet, center, alpha);
  _drawSurfaceDetails(canvas, planet, center, alpha);
  _drawHighlight(canvas, planet, center, alpha);
  if (planet.hasRings) _drawRings(canvas, planet, center, alpha, front: true);

  // A small grounding shadow helps the ship read as parked on weird worlds.
  final shadowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withValues(alpha: 0.18 * alpha);
  canvas.drawRect(
    Rect.fromCenter(
      center: Offset(center.dx + r * 0.22, center.dy + r * 0.72),
      width: r * 0.78,
      height: px,
    ),
    shadowPaint,
  );
}

void _drawAtmosphere(
    Canvas canvas, PlanetData planet, Offset center, double alpha) {
  final px = SpacePalette.px;
  final p = Paint()..style = PaintingStyle.fill;
  for (var i = 3; i >= 1; i--) {
    final radius = planet.radius + i * px * 1.45;
    p.color =
        planet.glowColor.withValues(alpha: alpha * (0.07 + (3 - i) * 0.03));
    _drawPixelCircle(canvas, center, radius, px, p);
  }
}

void _drawPlanetBody(
    Canvas canvas, PlanetData planet, Offset center, double alpha) {
  final paint = Paint()..style = PaintingStyle.fill;
  final double r = planet.radius;
  final double px = SpacePalette.px;

  for (double dy = -r; dy <= r; dy += px) {
    for (double dx = -r; dx <= r; dx += px) {
      if (math.sqrt(dx * dx + dy * dy) > r) continue;
      paint.color = _surfaceColor(planet, dx, dy, r).withValues(alpha: alpha);
      canvas.drawRect(
        Rect.fromLTWH(center.dx + dx, center.dy + dy, px, px),
        paint,
      );
    }
  }
}

Color _surfaceColor(PlanetData planet, double dx, double dy, double r) {
  final shade = ((dx + dy) / (r * 2) + 0.5).clamp(0.0, 1.0);
  final noise = _hash01(planet.seed, dx, dy);

  switch (planet.style) {
    case PlanetStyle.lava:
      final river = math.sin(dx * 0.23 + dy * 0.39 + planet.seed) +
          math.sin(dx * 0.51 - dy * 0.17);
      if (river > 1.18 || noise > 0.92) return planet.accentColor;
      if (river > 0.86) {
        return Color.lerp(planet.colorA, planet.accentColor, 0.48)!;
      }
      return Color.lerp(planet.colorA, planet.colorB, shade)!;
    case PlanetStyle.iceMoon:
      final crack = (dx + dy * 1.55 + planet.seed % 17).abs() % 23;
      if (crack < 2.0 || noise > 0.96) return planet.accentColor;
      return Color.lerp(planet.colorA, planet.colorB, shade * 0.72)!;
    case PlanetStyle.toxic:
      final bubble = math.sin(dx * 0.31 + planet.seed) * math.cos(dy * 0.27);
      if (bubble > 0.74 || noise > 0.9) return planet.accentColor;
      return Color.lerp(planet.colorA, planet.colorB, shade)!;
    case PlanetStyle.gasGiant:
    case PlanetStyle.ringed:
    case PlanetStyle.desert:
    case PlanetStyle.candy:
    case PlanetStyle.storm:
      final band = ((dy / math.max(1, r)) * planet.bandCount + 4.0).floor();
      final wobble = math.sin(dx * 0.17 + planet.seed * 0.01) * 0.14;
      final bandMix = ((band.isEven ? 0.22 : 0.78) + wobble).clamp(0.0, 1.0);
      final base = Color.lerp(planet.colorA, planet.colorB, bandMix)!;
      if (planet.style == PlanetStyle.storm &&
          (dx + dy * 0.45 + planet.seed).abs() % 31 < 2.2) {
        return planet.accentColor;
      }
      if (noise > 0.94) return Color.lerp(base, planet.accentColor, 0.55)!;
      return Color.lerp(base, Colors.black, shade * 0.18)!;
    case PlanetStyle.craterMoon:
      if (noise > 0.93) return planet.craterColor;
      return Color.lerp(planet.colorA, planet.colorB, shade)!;
    case PlanetStyle.cyberGrid:
      final gridX = (dx + planet.seed).abs() % 14 < 2;
      final gridY = (dy + planet.seed * 0.5).abs() % 14 < 2;
      if (gridX || gridY) return planet.accentColor;
      if (noise > 0.96) return planet.colorA;
      return Color.lerp(planet.colorA, planet.colorB, shade * 0.86)!;
    case PlanetStyle.crystal:
      final facet = (dx * 0.9 - dy * 1.35 + planet.seed).abs() % 24;
      if (facet < 2.4 || noise > 0.965) return planet.accentColor;
      return Color.lerp(planet.colorA, planet.colorB, shade)!;
    case PlanetStyle.neonOcean:
      final wave = math.sin(dx * 0.28 + planet.seed) + math.sin(dy * 0.34);
      if (wave > 1.25 || noise > 0.965) return planet.accentColor;
      return Color.lerp(planet.colorA, planet.colorB, shade * 0.9)!;
    case PlanetStyle.jungle:
      final canopy = math.sin(dx * 0.42 + planet.seed) * math.sin(dy * 0.28);
      if (canopy > 0.48 || noise > 0.93) return planet.accentColor;
      return Color.lerp(planet.colorA, planet.colorB, shade)!;
    case PlanetStyle.voidPlanet:
      if (noise > 0.975) return planet.accentColor;
      if (noise < 0.045) return Colors.black;
      return Color.lerp(planet.colorA, planet.colorB, shade * 1.15)!;
    case PlanetStyle.metalWorld:
      final panelX = (dx + r + planet.seed).abs() % 18 < 1.8;
      final panelY = (dy + r + planet.seed * 0.3).abs() % 16 < 1.8;
      if (panelX || panelY) return planet.craterColor;
      if (noise > 0.965) return planet.accentColor;
      return Color.lerp(planet.colorA, planet.colorB, shade * 0.95)!;
    case PlanetStyle.deathStar:
      final trench = dy.abs() < SpacePalette.px * 1.4;
      final panelX = (dx + r + planet.seed).abs() % 13 < 1.4;
      final panelY = (dy + r + planet.seed * 0.7).abs() % 11 < 1.4;
      if (trench) return planet.craterColor;
      if ((panelX || panelY) && noise > 0.22) return planet.craterColor;
      return Color.lerp(planet.colorA, planet.colorB, shade)!;
  }
}

void _drawSurfaceDetails(
  Canvas canvas,
  PlanetData planet,
  Offset center,
  double alpha,
) {
  final rng = math.Random(planet.seed ^ 0x5F3759DF);
  final p = Paint()..style = PaintingStyle.fill;
  final count = switch (planet.style) {
    PlanetStyle.lava => 5,
    PlanetStyle.iceMoon => 7,
    PlanetStyle.toxic => 8,
    PlanetStyle.gasGiant => 4,
    PlanetStyle.ringed => 3,
    PlanetStyle.craterMoon => 9,
    PlanetStyle.cyberGrid => 6,
    PlanetStyle.crystal => 8,
    PlanetStyle.neonOcean => 5,
    PlanetStyle.desert => 5,
    PlanetStyle.jungle => 9,
    PlanetStyle.voidPlanet => 6,
    PlanetStyle.candy => 4,
    PlanetStyle.storm => 6,
    PlanetStyle.metalWorld => 7,
    PlanetStyle.deathStar => 0,
  };

  for (var i = 0; i < count; i++) {
    final angle = rng.nextDouble() * math.pi * 2;
    final distance = rng.nextDouble() * planet.radius * 0.62;
    final detailCenter =
        center + Offset(math.cos(angle), math.sin(angle)) * distance;
    final size = SpacePalette.px * (1.2 + rng.nextInt(3));

    switch (planet.style) {
      case PlanetStyle.lava:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.8);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: size * 1.8,
            height: SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.iceMoon:
        p.color = planet.craterColor.withValues(alpha: alpha * 0.5);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: size * 1.7,
            height: SpacePalette.px,
          ),
          p,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter + Offset(size * 0.35, size * 0.35),
            width: SpacePalette.px,
            height: size,
          ),
          p,
        );
      case PlanetStyle.toxic:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.58);
        _drawPixelCircle(canvas, detailCenter, size * 0.72, SpacePalette.px, p);
      case PlanetStyle.gasGiant:
      case PlanetStyle.ringed:
      case PlanetStyle.desert:
      case PlanetStyle.candy:
      case PlanetStyle.storm:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.58);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: size * 2.4,
            height: SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.craterMoon:
        p.color = planet.craterColor.withValues(alpha: alpha * 0.62);
        _drawPixelCircle(canvas, detailCenter, size * 0.8, SpacePalette.px, p);
        p.color = Colors.white.withValues(alpha: alpha * 0.13);
        canvas.drawRect(
          Rect.fromLTWH(
            detailCenter.dx - size * 0.42,
            detailCenter.dy - size * 0.42,
            SpacePalette.px,
            SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.cyberGrid:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.7);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: size * 0.9,
            height: size * 0.9,
          ),
          p,
        );
      case PlanetStyle.crystal:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.62);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: SpacePalette.px,
            height: size * 2.2,
          ),
          p,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter + Offset(size * 0.42, 0),
            width: size * 1.5,
            height: SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.neonOcean:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.54);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: size * 2.8,
            height: SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.jungle:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.56);
        _drawPixelCircle(canvas, detailCenter, size * 0.7, SpacePalette.px, p);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter + Offset(0, size * 0.5),
            width: SpacePalette.px,
            height: size,
          ),
          p,
        );
      case PlanetStyle.voidPlanet:
        p.color = planet.accentColor.withValues(alpha: alpha * 0.68);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: SpacePalette.px,
            height: SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.metalWorld:
        p.color = planet.craterColor.withValues(alpha: alpha * 0.56);
        canvas.drawRect(
          Rect.fromCenter(
              center: detailCenter, width: size * 1.8, height: size),
          p,
        );
        p.color = planet.accentColor.withValues(alpha: alpha * 0.74);
        canvas.drawRect(
          Rect.fromCenter(
            center: detailCenter,
            width: SpacePalette.px,
            height: SpacePalette.px,
          ),
          p,
        );
      case PlanetStyle.deathStar:
        break;
    }
  }

  if (planet.style == PlanetStyle.deathStar) {
    _drawDeathStarDetails(canvas, planet, center, alpha);
  }
}

void _drawDeathStarDetails(
  Canvas canvas,
  PlanetData planet,
  Offset center,
  double alpha,
) {
  final px = SpacePalette.px;
  final r = planet.radius;
  final p = Paint()..style = PaintingStyle.fill;

  p.color = planet.craterColor.withValues(alpha: alpha * 0.86);
  canvas.drawRect(
    Rect.fromCenter(center: center, width: r * 1.62, height: px * 1.4),
    p,
  );

  final dishCenter = center + Offset(-r * 0.36, -r * 0.24);
  p.color = planet.craterColor.withValues(alpha: alpha * 0.72);
  _drawPixelCircle(canvas, dishCenter, r * 0.25, px, p);
  p.color = planet.colorB.withValues(alpha: alpha * 0.8);
  _drawPixelCircle(canvas, dishCenter, r * 0.14, px, p);
  p.color = planet.accentColor.withValues(alpha: alpha * 0.92);
  canvas.drawRect(
    Rect.fromCenter(center: dishCenter, width: px * 1.4, height: px * 1.4),
    p,
  );

  p.color = Colors.white.withValues(alpha: alpha * 0.2);
  canvas.drawRect(
    Rect.fromCenter(
      center: center + Offset(r * 0.2, -r * 0.42),
      width: r * 0.36,
      height: px,
    ),
    p,
  );
  canvas.drawRect(
    Rect.fromCenter(
      center: center + Offset(r * 0.3, r * 0.25),
      width: r * 0.28,
      height: px,
    ),
    p,
  );
}

void _drawHighlight(
    Canvas canvas, PlanetData planet, Offset center, double alpha) {
  final px = SpacePalette.px;
  final r = planet.radius;
  canvas.drawRect(
    Rect.fromLTWH(
      center.dx - r * 0.45,
      center.dy - r * 0.48,
      px * 2,
      px * 2,
    ),
    Paint()
      ..color = planet.accentColor.withValues(alpha: 0.32 * alpha)
      ..style = PaintingStyle.fill,
  );
  canvas.drawRect(
    Rect.fromLTWH(
      center.dx - r * 0.28,
      center.dy - r * 0.56,
      px,
      px,
    ),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.32 * alpha)
      ..style = PaintingStyle.fill,
  );
}

void _drawRings(Canvas canvas, PlanetData planet, Offset center, double alpha,
    {required bool front}) {
  final p = Paint()..style = PaintingStyle.fill;
  final px = SpacePalette.px;
  final outerRx = planet.radius * 1.72;
  final outerRy = planet.radius * 0.46;
  final innerRx = planet.radius * 1.12;
  final innerRy = planet.radius * 0.28;

  for (double x = -outerRx; x <= outerRx; x += px) {
    for (double y = -outerRy; y <= outerRy; y += px) {
      final outer =
          (x * x) / (outerRx * outerRx) + (y * y) / (outerRy * outerRy);
      final inner =
          (x * x) / (innerRx * innerRx) + (y * y) / (innerRy * innerRy);
      if (outer > 1 || inner < 1) continue;
      if (front && y < 0) continue;
      if (!front && y >= 0) continue;
      if (_hash01(planet.seed + 97, x, y) < 0.18) continue;

      final ringShade = ((x / outerRx) + 1) * 0.5;
      p.color = Color.lerp(planet.ringColor, planet.accentColor, ringShade)!
          .withValues(alpha: alpha * (front ? 0.72 : 0.42));
      canvas.drawRect(
        Rect.fromLTWH(center.dx + x, center.dy + y, px, px),
        p,
      );
    }
  }
}

void _drawPixelCircle(
    Canvas canvas, Offset center, double radius, double px, Paint paint) {
  for (double dy = -radius; dy <= radius; dy += px) {
    for (double dx = -radius; dx <= radius; dx += px) {
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance <= radius && distance >= radius - px * 1.6) {
        canvas.drawRect(
            Rect.fromLTWH(center.dx + dx, center.dy + dy, px, px), paint);
      }
    }
  }
}

double _hash01(int seed, double x, double y) {
  final n = math.sin(seed * 12.9898 + x * 78.233 + y * 37.719) * 43758.5453;
  return n - n.floorToDouble();
}
