import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color _kBg = Color(0xFF0F0F2A);
const Color _kDisabled = Color(0xFF333355);

/// Small all-caps retro label (e.g. "FOCUS" / "BREAK").
class RetroLabel extends StatelessWidget {
  const RetroLabel({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 4,
        ),
      );
}

/// Tappable countdown display with retro border glow.
class RetroTimerField extends StatelessWidget {
  const RetroTimerField({
    super.key,
    required this.timeLabel,
    required this.isRunning,
    required this.accentColor,
    required this.onTap,
  });
  final String timeLabel;
  final bool isRunning;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: accentColor.withValues(alpha: isRunning ? 0.9 : 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isRunning
                  ? accentColor.withValues(alpha: 0.25)
                  : Colors.transparent,
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Text(
          timeLabel,
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: accentColor,
            letterSpacing: 4,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Four small retro squares that preserve the colors of completed planets.
class RetroPomodoroSetProgress extends StatelessWidget {
  const RetroPomodoroSetProgress({
    super.key,
    required this.completedPlanetColors,
    required this.totalSessions,
    required this.emptyColor,
  });

  final List<({Color colorA, Color colorB})> completedPlanetColors;
  final int totalSessions;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final safeTotal = math.max(1, totalSessions);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(safeTotal, (index) {
        final colors = index < completedPlanetColors.length
            ? completedPlanetColors[index]
            : null;
        return Padding(
          padding: EdgeInsets.only(right: index == safeTotal - 1 ? 0 : 10),
          child: _RetroProgressSquare(
            colorA: colors?.colorA,
            colorB: colors?.colorB,
            emptyColor: emptyColor,
          ),
        );
      }),
    );
  }
}

class _RetroProgressSquare extends StatelessWidget {
  const _RetroProgressSquare({
    required this.colorA,
    required this.colorB,
    required this.emptyColor,
  });

  final Color? colorA;
  final Color? colorB;
  final Color emptyColor;

  bool get isFilled => colorA != null && colorB != null;

  @override
  Widget build(BuildContext context) {
    final fillA = colorA ?? emptyColor;
    final fillB = colorB ?? emptyColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        gradient: isFilled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fillA,
                  Color.lerp(fillA, fillB, 0.45)!,
                  fillB,
                ],
                stops: const [0.0, 0.55, 1.0],
              )
            : null,
        color: isFilled ? null : _kBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isFilled ? fillA.withValues(alpha: 0.95) : emptyColor,
          width: 2,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: fillA.withValues(alpha: 0.45),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: isFilled
          ? Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.all(3),
                color: Colors.white.withValues(alpha: 0.25),
              ),
            )
          : Center(
              child: Container(
                width: 6,
                height: 6,
                color: emptyColor.withValues(alpha: 0.25),
              ),
            ),
    );
  }
}

/// Small pixel-fireworks burst for a completed four-session Pomodoro set.
class RetroFireworks extends StatelessWidget {
  const RetroFireworks({
    super.key,
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RetroFireworksPainter(
          progress: progress,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
        ),
        size: const Size(118, 74),
      ),
    );
  }
}

class _RetroFireworksPainter extends CustomPainter {
  const _RetroFireworksPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    final fade = math.sin(t * math.pi).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;
    final centers = [
      Offset(size.width * 0.28, size.height * 0.48),
      Offset(size.width * 0.56, size.height * 0.30),
      Offset(size.width * 0.76, size.height * 0.55),
    ];

    for (var burst = 0; burst < centers.length; burst++) {
      final center = centers[burst];
      final burstProgress = ((t - burst * 0.12) / 0.76).clamp(0.0, 1.0);
      if (burstProgress <= 0) continue;
      final radius = 8 + burstProgress * 26;
      for (var i = 0; i < 8; i++) {
        final angle = math.pi * 2 * i / 8 + burst * 0.35;
        final distance = radius * (0.45 + burstProgress * 0.55);
        final particleCenter = Offset(
          center.dx + math.cos(angle) * distance,
          center.dy + math.sin(angle) * distance,
        );
        final color = i.isEven ? primaryColor : secondaryColor;
        paint.color = color.withValues(alpha: fade * (1 - burstProgress * 0.35));
        canvas.drawRect(
          Rect.fromCenter(center: particleCenter, width: 5, height: 5),
          paint,
        );
      }
    }

    paint.color = Colors.white.withValues(alpha: fade * 0.85);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.62),
        width: 6,
        height: 6,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RetroFireworksPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;
}

/// Animated WORK / BREAK mode label.
class RetroModeLabel extends StatelessWidget {
  const RetroModeLabel({
    super.key,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.mutedColor,
  });
  final String label;
  final bool active;
  final Color activeColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) => AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w900 : FontWeight.w400,
          color: active ? activeColor : mutedColor,
          letterSpacing: 3,
        ),
        child: Text(label),
      );
}

/// Square retro play / pause / restart button.
class RetroPlayButton extends StatelessWidget {
  const RetroPlayButton({
    super.key,
    required this.isRunning,
    required this.isFinished,
    required this.isRestart,
    required this.accentColor,
    required this.onTap,
  });
  final bool isRunning;
  final bool isFinished;
  final bool isRestart;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isFinished && !isRestart ? _kDisabled : accentColor;
    final icon = isRestart
        ? Icons.restart_alt_rounded
        : isRunning
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 2),
          boxShadow: isFinished && !isRestart
              ? []
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Icon(
          icon,
          size: 44,
          color: color,
        ),
      ),
    );
  }
}
