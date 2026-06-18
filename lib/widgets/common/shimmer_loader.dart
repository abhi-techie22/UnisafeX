import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unisafex/core/constants/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkDivider,
      child: child,
    );
  }
}
