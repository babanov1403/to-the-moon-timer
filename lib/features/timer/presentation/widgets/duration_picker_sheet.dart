import 'package:flutter/material.dart';

import '../../application/timer_config.dart';
import 'debug_duration_chip.dart';
import 'duration_picker_header.dart';
import 'duration_wheel.dart';

const Color _kSheetBg = Color(0xFF080817);
const Color _kPanel = Color(0xFF0F0F2A);
const Color _kBorder = Color(0xFF333355);

/// Modal bottom sheet that lets the user pick a session duration.
///
/// Returns a [_PickerResult] via [Navigator.pop] when the user taps Done,
/// Reset, or the debug chip. Returns `null` if dismissed without a selection.
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
      decoration: BoxDecoration(
        color: _kSheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: _kBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          DurationPickerHeader(
            onReset: () =>
                Navigator.of(context).pop(const _PickerResult.reset()),
            onDone: () => Navigator.of(context).pop(
              _PickerResult.minutes(kDurationMinutes[_pickedIndex]),
            ),
          ),
          const _RetroDivider(),
          Expanded(
            child: DurationWheel(
              initialIndex: widget.initialIndex,
              onChanged: (i) => _pickedIndex = i,
            ),
          ),
          const _RetroDivider(),
          Container(
            color: _kPanel,
            child: DebugDurationChip(
              onTap: () =>
                  Navigator.of(context).pop(const _PickerResult.debug()),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetroDivider extends StatelessWidget {
  const _RetroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      color: _kBorder,
    );
  }
}

/// Discriminated result returned by [DurationPickerSheet].
class _PickerResult {
  const _PickerResult.minutes(this.minutes)
      : isDebug = false,
        isReset = false;
  const _PickerResult.debug()
      : minutes = 0,
        isDebug = true,
        isReset = false;
  const _PickerResult.reset()
      : minutes = 0,
        isDebug = false,
        isReset = true;

  final int minutes;
  final bool isDebug;
  final bool isReset;
}

/// Helper that shows the [DurationPickerSheet] and applies the result to
/// [onMinutes] / [onDebug] / [onReset] callbacks.
Future<void> showDurationPickerSheet({
  required BuildContext context,
  required int initialIndex,
  required void Function(int minutes) onMinutes,
  required VoidCallback onDebug,
  required VoidCallback onReset,
}) async {
  final result = await showModalBottomSheet<_PickerResult>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    builder: (_) => DurationPickerSheet(initialIndex: initialIndex),
  );

  if (result == null) return;
  if (result.isReset) {
    onReset();
  } else if (result.isDebug) {
    onDebug();
  } else {
    onMinutes(result.minutes);
  }
}
