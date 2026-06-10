import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/saved_places_provider.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final placesAsync = user == null
        ? ref.watch(popularPlacesProvider)
        : ref.watch(favoritePlacesProvider);
    final localIds = ref.watch(savedPlacesProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(user == null ? 'Saved Offline' : 'Saved Places'),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () => context.go(AppRoutes.authSelection),
              child: const Text('Sign in'),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(favoritePlacesProvider),
            ),
        ],
      ),
      body: placesAsync.when(
        data: (places) {
          final visible = user == null
              ? places.where((place) => localIds.contains(place.id)).toList()
              : places;
          if (visible.isEmpty) {
            return _EmptySavedState(isOffline: user == null);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final place = visible[index];
              return Dismissible(
                key: ValueKey(
                    '${user == null ? 'local' : 'remote'}-${place.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 22),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                onDismissed: (_) async {
                  if (user == null) {
                    await ref
                        .read(savedPlacesProvider.notifier)
                        .toggle(place.id);
                  } else {
                    await ref
                        .read(favoritesProvider.notifier)
                        .removeFavorite(place.id);
                    ref.invalidate(favoritePlacesProvider);
                  }
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      context.push(AppRoutes.placeDetail, extra: place),
                  child: _SavedPlaceCard(place: place),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load saved places: $error')),
      ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  final bool isOffline;

  const _EmptySavedState({required this.isOffline});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              isOffline ? 'No offline places yet' : 'No saved places yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              isOffline
                  ? 'Save a destination from its details page for quick local access.'
                  : 'Tap the bookmark on a destination to keep it here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore places'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final TourismPlace place;

  const _SavedPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              place.primaryImage,
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 104,
                height: 104,
                child: Icon(Icons.image_outlined),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text('${place.city}, ${place.state}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 15, color: AppColors.accent),
                      Text(' ${place.rating.toStringAsFixed(1)}'),
                      const Spacer(),
                      const Icon(Icons.bookmark_rounded,
                          color: AppColors.primary, size: 19),
                    ],
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
