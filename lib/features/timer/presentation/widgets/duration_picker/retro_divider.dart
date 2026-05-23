import 'package:flutter/material.dart';

import 'duration_picker_colors.dart';

class RetroDivider extends StatelessWidget {
  const RetroDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: kDurationPickerBorder.withValues(alpha: 0.42),
    );
  }
}
