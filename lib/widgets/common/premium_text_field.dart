import 'package:flutter/material.dart';
import 'package:unisafex/core/constants/app_colors.dart';
import 'package:unisafex/core/constants/app_text_styles.dart';

class PremiumTextField extends StatelessWidget {
  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ivory),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        filled: true,
        fillColor: AppColors.darkCard,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        hintStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.darkTextMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.goldPrimary),
        ),
      ),
    );
  }
}
