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
