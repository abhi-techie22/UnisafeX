import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';

class PlaceCard extends StatefulWidget {
  final TourismPlace place;
  final VoidCallback onTap;
  final double width;
  final bool showBadge;
  final String? badgeLabel;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.width = 180,
    this.showBadge = false,
    this.badgeLabel,
  });

  @override
  State<PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<PlaceCard> {
  static _PlaceCardState? _activeSlider;

  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    if (_activeSlider == this) _activeSlider = null;
    super.dispose();
  }

  void _activateSlider() {
    final images = _images;
    if (images.length <= 1) return;
    if (_activeSlider == this) return;
    _activeSlider?._stopSlider();
    _activeSlider = this;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_controller.hasClients) return;
      _index = (_index + 1) % images.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopSlider() {
    _timer?.cancel();
    _timer = null;
    if (_activeSlider == this) _activeSlider = null;
  }

  List<String> get _images {
    final urls = widget.place.images
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty && widget.place.primaryImage.trim().isNotEmpty) {
      urls.add(widget.place.primaryImage.trim());
    }
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageHeight = widget.width * 0.52;
    final safetyScore = SafetyScoreService.calculate(widget.place);
    final images = _images;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _activateSlider(),
      onExit: (_) => _stopSlider(),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _activateSlider(),
          onTapCancel: _stopSlider,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    width: widget.width,
                    height: imageHeight,
                    child: PageView.builder(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: images.isEmpty ? 1 : images.length,
                      itemBuilder: (_, index) {
                        if (images.isEmpty) {
                          return _imageFallback(widget.width, imageHeight);
                        }
                        return Image.network(
                          images[index],
                          width: widget.width,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imageFallback(widget.width, imageHeight),
                        );
                      },
                    ),
                  ),

                  // Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge
                  if (widget.showBadge && widget.badgeLabel != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.badgeLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Rating
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            widget.place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            '$safetyScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.place.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isDark ? AppColors.white : AppColors.grey900,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 11,
                          color: isDark ? AppColors.grey500 : AppColors.grey400,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.place.city,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.grey500
                                  : AppColors.grey500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 13,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.place.formattedLikes} likes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? AppColors.grey400 : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.image_outlined, color: AppColors.grey400),
    );
  }
}
