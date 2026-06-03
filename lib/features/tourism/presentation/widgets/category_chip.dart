import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? categoryColor;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.categoryColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = categoryColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(isDark ? 0.25 : 0.12)
                : (isDark ? AppColors.grey800 : AppColors.grey100),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? color
                      : (isDark ? AppColors.grey400 : AppColors.grey600),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? color
                      : (isDark ? AppColors.grey400 : AppColors.grey600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
