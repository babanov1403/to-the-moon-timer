import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'planet_data.dart';
import 'planet_painter.dart';
import 'ship_painter.dart';
import 'space_palette.dart';
import 'space_scene_state.dart';
import 'star_painter.dart';

/// Composes the full retro arcade space scene.
class SpaceScenePainter extends CustomPainter {
  const SpaceScenePainter({
    required this.state,
    required this.planet,
    required this.flightProgress,
    required this.transitionProgress,
    required this.exhaustPhase,
    required this.starPhase,
    required this.isPaused,
  });

  final SpaceSceneState state;
  final PlanetData planet;
  final double flightProgress;
  final double transitionProgress;
  final double exhaustPhase;
  final double starPhase;
  final bool isPaused;

  // Planet rests at bottom-center of the viewport.
  Offset _planetCenter(Size size) => Offset(size.width / 2, size.height * 0.78);

  // Planet slides down off-screen during takeoff / up from below during landing.
  Offset _planetOffscreen(Size size) =>
      Offset(size.width / 2, size.height + planet.radius + 20);

  static const double _flightAngle = -math.pi / 10;

  double _ease(double t) => Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

  Offset _starDrift(Size size) {
    // Stars are distant background objects: they drift from their own looping
    // animation, independent of timer duration or flight progress. Keep the
    // distance large enough to read as motion in the viewport.
    final distance = starPhase * size.width * 1.35;
    return Offset(
      -math.cos(_flightAngle) * distance,
      -math.sin(_flightAngle) * distance,
    );
  }

  Offset _flightShipCenter(Size size) =>
      Offset(size.width / 2, size.height * 0.45);

  @override
  void paint(Canvas canvas, Size size) {
    _paintSpaceBackground(canvas, size);
    drawStars(
      canvas,
      size,
      starPhase,
      drift: _starDrift(size),
      dimmed: isPaused,
    );

    switch (state) {
      case SpaceSceneState.landed:
        _paintLanded(canvas, size);
      case SpaceSceneState.takingOff:
        _paintTakingOff(canvas, size);
      case SpaceSceneState.flying:
        _paintFlying(canvas, size);
      case SpaceSceneState.pausedInSpace:
        _paintPausedInSpace(canvas, size);
      case SpaceSceneState.landing:
        _paintLanding(canvas, size);
    }
  }

  void _paintSpaceBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SpacePalette.spaceBg,
            SpacePalette.spaceBgAlt,
            Color(0xFF070015),
          ],
          stops: [0.0, 0.48, 1.0],
        ).createShader(rect),
    );

    final pulse = 0.65 + math.sin(starPhase * math.pi * 2) * 0.12;
    _drawNebulaBlob(
      canvas,
      rect,
      Offset(size.width * 0.18, size.height * 0.18),
      size.shortestSide * 0.42,
      SpacePalette.nebulaPurple.withValues(alpha: pulse * 0.2),
    );
    _drawNebulaBlob(
      canvas,
      rect,
      Offset(size.width * 0.82, size.height * 0.38),
      size.shortestSide * 0.34,
      SpacePalette.nebulaMagenta.withValues(alpha: pulse * 0.14),
    );
    _drawNebulaBlob(
      canvas,
      rect,
      Offset(size.width * 0.55, size.height * 0.92),
      size.shortestSide * 0.5,
      SpacePalette.nebulaBlue.withValues(alpha: pulse * 0.1),
    );

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = SpacePalette.nebulaPurple.withValues(alpha: 0.08);
    for (double y = 12; y < size.height; y += SpacePalette.px * 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawNebulaBlob(
    Canvas canvas,
    Rect sceneRect,
    Offset center,
    double radius,
    Color color,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _paintLanded(Canvas canvas, Size size) {
    final center = _planetCenter(size);
    drawPlanet(canvas, planet, center, 1.0);
    final bob =
        isPaused ? 0.0 : math.sin(exhaustPhase * math.pi * 2) * SpacePalette.px;
    final shipPos = Offset(center.dx, center.dy - planet.radius - 14 + bob);
    drawShip(canvas, shipPos, -math.pi / 2);
  }

  void _paintTakingOff(Canvas canvas, Size size) {
    final t = _ease(transitionProgress);
    final planetPos =
        Offset.lerp(_planetCenter(size), _planetOffscreen(size), t)!;
    drawPlanet(canvas, planet, planetPos, 1.0 - t);

    final startPos = Offset(
        _planetCenter(size).dx, _planetCenter(size).dy - planet.radius - 14);
    final shipPos = Offset.lerp(startPos, _flightShipCenter(size), t)!;
    final angle = lerpAngle(-math.pi / 2, _flightAngle, t);
    drawExhaust(canvas, shipPos, angle, exhaustPhase, intensity: 0.6 + t * 0.4);
    drawShip(canvas, shipPos, angle);
  }

  void _paintFlying(Canvas canvas, Size size) {
    final shipPos = _flightShipCenter(size);
    drawExhaust(canvas, shipPos, _flightAngle, exhaustPhase);
    drawShip(canvas, shipPos, _flightAngle);
  }

  void _paintPausedInSpace(Canvas canvas, Size size) {
    drawShip(canvas, _flightShipCenter(size), _flightAngle);
  }

  void _paintLanding(Canvas canvas, Size size) {
    final t = _ease(transitionProgress);
    final planetPos =
        Offset.lerp(_planetOffscreen(size), _planetCenter(size), t)!;
    drawPlanet(canvas, planet, planetPos, t);

    final endPos = Offset(
        _planetCenter(size).dx, _planetCenter(size).dy - planet.radius - 14);
    final shipPos = Offset.lerp(_flightShipCenter(size), endPos, t)!;
    final angle = lerpAngle(_flightAngle, -math.pi / 2, t);
    drawExhaust(canvas, shipPos, angle, exhaustPhase,
        intensity: (1.0 - t) * 0.8);
    drawShip(canvas, shipPos, angle);
  }

  @override
  bool shouldRepaint(SpaceScenePainter old) =>
      old.state != state ||
      old.planet != planet ||
      old.flightProgress != flightProgress ||
      old.transitionProgress != transitionProgress ||
      old.exhaustPhase != exhaustPhase ||
      old.starPhase != starPhase ||
      old.isPaused != isPaused;
}
