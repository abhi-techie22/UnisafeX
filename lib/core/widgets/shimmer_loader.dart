import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.grey800 : AppColors.grey200,
      highlightColor: isDark ? AppColors.grey700 : AppColors.grey100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerText extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerText({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      width: width,
      height: height,
      borderRadius: 4,
    );
  }
}

class PlaceCardShimmer extends StatelessWidget {
  final double width;
  final double height;

  const PlaceCardShimmer({
    super.key,
    this.width = 200,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader(
            width: width,
            height: height * 0.65,
            borderRadius: 16,
          ),
          const SizedBox(height: 8),
          ShimmerText(width: width * 0.7),
          const SizedBox(height: 6),
          ShimmerText(width: width * 0.5, height: 12),
        ],
      ),
    );
  }
}
