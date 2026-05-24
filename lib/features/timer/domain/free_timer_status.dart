/// Lifecycle for the free-duration Timer mode countdown.
enum FreeTimerStatus {
  /// Countdown is stopped and ready to start from the selected duration.
  idle,

  /// Countdown is actively ticking.
  running,

  /// Countdown was paused mid-session.
  paused,

  /// Countdown reached zero and is waiting for a reset/restart.
  finished,
}
