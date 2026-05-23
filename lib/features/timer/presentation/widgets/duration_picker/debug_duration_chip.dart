import 'package:flutter/material.dart';

/// A small tappable chip that sets the timer to the 10-second debug duration.
class DebugDurationChip extends StatelessWidget {
  const DebugDurationChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.bug_report_outlined,
            size: 16,
            color: Color(0xFF8F98B8),
          ),
          const SizedBox(width: 6),
          const Text(
            'Debug:',
            style: TextStyle(color: Color(0xFF8F98B8), fontSize: 13),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              key: const Key('debug_10sec_button'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF111D3A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE6A95C).withValues(alpha: 0.42),
                  width: 1,
                ),
              ),
              child: const Text(
                '10 sec',
                style: TextStyle(
                  color: Color(0xFFE6A95C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
