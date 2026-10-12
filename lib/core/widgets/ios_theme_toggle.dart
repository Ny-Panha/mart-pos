import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// iPhone/iOS-style animated toggle switch with sun and moon icons
class IosThemeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const IosThemeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value
              ? AppColors.primary
              : const Color(0xFFCBD5E1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                value ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                size: 13,
                color: value ? AppColors.primary : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
