import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

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

  double? _calculateDistance() {
    final location = ref.read(locationProvider).value;
    if (location == null) return null;

    const radians = math.pi / 180;
    final haversine = 0.5 -
        math.cos((widget.place.latitude - location.latitude) * radians) / 2 +
        math.cos(location.latitude * radians) *
            math.cos(widget.place.latitude * radians) *
            (1 -
                math.cos(
                  (widget.place.longitude - location.longitude) * radians,
                )) /
            2;

    return 12742 * math.asin(math.sqrt(haversine));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final place = widget.place;
    final distance = _calculateDistance();

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
                _Section(
                  title: 'Visitor Information',
                  child: _InfoCard(
                    isDark: isDark,
                    children: [
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: place.address?.isNotEmpty == true
                            ? place.address!
                            : _locationLabel(place),
                      ),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Timings',
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
                          label: 'Best season',
                          value: place.bestSeason!,
                        ),
                      if (place.visitDurationMinutes != null)
                        _InfoRow(
                          icon: Icons.timelapse,
                          label: 'Suggested duration',
                          value: _formatDuration(place.visitDurationMinutes!),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'About',
                  child: Text(
                    place.description,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
                if (place.bestMonths.isNotEmpty)
                  _Section(
                    title: 'Best Months',
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
                    title: 'Safety Guidelines',
                    icon: Icons.health_and_safety_outlined,
                    items: place.safetyGuidelines,
                  ),
                if (place.touristTips.isNotEmpty)
                  _BulletSection(
                    title: 'Traveler Tips',
                    icon: Icons.lightbulb_outline,
                    items: place.touristTips,
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
                label: 'Get Directions',
                onPressed: () => context.go(AppRoutes.map, extra: place),
                icon: Icons.navigation,
              ),
            ],
          ),
        ),
      ),
    );
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
