import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../domain/entities/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final bool isSelected;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldPrimary.withValues(alpha: 0.08)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : AppColors.darkDivider,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image strip
            if (room.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: room.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.ivory),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.goldPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: AppColors.navyDeep, size: 13),
                        ),
                    ],
                  ),

                  if (room.description != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      room.description!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.darkTextSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Bed + occupancy
                  Row(
                    children: [
                      _InfoPill(
                        icon: Icons.bed_outlined,
                        label: '${room.bedCount}× ${room.bedType}',
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        icon: Icons.person_outline,
                        label: 'Max ${room.maxOccupancy}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tags row
                  Wrap(
                    spacing: 6,
                    children: [
                      if (room.breakfastIncluded)
                        _Tag(
                            label: 'Breakfast Included',
                            color: AppColors.success),
                      if (room.refundable)
                        _Tag(
                            label: 'Free Cancellation',
                            color: AppColors.info),
                      if (!room.refundable)
                        _Tag(
                            label: 'Non-Refundable',
                            color: AppColors.warning),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        room.formattedPrice,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '/ night',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.darkTextMuted),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? null
                              : const LinearGradient(colors: [
                                  AppColors.goldLight,
                                  AppColors.goldDark,
                                ]),
                          color: isSelected
                              ? AppColors.goldPrimary.withValues(alpha: 0.15)
                              : null,
                          borderRadius: BorderRadius.circular(100),
                          border: isSelected
                              ? Border.all(color: AppColors.goldPrimary)
                              : null,
                        ),
                        child: Text(
                          isSelected ? 'Selected ✓' : 'Select',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.goldPrimary
                                : AppColors.navyDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.darkTextMuted, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.darkTextSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 9),
      ),
    );
  }
}
