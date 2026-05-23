import 'package:flutter/material.dart';

import '../../../application/timer_config.dart';
import 'debug_duration_chip.dart';
import 'duration_picker_colors.dart';
import 'duration_picker_header.dart';
import 'duration_picker_result.dart';
import 'duration_wheel.dart';
import 'retro_divider.dart';

/// Modal bottom sheet that lets the user pick a session duration.
class DurationPickerSheet extends StatefulWidget {
  const DurationPickerSheet({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  State<DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<DurationPickerSheet> {
  late int _pickedIndex;

  @override
  void initState() {
    super.initState();
    _pickedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 486,
      decoration: _sheetDecoration(),
      child: Column(
        children: [
          DurationPickerHeader(
            onReset: () => Navigator.of(context).pop(
              const DurationPickerResult.reset(),
            ),
            onDone: () => Navigator.of(context).pop(
              DurationPickerResult.minutes(kDurationMinutes[_pickedIndex]),
            ),
          ),
          const RetroDivider(),
          Expanded(
            child: DurationWheel(
              initialIndex: widget.initialIndex,
              onChanged: (i) => _pickedIndex = i,
            ),
          ),
          const RetroDivider(),
          Container(
            color: kDurationPickerPanel,
            child: DebugDurationChip(
              onTap: () => Navigator.of(context).pop(
                const DurationPickerResult.debug(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _sheetDecoration() {
    return BoxDecoration(
      color: kDurationPickerSheetBg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      border: Border.all(color: kDurationPickerBorder, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 24,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }
}
