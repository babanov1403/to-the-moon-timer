import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Visual archetype used by the pixel-art planet renderer.
enum PlanetStyle {
  lava,
  iceMoon,
  toxic,
  gasGiant,
  ringed,
  craterMoon,
  cyberGrid,
  crystal,
  neonOcean,
  desert,
  jungle,
  voidPlanet,
  candy,
  storm,
  metalWorld,
  deathStar,
}

/// Immutable description of a procedurally generated planet.
class PlanetData {
  const PlanetData({
    required this.colorA,
    required this.colorB,
    required this.accentColor,
    required this.glowColor,
    required this.craterColor,
    required this.ringColor,
    required this.radius,
    required this.seed,
    required this.style,
    required this.hasRings,
    required this.bandCount,
  });

  final Color colorA;
  final Color colorB;
  final Color accentColor;
  final Color glowColor;
  final Color craterColor;
  final Color ringColor;
  final double radius;

  /// Seed for deterministic pixel-art surface details.
  final int seed;
  final PlanetStyle style;
  final bool hasRings;
  final int bandCount;

  /// Generates a random planet from [seed].
  factory PlanetData.generate(int seed) {
    final rng = math.Random(seed);
    final style = PlanetStyle.values[rng.nextInt(PlanetStyle.values.length)];
    final radius = 24.0 + rng.nextDouble() * 17.0;

    final spec = switch (style) {
      PlanetStyle.lava => (
          colorA: const Color(0xFFFF4A1C),
          colorB: const Color(0xFF4B0618),
          accent: const Color(0xFFFFF04A),
          glow: const Color(0xFFFF2D00),
          crater: const Color(0xFF21000A),
          ring: const Color(0xFFFF8A00),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.iceMoon => (
          colorA: const Color(0xFFE9FFFF),
          colorB: const Color(0xFF3D8CFF),
          accent: const Color(0xFFB8F7FF),
          glow: const Color(0xFF69DFFF),
          crater: const Color(0xFF7AA6E8),
          ring: const Color(0xFFD8FBFF),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.toxic => (
          colorA: const Color(0xFFB6FF00),
          colorB: const Color(0xFF04451A),
          accent: const Color(0xFF39FF88),
          glow: const Color(0xFF7CFF00),
          crater: const Color(0xFF012D12),
          ring: const Color(0xFFCCFF33),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.gasGiant => (
          colorA: const Color(0xFFFFB84D),
          colorB: const Color(0xFF8F2BFF),
          accent: const Color(0xFFFF49C6),
          glow: const Color(0xFFFFB000),
          crater: const Color(0xFF41137A),
          ring: const Color(0xFFFFE05A),
          rings: false,
          bands: 5,
        ),
      PlanetStyle.ringed => (
          colorA: const Color(0xFFFF4FD8),
          colorB: const Color(0xFF2514A8),
          accent: const Color(0xFFFFE65C),
          glow: const Color(0xFFC741FF),
          crater: const Color(0xFF190B5B),
          ring: const Color(0xFFFFF078),
          rings: true,
          bands: 3,
        ),
      PlanetStyle.craterMoon => (
          colorA: const Color(0xFFD7C9FF),
          colorB: const Color(0xFF6C5A92),
          accent: const Color(0xFFFFFFFF),
          glow: const Color(0xFFB78BFF),
          crater: const Color(0xFF3D315D),
          ring: const Color(0xFFA591D9),
          rings: rng.nextBool(),
          bands: 0,
        ),
      PlanetStyle.cyberGrid => (
          colorA: const Color(0xFF1AFBFF),
          colorB: const Color(0xFF08114D),
          accent: const Color(0xFFFF3DF2),
          glow: const Color(0xFF00E5FF),
          crater: const Color(0xFF03102C),
          ring: const Color(0xFF78FFF2),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.crystal => (
          colorA: const Color(0xFFE8D7FF),
          colorB: const Color(0xFF4A19A8),
          accent: const Color(0xFF66FFF0),
          glow: const Color(0xFFB45CFF),
          crater: const Color(0xFF27125C),
          ring: const Color(0xFFD7B9FF),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.neonOcean => (
          colorA: const Color(0xFF00D7FF),
          colorB: const Color(0xFF00317A),
          accent: const Color(0xFF7CFF6B),
          glow: const Color(0xFF00B8FF),
          crater: const Color(0xFF00183D),
          ring: const Color(0xFF9DFFF7),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.desert => (
          colorA: const Color(0xFFFFD35A),
          colorB: const Color(0xFF9B3F12),
          accent: const Color(0xFFFF7C2E),
          glow: const Color(0xFFFFB33A),
          crater: const Color(0xFF5B220B),
          ring: const Color(0xFFFFE18E),
          rings: rng.nextInt(5) == 0,
          bands: 4,
        ),
      PlanetStyle.jungle => (
          colorA: const Color(0xFF32FF72),
          colorB: const Color(0xFF06431C),
          accent: const Color(0xFFFFF06A),
          glow: const Color(0xFF2DFF8C),
          crater: const Color(0xFF01240E),
          ring: const Color(0xFF9BFF7B),
          rings: false,
          bands: 0,
        ),
      PlanetStyle.voidPlanet => (
          colorA: const Color(0xFF27144F),
          colorB: const Color(0xFF03030B),
          accent: const Color(0xFFFF4BD8),
          glow: const Color(0xFF7D45FF),
          crater: const Color(0xFF000000),
          ring: const Color(0xFF7D45FF),
          rings: rng.nextBool(),
          bands: 0,
        ),
      PlanetStyle.candy => (
          colorA: const Color(0xFFFF7AD9),
          colorB: const Color(0xFFFFF0A8),
          accent: const Color(0xFF7CFFF2),
          glow: const Color(0xFFFF85EA),
          crater: const Color(0xFFC13F9F),
          ring: const Color(0xFFFFFFFF),
          rings: false,
          bands: 6,
        ),
      PlanetStyle.storm => (
          colorA: const Color(0xFF9FD6FF),
          colorB: const Color(0xFF2631A7),
          accent: const Color(0xFFFFF56A),
          glow: const Color(0xFF6BCBFF),
          crater: const Color(0xFF11175C),
          ring: const Color(0xFFCDE9FF),
          rings: false,
          bands: 5,
        ),
      PlanetStyle.metalWorld => (
          colorA: const Color(0xFFD0D6E4),
          colorB: const Color(0xFF4D596D),
          accent: const Color(0xFFFF3D4F),
          glow: const Color(0xFFB9C5E4),
          crater: const Color(0xFF222B3A),
          ring: const Color(0xFFEBF1FF),
          rings: true,
          bands: 0,
        ),
      PlanetStyle.deathStar => (
          colorA: const Color(0xFFD9DCE3),
          colorB: const Color(0xFF5D6470),
          accent: const Color(0xFF8FFF9D),
          glow: const Color(0xFFB7BDC9),
          crater: const Color(0xFF232832),
          ring: const Color(0xFF9EA6B5),
          rings: false,
          bands: 0,
        ),
    };

    return PlanetData(
      colorA: spec.colorA,
      colorB: spec.colorB,
      accentColor: spec.accent,
      glowColor: spec.glow,
      craterColor: spec.crater,
      ringColor: spec.ring,
      radius: radius,
      seed: seed,
      style: style,
      hasRings: spec.rings,
      bandCount: spec.bands,
    );
  }
}
