import 'package:flutter/material.dart';

import '../../../application/timer_config.dart';
import 'debug_duration_chip.dart';
import 'duration_picker_colors.dart';
import 'duration_picker_header.dart';
import 'duration_picker_result.dart';
import 'duration_wheel.dart';
import 'retro_divider.dart';

/// Modal bottom sheet that lets the user pick focus and break durations.
class DurationPickerSheet extends StatefulWidget {
  const DurationPickerSheet({
    super.key,
    required this.initialFocusIndex,
    required this.initialBreakIndex,
  });

  final int initialFocusIndex;
  final int initialBreakIndex;

  @override
  State<DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<DurationPickerSheet> {
  late int _pickedFocusIndex;
  late int _pickedBreakIndex;
  _DurationPickerPage _page = _DurationPickerPage.focus;

  @override
  void initState() {
    super.initState();
    _pickedFocusIndex = _clampIndex(widget.initialFocusIndex, kDurationMinutes);
    _pickedBreakIndex =
        _clampIndex(widget.initialBreakIndex, kBreakDurationMinutes);
  }

  int _clampIndex(int index, List<int> minutes) =>
      index.clamp(0, minutes.length - 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: _sheetDecoration(),
      child: Column(
        children: [
          DurationPickerHeader(
            onReset: () => Navigator.of(context).pop(
              const DurationPickerResult.reset(),
            ),
            onDone: () => Navigator.of(context).pop(
              DurationPickerResult.durations(
                focusMinutes: kDurationMinutes[_pickedFocusIndex],
                breakMinutes: kBreakDurationMinutes[_pickedBreakIndex],
              ),
            ),
          ),
          const RetroDivider(),
          _DurationPageSelector(
            page: _page,
            focusMinutes: kDurationMinutes[_pickedFocusIndex],
            breakMinutes: kBreakDurationMinutes[_pickedBreakIndex],
            onChanged: (page) => setState(() => _page = page),
          ),
          const RetroDivider(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: DurationWheel(
                key: ValueKey(_page),
                initialIndex: _page == _DurationPickerPage.focus
                    ? _pickedFocusIndex
                    : _pickedBreakIndex,
                minutes: _page == _DurationPickerPage.focus
                    ? kDurationMinutes
                    : kBreakDurationMinutes,
                selectedColor: _page == _DurationPickerPage.focus
                    ? kDurationPickerCyan
                    : kDurationPickerYellow,
                onChanged: (i) {
                  if (_page == _DurationPickerPage.focus) {
                    _pickedFocusIndex = i;
                  } else {
                    _pickedBreakIndex = i;
                  }
                  setState(() {});
                },
              ),
            ),
          ),
          const RetroDivider(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: kDurationPickerPanel.withValues(alpha: 0.72),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
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
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF111D3A),
          kDurationPickerSheetBg,
        ],
      ),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      border: Border.all(
        color: kDurationPickerBorder.withValues(alpha: 0.74),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          blurRadius: 30,
          offset: const Offset(0, -10),
        ),
        BoxShadow(
          color: kDurationPickerCyan.withValues(alpha: 0.08),
          blurRadius: 28,
          spreadRadius: 1,
        ),
      ],
    );
  }
}

enum _DurationPickerPage { focus, breakTime }

class _DurationPageSelector extends StatelessWidget {
  const _DurationPageSelector({
    required this.page,
    required this.focusMinutes,
    required this.breakMinutes,
    required this.onChanged,
  });

  final _DurationPickerPage page;
  final int focusMinutes;
  final int breakMinutes;
  final ValueChanged<_DurationPickerPage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDurationPickerSheetBg.withValues(alpha: 0.38),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _DurationPageButton(
              label: 'Focus',
              minutes: focusMinutes,
              color: kDurationPickerCyan,
              selected: page == _DurationPickerPage.focus,
              onTap: () => onChanged(_DurationPickerPage.focus),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DurationPageButton(
              label: 'Rest',
              minutes: breakMinutes,
              color: kDurationPickerYellow,
              selected: page == _DurationPickerPage.breakTime,
              onTap: () => onChanged(_DurationPickerPage.breakTime),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationPageButton extends StatelessWidget {
  const _DurationPageButton({
    required this.label,
    required this.minutes,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.10),
        highlightColor: color.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : kDurationPickerPanel.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.62)
                  : kDurationPickerMuted.withValues(alpha: 0.34),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 18,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: _labelStyle(selected ? color : kDurationPickerTitle)),
              const SizedBox(height: 4),
              Text(
                '$minutes MIN',
                style: _minutesStyle(selected ? color : kDurationPickerMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(Color textColor) => TextStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.4,
      );

  TextStyle _minutesStyle(Color textColor) => TextStyle(
        color: textColor.withValues(alpha: 0.85),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      );
}
