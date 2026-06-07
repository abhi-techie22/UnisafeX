import 'package:flutter/material.dart';
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
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 250;
      if (show != _showAppBarTitle) {
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

    const p = math.pi / 180;

    final a = 0.5 -
        math.cos((widget.place.latitude - location.latitude) * p) / 2 +
        math.cos(location.latitude * p) *
            math.cos(widget.place.latitude * p) *
            (1 -
                math.cos(
                    (widget.place.longitude - location.longitude) * p)) /
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

    final isFavorited =
        favoritesAsync.value?.any((f) => f.placeId == place.id) ?? false;

    final distance = _calculateDistance();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                    itemCount:
                        place.images.isNotEmpty ? place.images.length : 1,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) {
                      final img = place.images.isNotEmpty
                          ? place.images[i]
                          : place.primaryImage;

                      return Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey,
                          child: const Icon(Icons.image),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      const SizedBox(height: 6),

                      Text('${place.city}, ${place.state}'),

                      const SizedBox(height: 12),

                      if (distance != null)
                        Text('${distance.toStringAsFixed(1)} km away'),

                      const SizedBox(height: 20),

                      Text(
                        place.description,
                        style: const TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      place.isFree
                          ? 'Free Entry'
                          : place.formattedEntryFee,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  AppButton(
                    label: 'Get Directions',
                    onPressed: () {
                      context.go(AppRoutes.map);
                    },
                    icon: Icons.navigation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}