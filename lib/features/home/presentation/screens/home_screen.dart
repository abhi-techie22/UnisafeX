import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';
import 'package:unisafex/features/tourism/presentation/widgets/category_chip.dart';
import 'package:unisafex/features/tourism/presentation/widgets/featured_place_card.dart';
import 'package:unisafex/features/tourism/presentation/widgets/place_card.dart';
import 'package:unisafex/features/tourism/presentation/widgets/section_header.dart';
import 'package:unisafex/core/widgets/shimmer_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileNotifierProvider);
    final location = ref.watch(locationProvider);
    final featured = ref.watch(featuredPlacesProvider);
    final popular = ref.watch(popularPlacesProvider);
    final trending = ref.watch(trendingPlacesProvider);
    final mustVisit = ref.watch(mustVisitPlacesProvider);
    final isGuest = ref.watch(isGuestProvider);

    final cityName = location.value?.name ?? 'India';
    final greeting = _getGreeting();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                greeting,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? AppColors.grey400
                                          : AppColors.grey600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              profile.when(
                                data: (p) => Text(
                                  p?.fullName != null
                                      ? 'Hello, ${p!.fullName!.split(' ').first} 👋'
                                      : 'Explore $cityName',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                loading: () => Container(
                                  height: 28,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.grey800
                                        : AppColors.grey200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                error: (_, __) => Text(
                                  'Explore $cityName',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Avatar
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.profile),
                          child: profile.when(
                            data: (p) => _buildAvatar(p?.profileImageUrl,
                                p?.initials ?? 'T', p?.countryCode),
                            loading: () => const _AvatarShimmer(),
                            error: (_, __) =>
                                _buildAvatar(null, 'T', null),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search bar CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: GestureDetector(
                onTap: () => context.go(AppRoutes.search),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search places, cities, monuments...',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    CategoryChip(
                      label: 'All',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...AppConstants.placeCategories.map((cat) => CategoryChip(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory =
                                _selectedCategory == cat ? null : cat;
                          }),
                          categoryColor: _getCategoryColor(cat),
                        )),
                  ],
                ),
              ),
            ).animate().slideX(
                  begin: -0.1,
                  duration: 400.ms,
                  delay: 100.ms,
                ),
          ),

          // Featured / Hero cards
          SliverToBoxAdapter(
            child: featured.when(
              data: (places) => places.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Featured Destinations',
                          onSeeAll: () => context.go(
                            '${AppRoutes.placesList}?title=Featured',
                          ),
                        ),
                        SizedBox(
                          height: 260,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: places.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (ctx, i) => FeaturedPlaceCard(
                              place: places[i],
                              onTap: () => context.push(
                                AppRoutes.placeDetail,
                                extra: places[i],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
              loading: () => _buildHorizontalShimmer(height: 260),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          // Must Visit
          SliverToBoxAdapter(
            child: mustVisit.when(
              data: (places) => places.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Must Visit Places',
                          subtitle: 'Iconic Indian landmarks',
                          onSeeAll: () => context.go(
                            '${AppRoutes.placesList}?title=Must Visit',
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: places.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (ctx, i) => PlaceCard(
                              place: places[i],
                              onTap: () => context.push(
                                AppRoutes.placeDetail,
                                extra: places[i],
                              ),
                              width: 180,
                            ),
                          ),
                        ),
                      ],
                    ),
              loading: () => _buildHorizontalShimmer(height: 200),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          // Trending
          SliverToBoxAdapter(
            child: trending.when(
              data: (places) => places.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: '🔥 Trending Now',
                          subtitle: 'Popular with travelers this week',
                          onSeeAll: () => context.go(
                            '${AppRoutes.placesList}?title=Trending',
                          ),
                        ),
                        SizedBox(
                          height: 210,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: places.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (ctx, i) => PlaceCard(
                              place: places[i],
                              onTap: () => context.push(
                                AppRoutes.placeDetail,
                                extra: places[i],
                              ),
                              showBadge: true,
                              badgeLabel: '#${i + 1}',
                              width: 190,
                            ),
                          ),
                        ),
                      ],
                    ),
              loading: () => _buildHorizontalShimmer(height: 210),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          // Popular Places vertical
          SliverToBoxAdapter(
            child: popular.when(
              data: (places) {
                final filtered = _selectedCategory == null
                    ? places
                    : places
                        .where((p) => p.category == _selectedCategory)
                        .toList();

                return filtered.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Popular Places',
                            subtitle: 'Loved by international tourists',
                            onSeeAll: () => context.go(
                              '${AppRoutes.placesList}?title=Popular',
                            ),
                          ),
                          ...filtered.take(6).map((place) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 12),
                                child: _PopularPlaceListItem(
                                  place: place,
                                  onTap: () => context.push(
                                    AppRoutes.placeDetail,
                                    extra: place,
                                  ),
                                ),
                              )),
                        ],
                      );
              },
              loading: () => _buildVerticalShimmer(),
              error: (e, _) => const SizedBox.shrink(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildAvatar(
      String? imageUrl, String initials, String? countryCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                )
              : Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ),
        if (countryCode != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _countryCodeToFlag(countryCode),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  String _countryCodeToFlag(String countryCode) {
    return countryCode.toUpperCase().runes.map((r) => String.fromCharCode(r + 127397)).join('');
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Historical':
        return AppColors.historical;
      case 'Nature':
        return AppColors.nature;
      case 'Spiritual':
        return AppColors.spiritual;
      case 'Adventure':
        return AppColors.adventure;
      case 'Photography':
        return AppColors.photography;
      case 'Food':
        return AppColors.food;
      case 'Shopping':
        return AppColors.shopping;
      case 'Wildlife':
        return AppColors.wildlife;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildHorizontalShimmer({required double height}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: height + 60,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                height: 18,
                width: 160,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.grey800
                      : AppColors.grey200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            SizedBox(
              height: height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, __) => ShimmerLoader(
                  width: 200,
                  height: height,
                  borderRadius: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerLoader(
              width: double.infinity,
              height: 100,
              borderRadius: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.explore_off_rounded,
                size: 48, color: AppColors.grey400),
            const SizedBox(height: 12),
            Text(
              'No places found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different category',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarShimmer extends StatelessWidget {
  const _AvatarShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(width: 48, height: 48, borderRadius: 14);
  }
}

class _PopularPlaceListItem extends StatelessWidget {
  final TourismPlace place;
  final VoidCallback onTap;

  const _PopularPlaceListItem(
      {required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Image.network(
                place.primaryImage,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  color: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.grey400),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${place.city}, ${place.state}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                  color: isDark
                                      ? AppColors.grey300
                                      : AppColors.grey700),
                        ),
                        const SizedBox(width: 12),
                        if (place.isFree)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Free Entry',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppColors.grey600 : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
