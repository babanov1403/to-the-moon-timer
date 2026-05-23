import 'package:flutter/material.dart';

import 'duration_picker_colors.dart';
import 'retro_header_button.dart';

/// Header bar for the duration picker sheet with Reset and Done actions.
class DurationPickerHeader extends StatelessWidget {
  const DurationPickerHeader({
    super.key,
    required this.onReset,
    required this.onDone,
  });

  final VoidCallback onReset;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          RetroHeaderButton(
            label: 'RESET',
            color: kDurationPickerYellow,
            icon: Icons.restart_alt_rounded,
            onTap: onReset,
          ),
          const Expanded(
            child: Text(
              'Duration',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kDurationPickerTitle,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.6,
              ),
            ),
          ),
          RetroHeaderButton(
            label: 'DONE',
            color: kDurationPickerCyan,
            icon: Icons.check_rounded,
            onTap: onDone,
          ),
        ],
      ),
    );
  }
}
