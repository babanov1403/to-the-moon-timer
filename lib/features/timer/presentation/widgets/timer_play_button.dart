import 'package:flutter/material.dart';

/// Large circular play/pause button shown above the timer display.
class TimerPlayButton extends StatelessWidget {
  const TimerPlayButton({
    super.key,
    required this.isRunning,
    required this.isFinished,
    required this.onTap,
  });

  final bool isRunning;
  final bool isFinished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);
    final Color buttonColor = isFinished ? Colors.grey.shade700 : primaryRed;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: buttonColor,
          boxShadow: isFinished
              ? []
              : [
                  BoxShadow(
                    color: primaryRed.withValues(alpha: 0.4),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
        ),
        child: Icon(
          isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 68,
          color: Colors.white,
        ),
      ),
    );
  }
}
