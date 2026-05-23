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
