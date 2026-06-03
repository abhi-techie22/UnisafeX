import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController; // ✅ Fixed: MaplibreMapController -> MapLibreMapController
  TourismPlace? _selectedPlace;
  bool _isLoading = true;

  static const String _mapStyleUrl =
      'https://api.maptiler.com/maps/streets-v2/style.json?key=get_your_own_key';

  static const String _fallbackStyleUrl =
      'https://demotiles.maplibre.org/style.json';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = ref.watch(locationProvider);
    final popularPlaces = ref.watch(popularPlacesProvider);

    final initialLat =
        location.value?.latitude ?? AppConstants.defaultLatitude;
    final initialLng =
        location.value?.longitude ?? AppConstants.defaultLongitude;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          MapLibreMap( // ✅ Fixed: MaplibreMap -> MapLibreMap
            styleString: _fallbackStyleUrl,
            initialCameraPosition: CameraPosition(
              target: LatLng(initialLat, initialLng),
              zoom: location.value != null ? 10 : AppConstants.defaultZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: () {
              setState(() => _isLoading = false);
              _addMarkers(popularPlaces.value ?? []);
            },
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.none, // ✅ Fixed: .None -> .none
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),

          // App bar overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      // Back
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.home),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 18,
                            color: isDark ? AppColors.white : AppColors.grey900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Search bar
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.search),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey500,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Search on map...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.grey500
                                        : AppColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom place card
          if (_selectedPlace != null)
            Positioned(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: _PlaceMapCard(
                place: _selectedPlace!,
                onTap: () => context.push(
                  AppRoutes.placeDetail,
                  extra: _selectedPlace!,
                ),
                onClose: () => setState(() => _selectedPlace = null),
              ),
            ),

          // My location button
          Positioned(
            right: 16,
            bottom: _selectedPlace != null
                ? 160 + MediaQuery.of(context).padding.bottom
                : 40 + MediaQuery.of(context).padding.bottom,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapLibreMapController controller) { // ✅ Fixed: MaplibreMapController -> MapLibreMapController
    _mapController = controller;
    controller.onSymbolTapped.add(_onMarkerTapped);
  }

  Future<void> _addMarkers(List<TourismPlace> places) async {
    if (_mapController == null) return;

    for (final place in places) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(place.latitude, place.longitude),
          iconImage: 'marker-15',
          iconColor: '#1A6B4A',
          iconSize: 2.0,
          textField: place.name,
          textSize: 11,
          textOffset: const Offset(0, 1.8),
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
        ),
        {'placeId': place.id, 'placeName': place.name},
      );
    }
  }

  void _onMarkerTapped(Symbol symbol) {
    final places = ref.read(popularPlacesProvider).value ?? [];
    final placeId = symbol.data?['placeId'] as String?;
    if (placeId != null) {
      final place = places.firstWhere((p) => p.id == placeId,
          orElse: () => places.first);
      setState(() => _selectedPlace = place);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(place.latitude, place.longitude),
            zoom: AppConstants.placeZoom,
          ),
        ),
      );
    }
  }

  Future<void> _goToMyLocation() async {
    final location = ref.read(locationProvider).value;
    if (location != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: 12,
          ),
        ),
      );
    }
  }
}

class _PlaceMapCard extends StatelessWidget {
  final TourismPlace place;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _PlaceMapCard({
    required this.place,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Image.network(
              place.primaryImage,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                color: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.image_outlined, color: AppColors.grey400),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'View Details →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey700 : AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isDark ? AppColors.grey300 : AppColors.grey600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}