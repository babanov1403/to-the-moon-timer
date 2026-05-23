import 'package:flutter/material.dart';

import 'duration_picker_colors.dart';

class RetroDivider extends StatelessWidget {
  const RetroDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      color: kDurationPickerBorder,
    );
  }
}
