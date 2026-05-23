import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/timer_state.dart';

/// Coordinates platform runtime behavior for an active timer session.
///
/// This keeps the screen awake while the focus or break countdown is actively
/// playing. Notifications and Android foreground services are intentionally not
/// used to avoid timer-session UI lag.
class TimerSessionRuntime {
  TimerSessionRuntime();

  bool _active = false;

  Future<void> sync(TimerState state) async {
    if (state.isActivelyPlaying) {
      await _start();
    } else {
      await stop();
    }
  }

  Future<void> stop() async {
    _active = false;
    await WakelockPlus.disable();
  }

  Future<void> _start() async {
    await WakelockPlus.enable();
    _active = true;
  }

  bool get isActive => _active;
}
