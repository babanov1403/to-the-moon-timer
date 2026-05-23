import 'package:flutter/material.dart';

/// Small all-caps retro label (e.g. "FOCUS" / "BREAK").
class RetroLabel extends StatelessWidget {
  const RetroLabel({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 4,
        ),
      );
}
