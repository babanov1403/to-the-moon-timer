import 'free_timer_status.dart';

/// Immutable snapshot for the free-duration Timer mode countdown.
class FreeTimerState {
  const FreeTimerState({
    required this.selectedHours,
    required this.selectedMinutes,
    required this.remainingSeconds,
    required this.status,
  });

  final int selectedHours;
  final int selectedMinutes;
  final int remainingSeconds;
  final FreeTimerStatus status;

  int get selectedSeconds => selectedHours * 3600 + selectedMinutes * 60;
  bool get isRunning => status == FreeTimerStatus.running;
  bool get isPaused => status == FreeTimerStatus.paused;
  bool get isFinished => status == FreeTimerStatus.finished;
  bool get canStart => selectedSeconds > 0 && remainingSeconds > 0;

  FreeTimerState copyWith({
    int? selectedHours,
    int? selectedMinutes,
    int? remainingSeconds,
    FreeTimerStatus? status,
  }) {
    return FreeTimerState(
      selectedHours: selectedHours ?? this.selectedHours,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
    );
  }
}
