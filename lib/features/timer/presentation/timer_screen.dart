import 'package:flutter/material.dart';
import '../application/timer_config.dart';
import '../application/timer_controller.dart';
import '../application/timer_formatter.dart';
import 'widgets/duration_picker_sheet.dart';
import 'widgets/timer_display.dart';
import 'widgets/timer_play_button.dart';

/// Timer feature content widget.
///
/// Owns the [TimerController] lifecycle and renders the play button,
/// countdown display, and status label. Does NOT include a [Scaffold] —
/// the parent screen is responsible for that.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final TimerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimerController();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  Future<void> _openDurationPicker() async {
    if (_controller.state.isRunning) return;

    final state = _controller.state;
    final int initialIndex = state.isDebugMode
        ? 0
        : kDurationMinutes
            .indexOf(state.selectedMinutes)
            .clamp(0, kDurationMinutes.length - 1);

    await showDurationPickerSheet(
      context: context,
      initialIndex: initialIndex,
      onMinutes: _controller.applyMinutes,
      onDebug: _controller.applyDebugSeconds,
      onReset: _controller.restartSet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final String timeLabel = TimerFormatter.format(state.remainingSeconds);

    final String statusLabel;
    if (state.isBreakFinished) {
      statusLabel = 'Break complete!';
    } else if (state.isOnBreak) {
      statusLabel = 'Break time';
    } else if (state.isFinished) {
      statusLabel = 'Session complete!';
    } else if (state.isRunning) {
      statusLabel = 'Focus time';
    } else {
      statusLabel = 'Tap time to change duration';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Play / Pause button — above the timer
        TimerPlayButton(
          isRunning: state.isRunning || state.isBreakRunning,
          isFinished: state.isBreakFinished,
          onTap: _controller.togglePlayPause,
        ),
        const SizedBox(height: 48),

        // Timer display — tappable when stopped
        TimerDisplay(
          formattedTime: timeLabel,
          isRunning: state.isRunning,
          onTap: _openDurationPicker,
        ),
        const SizedBox(height: 32),

        // Status label
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
