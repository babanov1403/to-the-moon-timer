import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'app/pomodoro_app.dart';

// Re-export so existing imports of `package:pomodoro_timer/main.dart`
// that reference PomodoroApp continue to resolve (e.g. widget tests).
export 'app/pomodoro_app.dart' show PomodoroApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const PomodoroApp());
}
