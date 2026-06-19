import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';
import 'package:unisafex/features/guide/presentation/providers/guide_request_provider.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/profile/domain/profile_completion.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';
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
  Set<String> _dismissedGuideRequestKeys = const {};
  ProviderSubscription<List<GuideRequest>>? _guideRequestSubscription;
  bool _tourCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedGuideRequests();
    _guideRequestSubscription = ref.listenManual<List<GuideRequest>>(
      guideRequestsProvider,
      (previous, next) => _showHomeGuideStatusPopup(previous, next),
    );
  }

  @override
  void dispose() {
    _guideRequestSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileNotifierProvider);
    final location = ref.watch(locationProvider);
    final featured = ref.watch(featuredPlacesProvider);
    final popular = ref.watch(popularPlacesProvider);
    final trending = ref.watch(trendingPlacesProvider);
    final mustVisit = ref.watch(mustVisitPlacesProvider);
    final guideRequests = ref.watch(guideRequestsProvider);
    final featureFlags = ref.watch(publicFeatureFlagsProvider).valueOrNull ??
        const FeatureFlags({});
    final banners = ref.watch(activeHomeBannersProvider);
    final travelAlerts = ref.watch(activeTravelAlertsProvider);
    final visibleGuideRequest = _visibleGuideRequest(guideRequests);
    final cityName = location.asData?.value?.name ?? 'India';
    final locationData = location.asData?.value;
    final nearby = locationData == null
        ? null
        : ref.watch(
            nearbyPlacesProvider(
              NearbyParams(
                lat: locationData.latitude,
                lng: locationData.longitude,
                radiusKm: 100,
              ),
            ),
          );
    final greeting = _getGreeting();
    if (user != null && !_tourCheckScheduled) {
      _tourCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowFeatureTour(user.id);
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                                      : 'explore'.tr() + ' $cityName',
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
                                  'explore'.tr() + ' $cityName',
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
                            error: (_, __) => _buildAvatar(null, 'T', null),
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
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
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
                        'search'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          if (visibleGuideRequest != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _HomeGuideRequestCard(
                  request: visibleGuideRequest,
                  onTap: () => context.go(AppRoutes.guideRequest),
                  onDismiss: () => _dismissGuideRequest(visibleGuideRequest),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: profile.when(
              data: (p) => _ProfileCompletionPrompt(
                percent: profileCompletionPercent(p),
                onTap: () => context.push(AppRoutes.identityDetails),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          SliverToBoxAdapter(
            child: _HomeTravelAlertsSection(alerts: travelAlerts),
          ),

          SliverToBoxAdapter(
            child: _HomeRemoteBannersSection(
              banners: banners,
              flags: featureFlags,
              onTap: (route) {
                if (route == null || route.trim().isEmpty) return;
                context.push(route.trim());
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push(AppRoutes.travelToolkit),
                child: Ink(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan your India journey',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Trip planner, currency, phrases and more',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Featured
          if (nearby != null)
            SliverToBoxAdapter(
              child: nearby.when(
                loading: () => _buildHorizontalShimmer(height: 200),
                error: (_, __) => const SizedBox.shrink(),
                data: (places) => places.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'nearby_places'.tr(),
                            subtitle: 'real_distance_from'.tr(args: [cityName]),
                            onSeeAll: () => context.go(AppRoutes.map),
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: places.take(10).length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (_, index) => PlaceCard(
                                place: places[index],
                                onTap: () => context.push(
                                  AppRoutes.placeDetail,
                                  extra: places[index],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          // Featured
          SliverToBoxAdapter(
            child: featured.when(
              data: (places) => places.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'featured_destinations'.tr(),
                          onSeeAll: () => context.go(
                            '${AppRoutes.placesList}?title=Featured',
                          ),
                        ),
                        SizedBox(
                          height: 260,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          title: 'must_visit_places'.tr(),
                          subtitle: 'Iconic Indian landmarks',
                          onSeeAll: () => context.go(
                            '${AppRoutes.placesList}?title=Must Visit',
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          title: 'trending_now'.tr(),
                          subtitle: 'Popular with travelers this week',
                          onSeeAll: () => context.go(
                            '${AppRoutes.placesList}?title=Trending',
                          ),
                        ),
                        SizedBox(
                          height: 210,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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

          // Popular Places
          SliverToBoxAdapter(
            child: popular.when(
              data: (places) {
                final filtered = places;

                return filtered.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'popular_places'.tr(),
                            subtitle: 'Loved by international tourists',
                            onSeeAll: () => context.go(
                              '${AppRoutes.placesList}?title=Popular',
                            ),
                          ),
                          ...filtered.take(6).map((place) => Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _HomeBottomDiscoveryCard(
                aiEnabled: featureFlags.aiAssistant,
                onToolkit: () => context.push(AppRoutes.travelToolkit),
                onAssistant: () => context.push(AppRoutes.aiAssistant),
                onAllPlaces: () => context.push(
                  '${AppRoutes.placesList}?title=All Destinations',
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning'.tr();
    if (hour < 17) return 'good_afternoon'.tr();
    return 'good_evening'.tr();
  }

  Widget _buildAvatar(String? imageUrl, String initials, String? countryCode) {
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
    return countryCode
        .toUpperCase()
        .runes
        .map((r) => String.fromCharCode(r + 127397))
        .join('');
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
              'no_results'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'browse_by_category'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDismissedGuideRequests() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences.getStringList(_dismissedGuideRequestsKey) ?? [];
    if (!mounted) return;
    setState(() => _dismissedGuideRequestKeys = keys.toSet());
  }

  GuideRequest? _visibleGuideRequest(List<GuideRequest> requests) {
    for (final request in requests) {
      if (!_dismissedGuideRequestKeys.contains(_guideDismissKey(request))) {
        return request;
      }
    }
    return null;
  }

  Future<void> _dismissGuideRequest(GuideRequest request) async {
    final next = {..._dismissedGuideRequestKeys, _guideDismissKey(request)};
    setState(() => _dismissedGuideRequestKeys = next);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_dismissedGuideRequestsKey, next.toList());
  }

  void _showHomeGuideStatusPopup(
    List<GuideRequest>? previous,
    List<GuideRequest> next,
  ) {
    if (previous == null || previous.isEmpty || next.isEmpty) return;
    final oldById = {for (final request in previous) request.id: request};
    for (final request in next) {
      final old = oldById[request.id];
      if (old == null || old.status == request.status) continue;
      if (!_homeShouldPopupForStatus(request.status)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_homeGuidePopupTitle(request.status)),
            content: Text(
              '${request.placeName} is now '
              '${_homeGuideStatusMessage(request.status).toLowerCase()}.\n\n'
              'Tap the guide card on Home or open Guide Request to see history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.guideRequest);
                },
                child: const Text('Open request'),
              ),
            ],
          ),
        );
      });
      return;
    }
  }

  Future<void> _maybeShowFeatureTour(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _featureTourSeenKey(userId);
    if (preferences.getBool(key) == true || !mounted) return;
    await _showFeatureTour(userId);
  }

  Future<void> _markFeatureTourSeen(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_featureTourSeenKey(userId), true);
  }

  Future<void> _showFeatureTour(String userId) async {
    var page = 0;
    final controller = PageController();
    final steps = const [
      _TourData(
        icon: Icons.badge_outlined,
        title: 'Step 1: Complete your travel identity',
        text:
            'Add nationality, visa and current city so UniSafeX can personalize safety and travel flows.',
      ),
      _TourData(
        icon: Icons.flag_rounded,
        title: 'Step 2: Build your bucket list',
        text:
            'Save places you want to visit, then mark them completed after your trip.',
      ),
      _TourData(
        icon: Icons.support_agent_rounded,
        title: 'Step 3: Use tools and guide support',
        text:
            'Open toolkit for planner, currency and phrases. Delhi travelers can request a verified guide.',
      ),
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome to UniSafeX',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _markFeatureTourSeen(userId);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 290,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: steps.length,
                      onPageChanged: (value) =>
                          setDialogState(() => page = value),
                      itemBuilder: (_, index) =>
                          _FeatureTourPage(data: steps[index]),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == page ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == page
                              ? AppColors.primary
                              : AppColors.grey300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (page > 0)
                        TextButton(
                          onPressed: () => controller.previousPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          ),
                          child: const Text('Back'),
                        )
                      else
                        const Spacer(),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          if (page == steps.length - 1) {
                            await _markFeatureTourSeen(userId);
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            await controller.nextPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        icon: Icon(
                          page == steps.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                        label: Text(
                          page == steps.length - 1 ? 'Start exploring' : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    controller.dispose();
  }
}

const _dismissedGuideRequestsKey = 'dismissed_home_guide_requests_v1';
const _featureTourSeenPrefix = 'home_feature_tour_seen_v2';

String _featureTourSeenKey(String userId) => '$_featureTourSeenPrefix:$userId';

String _guideDismissKey(GuideRequest request) {
  return '${request.id}:${request.status.name}';
}

class _AvatarShimmer extends StatelessWidget {
  const _AvatarShimmer();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(width: 48, height: 48, borderRadius: 14);
  }
}

class _TourData {
  const _TourData({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;
}

class _FeatureTourPage extends StatelessWidget {
  const _FeatureTourPage({required this.data});

  final _TourData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(data.icon, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 22),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(
          data.text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _ProfileCompletionPrompt extends StatelessWidget {
  const _ProfileCompletionPrompt({
    required this.percent,
    required this.onTap,
  });

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (percent >= 100) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_pin_rounded, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile $percent% complete',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTravelAlertsSection extends StatelessWidget {
  const _HomeTravelAlertsSection({required this.alerts});

  final AsyncValue<List<TravelAlert>> alerts;

  @override
  Widget build(BuildContext context) {
    return alerts.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            children: items
                .take(2)
                .map((alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HomeTravelAlertCard(alert: alert),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _HomeTravelAlertCard extends StatelessWidget {
  const _HomeTravelAlertCard({required this.alert});

  final TravelAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = _homeAlertColor(alert.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(_homeAlertIcon(alert.severity), color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeRemoteBannersSection extends StatelessWidget {
  const _HomeRemoteBannersSection({
    required this.banners,
    required this.flags,
    required this.onTap,
  });

  final AsyncValue<List<HomeBanner>> banners;
  final FeatureFlags flags;
  final ValueChanged<String?> onTap;

  @override
  Widget build(BuildContext context) {
    return banners.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final visible = items.where((item) => _bannerAllowed(item)).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            itemCount: visible.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _HomeRemoteBannerCard(
              banner: visible[index],
              onTap: () => onTap(visible[index].actionRoute),
            ),
          ),
        );
      },
    );
  }

  bool _bannerAllowed(HomeBanner banner) {
    return switch (banner.bannerType) {
      'festival' => flags.festivalCampaign,
      'hotel_promo' => flags.hotels,
      'flight_promo' => flags.flights,
      'emergency' => flags.sos,
      _ => true,
    };
  }
}

class _HomeRemoteBannerCard extends StatelessWidget {
  const _HomeRemoteBannerCard({
    required this.banner,
    required this.onTap,
  });

  final HomeBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAction = banner.actionRoute?.trim().isNotEmpty == true;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: hasAction ? onTap : null,
      child: Ink(
        width: 285,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryDark,
              _homeBannerAccent(banner.bannerType),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          image: banner.imageUrl?.trim().isNotEmpty == true
              ? DecorationImage(
                  image: NetworkImage(banner.imageUrl!.trim()),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.42),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_homeBannerIcon(banner.bannerType),
                color: Colors.white, size: 26),
            const Spacer(),
            Text(
              banner.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (banner.subtitle?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 3),
              Text(
                banner.subtitle!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, height: 1.25),
              ),
            ],
            if (hasAction && banner.actionLabel?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                banner.actionLabel!.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeBottomDiscoveryCard extends StatelessWidget {
  const _HomeBottomDiscoveryCard({
    required this.aiEnabled,
    required this.onToolkit,
    required this.onAssistant,
    required this.onAllPlaces,
  });

  final bool aiEnabled;
  final VoidCallback onToolkit;
  final VoidCallback onAssistant;
  final VoidCallback onAllPlaces;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Make today’s plan stronger',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Compare safe places, ask the assistant, and browse every destination '
            'when you want a deeper India itinerary.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onToolkit,
                icon: const Icon(Icons.widgets_rounded, size: 18),
                label: const Text('Toolkit'),
              ),
              if (aiEnabled)
                FilledButton.tonalIcon(
                  onPressed: onAssistant,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Ask AI'),
                ),
              OutlinedButton.icon(
                onPressed: onAllPlaces,
                icon: const Icon(Icons.account_balance_rounded, size: 18),
                label: const Text('All places'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _homeAlertIcon(String severity) {
  return switch (severity) {
    'emergency' => Icons.emergency_rounded,
    'warning' => Icons.warning_amber_rounded,
    _ => Icons.info_outline_rounded,
  };
}

Color _homeAlertColor(String severity) {
  return switch (severity) {
    'emergency' => AppColors.error,
    'warning' => AppColors.warning,
    _ => AppColors.primary,
  };
}

IconData _homeBannerIcon(String type) {
  return switch (type) {
    'festival' => Icons.celebration_rounded,
    'hotel_promo' => Icons.hotel_rounded,
    'flight_promo' => Icons.flight_takeoff_rounded,
    'emergency' => Icons.warning_amber_rounded,
    _ => Icons.location_city_rounded,
  };
}

Color _homeBannerAccent(String type) {
  return switch (type) {
    'festival' => AppColors.accent,
    'hotel_promo' => AppColors.success,
    'flight_promo' => AppColors.info,
    'emergency' => AppColors.error,
    _ => AppColors.primary,
  };
}

class _HomeGuideRequestCard extends StatelessWidget {
  final GuideRequest request;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _HomeGuideRequestCard({
    required this.request,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _homeGuideStatusColor(request.status);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(_homeGuideStatusIcon(request.status), color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.placeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _homeGuideStatusMessage(request.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    minHeight: 3,
                    value: _homeGuideStatusProgress(request.status),
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
            IconButton(
              tooltip: 'View request',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              onPressed: onTap,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularPlaceListItem extends StatelessWidget {
  final TourismPlace place;
  final VoidCallback onTap;

  const _PopularPlaceListItem({required this.place, required this.onTap});

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
                          style: Theme.of(context).textTheme.bodySmall,
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
                            child: Text(
                              'free_entry'.tr(),
                              style: const TextStyle(
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

bool _homeShouldPopupForStatus(GuideRequestStatus status) {
  return status == GuideRequestStatus.confirmed ||
      status == GuideRequestStatus.rejected ||
      status == GuideRequestStatus.completed;
}

String _homeGuidePopupTitle(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.confirmed => 'Guide confirmed',
    GuideRequestStatus.rejected => 'Guide request rejected',
    GuideRequestStatus.completed => 'Guide request completed',
    GuideRequestStatus.pending => 'Guide request pending',
    GuideRequestStatus.processing => 'Guide request processing',
  };
}

String _homeGuideStatusMessage(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => 'Submitted and waiting for review',
    GuideRequestStatus.processing => 'Team review in progress',
    GuideRequestStatus.confirmed => 'Guide confirmed by UniSafeX',
    GuideRequestStatus.rejected => 'Rejected by admin team',
    GuideRequestStatus.completed => 'Guide service completed',
  };
}

double _homeGuideStatusProgress(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => 0.18,
    GuideRequestStatus.processing => 0.45,
    GuideRequestStatus.confirmed => 0.78,
    GuideRequestStatus.rejected => 1.0,
    GuideRequestStatus.completed => 1.0,
  };
}

IconData _homeGuideStatusIcon(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => Icons.hourglass_top_rounded,
    GuideRequestStatus.processing => Icons.manage_search_rounded,
    GuideRequestStatus.confirmed => Icons.verified_rounded,
    GuideRequestStatus.rejected => Icons.cancel_rounded,
    GuideRequestStatus.completed => Icons.task_alt_rounded,
  };
}

Color _homeGuideStatusColor(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => AppColors.warning,
    GuideRequestStatus.processing => AppColors.primary,
    GuideRequestStatus.confirmed => AppColors.success,
    GuideRequestStatus.rejected => AppColors.error,
    GuideRequestStatus.completed => AppColors.success,
  };
}
