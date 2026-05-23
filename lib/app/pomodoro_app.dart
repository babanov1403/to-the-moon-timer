import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'theme/themes/red_focus_theme.dart';
import '../features/home/presentation/home_screen.dart';

/// Root [MaterialApp] widget for the To The Moon Timer app.
class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To The Moon Timer',
      debugShowCheckedModeBanner: false,
      theme: buildRedFocusTheme(),
      home: const WithForegroundTask(child: HomeScreen()),
    );
  }
}
