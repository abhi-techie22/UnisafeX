import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/core/utils/google_maps_launcher.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key, this.selectedPlace});

  final TourismPlace? selectedPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby places'),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: () => ref.read(locationProvider.notifier).refresh(),
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: locationState.when(
        loading: () => const _LocationLoading(),
        error: (error, _) => _LocationError(error: error),
        data: (location) {
          if (location == null) {
            return const _LocationError(
              error: LocationException(LocationFailure.unavailable),
            );
          }
          return _NearbyContent(
            location: location,
            selectedPlace: selectedPlace,
          );
        },
      ),
    );
  }
}

class _NearbyContent extends ConsumerWidget {
  const _NearbyContent({
    required this.location,
    required this.selectedPlace,
  });

  final LocationData location;
  final TourismPlace? selectedPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(
      nearbyPlacesProvider(
        NearbyParams(
          lat: location.latitude,
          lng: location.longitude,
          radiusKm: 500,
        ),
      ),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(locationProvider.notifier).refresh();
        ref.invalidate(
          nearbyPlacesProvider(
            NearbyParams(
              lat: location.latitude,
              lng: location.longitude,
              radiusKm: 500,
            ),
          ),
        );
      },
      child: nearby.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            const SizedBox(height: 180),
            Center(child: Text('Unable to load nearby places: $error')),
          ],
        ),
        data: (places) {
          final ordered = [...places];
          if (selectedPlace != null) {
            ordered.removeWhere((place) => place.id == selectedPlace!.id);
            ordered.insert(0, selectedPlace!);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _LocationHeader(location: location),
              const SizedBox(height: 22),
              Text(
                selectedPlace == null
                    ? 'Closest destinations'
                    : 'Selected destination',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                'Distances are calculated from your current GPS coordinates.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              if (ordered.isEmpty)
                const _EmptyNearby()
              else
                ...ordered.take(selectedPlace == null ? 20 : 1).map(
                      (place) => _NearbyPlaceCard(
                        place: place,
                        location: location,
                      ),
                    ),
              if (selectedPlace != null && places.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Other places near your location',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ...places
                    .where((place) => place.id != selectedPlace!.id)
                    .take(8)
                    .map(
                      (place) => _NearbyPlaceCard(
                        place: place,
                        location: location,
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({required this.location});

  final LocationData location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.gps_fixed_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your live location',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  location.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'GPS accuracy ±${location.accuracyMeters.round()} m',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({
    required this.place,
    required this.location,
  });

  final TourismPlace place;
  final LocationData location;

  @override
  Widget build(BuildContext context) {
    final distance = DistanceCalculator.calculate(
      lat1: location.latitude,
      lon1: location.longitude,
      lat2: place.latitude,
      lon2: place.longitude,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(AppRoutes.placeDetail, extra: place),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: place.primaryImage.isEmpty
                    ? _imageFallback()
                    : Image.network(
                        place.primaryImage,
                        width: 88,
                        height: 98,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageFallback(),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DistanceCalculator.format(distance),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            place.timings?.trim().isNotEmpty == true
                                ? place.timings!
                                : 'Timings not available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Navigate with Google Maps',
                onPressed: () => _openDirections(context),
                icon: const Icon(
                  Icons.directions_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        width: 88,
        height: 98,
        color: AppColors.primary.withValues(alpha: 0.08),
        child: const Icon(Icons.place_outlined, color: AppColors.primary),
      );

  Future<void> _openDirections(BuildContext context) async {
    final opened = await GoogleMapsLauncher.openDirections(
      originLatitude: location.latitude,
      originLongitude: location.longitude,
      destinationLatitude: place.latitude,
      destinationLongitude: place.longitude,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}

class _LocationLoading extends StatelessWidget {
  const _LocationLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Finding your current location...'),
        ],
      ),
    );
  }
}

class _LocationError extends ConsumerWidget {
  const _LocationError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationError = error is LocationException
        ? error as LocationException
        : const LocationException(LocationFailure.unavailable);

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.location_off_outlined,
          size: 64,
          color: AppColors.warning,
        ),
        const SizedBox(height: 20),
        Text(
          'Location needed',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          locationError.message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => ref.read(locationProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
        if (locationError.failure ==
            LocationFailure.permissionDeniedForever) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => ref.read(locationProvider.notifier).openSettings(),
            child: const Text('Open app settings'),
          ),
        ],
        if (locationError.failure == LocationFailure.servicesDisabled) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () =>
                ref.read(locationProvider.notifier).openLocationSettings(),
            child: const Text('Open location settings'),
          ),
        ],
      ],
    );
  }
}

class _EmptyNearby extends StatelessWidget {
  const _EmptyNearby();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.explore_off_outlined, size: 42),
            SizedBox(height: 10),
            Text(
              'No destination coordinates are available near your location.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
