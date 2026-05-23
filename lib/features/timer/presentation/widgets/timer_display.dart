import 'package:flutter/material.dart';

/// Tappable container that shows the current countdown time.
///
/// Displays a blue border hint when tappable (timer stopped) and a subtle
/// border when the timer is running.
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({
    super.key,
    required this.formattedTime,
    required this.isRunning,
    required this.onTap,
  });

  final String formattedTime;
  final bool isRunning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRunning
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFF0A84FF).withValues(alpha: 0.5),
            width: isRunning ? 1 : 1.5,
          ),
        ),
        child: Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: 4,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
