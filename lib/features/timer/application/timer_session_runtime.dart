import 'package:wakelock_plus/wakelock_plus.dart';

import 'timer_notification_service.dart';

/// Coordinates platform runtime behavior for an active timer session.
///
/// Keeps the screen awake while a countdown is actively playing and mirrors the
/// session state into an Android pinned notification.
class TimerSessionRuntime {
  TimerSessionRuntime({TimerNotificationService? notificationService})
      : _notificationService =
            notificationService ?? TimerNotificationService();

  final TimerNotificationService _notificationService;
  bool _active = false;

  Future<void> sync({
    required bool isPlaying,
    required bool isComplete,
    required String modeLabel,
    required String timeLabel,
    required String completeMessage,
  }) async {
    if (isPlaying) {
      await _start(modeLabel: modeLabel, timeLabel: timeLabel);
    } else if (isComplete) {
      await _complete(completeMessage);
    } else {
      await stop();
    }
  }

  Future<void> stop() async {
    _active = false;
    await WakelockPlus.disable();
    await _notificationService.cancel();
  }

  Future<void> _start({
    required String modeLabel,
    required String timeLabel,
  }) async {
    await WakelockPlus.enable();
    await _notificationService.show(
      modeLabel: modeLabel,
      timeLabel: timeLabel,
    );
    _active = true;
  }

  Future<void> _complete(String message) async {
    _active = false;
    await WakelockPlus.disable();
    await _notificationService.showComplete(message);
  }

  bool get isActive => _active;
}
