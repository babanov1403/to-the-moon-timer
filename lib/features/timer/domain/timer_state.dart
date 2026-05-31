import 'timer_status.dart';

/// Immutable snapshot of the timer at any given moment.
class TimerState {
  const TimerState({
    required this.remainingSeconds,
    required this.selectedMinutes,
    required this.selectedBreakMinutes,
    required this.isDebugMode,
    required this.status,
    this.completedFocusSessions = 0,
    this.completedSetCount = 0,
  });

  final int remainingSeconds;

  /// 0 when debug mode is active.
  final int selectedMinutes;

  /// Selected break duration in minutes.
  final int selectedBreakMinutes;

  final bool isDebugMode;
  final TimerStatus status;

  /// Number of completed focus sessions in the current Pomodoro set.
  final int completedFocusSessions;

  /// Monotonic counter that increments whenever a full Pomodoro set completes.
  ///
  /// UI can compare this value with its previous value to play one-shot
  /// celebration animations without keeping transient animation flags in the
  /// timer domain state.
  final int completedSetCount;

  bool get isRunning => status == TimerStatus.running;
  bool get isFinished =>
      status == TimerStatus.finished ||
      status == TimerStatus.awaitingBreakAcknowledgement;
  bool get isAwaitingBreakAcknowledgement =>
      status == TimerStatus.awaitingBreakAcknowledgement;
  bool get isOnBreak =>
      status == TimerStatus.breakRunning ||
      status == TimerStatus.breakPaused ||
      status == TimerStatus.breakFinished ||
      status == TimerStatus.awaitingFocusAcknowledgement;
  bool get isBreakRunning => status == TimerStatus.breakRunning;
  bool get isBreakFinished =>
      status == TimerStatus.breakFinished ||
      status == TimerStatus.awaitingFocusAcknowledgement;
  bool get isAwaitingFocusAcknowledgement =>
      status == TimerStatus.awaitingFocusAcknowledgement;
  bool get isAwaitingAcknowledgement =>
      isAwaitingBreakAcknowledgement || isAwaitingFocusAcknowledgement;
  bool get isSetComplete => status == TimerStatus.setComplete;
  bool get isActivelyPlaying => isRunning || isBreakRunning;

  TimerState copyWith({
    int? remainingSeconds,
    int? selectedMinutes,
    int? selectedBreakMinutes,
    bool? isDebugMode,
    TimerStatus? status,
    int? completedFocusSessions,
    int? completedSetCount,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      selectedBreakMinutes: selectedBreakMinutes ?? this.selectedBreakMinutes,
      isDebugMode: isDebugMode ?? this.isDebugMode,
      status: status ?? this.status,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
      completedSetCount: completedSetCount ?? this.completedSetCount,
    );
  }
}
