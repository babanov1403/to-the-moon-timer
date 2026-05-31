import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'timer_notification_config.dart';

/// Small Android-only wrapper around local notifications for active timers.
class TimerNotificationService {
  TimerNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionAsked = false;

  Future<void> show({
    required String modeLabel,
    required String timeLabel,
  }) async {
    if (!_isAndroid) return;
    await _ensureInitialized();
    await _requestPermissionOnce();
    await _plugin.show(
      TimerNotificationConfig.notificationId,
      timeLabel,
      '$modeLabel • ${TimerNotificationConfig.activePhrase}',
      _details(ongoing: true),
    );
  }

  Future<void> showComplete(String message) async {
    if (!_isAndroid) return;
    await _ensureInitialized();
    await _requestPermissionOnce();
    await _plugin.show(
      TimerNotificationConfig.notificationId,
      TimerNotificationConfig.appTitle,
      message,
      _details(ongoing: false),
    );
  }

  Future<void> cancel() async {
    if (!_isAndroid || !_initialized) return;
    await _plugin.cancel(TimerNotificationConfig.notificationId);
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('ic_spaceship_notification');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> _requestPermissionOnce() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  NotificationDetails _details({required bool ongoing}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        TimerNotificationConfig.channelId,
        TimerNotificationConfig.channelName,
        channelDescription: TimerNotificationConfig.channelDescription,
        icon: 'ic_spaceship_notification',
        importance: ongoing ? Importance.low : Importance.defaultImportance,
        priority: ongoing ? Priority.low : Priority.defaultPriority,
        ongoing: ongoing,
        autoCancel: !ongoing,
        onlyAlertOnce: true,
        showWhen: false,
        category: AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
