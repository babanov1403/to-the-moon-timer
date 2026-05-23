import 'package:flutter/material.dart';

import 'duration_picker_colors.dart';

class RetroHeaderButton extends StatelessWidget {
  const RetroHeaderButton({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: _decoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(label, style: _textStyle()),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: kDurationPickerPanel.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: 0.42), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 14,
        ),
      ],
    );
  }

  TextStyle _textStyle() {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.4,
    );
  }
}
