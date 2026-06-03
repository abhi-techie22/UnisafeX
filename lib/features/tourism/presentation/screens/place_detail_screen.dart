import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'dart:math' as math;

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final TourismPlace place;

  const PlaceDetailScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  final _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show = _scrollController.offset > 250;
    if (show != _showAppBarTitle) {
      setState(() => _showAppBarTitle = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  double? _calculateDistance() {
    final location = ref.read(locationProvider).value;
    if (location == null) return null;

    const p = math.pi / 180;
    final a = 0.5 -
        math.cos((widget.place.latitude - location.latitude) * p) / 2 +
        math.cos(location.latitude * p) *
            math.cos(widget.place.latitude * p) *
            (1 - math.cos((widget.place.longitude - location.longitude) * p)) /
            2;
    final d = 12742 * math.asin(math.sqrt(a));
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final place = widget.place;
    final isGuest = ref.watch(isGuestProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final isFavorited = favoritesAsync.value?.any((f) => f.placeId == place.id) ?? false;
    final distance = _calculateDistance();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero image slider
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(isGuest, isFavorited),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isFavorited
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: isFavorited ? AppColors.accent : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                title: AnimatedOpacity(
                  opacity: _showAppBarTitle ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(place.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                backgroundColor:
                    _showAppBarTitle ? (isDark ? AppColors.cardDark : AppColors.white) : Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Image carousel
                      PageView.builder(
                        itemCount: place.images.isNotEmpty ? place.images.length : 1,
                        onPageChanged: (i) =>
                            setState(() => _currentImageIndex = i),
                        itemBuilder: (_, i) {
                          final img = place.images.isNotEmpty
                              ? place.images[i]
                              : place.primaryImage;
                          return Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withOpacity(0.15),
                              child: const Icon(Icons.image_outlined,
                                  size: 60, color: AppColors.grey400),
                            ),
                          );
                        },
                      ),

                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                              stops: const [0, 0.4, 1],
                            ),
                          ),
                        ),
                      ),

                      // Image counter
                      if (place.images.length > 1)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${place.images.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                      // Category badge
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(place.category),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            place.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${place.city}, ${place.state}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.grey400
                                                : AppColors.grey600,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 18, color: AppColors.accent),
                                const SizedBox(height: 2),
                                Text(
                                  place.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Quick info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (distance != null)
                            _InfoChip(
                              icon: Icons.near_me_rounded,
                              label: '${distance.toStringAsFixed(1)} km',
                              color: AppColors.info,
                            ),
                          if (place.timings != null)
                            _InfoChip(
                              icon: Icons.access_time_rounded,
                              label: place.timings!,
                              color: AppColors.primary,
                            ),
                          _InfoChip(
                            icon: Icons.confirmation_number_outlined,
                            label: place.formattedEntryFee,
                            color: place.isFree
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          if (place.visitDurationMinutes != null)
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label:
                                  '~${(place.visitDurationMinutes! / 60).toStringAsFixed(1)}h visit',
                              color: AppColors.spiritual,
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _Divider(),

                      // Description
                      _SectionTitle(title: 'About this Place'),
                      const SizedBox(height: 10),
                      Text(
                        place.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.65,
                              color: isDark
                                  ? AppColors.grey300
                                  : AppColors.grey700,
                            ),
                      ),

                      if (place.bestSeason != null) ...[
                        const SizedBox(height: 24),
                        _Divider(),
                        _SectionTitle(title: '🌤 Best Time to Visit'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                place.bestSeason!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (place.bestMonths.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: place.bestMonths
                                .map((m) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.grey800
                                            : AppColors.grey100,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight,
                                        ),
                                      ),
                                      child: Text(
                                        m,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors.grey300
                                              : AppColors.grey700,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],

                      if (place.safetyGuidelines.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _Divider(),
                        _SectionTitle(
                          title: '🛡️ Safety Guidelines',
                          titleColor: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        ...place.safetyGuidelines.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BulletItem(text: tip, color: AppColors.error),
                            )),
                      ],

                      if (place.touristTips.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _Divider(),
                        _SectionTitle(
                          title: '💡 Traveler Tips',
                          titleColor: AppColors.accent,
                        ),
                        const SizedBox(height: 12),
                        ...place.touristTips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BulletItem(text: tip, color: AppColors.accent),
                            )),
                      ],

                      const SizedBox(height: 24),
                      _Divider(),
                      _SectionTitle(title: '📍 Location'),
                      const SizedBox(height: 12),

                      // Map preview
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.map),
                        child: Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.grey800
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  'https://api.mapbox.com/styles/v1/mapbox/light-v11/static/pin-s+1A6B4A(${place.longitude},${place.latitude})/${place.longitude},${place.latitude},13,0/400x160@2x?access_token=pk_placeholder',
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.map_outlined,
                                            size: 40,
                                            color: isDark
                                                ? AppColors.grey600
                                                : AppColors.grey400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to open map',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.grey500
                                                : AppColors.grey400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    color: AppColors.primary.withOpacity(0.05),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.map_rounded,
                                              color: Colors.white, size: 16),
                                          SizedBox(width: 6),
                                          Text(
                                            'Open in Map',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Entry fee info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entry Fee',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          place.isFree
                              ? 'Free for all'
                              : place.formattedEntryFee,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: place.isFree
                                    ? AppColors.success
                                    : null,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Navigate CTA
                  AppButton(
                    label: 'Get Directions',
                    onPressed: () => context.go(AppRoutes.map),
                    icon: Icons.navigation_rounded,
                    height: 52,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(bool isGuest, bool isFavorited) {
    if (isGuest) {
      _showGuestDialog();
      return;
    }
    if (isFavorited) {
      ref.read(favoritesProvider.notifier).removeFavorite(widget.place.id);
    } else {
      ref.read(favoritesProvider.notifier).addFavorite(widget.place.id);
    }
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
            'Create an account to save your favorite places and sync across devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.authSelection);
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Historical': return AppColors.historical;
      case 'Nature': return AppColors.nature;
      case 'Spiritual': return AppColors.spiritual;
      case 'Adventure': return AppColors.adventure;
      case 'Photography': return AppColors.photography;
      case 'Food': return AppColors.food;
      case 'Shopping': return AppColors.shopping;
      case 'Wildlife': return AppColors.wildlife;
      default: return AppColors.primary;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;

  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7, right: 10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.grey300 : AppColors.grey700,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color? titleColor;

  const _SectionTitle({required this.title, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      height: 1,
    );
  }
}
