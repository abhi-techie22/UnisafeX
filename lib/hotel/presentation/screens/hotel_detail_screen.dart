import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/rating_stars.dart';
import '../../../widgets/common/shimmer_loader.dart';
import '../../domain/entities/hotel.dart';
import '../providers/hotel_providers.dart';

class HotelDetailScreen extends ConsumerStatefulWidget {
  final String hotelId;
  final Hotel? cachedHotel;

  const HotelDetailScreen({
    super.key,
    required this.hotelId,
    this.cachedHotel,
  });

  @override
  ConsumerState<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends ConsumerState<HotelDetailScreen> {
  late final ScrollController _scroll;
  bool _titleVisible = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()
      ..addListener(() {
        final show = _scroll.offset > 260;
        if (show != _titleVisible) setState(() => _titleVisible = show);
      });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotelAsync = ref.watch(hotelDetailProvider(widget.hotelId));
    final hotel = hotelAsync.value ?? widget.cachedHotel;
    final params = ref.watch(hotelSearchParamsProvider);
    final isSaved =
        ref.watch(savedHotelsProvider).contains(widget.hotelId);
    final fmt = DateFormat('dd MMM');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _titleVisible
            ? AppColors.darkSurface.withValues(alpha: 0.96)
            : Colors.transparent,
        elevation: 0,
        leading: _CircleBtn(
          icon: Icons.arrow_back,
          onTap: () => context.pop(),
        ),
        actions: [
          _CircleBtn(
            icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline,
            iconColor:
                isSaved ? AppColors.goldPrimary : Colors.white,
            onTap: () => ref
                .read(savedHotelsProvider.notifier)
                .toggle(widget.hotelId),
          ),
          const SizedBox(width: 8),
        ],
        title: AnimatedOpacity(
          opacity: _titleVisible ? 1 : 0,
          duration: 200.ms,
          child: Text(
            hotel?.name ?? '',
            style:
                AppTextStyles.titleLarge.copyWith(color: AppColors.ivory),
          ),
        ),
      ),
      body: hotel == null && hotelAsync.isLoading
          ? const _LoadingDetail()
          : hotel == null
              ? _errorWidget()
              : _buildContent(hotel, params, fmt),
      bottomNavigationBar:
          hotel == null ? null : _buildBottomBar(hotel, params),
    );
  }

  Widget _buildContent(Hotel hotel, params, DateFormat fmt) {
    return CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero image ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: _HeroImageSection(
            hotel: hotel,
            selectedIndex: _imageIndex,
            onPageChanged: (i) => setState(() => _imageIndex = i),
          ),
        ),

        // ── Content ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Name + tier
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        hotel.name,
                        style: AppTextStyles.displaySmall
                            .copyWith(color: AppColors.ivory),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TierBadgeDetail(tier: hotel.tier),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.goldPrimary, size: 15),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hotel.address ?? hotel.city,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.darkTextSecondary),
                      ),
                    ),
                    if (hotel.distanceKm != null)
                      Text(
                        '${hotel.distanceKm!.toStringAsFixed(1)} km away',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.info),
                      ),
                  ],
                ).animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 14),

                // Rating row
                Row(
                  children: [
                    RatingStars(rating: hotel.rating, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      hotel.rating.toStringAsFixed(1),
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.ivory),
                    ),
                    if (hotel.reviewCount != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${hotel.reviewCount} reviews)',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.darkTextMuted),
                      ),
                    ],
                  ],
                ).animate().fadeIn(delay: 120.ms),

                const SizedBox(height: 20),
                const Divider(color: AppColors.darkDivider),
                const SizedBox(height: 20),

                // Stay summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.darkDivider),
                  ),
                  child: Row(
                    children: [
                      _StayStat(
                        label: 'Check-in',
                        value: fmt.format(params.checkIn),
                        icon: Icons.login,
                      ),
                      const VerticalDivider(
                          color: AppColors.darkDivider, width: 32),
                      _StayStat(
                        label: 'Check-out',
                        value: fmt.format(params.checkOut),
                        icon: Icons.logout,
                      ),
                      const VerticalDivider(
                          color: AppColors.darkDivider, width: 32),
                      _StayStat(
                        label: 'Nights',
                        value: '${params.nights}',
                        icon: Icons.nights_stay_outlined,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 160.ms),

                const SizedBox(height: 24),

                // Description
                if (hotel.description != null) ...[
                  Text('About',
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.ivory)),
                  const SizedBox(height: 10),
                  Text(
                    hotel.description!,
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.darkTextSecondary, height: 1.7),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                ],

                // Amenities
                if (hotel.amenities.isNotEmpty) ...[
                  Text('Amenities',
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.ivory)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.amenities
                        .map((a) => _AmenityChip(label: a))
                        .toList(),
                  ).animate().fadeIn(delay: 240.ms),
                  const SizedBox(height: 24),
                ],

                // Price highlight
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navyMid, AppColors.navyLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            AppColors.goldPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Starting from',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.darkTextMuted)),
                          Text(
                            hotel.formattedPrice,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.goldPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text('per night',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.darkTextMuted)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total for ${params.nights} nights',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.darkTextMuted)),
                          Text(
                            '₹${(hotel.pricePerNight * params.nights).toStringAsFixed(0)}',
                            style: AppTextStyles.headlineMedium
                                .copyWith(color: AppColors.ivory),
                          ),
                          Text('excl. taxes',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.darkTextMuted,
                                  fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 280.ms),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Hotel hotel, params) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
            top: BorderSide(color: AppColors.darkDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Affiliate redirect button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(bookingFlowProvider.notifier).redirectToBookingCom(
                        hotel: hotel,
                        checkIn: params.checkIn,
                        checkOut: params.checkOut,
                        adults: params.adults,
                        rooms: params.rooms,
                      ),
              icon: const Icon(Icons.open_in_browser, size: 16),
              label: const Text('Booking.com'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldPrimary,
                side: const BorderSide(color: AppColors.goldPrimary),
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Select room + book button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                '/hotel/rooms/${hotel.id}',
                extra: hotel,
              ),
              icon: const Icon(Icons.bed_outlined, size: 16),
              label: const Text('Select Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.navyDeep,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorWidget() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined,
                color: AppColors.darkTextMuted, size: 56),
            SizedBox(height: 16),
            Text('Hotel not found',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ],
        ),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────

class _HeroImageSection extends StatelessWidget {
  final Hotel hotel;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  const _HeroImageSection({
    required this.hotel,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final images =
        hotel.imageUrls.isNotEmpty ? hotel.imageUrls : [hotel.imageUrl];
    final validImages = images.where((u) => u != null).toList();

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            onPageChanged: onPageChanged,
            itemCount: validImages.isEmpty ? 1 : validImages.length,
            itemBuilder: (_, i) {
              final url = validImages.isNotEmpty ? validImages[i] : null;
              return url != null
                  ? CachedNetworkImage(
                      imageUrl: url!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.navyMid),
                      errorWidget: (_, __, ___) => _fallback(),
                    )
                  : _fallback();
            },
          ),

          // Gradient overlay
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 1.0],
                  colors: [Colors.transparent, Color(0xFF07101F)],
                ),
              ),
            ),
          ),

          // Image count badge
          if (validImages.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${selectedIndex + 1}/${validImages.length}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.navyMid,
        child: Center(
          child: Icon(Icons.hotel,
              color: AppColors.goldPrimary.withValues(alpha: 0.4), size: 72),
        ),
      );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleBtn({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 18),
      ),
    );
  }
}

class _StayStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StayStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.goldPrimary, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.ivory)),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.darkTextMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Text(label,
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.darkTextSecondary)),
    );
  }
}

class _TierBadgeDetail extends StatelessWidget {
  final HotelTier tier;
  const _TierBadgeDetail({required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      HotelTier.budget => 'BUDGET',
      HotelTier.midRange => 'PREMIUM',
      HotelTier.luxury => 'LUXURY',
      HotelTier.ultraLuxury => '👑 ULTRA',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.overline
              .copyWith(color: AppColors.goldPrimary, fontSize: 9)),
    );
  }
}

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ShimmerLoader(
            child: Container(
                height: 320, color: AppColors.darkCard),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ShimmerLoader(
                    child: Container(
                        height: 28,
                        color: AppColors.darkCard,
                        margin: const EdgeInsets.only(bottom: 10))),
                ShimmerLoader(
                    child: Container(
                        height: 16, color: AppColors.darkCard)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
