import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../domain/timer_state.dart';

/// Coordinates platform runtime behavior for an active timer session.
///
/// On Android this keeps the screen awake and runs a foreground service with an
/// ongoing notification while the focus or break countdown is actively playing.
/// Unsupported platforms only use the wake lock plugin when available and do not
/// start a foreground notification.
class TimerSessionRuntime {
  TimerSessionRuntime();

  static const int _serviceId = 1001;
  static const String _notificationChannelId = 'timer_session';
  static const String _notificationChannelName = 'Timer session';
  static const String _notificationChannelDescription =
      'Shown while a focus or break session is playing.';

  bool _initialized = false;
  bool _active = false;

  Future<void> sync(TimerState state) async {
    if (state.isActivelyPlaying) {
      await _start(state);
    } else {
      await stop();
    }
  }

  Future<void> stop() async {
    _active = false;
    await WakelockPlus.disable();

    if (!_isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _start(TimerState state) async {
    await WakelockPlus.enable();

    if (!_isAndroid) {
      _active = true;
      return;
    }

    _ensureInitialized();
    await _requestNotificationPermissionIfNeeded();

    final String title = state.isBreakRunning
        ? 'Break session is playing'
        : 'Focus session is playing';
    final String text = state.isBreakRunning
        ? 'To The Moon Timer break is active.'
        : 'To The Moon Timer focus session is active.';

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } else {
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: const [ForegroundServiceTypes.dataSync],
        notificationTitle: title,
        notificationText: text,
        callback: timerSessionForegroundTaskStartCallback,
      );
    }

    _active = true;
  }

  void _ensureInitialized() {
    if (_initialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _notificationChannelId,
        channelName: _notificationChannelName,
        channelDescription: _notificationChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
        showBadge: false,
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: false,
        stopWithTask: false,
      ),
    );

    _initialized = true;
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission == NotificationPermission.denied) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isActive => _active;
}

@pragma('vm:entry-point')
void timerSessionForegroundTaskStartCallback() {
  FlutterForegroundTask.setTaskHandler(_TimerSessionForegroundTaskHandler());
}

class _TimerSessionForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
