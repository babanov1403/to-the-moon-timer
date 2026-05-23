import 'package:flutter/material.dart';

import 'duration_picker_colors.dart';
import 'tile_label.dart';

class RetroDurationTile extends StatelessWidget {
  const RetroDurationTile({
    super.key,
    required this.minutes,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final int minutes;
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
        borderRadius: BorderRadius.circular(4),
        splashColor: selectedColor.withValues(alpha: 0.16),
        highlightColor: selectedColor.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: _decoration(borderColor),
          child: Stack(
            children: [
              if (selected) const _SelectedMarker(),
              Center(child: TileLabel(minutes: minutes, textColor: textColor)),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(Color borderColor) {
    return BoxDecoration(
      color: selected
          ? selectedColor.withValues(alpha: 0.09)
          : kDurationPickerPanel,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: borderColor, width: selected ? 2 : 1),
      boxShadow: selected ? [_shadow()] : [],
    );
  }

  BoxShadow _shadow() {
    return BoxShadow(
      color: selectedColor.withValues(alpha: 0.28),
      blurRadius: 14,
      spreadRadius: 1,
    );
  }
}

class _SelectedMarker extends StatelessWidget {
  const _SelectedMarker();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 6,
      top: 6,
      child: Container(width: 6, height: 6, color: kDurationPickerYellow),
    );
  }
}
