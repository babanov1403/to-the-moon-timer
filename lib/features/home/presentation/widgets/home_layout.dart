import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme_tokens.dart';

/// Provides the standard home-screen scaffold: dark background + safe area.
///
/// Wrap any home content with this widget so future layout changes are
/// localised here.
class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeTokens.backgroundDeep,
      body: SafeArea(
        child: Center(child: child),
      ),
    );
  }
}
