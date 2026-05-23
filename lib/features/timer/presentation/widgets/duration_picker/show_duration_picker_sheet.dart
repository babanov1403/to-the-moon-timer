import 'package:flutter/material.dart';

import 'duration_picker_result.dart';
import 'duration_picker_sheet.dart';

/// Shows the duration picker and applies the selected result to callbacks.
Future<void> showDurationPickerSheet({
  required BuildContext context,
  required int initialFocusIndex,
  required int initialBreakIndex,
  required void Function({required int focusMinutes, required int breakMinutes})
      onDurations,
  required VoidCallback onDebug,
  required VoidCallback onReset,
}) async {
  final result = await showModalBottomSheet<DurationPickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DurationPickerSheet(
      initialFocusIndex: initialFocusIndex,
      initialBreakIndex: initialBreakIndex,
    ),
  );

  if (result == null) return;
  if (result.isReset) {
    onReset();
  } else if (result.isDebug) {
    onDebug();
  } else {
    onDurations(
      focusMinutes: result.focusMinutes,
      breakMinutes: result.breakMinutes,
    );
  }
}
