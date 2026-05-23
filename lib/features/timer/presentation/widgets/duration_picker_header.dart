import 'package:flutter/material.dart';

const Color _kCyan = Color(0xFF44DDFF);
const Color _kYellow = Color(0xFFFFDD00);
const Color _kPanel = Color(0xFF0F0F2A);

/// Header bar for the duration picker sheet with Reset and Done actions.
class DurationPickerHeader extends StatelessWidget {
  const DurationPickerHeader({
    super.key,
    required this.onReset,
    required this.onDone,
  });

  final VoidCallback onReset;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          _RetroHeaderButton(
            label: 'RESET',
            color: _kYellow,
            icon: Icons.restart_alt_rounded,
            onTap: onReset,
          ),
          const Expanded(
            child: Text(
              'DURATION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCCCCFF),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.6,
              ),
            ),
          ),
          _RetroHeaderButton(
            label: 'DONE',
            color: _kCyan,
            icon: Icons.check_rounded,
            onTap: onDone,
          ),
        ],
      ),
    );
  }
}

class _RetroHeaderButton extends StatelessWidget {
  const _RetroHeaderButton({
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
        borderRadius: BorderRadius.circular(4),
        splashColor: color.withValues(alpha: 0.16),
        highlightColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
