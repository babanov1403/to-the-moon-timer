import 'package:flutter/material.dart';

import '../../../application/timer_config.dart';
import 'retro_duration_tile.dart';

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
      _selectedIndex = widget.initialIndex.clamp(
        0,
        kDurationMinutes.length - 1,
      );
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
      itemBuilder: (context, index) => RetroDurationTile(
        minutes: kDurationMinutes[index],
        selected: index == _selectedIndex,
        onTap: () => _select(index),
      ),
    );
  }
}
