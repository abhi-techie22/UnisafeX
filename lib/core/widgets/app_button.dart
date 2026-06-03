import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild;

    if (isLoading) {
      buttonChild = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.white,
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      buttonChild = Text(label);
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.white,
        ),
        child: buttonChild,
      ),
    );
  }
}

class AppOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;
  final double? height;

  const AppOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      buttonChild = Text(label);
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height ?? 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: buttonChild,
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label),
              ],
            )
          : Text(label),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 44,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isDark ? AppColors.grey800 : AppColors.grey100),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ??
                (isDark ? AppColors.grey300 : AppColors.grey700),
            size: 20,
          ),
        ),
      ),
    );
  }
}
