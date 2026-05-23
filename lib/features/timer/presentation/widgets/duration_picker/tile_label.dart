import 'package:flutter/material.dart';

class TileLabel extends StatelessWidget {
  const TileLabel({
    super.key,
    required this.minutes,
    required this.textColor,
  });

  final int minutes;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$minutes', style: _minuteStyle()),
        const SizedBox(height: 3),
        Text('MIN', style: _unitStyle()),
      ],
    );
  }

  TextStyle _minuteStyle() => TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        height: 1,
        letterSpacing: 1.2,
      );

  TextStyle _unitStyle() => TextStyle(
        color: textColor.withValues(alpha: 0.76),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
      );
}
