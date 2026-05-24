import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../duration_picker/duration_picker_colors.dart';
import '../duration_picker/retro_divider.dart';
import '../duration_picker/retro_header_button.dart';
import 'free_timer_duration_picker_result.dart';

/// Modal sheet for Timer mode's free-duration picker.
class FreeTimerDurationPickerSheet extends StatefulWidget {
  const FreeTimerDurationPickerSheet({
    super.key,
    required this.initialHours,
    required this.initialMinutes,
  });

  final int initialHours;
  final int initialMinutes;

  @override
  State<FreeTimerDurationPickerSheet> createState() =>
      _FreeTimerDurationPickerSheetState();
}

class _FreeTimerDurationPickerSheetState
    extends State<FreeTimerDurationPickerSheet> {
  static const int _minutesStep = 5;
  static const int _maxHours = 6;
  static const int _minuteTicks = 12;

  late int _pickedHours;
  late int _pickedMinutes;
  _TimerDurationPage _page = _TimerDurationPage.hours;

  bool get _canSubmit => _pickedHours > 0 || _pickedMinutes > 0;

  @override
  void initState() {
    super.initState();
    _pickedHours = widget.initialHours.clamp(0, _maxHours);
    _pickedMinutes =
        ((widget.initialMinutes ~/ _minutesStep).clamp(0, 11)) * _minutesStep;
    if (!_canSubmit) _pickedMinutes = _minutesStep;
  }

  void _setDuration({required int hours, required int minutes}) {
    final nextHours = hours.clamp(0, _maxHours);
    final nextMinutes = ((minutes ~/ _minutesStep).clamp(0, 11)) * _minutesStep;
    setState(() {
      _pickedHours = nextHours;
      _pickedMinutes =
          nextHours == 0 && nextMinutes == 0 ? _minutesStep : nextMinutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = math.min(
      500.0,
      MediaQuery.sizeOf(context).height * 0.72,
    );

    return SafeArea(
      top: false,
      child: Container(
        height: sheetHeight,
        decoration: _sheetDecoration(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  RetroHeaderButton(
                    label: 'RESET',
                    color: kDurationPickerYellow,
                    icon: Icons.restart_alt_rounded,
                    onTap: () => _setDuration(hours: 0, minutes: 5),
                  ),
                  const Expanded(
                    child: Text(
                      'Timer',
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
                    color:
                        _canSubmit ? kDurationPickerCyan : kDurationPickerMuted,
                    icon: Icons.check_rounded,
                    onTap: _canSubmit
                        ? () => Navigator.of(context).pop(
                              FreeTimerDurationPickerResult(
                                hours: _pickedHours,
                                minutes: _pickedMinutes,
                              ),
                            )
                        : () {},
                  ),
                ],
              ),
            ),
            const RetroDivider(),
            _DurationPartSelector(
              page: _page,
              hours: _pickedHours,
              minutes: _pickedMinutes,
              onChanged: (page) => setState(() => _page = page),
            ),
            const RetroDivider(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _TimerDurationGrid(
                  key: ValueKey(_page),
                  values: _page == _TimerDurationPage.hours
                      ? List<int>.generate(_maxHours + 1, (i) => i)
                      : List<int>.generate(
                          _minuteTicks,
                          (i) => i * _minutesStep,
                        ),
                  selectedValue: _page == _TimerDurationPage.hours
                      ? _pickedHours
                      : _pickedMinutes,
                  unit: _page == _TimerDurationPage.hours ? 'HRS' : 'MIN',
                  selectedColor: _page == _TimerDurationPage.hours
                      ? kDurationPickerCyan
                      : kDurationPickerYellow,
                  onChanged: (value) {
                    if (_page == _TimerDurationPage.hours) {
                      _setDuration(hours: value, minutes: _pickedMinutes);
                    } else {
                      _setDuration(hours: _pickedHours, minutes: value);
                    }
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
              child: _PickedDurationFooter(
                hours: _pickedHours,
                minutes: _pickedMinutes,
              ),
            ),
          ],
        ),
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

enum _TimerDurationPage { hours, minutes }

class _DurationPartSelector extends StatelessWidget {
  const _DurationPartSelector({
    required this.page,
    required this.hours,
    required this.minutes,
    required this.onChanged,
  });

  final _TimerDurationPage page;
  final int hours;
  final int minutes;
  final ValueChanged<_TimerDurationPage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kDurationPickerSheetBg.withValues(alpha: 0.38),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _DurationPartButton(
              label: 'Hours',
              valueLabel: '${hours}H',
              color: kDurationPickerCyan,
              selected: page == _TimerDurationPage.hours,
              onTap: () => onChanged(_TimerDurationPage.hours),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DurationPartButton(
              label: 'Minutes',
              valueLabel: '${minutes.toString().padLeft(2, '0')}M',
              color: kDurationPickerYellow,
              selected: page == _TimerDurationPage.minutes,
              onTap: () => onChanged(_TimerDurationPage.minutes),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationPartButton extends StatelessWidget {
  const _DurationPartButton({
    required this.label,
    required this.valueLabel,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String valueLabel;
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
                valueLabel,
                style: _valueStyle(selected ? color : kDurationPickerMuted),
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

  TextStyle _valueStyle(Color textColor) => TextStyle(
        color: textColor.withValues(alpha: 0.85),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      );
}

class _TimerDurationGrid extends StatefulWidget {
  const _TimerDurationGrid({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.unit,
    required this.selectedColor,
    required this.onChanged,
  });

  final List<int> values;
  final int selectedValue;
  final String unit;
  final Color selectedColor;
  final ValueChanged<int> onChanged;

  @override
  State<_TimerDurationGrid> createState() => _TimerDurationGridState();
}

class _TimerDurationGridState extends State<_TimerDurationGrid> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForValue(widget.selectedValue);
  }

  @override
  void didUpdateWidget(covariant _TimerDurationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue ||
        oldWidget.values != widget.values) {
      _selectedIndex = _indexForValue(widget.selectedValue);
    }
  }

  int _indexForValue(int value) {
    final index = widget.values.indexOf(value);
    return index == -1 ? 0 : index.clamp(0, widget.values.length - 1);
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    widget.onChanged(widget.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: widget.values.length,
      itemBuilder: (context, index) => _TimerDurationTile(
        value: widget.values[index],
        unit: widget.unit,
        selected: index == _selectedIndex,
        selectedColor: widget.selectedColor,
        onTap: () => _select(index),
      ),
    );
  }
}

class _TimerDurationTile extends StatelessWidget {
  const _TimerDurationTile({
    required this.value,
    required this.unit,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final int value;
  final String unit;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? selectedColor : kDurationPickerMuted;
    final textColor = selected ? selectedColor : kDurationPickerTitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: selectedColor.withValues(alpha: 0.10),
        highlightColor: selectedColor.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: _decoration(borderColor),
          child: Stack(
            children: [
              if (selected) const _SelectedMarker(),
              Center(
                child: _TimerTileLabel(
                  value: value,
                  unit: unit,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(Color borderColor) {
    return BoxDecoration(
      color: selected
          ? selectedColor.withValues(alpha: 0.11)
          : kDurationPickerPanel.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor.withValues(alpha: selected ? 0.62 : 0.34),
        width: 1.2,
      ),
      boxShadow: selected ? [_shadow()] : [],
    );
  }

  BoxShadow _shadow() {
    return BoxShadow(
      color: selectedColor.withValues(alpha: 0.14),
      blurRadius: 18,
      spreadRadius: 0,
    );
  }
}

class _SelectedMarker extends StatelessWidget {
  const _SelectedMarker();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      top: 10,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: kDurationPickerYellow,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TimerTileLabel extends StatelessWidget {
  const _TimerTileLabel({
    required this.value,
    required this.unit,
    required this.textColor,
  });

  final int value;
  final String unit;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: _valueStyle()),
        const SizedBox(height: 3),
        Text(unit, style: _unitStyle()),
      ],
    );
  }

  TextStyle _valueStyle() => TextStyle(
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

class _PickedDurationFooter extends StatelessWidget {
  const _PickedDurationFooter({required this.hours, required this.minutes});

  final int hours;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SELECTED',
            style: TextStyle(
              color: kDurationPickerTitle.withValues(alpha: 0.66),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${hours}H ${minutes.toString().padLeft(2, '0')}M',
            style: const TextStyle(
              color: kDurationPickerTitle,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}
