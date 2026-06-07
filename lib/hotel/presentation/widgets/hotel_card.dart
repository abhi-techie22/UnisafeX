import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../domain/entities/hotel.dart';
import '../providers/hotel_providers.dart';

class HotelCard extends ConsumerWidget {
  final Hotel hotel;
  final VoidCallback onTap;
  final int index;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(savedHotelsProvider).contains(hotel.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.darkDivider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: hotel.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: hotel.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _shimmerPlaceholder(),
                            errorWidget: (_, __, ___) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),

                  // Tier badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _TierBadge(tier: hotel.tier),
                  ),

                  // Save button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(savedHotelsProvider.notifier).toggle(hotel.id),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline,
                          color: isSaved
                              ? AppColors.goldPrimary
                              : Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),

                  // Price overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.navyDeep,
                        borderRadius:
                            BorderRadius.only(topLeft: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hotel.formattedPrice,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.goldPrimary,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'per night',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.darkTextMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Details ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    hotel.name,
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.ivory),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.darkTextMuted, size: 13),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          hotel.address ?? hotel.city,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.darkTextMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hotel.distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${hotel.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.info, fontSize: 10),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Rating + amenities row
                  Row(
                    children: [
                      _RatingBadge(rating: hotel.rating),
                      const SizedBox(width: 8),
                      if (hotel.reviewCount != null)
                        Text(
                          '${hotel.reviewCount} reviews',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.darkTextMuted),
                        ),
                      const Spacer(),
                      // Top 3 amenity icons
                      ..._topAmenities(hotel.amenities)
                          .map((a) => _AmenityDot(label: a)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  List<String> _topAmenities(List<String> all) {
    const priority = ['Pool', 'Spa', 'WiFi', 'Gym', 'Restaurant', 'Bar'];
    final hits = priority.where((p) => all.any(
          (a) => a.toLowerCase().contains(p.toLowerCase()),
        )).take(3).toList();
    return hits;
  }

  Widget _shimmerPlaceholder() => Container(color: AppColors.navyMid);

  Widget _imageFallback() => Container(
        color: AppColors.navyMid,
        child: Center(
          child: Icon(
            Icons.hotel,
            color: AppColors.goldPrimary.withValues(alpha: 0.4),
            size: 48,
          ),
        ),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  final HotelTier tier;
  const _TierBadge({required this.tier});

  Color get _bg {
    switch (tier) {
      case HotelTier.budget:
        return AppColors.success;
      case HotelTier.midRange:
        return AppColors.info;
      case HotelTier.luxury:
        return AppColors.goldDark;
      case HotelTier.ultraLuxury:
        return const Color(0xFF8B0000);
    }
  }

  String get _label {
    switch (tier) {
      case HotelTier.budget:
        return 'BUDGET';
      case HotelTier.midRange:
        return 'PREMIUM';
      case HotelTier.luxury:
        return 'LUXURY';
      case HotelTier.ultraLuxury:
        return 'ULTRA LUXURY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label,
        style: AppTextStyles.overline.copyWith(
          color: Colors.white,
          fontSize: 8,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              color: AppColors.goldPrimary, size: 12),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.goldPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityDot extends StatelessWidget {
  final String label;
  const _AmenityDot({required this.label});

  IconData get _icon {
    final l = label.toLowerCase();
    if (l.contains('pool')) return Icons.pool;
    if (l.contains('spa')) return Icons.spa;
    if (l.contains('wifi')) return Icons.wifi;
    if (l.contains('gym')) return Icons.fitness_center;
    if (l.contains('restaurant')) return Icons.restaurant;
    if (l.contains('bar')) return Icons.local_bar;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: label,
        child: Icon(_icon, color: AppColors.darkTextMuted, size: 14),
      ),
    );
  }
}
