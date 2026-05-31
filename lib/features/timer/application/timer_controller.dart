import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/timer_state.dart';
import '../domain/timer_status.dart';
import 'timer_config.dart';

/// Controls the Pomodoro countdown and exposes state via [ChangeNotifier].
///
/// Session flow: focus → break → focus, repeated until the four-session set is
/// complete. Completing the fourth focus session stops the timer in a
/// celebration/restart state instead of auto-starting another break.
class TimerController extends ChangeNotifier {
  TimerController()
      : _state = TimerState(
          remainingSeconds: kDefaultMinutes * 60,
          selectedMinutes: kDefaultMinutes,
          selectedBreakMinutes: kDefaultBreakMinutes,
          isDebugMode: false,
          status: TimerStatus.idle,
        );

  TimerState _state;
  Timer? _ticker;
  DateTime? _deadline;

  TimerState get state => _state;

  // ── Public API ──────────────────────────────────────────────────────────────

  void togglePlayPause() {
    switch (_state.status) {
      case TimerStatus.running:
        _pause();
      case TimerStatus.breakRunning:
        _pauseBreak();
      case TimerStatus.idle:
      case TimerStatus.paused:
        if (_state.remainingSeconds > 0) _start();
      case TimerStatus.breakPaused:
        if (_state.remainingSeconds > 0) _startBreak();
      case TimerStatus.setComplete:
        restartSet();
      case TimerStatus.awaitingBreakAcknowledgement:
      case TimerStatus.awaitingFocusAcknowledgement:
        acknowledgeTransitionAlarm();
      case TimerStatus.finished:
      case TimerStatus.breakFinished:
        // Legacy transitional states are not expected in the current flow.
        break;
    }
  }

  /// Acknowledges a completed focus/rest transition alarm and starts next phase.
  void acknowledgeTransitionAlarm() {
    switch (_state.status) {
      case TimerStatus.awaitingBreakAcknowledgement:
        _beginBreak();
      case TimerStatus.awaitingFocusAcknowledgement:
        _beginNextFocus();
      case TimerStatus.idle:
      case TimerStatus.running:
      case TimerStatus.paused:
      case TimerStatus.finished:
      case TimerStatus.breakRunning:
      case TimerStatus.breakPaused:
      case TimerStatus.breakFinished:
      case TimerStatus.setComplete:
        break;
    }
  }

  /// Clears a completed Pomodoro set and returns to an idle focus timer.
  ///
  /// This is used by the restart button shown during the celebration phase and
  /// intentionally does not auto-start the next set.
  void restartSet() {
    _cancelTicker();
    _state = TimerState(
      remainingSeconds: _focusSeconds,
      selectedMinutes: _state.selectedMinutes,
      selectedBreakMinutes: _state.selectedBreakMinutes,
      isDebugMode: _state.isDebugMode,
      status: TimerStatus.idle,
      completedSetCount: _state.completedSetCount,
    );
    notifyListeners();
  }

  /// Called when the user picks new focus and break durations from the picker.
  ///
  /// This is also a manual reset path for the four progress squares.
  void applyDurations({required int focusMinutes, required int breakMinutes}) {
    _cancelTicker();
    _state = TimerState(
      remainingSeconds: focusMinutes * 60,
      selectedMinutes: focusMinutes,
      selectedBreakMinutes: breakMinutes,
      isDebugMode: false,
      status: TimerStatus.idle,
    );
    notifyListeners();
  }

  /// Called when the user picks a new focus duration from legacy callers.
  void applyMinutes(int minutes) {
    applyDurations(
      focusMinutes: minutes,
      breakMinutes: _state.selectedBreakMinutes,
    );
  }

  /// Called when the user taps the debug "10 sec" chip.
  ///
  /// This is also a manual reset path for the four progress squares.
  void applyDebugSeconds() {
    _cancelTicker();
    _state = const TimerState(
      remainingSeconds: kDebugSeconds,
      selectedMinutes: 0,
      selectedBreakMinutes: kDefaultBreakMinutes,
      isDebugMode: true,
      status: TimerStatus.idle,
    );
    notifyListeners();
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  int get _focusSeconds =>
      _state.isDebugMode ? kDebugSeconds : _state.selectedMinutes * 60;

  void _start() {
    _beginCountdown(_state.remainingSeconds, _tickFocus);
    _state = _state.copyWith(status: TimerStatus.running);
    notifyListeners();
  }

  void _pause() {
    final int remainingSeconds = _remainingSecondsUntilDeadline();
    _cancelTicker();
    _state = _state.copyWith(
      remainingSeconds: remainingSeconds,
      status: TimerStatus.paused,
    );
    notifyListeners();
  }

  void _startBreak() {
    _beginCountdown(_state.remainingSeconds, _tickBreak);
    _state = _state.copyWith(status: TimerStatus.breakRunning);
    notifyListeners();
  }

  void _pauseBreak() {
    final int remainingSeconds = _remainingSecondsUntilDeadline();
    _cancelTicker();
    _state = _state.copyWith(
      remainingSeconds: remainingSeconds,
      status: TimerStatus.breakPaused,
    );
    notifyListeners();
  }

  /// Transitions from a completed focus session into a break countdown.
  void _beginBreak() {
    final int breakSeconds = _state.isDebugMode
        ? kDebugBreakSeconds
        : _state.selectedBreakMinutes * 60;
    _beginCountdown(breakSeconds, _tickBreak);
    _state = _state.copyWith(
      remainingSeconds: breakSeconds,
      status: TimerStatus.breakRunning,
    );
    notifyListeners();
  }

  /// Transitions from a completed break into the next focus session.
  void _beginNextFocus() {
    final int focusSeconds = _focusSeconds;
    _beginCountdown(focusSeconds, _tickFocus);
    _state = _state.copyWith(
      remainingSeconds: focusSeconds,
      status: TimerStatus.running,
    );
    notifyListeners();
  }

  void _tickFocus() {
    final int next = _remainingSecondsUntilDeadline();
    if (next <= 0) {
      _cancelTicker();
      final int nextCompletedSessions =
          (_state.completedFocusSessions + 1).clamp(0, kPomodoroSessionsPerSet);
      final bool completedSet =
          nextCompletedSessions == kPomodoroSessionsPerSet;

      _state = _state.copyWith(
        remainingSeconds: 0,
        status: completedSet
            ? TimerStatus.setComplete
            : TimerStatus.awaitingBreakAcknowledgement,
        completedFocusSessions: nextCompletedSessions,
        completedSetCount: completedSet
            ? _state.completedSetCount + 1
            : _state.completedSetCount,
      );
      notifyListeners();
    } else {
      _state = _state.copyWith(remainingSeconds: next);
      notifyListeners();
    }
  }

  void _tickBreak() {
    final int next = _remainingSecondsUntilDeadline();
    if (next <= 0) {
      _cancelTicker();
      _state = _state.copyWith(
        remainingSeconds: 0,
        status: TimerStatus.awaitingFocusAcknowledgement,
      );
      notifyListeners();
    } else {
      _state = _state.copyWith(remainingSeconds: next);
      notifyListeners();
    }
  }

  void _beginCountdown(int seconds, void Function() onTick) {
    _cancelTicker();
    _deadline = DateTime.now().add(Duration(seconds: seconds));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
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
