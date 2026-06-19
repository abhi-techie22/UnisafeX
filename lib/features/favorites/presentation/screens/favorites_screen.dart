import 'package:easy_localization/easy_localization.dart';
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
    final completedIds = ref.watch(bucketListCompletedProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          user == null ? 'saved_offline'.tr() : 'saved_places'.tr(),
        ),
        actions: [
          if (user == null)
            TextButton(
              onPressed: () => context.go(AppRoutes.authSelection),
              child: Text('sign_in'.tr()),
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
          final completedCount =
              visible.where((place) => completedIds.contains(place.id)).length;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visible.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _BucketProgressCard(
                  completed: completedCount,
                  total: visible.length,
                );
              }
              final place = visible[index - 1];
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
                  await ref
                      .read(bucketListCompletedProvider.notifier)
                      .setCompleted(place.id, false);
                },
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      context.push(AppRoutes.placeDetail, extra: place),
                  child: _SavedPlaceCard(
                    place: place,
                    completed: completedIds.contains(place.id),
                    onToggleCompleted: () => ref
                        .read(bucketListCompletedProvider.notifier)
                        .toggleCompleted(place.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('saved_load_error'.tr(args: ['$error'])),
        ),
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
              isOffline ? 'saved_offline_empty'.tr() : 'no_saved_places'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              isOffline
                  ? 'saved_offline_description'.tr()
                  : 'saved_online_description'.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.explore_outlined),
              label: Text('explore_places'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketProgressCard extends StatelessWidget {
  const _BucketProgressCard({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.success.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bucket list progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('$completed/$total'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save places you want to visit, then mark them completed after the trip.',
          ),
        ],
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final TourismPlace place;
  final bool completed;
  final VoidCallback onToggleCompleted;

  const _SavedPlaceCard({
    required this.place,
    required this.completed,
    required this.onToggleCompleted,
  });

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
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: AppColors.accent),
                          Text(' ${place.rating.toStringAsFixed(1)}'),
                        ],
                      ),
                      ActionChip(
                        avatar: Icon(
                          completed
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 17,
                          color:
                              completed ? AppColors.success : AppColors.primary,
                        ),
                        label: Text(completed ? 'Completed' : 'Mark visited'),
                        onPressed: onToggleCompleted,
                        visualDensity: VisualDensity.compact,
                      ),
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
