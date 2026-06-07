import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Premium hotel discovery entry card displayed on the Home screen.
class HotelEntryBanner extends StatelessWidget {
  const HotelEntryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/hotel/search'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2850), Color(0xFF1A4080)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.goldPrimary.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.6),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.hotel,
                  color: AppColors.goldPrimary, size: 28),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find & Book Hotels',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.ivory,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Best prices · Instant confirmation · Earn rewards',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.darkTextSecondary, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.goldPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward,
                  color: AppColors.navyDeep, size: 18),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 500.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
