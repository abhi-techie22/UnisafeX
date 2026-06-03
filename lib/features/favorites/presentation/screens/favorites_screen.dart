import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/shimmer_loader.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/favorites/presentation/providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);

    if (isGuest) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.bookmark_border_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Save Your Favorites',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create an account to bookmark places and access them anytime, from any device.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.grey400
                              : AppColors.grey600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.authSelection),
                      child: const Text('Sign In or Create Account'),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),
        ),
      );
    }

    final favPlaces = ref.watch(favoritePlacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(favoritePlacesProvider),
          ),
        ],
      ),
      body: favPlaces.when(
        data: (places) {
          if (places.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text('No saved places yet',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(
                      'Tap the bookmark icon on any place to save it here.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppColors.grey400
                                : AppColors.grey600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.explore_rounded, size: 18),
                      label: const Text('Explore Places'),
                    ),
                  ],
                ).animate().fadeIn(),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final place = places[i];
              return Dismissible(
                key: Key(place.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
                onDismissed: (_) {
                  ref.read(favoritesProvider.notifier).removeFavorite(place.id);
                  ref.invalidate(favoritePlacesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${place.name} removed'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .addFavorite(place.id);
                          ref.invalidate(favoritePlacesProvider);
                        },
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.placeDetail, extra: place),
                  child: _FavoriteCard(place: place),
                ),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => ShimmerLoader(
            width: double.infinity,
            height: 100,
            borderRadius: 16,
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Failed to load favorites',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(favoritePlacesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final place;

  const _FavoriteCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Image.network(
            place.primaryImage,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              color: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.image_outlined, color: AppColors.grey400),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Icon(
              Icons.bookmark_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
