/// Represents the lifecycle state of the Pomodoro timer.
enum TimerStatus {
  /// Timer is stopped and has not been started yet (or was reset).
  idle,

  /// Timer is actively counting down (focus session).
  running,

  /// Timer was started but then paused mid-session.
  paused,

  /// Focus session reached zero.
  finished,

  /// Focus session reached zero and waits for user acknowledgement before break.
  awaitingBreakAcknowledgement,

  /// Break countdown is actively running.
  breakRunning,

  /// Break countdown was paused mid-break.
  breakPaused,

  /// Break session reached zero.
  breakFinished,

  /// Break reached zero and waits for user acknowledgement before next focus.
  awaitingFocusAcknowledgement,

  /// Four focus sessions were completed and the app is waiting for restart.
  setComplete,
}
