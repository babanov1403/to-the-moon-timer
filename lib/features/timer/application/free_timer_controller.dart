import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/free_timer_state.dart';
import '../domain/free_timer_status.dart';

/// Controls the free-duration countdown used by Timer mode.
class FreeTimerController extends ChangeNotifier {
  FreeTimerController()
      : _state = const FreeTimerState(
          selectedHours: 0,
          selectedMinutes: 5,
          remainingSeconds: 5 * 60,
          status: FreeTimerStatus.idle,
        );

  FreeTimerState _state;
  Timer? _ticker;
  DateTime? _deadline;

  FreeTimerState get state => _state;

  void togglePlayPause() {
    switch (_state.status) {
      case FreeTimerStatus.running:
        _pause();
      case FreeTimerStatus.idle:
      case FreeTimerStatus.paused:
        if (_state.canStart) _start();
      case FreeTimerStatus.finished:
        resetSession();
    }
  }

  void applyDuration({required int hours, required int minutes}) {
    final safeHours = hours.clamp(0, 6);
    final safeMinutes = (minutes ~/ 5).clamp(0, 11) * 5;
    final totalSeconds = safeHours * 3600 + safeMinutes * 60;
    _cancelTicker();
    _state = FreeTimerState(
      selectedHours: safeHours,
      selectedMinutes: safeMinutes,
      remainingSeconds: totalSeconds,
      status: FreeTimerStatus.idle,
    );
    notifyListeners();
  }

  /// Clears only the active Timer mode session and keeps the selected duration.
  void resetSession() {
    _cancelTicker();
    _state = _state.copyWith(
      remainingSeconds: _state.selectedSeconds,
      status: FreeTimerStatus.idle,
    );
    notifyListeners();
  }

  void _start() {
    _beginCountdown(_state.remainingSeconds);
    _state = _state.copyWith(status: FreeTimerStatus.running);
    notifyListeners();
  }

  void _pause() {
    final remainingSeconds = _remainingSecondsUntilDeadline();
    _cancelTicker();
    _state = _state.copyWith(
      remainingSeconds: remainingSeconds,
      status: FreeTimerStatus.paused,
    );
    notifyListeners();
  }

  void _tick() {
    final next = _remainingSecondsUntilDeadline();
    if (next <= 0) {
      _cancelTicker();
      _state = _state.copyWith(
        remainingSeconds: 0,
        status: FreeTimerStatus.finished,
      );
    } else {
      _state = _state.copyWith(remainingSeconds: next);
    }
    notifyListeners();
  }

  void _beginCountdown(int seconds) {
    _cancelTicker();
    _deadline = DateTime.now().add(Duration(seconds: seconds));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  int _remainingSecondsUntilDeadline() {
    final deadline = _deadline;
    if (deadline == null) return _state.remainingSeconds;

    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / Duration.millisecondsPerSecond).ceil();
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
    _deadline = null;
  }

  @override
  void dispose() {
    _cancelTicker();
    super.dispose();
  }
}
