/// Pure formatting utilities for the timer display.
abstract final class TimerFormatter {
  /// Converts [totalSeconds] into a `MM:SS` string.
  static String format(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
