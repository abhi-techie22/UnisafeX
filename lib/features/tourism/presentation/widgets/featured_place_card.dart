import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';

class FeaturedPlaceCard extends StatefulWidget {
  final TourismPlace place;
  final VoidCallback onTap;
  final double width;

  const FeaturedPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.width = 280,
  });

  @override
  State<FeaturedPlaceCard> createState() => _FeaturedPlaceCardState();
}

class _FeaturedPlaceCardState extends State<FeaturedPlaceCard> {
  static _FeaturedPlaceCardState? _activeSlider;

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
    if (images.length <= 1 || _activeSlider == this) return;
    _activeSlider?._stopSlider();
    _activeSlider = this;
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
    final safetyScore = SafetyScoreService.calculate(widget.place);
    final images = _images;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _activateSlider(),
      onExit: (_) => _stopSlider(),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _activateSlider(),
          onTapCancel: _stopSlider,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Image
                Positioned.fill(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: images.isEmpty ? 1 : images.length,
                    itemBuilder: (_, index) {
                      if (images.isEmpty) return _imageFallback();
                      return Image.network(
                        images[index],
                        width: widget.width,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      );
                    },
                  ),
                ),

                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.75),
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Top badges
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (widget.place.featured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.only(right: 7),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$safetyScore',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 13, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              widget.place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.place.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${widget.place.city}, ${widget.place.state}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.place.isFree)
                              _FeaturedInfoPill(
                                color: AppColors.success.withOpacity(0.85),
                                child: const Text(
                                  'Free',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            _FeaturedInfoPill(
                              color: Colors.black.withOpacity(0.35),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 12,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.place.formattedLikes,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: widget.width,
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.image_outlined, color: AppColors.grey400),
    );
  }
}

class _FeaturedInfoPill extends StatelessWidget {
  const _FeaturedInfoPill({
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
