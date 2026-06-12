import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/core/utils/google_maps_launcher.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';
import 'package:unisafex/features/tourism/presentation/providers/saved_places_provider.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final TourismPlace place;

  const PlaceDetailScreen({
    super.key,
    required this.place,
  });

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 250;
      if (show != _showAppBarTitle && mounted) {
        setState(() => _showAppBarTitle = show);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double? _calculateDistance(LocationData? location) {
    if (location == null) return null;

    return DistanceCalculator.calculate(
      lat1: location.latitude,
      lon1: location.longitude,
      lat2: widget.place.latitude,
      lon2: widget.place.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final place = widget.place;
    final distance = _calculateDistance(ref.watch(locationProvider).value);
    final safetyScore = SafetyScoreService.calculate(place);
    final localSaved = ref.watch(savedPlacesProvider).contains(place.id);
    final remoteFavorites = ref.watch(favoritesProvider).value ?? [];
    final remoteSaved =
        remoteFavorites.any((favorite) => favorite.placeId == place.id);
    final isFavorite = localSaved || remoteSaved;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Remove saved place' : 'Save place',
                icon: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _toggleFavorite(
                  localSaved: localSaved,
                  remoteSaved: remoteSaved,
                ),
              ),
              IconButton(
                tooltip: 'share'.tr(),
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                onPressed: _sharePlace,
              ),
            ],
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showAppBarTitle ? 1 : 0,
              child: Text(place.name),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: place.images.isNotEmpty ? place.images.length : 1,
                itemBuilder: (_, index) {
                  final imageUrl = place.images.isNotEmpty
                      ? place.images[index]
                      : place.primaryImage;
                  if (imageUrl.isEmpty) return _imageFallback();

                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverList.list(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _locationLabel(place),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    _RatingBadge(rating: place.rating),
                  ],
                ),
                if (distance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${distance.toStringAsFixed(1)} km from your location',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FactChip(
                      icon: Icons.category_outlined,
                      label: place.category,
                    ),
                    if (place.timings?.isNotEmpty == true)
                      _FactChip(
                        icon: Icons.schedule,
                        label: place.timings!,
                      ),
                    if (place.visitDurationMinutes != null)
                      _FactChip(
                        icon: Icons.timelapse,
                        label: _formatDuration(place.visitDurationMinutes!),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                _SafetyScoreCard(score: safetyScore),
                const SizedBox(height: 28),
                _Section(
                  title: 'visitor_information'.tr(),
                  child: _InfoCard(
                    isDark: isDark,
                    children: [
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'address'.tr(),
                        value: place.address?.isNotEmpty == true
                            ? place.address!
                            : _locationLabel(place),
                      ),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'timings'.tr(),
                        value: place.timings?.isNotEmpty == true
                            ? place.timings!
                            : 'Not specified',
                      ),
                      _InfoRow(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Indian entry fee',
                        value: _formatFee(place.entryFeeIndian),
                      ),
                      _InfoRow(
                        icon: Icons.public,
                        label: 'Foreigner entry fee',
                        value: _formatFee(place.entryFeeForeigner),
                      ),
                      if (place.bestSeason?.isNotEmpty == true)
                        _InfoRow(
                          icon: Icons.wb_sunny_outlined,
                          label: 'best_season'.tr(),
                          value: place.bestSeason!,
                        ),
                      if (place.visitDurationMinutes != null)
                        _InfoRow(
                          icon: Icons.timelapse,
                          label: 'suggested_duration'.tr(),
                          value: _formatDuration(place.visitDurationMinutes!),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'about'.tr(),
                  child: Text(
                    place.description,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
                if (place.bestMonths.isNotEmpty)
                  _Section(
                    title: 'best_months'.tr(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: place.bestMonths
                          .map((month) => Chip(label: Text(month)))
                          .toList(),
                    ),
                  ),
                if (place.safetyGuidelines.isNotEmpty)
                  _BulletSection(
                    title: 'safety_guidelines'.tr(),
                    icon: Icons.health_and_safety_outlined,
                    items: place.safetyGuidelines,
                  ),
                if (place.touristTips.isNotEmpty)
                  _BulletSection(
                    title: 'traveler_tips'.tr(),
                    icon: Icons.lightbulb_outline,
                    items: place.touristTips,
                  ),
                _Section(
                  title: 'Continue Planning',
                  child: _PlanningCard(
                    icon: Icons.emergency_outlined,
                    title: 'emergency_help'.tr(),
                    subtitle: 'Essential India helplines',
                    onTap: _showEmergencyHelp,
                  ),
                ),
                _Section(
                  title: 'Coordinates',
                  child: Text(
                    '${place.latitude.toStringAsFixed(5)}, '
                    '${place.longitude.toStringAsFixed(5)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foreigner entry',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatFee(place.entryFeeForeigner),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'get_directions'.tr(),
                onPressed: _openGoogleMaps,
                icon: Icons.navigation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps() async {
    final location = ref.read(locationProvider).value;
    final opened = await GoogleMapsLauncher.openDirections(
      originLatitude: location?.latitude,
      originLongitude: location?.longitude,
      destinationLatitude: widget.place.latitude,
      destinationLongitude: widget.place.longitude,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.grey300,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 48),
    );
  }

  String _locationLabel(TourismPlace place) {
    final parts = [
      if (place.address?.isNotEmpty == true) place.address!,
      if (place.city.isNotEmpty) place.city,
      if (place.state.isNotEmpty) place.state,
    ];
    return parts.toSet().join(', ');
  }

  String _formatFee(double fee) {
    return fee == 0 ? 'Free' : 'INR ${fee.toStringAsFixed(0)}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$minutes min';
    if (remainingMinutes == 0) return '$hours hr';
    return '$hours hr $remainingMinutes min';
  }

  Future<void> _toggleFavorite({
    required bool localSaved,
    required bool remoteSaved,
  }) async {
    final isFavorite = localSaved || remoteSaved;
    if (localSaved || !isFavorite) {
      await ref.read(savedPlacesProvider.notifier).toggle(widget.place.id);
    }
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final notifier = ref.read(favoritesProvider.notifier);
      if (remoteSaved) {
        await notifier.removeFavorite(widget.place.id);
      } else if (!isFavorite) {
        await notifier.addFavorite(widget.place.id);
      }
      ref.invalidate(favoritePlacesProvider);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? '${widget.place.name} removed from saved places'
              : '${widget.place.name} saved for offline reference',
        ),
      ),
    );
  }

  Future<void> _sharePlace() async {
    final text = '${widget.place.name}, ${widget.place.city}, India\n'
        '${widget.place.description}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Place details copied to share')),
    );
  }

  void _showEmergencyHelp() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency help in India',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 18),
            _EmergencyRow(label: 'National emergency', number: '112'),
            _EmergencyRow(label: 'Police', number: '100'),
            _EmergencyRow(label: 'Ambulance', number: '108'),
            _EmergencyRow(label: 'Tourist helpline', number: '1363'),
          ],
        ),
      ),
    );
  }
}

class _SafetyScoreCard extends StatelessWidget {
  final int score;

  const _SafetyScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70 ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: const Icon(Icons.shield_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Safety score · ${SafetyScoreService.label(score)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Estimated from ratings, popularity, and available safety guidance.',
                ),
              ],
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlanningCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmergencyRow extends StatelessWidget {
  final String label;
  final String number;

  const _EmergencyRow({required this.label, required this.number});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.phone_outlined, color: AppColors.error),
      title: Text(label),
      trailing: Text(
        number,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 4),
          Text(rating.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FactChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _InfoCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;

  const _BulletSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      size: 19,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
