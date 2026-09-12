import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/core/utils/google_maps_launcher.dart';
import 'package:unisafex/core/utils/traveler_map_marker.dart';
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
        title: Text('nearby_places'.tr()),
        actions: [
          IconButton(
            tooltip: 'use_my_location'.tr(),
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
            Center(child: Text('${'unable_to_load'.tr()}: $error')),
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
              _LocationHeader(
                location: location,
                onChangeLocation: () => _showLocationPicker(context, ref),
                onUseGps: location.source == LocationSource.selected
                    ? () => ref.read(locationProvider.notifier).refresh()
                    : null,
              ),
              const SizedBox(height: 12),
              _FullMapAction(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _FullPlacesMapPage(
                      initialLocation: location,
                      selectedPlace: selectedPlace,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                selectedPlace == null
                    ? 'Closest destinations'
                    : 'Selected destination',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                location.source == LocationSource.gps
                    ? 'Calculated now from your live GPS and each place coordinate.'
                    : 'Calculated now from your chosen location and each place coordinate.',
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

  Future<void> _showLocationPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _LocationPickerSheet(),
    );
    if (query == null || !context.mounted) return;

    final found =
        await ref.read(locationProvider.notifier).selectLocation(query);
    if (!found && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location not found. Try a city, landmark, or full address.',
          ),
        ),
      );
    }
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({
    required this.location,
    required this.onChangeLocation,
    this.onUseGps,
  });

  final LocationData location;
  final VoidCallback onChangeLocation;
  final VoidCallback? onUseGps;

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
                Text(
                  location.source == LocationSource.gps
                      ? 'Your live GPS location'
                      : 'Your chosen location',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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
                if (location.source == LocationSource.gps)
                  Text(
                    'GPS accuracy ±${location.accuracyMeters.round()} m',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  )
                else
                  const Text(
                    'Distances use this selected starting point',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onChangeLocation,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Change'),
              ),
              if (onUseGps != null)
                IconButton(
                  tooltip: 'Use current GPS',
                  onPressed: onUseGps,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullMapAction extends StatelessWidget {
  const _FullMapAction({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.travel_explore_rounded),
        label: const Text('Full photo map'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _FullPlacesMapPage extends ConsumerStatefulWidget {
  const _FullPlacesMapPage({
    required this.initialLocation,
    this.selectedPlace,
  });

  final LocationData initialLocation;
  final TourismPlace? selectedPlace;

  @override
  ConsumerState<_FullPlacesMapPage> createState() => _FullPlacesMapPageState();
}

class _FullPlacesMapPageState extends ConsumerState<_FullPlacesMapPage> {
  static const _allStatesKey = '__all__';
  static const _maxPhotoMarkers = 220;
  static const _maxAllStateMarkers = 700;

  GoogleMapController? _controller;
  final Map<String, BitmapDescriptor> _photoIcons = {};
  final Set<String> _loadingIcons = {};
  BitmapDescriptor? _travelerIcon;
  String? _selectedStateKey;
  String? _lastFittedStateKey;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTravelerIcon());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadTravelerIcon() async {
    try {
      final icon = await TravelerMapMarker.build();
      if (!mounted) return;
      setState(() => _travelerIcon = icon);
    } catch (_) {
      // The default marker remains available if custom marker drawing fails.
    }
  }

  Future<void> _fitPlaces(List<TourismPlace> places) async {
    if (_controller == null || places.isEmpty) return;
    final selected = widget.selectedPlace;
    if (selected != null && _selectedStateKey == null) {
      await _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(selected.latitude, selected.longitude),
          13.5,
        ),
      );
      return;
    }
    final points = [
      LatLng(widget.initialLocation.latitude, widget.initialLocation.longitude),
      ...places
          .take(80)
          .map((place) => LatLng(place.latitude, place.longitude)),
    ];
    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsFor(points), 54),
    );
  }

  void _scheduleFit(String stateKey, List<TourismPlace> places) {
    if (_controller == null ||
        places.isEmpty ||
        _lastFittedStateKey == stateKey) {
      return;
    }
    _lastFittedStateKey = stateKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_fitPlaces(places));
    });
  }

  Map<String, int> _stateCounts(List<TourismPlace> places) {
    final counts = <String, int>{};
    for (final place in places) {
      final state = _stateKeyForPlace(place);
      counts[state] = (counts[state] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        return countCompare == 0 ? a.key.compareTo(b.key) : countCompare;
      });
    return Map<String, int>.fromEntries(entries);
  }

  String _stateKeyForPlace(TourismPlace place) {
    final state = place.state.trim();
    return state.isEmpty ? 'Unknown' : state;
  }

  String? _defaultStateKey(
    List<TourismPlace> places,
    Iterable<String> stateKeys,
  ) {
    final selected = widget.selectedPlace;
    if (selected != null) {
      final selectedState = _stateKeyForPlace(selected);
      if (stateKeys.contains(selectedState)) return selectedState;
    }

    final fromLocationState =
        _matchKnownState(widget.initialLocation.state, stateKeys);
    if (fromLocationState != null) return fromLocationState;

    final fromLocationName =
        _matchKnownState(widget.initialLocation.name, stateKeys);
    if (fromLocationName != null) return fromLocationName;

    TourismPlace? nearest;
    double? nearestDistance;
    for (final place in places) {
      final distance = DistanceCalculator.calculate(
        lat1: widget.initialLocation.latitude,
        lon1: widget.initialLocation.longitude,
        lat2: place.latitude,
        lon2: place.longitude,
      );
      if (nearestDistance == null || distance < nearestDistance) {
        nearest = place;
        nearestDistance = distance;
      }
    }
    return nearest == null ? null : _stateKeyForPlace(nearest);
  }

  String? _matchKnownState(String? value, Iterable<String> stateKeys) {
    final normalizedValue = _normalizeState(value);
    if (normalizedValue.isEmpty) return null;
    for (final state in stateKeys) {
      final normalizedState = _normalizeState(state);
      if (normalizedState == normalizedValue ||
          normalizedValue.contains(normalizedState) ||
          normalizedState.contains(normalizedValue)) {
        return state;
      }
    }
    return null;
  }

  String _normalizeState(String? value) {
    return (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z]'), '').trim();
  }

  List<TourismPlace> _placesForState(
    List<TourismPlace> places,
    String stateKey,
  ) {
    final scoped = stateKey == _allStatesKey
        ? places
        : places.where((place) => _stateKeyForPlace(place) == stateKey);
    final ranked = scoped.toList()
      ..sort((a, b) {
        final imageCompare = (b.primaryImage.trim().isNotEmpty ? 1 : 0)
            .compareTo(a.primaryImage.trim().isNotEmpty ? 1 : 0);
        if (imageCompare != 0) return imageCompare;
        return b.rating.compareTo(a.rating);
      });
    if (stateKey == _allStatesKey && ranked.length > _maxAllStateMarkers) {
      return ranked.take(_maxAllStateMarkers).toList();
    }
    return ranked;
  }

  void _selectState(String stateKey) {
    setState(() {
      _selectedStateKey = stateKey;
      _lastFittedStateKey = null;
    });
  }

  void _loadPhotoMarkers(List<TourismPlace> places) {
    final imagePlaces = places
        .where((place) => place.primaryImage.trim().isNotEmpty)
        .take(_maxPhotoMarkers);
    for (final place in imagePlaces) {
      if (_photoIcons.containsKey(place.id) ||
          _loadingIcons.contains(place.id)) {
        continue;
      }
      _loadingIcons.add(place.id);
      unawaited(_loadPhotoMarker(place));
    }
  }

  Future<void> _loadPhotoMarker(TourismPlace place) async {
    try {
      final data =
          await NetworkAssetBundle(Uri.parse(place.primaryImage.trim()))
              .load('');
      final bytes = await _buildPhotoMarker(data.buffer.asUint8List());
      if (!mounted) return;
      setState(() {
        _photoIcons[place.id] = BitmapDescriptor.bytes(
          bytes,
          width: 60,
          height: 70,
        );
      });
    } catch (_) {
      // The default pin remains visible if a thumbnail cannot be decoded.
    } finally {
      _loadingIcons.remove(place.id);
    }
  }

  Future<Uint8List> _buildPhotoMarker(Uint8List imageBytes) async {
    const width = 180.0;
    const height = 210.0;
    const center = Offset(width / 2, 78);
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: 140,
      targetHeight: 140,
    );
    final frame = await codec.getNextFrame();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      center.translate(0, 8),
      76,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, 75, Paint()..color = Colors.white);
    canvas.save();
    canvas
        .clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: 64)));
    canvas.drawImageRect(
      frame.image,
      Rect.fromLTWH(
        0,
        0,
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      ),
      Rect.fromCircle(center: center, radius: 64),
      Paint()..isAntiAlias = true,
    );
    canvas.restore();
    canvas.drawCircle(
      center,
      68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = AppColors.primary,
    );
    final pointer = Path()
      ..moveTo(width / 2 - 20, 142)
      ..quadraticBezierTo(width / 2, height - 8, width / 2 + 20, 142)
      ..close();
    canvas.drawPath(pointer, Paint()..color = AppColors.primary);

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(fullMapPlacesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full photo map'),
        actions: [
          IconButton(
            tooltip: 'Refresh places',
            onPressed: () => ref.invalidate(fullMapPlacesProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: placesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load map: $error')),
        data: (places) {
          final visiblePlaces = places
              .where((place) => place.latitude != 0 && place.longitude != 0)
              .toList();
          final stateCounts = _stateCounts(visiblePlaces);
          final activeStateKey = _selectedStateKey ??
              _defaultStateKey(visiblePlaces, stateCounts.keys) ??
              _allStatesKey;
          final mappedPlaces = _placesForState(visiblePlaces, activeStateKey);
          _loadPhotoMarkers(mappedPlaces);
          _scheduleFit(activeStateKey, mappedPlaces);
          final selected = widget.selectedPlace;
          final initialTarget = selected == null
              ? LatLng(
                  widget.initialLocation.latitude,
                  widget.initialLocation.longitude,
                )
              : LatLng(selected.latitude, selected.longitude);
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: selected == null ? 5.2 : 13.5,
                ),
                mapType: MapType.normal,
                compassEnabled: true,
                zoomControlsEnabled: true,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('map-origin'),
                    position: LatLng(
                      widget.initialLocation.latitude,
                      widget.initialLocation.longitude,
                    ),
                    anchor: const Offset(0.5, 0.5),
                    icon: _travelerIcon ??
                        BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                    infoWindow: InfoWindow(
                      title: widget.initialLocation.source == LocationSource.gps
                          ? 'Your current location'
                          : widget.initialLocation.name,
                    ),
                  ),
                  for (final place in mappedPlaces)
                    Marker(
                      markerId: MarkerId(place.id),
                      position: LatLng(place.latitude, place.longitude),
                      icon: _photoIcons[place.id] ??
                          BitmapDescriptor.defaultMarkerWithHue(
                            place.primaryImage.isEmpty
                                ? BitmapDescriptor.hueGreen
                                : BitmapDescriptor.hueRed,
                          ),
                      infoWindow: InfoWindow(title: place.name),
                      onTap: () => _showPlaceActions(place),
                    ),
                },
                onMapCreated: (controller) {
                  _controller = controller;
                  unawaited(_fitPlaces(mappedPlaces));
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FullMapSummary(
                      placesCount: activeStateKey == _allStatesKey
                          ? visiblePlaces.length
                          : mappedPlaces.length,
                      shownCount: mappedPlaces.length,
                      photoCount: mappedPlaces
                          .where(
                            (place) => place.primaryImage.trim().isNotEmpty,
                          )
                          .length,
                    ),
                    const SizedBox(height: 8),
                    _FullMapStateFilters(
                      stateCounts: stateCounts,
                      activeStateKey: activeStateKey,
                      totalCount: visiblePlaces.length,
                      onSelected: _selectState,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPlaceActions(TourismPlace place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: place.primaryImage.isEmpty
                    ? _sheetImageFallback()
                    : Image.network(
                        place.primaryImage,
                        width: 92,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _sheetImageFallback(),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place.city}, ${place.state}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.placeDetail, extra: place);
                          },
                          icon: const Icon(Icons.article_outlined),
                          label: const Text('Visit details'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push(
                              AppRoutes.destinationMapLocation(
                                placeName: place.name,
                                latitude: place.latitude,
                                longitude: place.longitude,
                                address:
                                    place.address?.trim().isNotEmpty == true
                                        ? place.address
                                        : '${place.city}, ${place.state}',
                                imageUrl: place.primaryImage,
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open map'),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Open Google Maps',
                          onPressed: () {
                            GoogleMapsLauncher.openDirections(
                              originLatitude: widget.initialLocation.latitude,
                              originLongitude: widget.initialLocation.longitude,
                              destinationLatitude: place.latitude,
                              destinationLongitude: place.longitude,
                            );
                          },
                          icon: const Icon(Icons.near_me_outlined),
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

  Widget _sheetImageFallback() => Container(
        width: 92,
        height: 96,
        color: AppColors.primary.withValues(alpha: 0.08),
        child: const Icon(Icons.place_outlined, color: AppColors.primary),
      );

  LatLngBounds _boundsFor(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _FullMapSummary extends StatelessWidget {
  const _FullMapSummary({
    required this.placesCount,
    required this.shownCount,
    required this.photoCount,
  });

  final int placesCount;
  final int shownCount;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final placesLabel = shownCount < placesCount
        ? 'Showing $shownCount of $placesCount places'
        : '$placesCount places';
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.photo_camera_back_rounded,
                color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$placesLabel · $photoCount photo icons',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.touch_app_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FullMapStateFilters extends StatelessWidget {
  const _FullMapStateFilters({
    required this.stateCounts,
    required this.activeStateKey,
    required this.totalCount,
    required this.onSelected,
  });

  final Map<String, int> stateCounts;
  final String activeStateKey;
  final int totalCount;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      const MapEntry(_FullPlacesMapPageState._allStatesKey, 'All'),
      ...stateCounts.keys.map((state) => MapEntry(state, state)),
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (final option in options) ...[
                ChoiceChip(
                  label: Text(_labelFor(option.key, option.value)),
                  selected: activeStateKey == option.key,
                  onSelected: (_) => onSelected(option.key),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(String key, String label) {
    final count = key == _FullPlacesMapPageState._allStatesKey
        ? totalCount
        : stateCounts[key] ?? 0;
    return '$label ($count)';
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet();

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  final _controller = TextEditingController();

  static const _suggestions = [
    'New Delhi',
    'Mumbai',
    'Jaipur',
    'Agra',
    'Goa',
    'Varanasi',
    'Bengaluru',
    'Kochi',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final query = (value ?? _controller.text).trim();
    if (query.isNotEmpty) Navigator.pop(context, query);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your starting location',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a city, landmark, hotel, or full address. All distances '
            'will be recalculated from that point.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            decoration: const InputDecoration(
              labelText: 'City or address',
              hintText: 'For example: Jaipur',
              prefixIcon: Icon(Icons.location_searching_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (city) => ActionChip(
                    label: Text(city),
                    onPressed: () => _submit(city),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Use this location'),
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
                tooltip: 'view_on_map'.tr(),
                onPressed: () => _openInAppMap(context),
                icon: const Icon(
                  Icons.map_outlined,
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

  void _openInAppMap(BuildContext context) {
    context.push(
      AppRoutes.destinationMapLocation(
        placeName: place.name,
        latitude: place.latitude,
        longitude: place.longitude,
        address: place.address?.trim().isNotEmpty == true
            ? place.address
            : '${place.city}, ${place.state}',
        imageUrl: place.primaryImage,
      ),
    );
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
          label: Text('try_again'.tr()),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _chooseLocation(context, ref),
          icon: const Icon(Icons.edit_location_alt_outlined),
          label: Text('choose_location'.tr()),
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

  Future<void> _chooseLocation(BuildContext context, WidgetRef ref) async {
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _LocationPickerSheet(),
    );
    if (query == null) return;
    final found =
        await ref.read(locationProvider.notifier).selectLocation(query);
    if (!found && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not found. Try another name.')),
      );
    }
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
