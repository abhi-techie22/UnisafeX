import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/shimmer_loader.dart';
import '../providers/hotel_providers.dart';
import '../widgets/hotel_card.dart';
import '../widgets/hotel_filter_sheet.dart';
import '../widgets/hotel_date_picker_sheet.dart';

class HotelListScreen extends ConsumerWidget {
  const HotelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(hotelSearchParamsProvider);
    final hotelsAsync = ref.watch(hotelSearchResultsProvider);
    final fmt = DateFormat('dd MMM');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: innerBoxIsScrolled
                ? AppColors.darkSurface.withValues(alpha: 0.97)
                : AppColors.darkBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.darkTextPrimary),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  params.city,
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.ivory),
                ),
                Text(
                  '${fmt.format(params.checkIn)} – ${fmt.format(params.checkOut)} · ${params.adults} adult${params.adults != 1 ? 's' : ''}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.darkTextMuted),
                ),
              ],
            ),
            actions: [
              // Date edit
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined,
                    color: AppColors.goldPrimary, size: 20),
                onPressed: () => _showDatePicker(context, ref),
              ),
              // Filter
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.goldPrimary, size: 20),
                onPressed: () => _showFilters(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
        body: hotelsAsync.when(
          data: (hotels) {
            if (hotels.isEmpty) return _EmptyState(city: params.city);

            return Column(
              children: [
                // Result count + sort chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '${hotels.length} hotels found',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.darkTextMuted),
                      ),
                      const Spacer(),
                      _SortChip(sort: params.sortBy),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // Hotel list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: hotels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => HotelCard(
                      hotel: hotels[i],
                      index: i,
                      onTap: () => context.push(
                        '/hotel/detail/${hotels[i].id}',
                        extra: hotels[i],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => _LoadingList(),
          error: (e, _) => _ErrorState(message: e.toString()),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HotelFilterSheet(),
    );
  }

  void _showDatePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HotelDatePickerSheet(
        onConfirm: (checkIn, checkOut, adults, rooms) {
          final n = ref.read(hotelSearchParamsProvider.notifier);
          n.updateDates(checkIn, checkOut);
          n.updateGuests(adults);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  final HotelSortBy sort;
  const _SortChip({required this.sort});

  String get _label {
    switch (sort) {
      case HotelSortBy.recommended:
        return 'Recommended';
      case HotelSortBy.priceLow:
        return 'Price ↑';
      case HotelSortBy.priceHigh:
        return 'Price ↓';
      case HotelSortBy.rating:
        return 'Top Rated';
      case HotelSortBy.distance:
        return 'Nearest';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const HotelFilterSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.darkDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.darkTextSecondary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_vert,
                color: AppColors.darkTextMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => ShimmerLoader(
        child: Container(
          height: 270,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String city;
  const _EmptyState({required this.city});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel, color: AppColors.darkTextMuted, size: 64),
          const SizedBox(height: 16),
          Text('No hotels found in $city',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 8),
          Text('Try adjusting your filters',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.darkTextMuted)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.darkTextMuted, size: 56),
            const SizedBox(height: 16),
            Text('Unable to load hotels',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.darkTextSecondary)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.darkTextMuted)),
          ],
        ),
      ),
    );
  }
}
