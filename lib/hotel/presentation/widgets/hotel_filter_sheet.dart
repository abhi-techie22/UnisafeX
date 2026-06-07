import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../domain/entities/hotel_search_params.dart';
import '../providers/hotel_providers.dart';

class HotelFilterSheet extends ConsumerStatefulWidget {
  const HotelFilterSheet({super.key});

  @override
  ConsumerState<HotelFilterSheet> createState() => _HotelFilterSheetState();
}

class _HotelFilterSheetState extends ConsumerState<HotelFilterSheet> {
  late HotelSortBy _sort;
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;
  late List<HotelTierFilter> _tiers;

  @override
  void initState() {
    super.initState();
    final p = ref.read(hotelSearchParamsProvider);
    _sort = p.sortBy;
    _minPrice = p.minPrice ?? 0;
    _maxPrice = p.maxPrice ?? 50000;
    _minRating = p.minRating ?? 0;
    _tiers = List.from(p.tiers);
  }

  void _apply() {
    final notifier = ref.read(hotelSearchParamsProvider.notifier);
    notifier.updateSort(_sort);
    notifier.updateMinPrice(_minPrice > 0 ? _minPrice : null);
    notifier.updateMaxPrice(_maxPrice < 50000 ? _maxPrice : null);
    notifier.updateMinRating(_minRating > 0 ? _minRating : null);
    notifier.updateTiers(_tiers);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _sort = HotelSortBy.recommended;
      _minPrice = 0;
      _maxPrice = 50000;
      _minRating = 0;
      _tiers = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Text('Filter Hotels',
                  style: AppTextStyles.headlineMedium
                      .copyWith(color: AppColors.ivory)),
              const Spacer(),
              TextButton(
                onPressed: _reset,
                child: Text('Reset',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.goldPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sort by
          Text('Sort by',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: HotelSortBy.values.map((s) {
              final isSelected = _sort == s;
              return GestureDetector(
                onTap: () => setState(() => _sort = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldPrimary
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : AppColors.darkDivider,
                    ),
                  ),
                  child: Text(
                    _sortLabel(s),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.navyDeep
                          : AppColors.darkTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Hotel tier
          Text('Hotel Tier',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: HotelTierFilter.values.map((t) {
              final isSelected = _tiers.contains(t);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _tiers.remove(t);
                    } else {
                      _tiers.add(t);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.navyLight
                        : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : AppColors.darkDivider,
                    ),
                  ),
                  child: Text(
                    _tierLabel(t),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : AppColors.darkTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Price range
          Row(
            children: [
              Text('Price Range',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.darkTextSecondary)),
              const Spacer(),
              Text(
                '₹${_minPrice.toInt()} – ₹${_maxPrice.toInt()}',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.goldPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 50000,
            divisions: 50,
            activeColor: AppColors.goldPrimary,
            inactiveColor: AppColors.darkDivider,
            onChanged: (v) => setState(() {
              _minPrice = v.start;
              _maxPrice = v.end;
            }),
          ),

          const SizedBox(height: 12),

          // Minimum rating
          Row(
            children: [
              Text('Min Rating',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.darkTextSecondary)),
              const Spacer(),
              Text(
                _minRating == 0
                    ? 'Any'
                    : '${_minRating.toStringAsFixed(1)}+',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.goldPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: AppColors.goldPrimary,
            inactiveColor: AppColors.darkDivider,
            onChanged: (v) => setState(() => _minRating = v),
          ),

          const SizedBox(height: 20),

          // Apply
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.navyDeep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              child: Text('Apply Filters',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.navyDeep)),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(HotelSortBy s) {
    switch (s) {
      case HotelSortBy.recommended:
        return 'Recommended';
      case HotelSortBy.priceLow:
        return 'Price: Low';
      case HotelSortBy.priceHigh:
        return 'Price: High';
      case HotelSortBy.rating:
        return 'Top Rated';
      case HotelSortBy.distance:
        return 'Nearest';
    }
  }

  String _tierLabel(HotelTierFilter t) {
    switch (t) {
      case HotelTierFilter.budget:
        return '💰 Budget';
      case HotelTierFilter.midRange:
        return '⭐ Premium';
      case HotelTierFilter.luxury:
        return '✨ Luxury';
      case HotelTierFilter.ultraLuxury:
        return '👑 Ultra Luxury';
    }
  }
}
