import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';
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
  late int _likesCount;
  int? _likesOverride;
  bool? _likedOverride;
  bool _liking = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.place.likesCount;
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

  Favorite? _favoriteFor(List<Favorite> favorites, String placeId) {
    for (final favorite in favorites) {
      if (favorite.placeId == placeId) return favorite;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final place = widget.place;
    final distance = _calculateDistance(
      ref.watch(locationProvider).valueOrNull,
    );
    final safetyScore = SafetyScoreService.calculate(place);
    final localSaved = ref.watch(savedPlacesProvider).contains(place.id);
    final remoteFavorites = ref.watch(favoritesProvider).value ?? [];
    final remoteSaved =
        remoteFavorites.any((favorite) => favorite.placeId == place.id);
    final remoteFavorite = _favoriteFor(remoteFavorites, place.id);
    final isFavorite = localSaved || remoteSaved;
    final completedPlaces = ref.watch(bucketListCompletedProvider);
    final isCompleted = completedPlaces.contains(place.id) ||
        remoteFavorite?.isCompleted == true;
    final imageUrls = _imageUrls(place);
    final reviewsAsync = ref.watch(placeReviewsProvider(place.id));
    final myReview = ref.watch(myPlaceReviewProvider(place.id)).valueOrNull;
    final likeState = ref.watch(placeLikeStateProvider(place.id)).valueOrNull;
    final liked = _likedOverride ?? likeState?.liked ?? false;
    final likesCount = _likesOverride ?? likeState?.likesCount ?? _likesCount;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _goBack,
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
              background: _PlaceImageHeader(
                imageUrls: imageUrls,
                currentIndex: _currentImageIndex,
                onPageChanged: (index) =>
                    setState(() => _currentImageIndex = index),
                onViewAll: imageUrls.isEmpty
                    ? null
                    : () => _showImageGallery(imageUrls),
                fallback: _imageFallback,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 168),
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
                const SizedBox(height: 14),
                _LikeCard(
                  likesLabel: _formatLikes(likesCount),
                  liked: liked,
                  loading: _liking,
                  onTap: _togglePlaceLike,
                ),
                const SizedBox(height: 12),
                _ReviewActionCard(
                  myReview: myReview,
                  onTap: () => _showReviewSheet(myReview),
                ),
                const SizedBox(height: 12),
                _BucketListCard(
                  saved: isFavorite,
                  completed: isCompleted,
                  favorite: remoteFavorite,
                  onSave: () => _toggleFavorite(
                    localSaved: localSaved,
                    remoteSaved: remoteSaved,
                  ),
                  onToggleCompleted: isFavorite
                      ? () async {
                          await ref
                              .read(bucketListCompletedProvider.notifier)
                              .toggleCompleted(place.id);
                          final user = ref.read(currentUserProvider);
                          if (user != null) {
                            await ref
                                .read(favoritesProvider.notifier)
                                .setCompleted(place.id, !isCompleted);
                            ref.invalidate(favoritePlacesProvider);
                          }
                        }
                      : null,
                  onPlan: isFavorite ? () => _showBucketPlanSheet() : null,
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
                  title: 'Traveler Reviews',
                  child: _ReviewsList(
                    reviewsAsync: reviewsAsync,
                    myReview: myReview,
                  ),
                ),
                _Section(
                  title: 'Continue Planning',
                  child: _PlanningActions(
                    onEmergency: _showEmergencyHelp,
                    onTripPlanner: () => context.push(AppRoutes.tripPlanner),
                    onAssistant: () => context.push(AppRoutes.aiAssistant),
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
                label: 'view_on_map'.tr(),
                onPressed: _openInAppMap,
                icon: Icons.map_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInAppMap() {
    context.push(
      AppRoutes.destinationMapLocation(
        placeName: widget.place.name,
        latitude: widget.place.latitude,
        longitude: widget.place.longitude,
        address: widget.place.address?.trim().isNotEmpty == true
            ? widget.place.address
            : _locationLabel(widget.place),
        imageUrl: widget.place.primaryImage,
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.grey300,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 48),
    );
  }

  List<String> _imageUrls(TourismPlace place) {
    final urls = place.images
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty && place.primaryImage.trim().isNotEmpty) {
      urls.add(place.primaryImage.trim());
    }
    return urls;
  }

  void _showImageGallery(List<String> imageUrls) {
    final initialIndex =
        _currentImageIndex.clamp(0, imageUrls.length - 1).toInt();
    final controller = PageController(initialPage: initialIndex);
    var selectedIndex = initialIndex;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            widget.place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Text(
                          '${selectedIndex + 1}/${imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) {
                        setDialogState(() => selectedIndex = index);
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (_, index) {
                        return InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Center(
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                                size: 54,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      itemCount: imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final selected = selectedIndex == index;
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => controller.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.24),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Colors.white10,
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

  String _formatLikes(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Future<void> _togglePlaceLike() async {
    if (_liking) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like destinations')),
      );
      return;
    }

    setState(() => _liking = true);
    try {
      final state = await ref
          .read(tourismRepositoryProvider)
          .togglePlaceLike(widget.place.id);
      if (!mounted) return;
      setState(() {
        _likesOverride = state.likesCount;
        _likedOverride = state.liked;
      });
      ref.invalidate(placeLikeStateProvider(widget.place.id));
      ref.invalidate(featuredPlacesProvider);
      ref.invalidate(popularPlacesProvider);
      ref.invalidate(trendingPlacesProvider);
      ref.invalidate(mustVisitPlacesProvider);
      ref.invalidate(explorerPlacesProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this like right now')),
      );
    } finally {
      if (mounted) setState(() => _liking = false);
    }
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

  Future<void> _showReviewSheet(PlaceReview? existing) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to review destinations')),
      );
      return;
    }

    final titleController = TextEditingController(text: existing?.title ?? '');
    final bodyController = TextEditingController(text: existing?.body ?? '');
    var rating = existing?.rating ?? 5;
    final imageUrls = [...?existing?.imageUrls];
    var uploading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add review' : 'Update review',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: '$value stars',
                    onPressed: () => setSheetState(() => rating = value),
                    icon: Icon(
                      value <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.accent,
                    ),
                  );
                }),
              ),
              TextField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Short title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Review',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrls[index],
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: IconButton.filled(
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setSheetState(() => imageUrls.removeAt(index));
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: uploading
                    ? null
                    : () async {
                        final picker = ImagePicker();
                        final images = await picker.pickMultiImage(
                          imageQuality: 82,
                          limit: 4,
                        );
                        if (images.isEmpty) return;
                        setSheetState(() => uploading = true);
                        try {
                          for (final image in images.take(4)) {
                            final bytes = await image.readAsBytes();
                            final parts = image.name.split('.');
                            final extension =
                                parts.length > 1 ? parts.last : 'jpg';
                            final url = await ref
                                .read(tourismRepositoryProvider)
                                .uploadReviewImageBytes(
                                  bytes: bytes,
                                  extension: extension,
                                  placeId: widget.place.id,
                                );
                            imageUrls.add(url);
                          }
                        } finally {
                          setSheetState(() => uploading = false);
                        }
                      },
                icon: Icon(
                  uploading
                      ? Icons.hourglass_top_rounded
                      : Icons.add_photo_alternate_outlined,
                ),
                label: Text(uploading ? 'Uploading images' : 'Add images'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(tourismRepositoryProvider).saveReview(
                        placeId: widget.place.id,
                        rating: rating,
                        title: titleController.text,
                        body: bodyController.text,
                        imageUrls: imageUrls,
                      );
                  ref.invalidate(myPlaceReviewProvider(widget.place.id));
                  ref.invalidate(placeReviewsProvider(widget.place.id));
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted for checking'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Submit for check'),
              ),
            ],
          ),
        ),
      ),
    );

    titleController.dispose();
    bodyController.dispose();
  }

  Future<void> _showBucketPlanSheet() async {
    final noteController = TextEditingController();
    DateTime? plannedDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan bucket visit',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Trip note',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    initialDate: plannedDate ?? DateTime.now(),
                  );
                  if (picked != null) {
                    setSheetState(() => plannedDate = picked);
                  }
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  plannedDate == null
                      ? 'Choose planned date'
                      : '${plannedDate!.day}/${plannedDate!.month}/${plannedDate!.year}',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    await ref.read(favoritesProvider.notifier).saveBucketNotes(
                          placeId: widget.place.id,
                          notes: noteController.text,
                          plannedVisitDate: plannedDate,
                        );
                    ref.invalidate(favoritePlacesProvider);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save plan'),
              ),
            ],
          ),
        ),
      ),
    );

    noteController.dispose();
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

class _BucketListCard extends StatelessWidget {
  const _BucketListCard({
    required this.saved,
    required this.completed,
    required this.favorite,
    required this.onSave,
    required this.onToggleCompleted,
    required this.onPlan,
  });

  final bool saved;
  final bool completed;
  final Favorite? favorite;
  final VoidCallback onSave;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            child: Icon(saved ? Icons.flag_rounded : Icons.flag_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saved ? 'In your bucket list' : 'Add to bucket list',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (favorite?.notes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    favorite!.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (!saved)
            FilledButton.tonal(
              onPressed: onSave,
              child: const Text('Save'),
            )
          else ...[
            IconButton.filledTonal(
              tooltip: 'Plan visit',
              onPressed: onPlan,
              icon: const Icon(Icons.edit_calendar_outlined),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: completed ? 'Mark not visited' : 'Mark visited',
              onPressed: onToggleCompleted,
              icon: Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _subtitle {
    if (!saved) return 'Save this place before your trip.';
    if (completed) return 'Marked completed after your visit.';
    final date = favorite?.plannedVisitDate;
    if (date != null) {
      return 'Planned for ${date.day}/${date.month}/${date.year}.';
    }
    return 'Track this place, add notes, and mark it completed later.';
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

class _PlanningActions extends StatelessWidget {
  const _PlanningActions({
    required this.onEmergency,
    required this.onTripPlanner,
    required this.onAssistant,
  });

  final VoidCallback onEmergency;
  final VoidCallback onTripPlanner;
  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 560;
        final cardWidth =
            twoColumns ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _PlanningCard(
                icon: Icons.emergency_outlined,
                title: 'emergency_help'.tr(),
                subtitle: 'Essential India helplines',
                onTap: onEmergency,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _PlanningCard(
                icon: Icons.route_outlined,
                title: 'Smart Trip Planner',
                subtitle: 'Add this place to a day-wise India itinerary',
                onTap: onTripPlanner,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _PlanningCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Ask Travel AI',
                subtitle: 'Get timing, safety and route suggestions',
                onTap: onAssistant,
              ),
            ),
          ],
        );
      },
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
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              foregroundColor: AppColors.primary,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
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

class _ReviewActionCard extends StatelessWidget {
  const _ReviewActionCard({
    required this.myReview,
    required this.onTap,
  });

  final PlaceReview? myReview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pending = myReview != null && !myReview!.isApproved;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withValues(alpha: 0.14),
            foregroundColor: AppColors.accent,
            child: const Icon(Icons.rate_review_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myReview == null ? 'Review this place' : 'Your review',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  pending
                      ? 'Submitted and waiting for admin check.'
                      : 'Share a rating and travel note for other visitors.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onTap,
            child: Text(myReview == null ? 'Add' : 'Edit'),
          ),
        ],
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList({
    required this.reviewsAsync,
    required this.myReview,
  });

  final AsyncValue<List<PlaceReview>> reviewsAsync;
  final PlaceReview? myReview;

  @override
  Widget build(BuildContext context) {
    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const Text('Reviews are unavailable right now.'),
      data: (reviews) {
        final visibleReviews = [...reviews];
        final ownReview = myReview;
        if (ownReview != null &&
            !visibleReviews.any((review) => review.id == ownReview.id)) {
          visibleReviews.insert(0, ownReview);
        }
        if (visibleReviews.isEmpty) {
          return const Text('No checked traveler reviews yet.');
        }
        return Column(
          children: visibleReviews
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewTile(review: review),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final PlaceReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage:
                    review.reviewerAvatarUrl?.trim().isNotEmpty == true
                        ? NetworkImage(review.reviewerAvatarUrl!.trim())
                        : null,
                child: review.reviewerAvatarUrl?.trim().isNotEmpty == true
                    ? null
                    : Text(
                        review.displayReviewerName
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  review.displayReviewerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
              if (review.status != 'approved') ...[
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    review.status == 'pending'
                        ? 'Pending approval'
                        : 'Rejected',
                  ),
                ),
              ],
            ],
          ),
          if (review.title?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              review.title!.trim(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          if (review.body?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(review.body!.trim()),
          ],
          if (review.hasAdminReply) ...[
            const SizedBox(height: 10),
            _OfficialReviewReply(reply: review.adminReply!.trim()),
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    review.imageUrls[index],
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Icon(Icons.image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfficialReviewReply extends StatelessWidget {
  const _OfficialReviewReply({required this.reply});

  final String reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UniSafeX team reply',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(reply),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceImageHeader extends StatefulWidget {
  const _PlaceImageHeader({
    required this.imageUrls,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onViewAll,
    required this.fallback,
  });

  final List<String> imageUrls;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onViewAll;
  final Widget Function() fallback;

  @override
  State<_PlaceImageHeader> createState() => _PlaceImageHeaderState();
}

class _PlaceImageHeaderState extends State<_PlaceImageHeader> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _PlaceImageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length ||
        oldWidget.imageUrls.join('|') != widget.imageUrls.join('|')) {
      _index = 0;
      _timer?.cancel();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (widget.imageUrls.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _index = (_index + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      widget.onPageChanged(_index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imageUrls.length;
    final visibleIndex =
        total == 0 ? 0 : _clampedImageIndex(widget.currentIndex, total);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.imageUrls.isEmpty)
          widget.fallback()
        else
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              _index = index;
              widget.onPageChanged(index);
            },
            itemBuilder: (_, index) {
              return Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => widget.fallback(),
              );
            },
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.transparent,
                Colors.black54,
              ],
            ),
          ),
        ),
        if (total > 0)
          Positioned(
            right: 16,
            bottom: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$visibleIndex / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (total > 1) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: widget.onViewAll,
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: Text('View all $total'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  int _clampedImageIndex(int index, int total) {
    if (index < 0) return 1;
    if (index >= total) return total;
    return index + 1;
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

class _LikeCard extends StatelessWidget {
  final String likesLabel;
  final bool liked;
  final bool loading;
  final VoidCallback onTap;

  const _LikeCard({
    required this.likesLabel,
    required this.liked,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: loading ? null : onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.16)),
            color: AppColors.error.withValues(alpha: liked ? 0.08 : 0.04),
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Like this place',
                child: SizedBox.square(
                  dimension: 54,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: liked ? 1 : 0),
                    duration: const Duration(milliseconds: 640),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) {
                      final fillAlpha = liked ? 0.16 + (progress * 0.84) : 0.1;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.error.withValues(
                                alpha: fillAlpha,
                              ),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.22),
                              ),
                            ),
                          ),
                          SizedBox.square(
                            dimension: 52,
                            child: CircularProgressIndicator(
                              value: loading ? null : progress,
                              strokeWidth: 3,
                              backgroundColor:
                                  AppColors.error.withValues(alpha: 0.16),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.error,
                              ),
                            ),
                          ),
                          AnimatedScale(
                            scale: liked ? 1.15 : 1,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: liked ? Colors.white : AppColors.error,
                              size: 25,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liked ? 'Supported' : 'Like this place',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      liked
                          ? 'Thanks for supporting this destination'
                          : 'Help travelers find this destination',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$likesLabel likes',
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
