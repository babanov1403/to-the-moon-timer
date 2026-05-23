import 'package:flutter/material.dart';

import '../../application/timer_config.dart';

const Color _kPanel = Color(0xFF0F0F2A);
const Color _kCyan = Color(0xFF44DDFF);
const Color _kYellow = Color(0xFFFFDD00);
const Color _kMuted = Color(0xFF5555AA);

/// Retro Material duration selector that lists all selectable durations.
class DurationWheel extends StatefulWidget {
  const DurationWheel({
    super.key,
    required this.initialIndex,
    required this.onChanged,
  });

  final int initialIndex;
  final ValueChanged<int> onChanged;

  @override
  State<DurationWheel> createState() => _DurationWheelState();
}

class _DurationWheelState extends State<DurationWheel> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, kDurationMinutes.length - 1);
  }

  @override
  void didUpdateWidget(DurationWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex =
          widget.initialIndex.clamp(0, kDurationMinutes.length - 1);
    }
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    widget.onChanged(index);
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
      itemCount: kDurationMinutes.length,
      itemBuilder: (context, index) {
        final minutes = kDurationMinutes[index];
        final selected = index == _selectedIndex;
        return _RetroDurationTile(
          minutes: minutes,
          selected: selected,
          onTap: () => _select(index),
        );
      },
    );
  }
}

class _RetroDurationTile extends StatelessWidget {
  const _RetroDurationTile({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _kCyan : _kMuted;
    final textColor = selected ? _kCyan : const Color(0xFFCCCCFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        splashColor: _kCyan.withValues(alpha: 0.16),
        highlightColor: _kCyan.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? _kCyan.withValues(alpha: 0.09) : _kPanel,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kCyan.withValues(alpha: 0.28),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    color: _kYellow,
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MIN',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.76),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
