import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/core/utils/google_maps_launcher.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';
import 'package:unisafex/features/maps/data/map_route_repository.dart';
import 'package:unisafex/features/maps/domain/map_route.dart';

class InAppMapScreen extends ConsumerStatefulWidget {
  const InAppMapScreen({
    super.key,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final String placeName;
  final double latitude;
  final double longitude;
  final String? address;

  @override
  ConsumerState<InAppMapScreen> createState() => _InAppMapScreenState();
}

class _InAppMapScreenState extends ConsumerState<InAppMapScreen> {
  GoogleMapController? _mapController;
  AsyncValue<MapRoute?> _routeState = const AsyncValue.data(null);
  RouteTravelMode _travelMode = RouteTravelMode.driving;
  String? _lastOriginKey;
  bool _isCardCollapsed = false;

  LatLng get _destination => LatLng(widget.latitude, widget.longitude);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _centerDestination() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _destination, zoom: 15.5),
      ),
    );
  }

  Future<void> _loadRoute(LocationData location) async {
    final originKey =
        '${location.latitude},${location.longitude},${_travelMode.name}';
    if (_routeState.isLoading || originKey == _lastOriginKey) return;

    _lastOriginKey = originKey;
    setState(() => _routeState = const AsyncValue.loading());
    try {
      final route = await ref.read(mapRouteRepositoryProvider).computeRoute(
            originLatitude: location.latitude,
            originLongitude: location.longitude,
            destinationLatitude: widget.latitude,
            destinationLongitude: widget.longitude,
            travelMode: _travelMode,
          );
      if (!mounted) return;
      setState(() => _routeState = AsyncValue.data(route));
      await _focusDestinationRoute();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _routeState = AsyncValue.error(error, stackTrace));
    }
  }

  Future<void> _focusDestinationRoute() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _destination, zoom: 14.2),
      ),
    );
  }

  Future<void> _changeTravelMode(
    RouteTravelMode mode,
    LocationData? location,
  ) async {
    if (mode == _travelMode) return;
    setState(() {
      _travelMode = mode;
      _lastOriginKey = null;
    });
    if (location != null) await _loadRoute(location);
  }

  Future<void> _showStartLocationPicker() async {
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _MapLocationPickerSheet(),
    );
    if (query == null || !mounted) return;

    final found =
        await ref.read(locationProvider.notifier).selectLocation(query);
    if (!mounted) return;

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location not found. Try a city, landmark, hotel, or full address.',
          ),
        ),
      );
      return;
    }

    final location = ref.read(locationProvider).asData?.value;
    if (location != null) {
      _lastOriginKey = null;
      await _loadRoute(location);
    }
  }

  Future<void> _showCurrentLocation() async {
    await ref.read(locationProvider.notifier).refresh();
    if (!mounted) return;

    final location = ref.read(locationProvider).asData?.value;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is unavailable.')),
      );
      return;
    }

    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15,
      ),
    );
    _lastOriginKey = null;
    await _loadRoute(location);
  }

  Future<void> _openExternalMaps() async {
    final location = ref.read(locationProvider).asData?.value;
    final opened = await GoogleMapsLauncher.openDirections(
      originLatitude: location?.latitude,
      originLongitude: location?.longitude,
      destinationLatitude: widget.latitude,
      destinationLongitude: widget.longitude,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final location = locationState.asData?.value;
    final hasLiveLocation = location?.source == LocationSource.gps;
    final straightLineDistance = location == null
        ? null
        : DistanceCalculator.calculate(
            lat1: location.latitude,
            lon1: location.longitude,
            lat2: widget.latitude,
            lon2: widget.longitude,
          );
    final route = _routeState.asData?.value;

    ref.listen(locationProvider, (previous, next) {
      final nextLocation = next.asData?.value;
      if (nextLocation != null) {
        unawaited(_loadRoute(nextLocation));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.placeName)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _destination,
              zoom: 15.5,
            ),
            mapType: MapType.normal,
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationEnabled: hasLiveLocation,
            myLocationButtonEnabled: false,
            padding: EdgeInsets.only(
              top: 18,
              right: 18,
              bottom: _isCardCollapsed ? 110 : 320,
            ),
            markers: <Marker>{
              Marker(
                markerId: const MarkerId('destination'),
                position: _destination,
                infoWindow: InfoWindow(
                  title: widget.placeName,
                  snippet: widget.address,
                ),
              ),
              if (location != null)
                Marker(
                  markerId: const MarkerId('origin'),
                  position: LatLng(location.latitude, location.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                  infoWindow: InfoWindow(
                    title: location.source == LocationSource.gps
                        ? 'Your current location'
                        : location.name,
                    snippet: 'Route start',
                  ),
                ),
            },
            polylines: route == null
                ? const <Polyline>{}
                : {
                    Polyline(
                      polylineId: const PolylineId('active-route-outline'),
                      points: route.points,
                      color: Colors.white,
                      width: 7,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      zIndex: 1,
                    ),
                    Polyline(
                      polylineId: const PolylineId('active-route'),
                      points: route.points,
                      color: AppColors.primary,
                      width: 4,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      zIndex: 2,
                    ),
                  },
            onMapCreated: (controller) {
              _mapController = controller;
              if (location != null) {
                unawaited(_loadRoute(location));
              }
            },
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                _MapControlButton(
                  tooltip: 'Center destination',
                  icon: Icons.center_focus_strong_rounded,
                  onPressed: _centerDestination,
                ),
                const SizedBox(height: 10),
                _MapControlButton(
                  tooltip: 'Show current location',
                  icon: locationState.isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.my_location_rounded,
                  onPressed:
                      locationState.isLoading ? null : _showCurrentLocation,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: _DestinationCard(
                isCollapsed: _isCardCollapsed,
                placeName: widget.placeName,
                address: widget.address,
                latitude: widget.latitude,
                longitude: widget.longitude,
                straightLineDistance: straightLineDistance,
                routeState: _routeState,
                travelMode: _travelMode,
                origin: location,
                locationError: locationState.hasError
                    ? locationState.error.toString()
                    : null,
                onTravelModeChanged: (mode) =>
                    _changeTravelMode(mode, location),
                onCenter: _centerDestination,
                onCurrentLocation:
                    locationState.isLoading ? null : _showCurrentLocation,
                onChangeStartLocation: _showStartLocationPicker,
                onRetryRoute: location == null
                    ? null
                    : () {
                        _lastOriginKey = null;
                        _loadRoute(location);
                      },
                onDirections: route?.steps.isNotEmpty == true
                    ? () => _showDirections(route!)
                    : null,
                onExternalMaps: _openExternalMaps,
                onToggleCollapsed: () {
                  setState(() => _isCardCollapsed = !_isCardCollapsed);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDirections(MapRoute route) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.68,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  const Icon(Icons.route_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${route.formattedDistance} · '
                      '${route.formattedDuration}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: route.steps.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final step = route.steps[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.instruction),
                            if (step.distanceMeters > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatStepDistance(step.distanceMeters),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStepDistance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.isCollapsed,
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.straightLineDistance,
    required this.routeState,
    required this.travelMode,
    required this.origin,
    required this.locationError,
    required this.onTravelModeChanged,
    required this.onCenter,
    required this.onCurrentLocation,
    required this.onChangeStartLocation,
    required this.onRetryRoute,
    required this.onDirections,
    required this.onExternalMaps,
    required this.onToggleCollapsed,
  });

  final bool isCollapsed;
  final String placeName;
  final String? address;
  final double latitude;
  final double longitude;
  final double? straightLineDistance;
  final AsyncValue<MapRoute?> routeState;
  final RouteTravelMode travelMode;
  final LocationData? origin;
  final String? locationError;
  final ValueChanged<RouteTravelMode> onTravelModeChanged;
  final VoidCallback onCenter;
  final VoidCallback? onCurrentLocation;
  final VoidCallback onChangeStartLocation;
  final VoidCallback? onRetryRoute;
  final VoidCallback? onDirections;
  final VoidCallback onExternalMaps;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayAddress = address?.trim().isNotEmpty == true
        ? address!.trim()
        : 'Address not available';
    final route = routeState.asData?.value;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: isCollapsed
            ? _CollapsedDestinationCard(
                key: const ValueKey('collapsed-map-card'),
                placeName: placeName,
                route: route,
                straightLineDistance: straightLineDistance,
                routeState: routeState,
                onExpand: onToggleCollapsed,
                onDirections: onDirections,
                onCenter: onCenter,
              )
            : Material(
                key: const ValueKey('expanded-map-card'),
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Minimize details',
                            onPressed: onToggleCollapsed,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: RouteTravelMode.values
                              .map(
                                (mode) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    selected: travelMode == mode,
                                    onSelected: (_) =>
                                        onTravelModeChanged(mode),
                                    avatar:
                                        Icon(_travelModeIcon(mode), size: 17),
                                    label: Text(mode.label),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.pin_drop_outlined,
                            label:
                                '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                          ),
                          if (route != null) ...[
                            _InfoChip(
                              icon: Icons.near_me_outlined,
                              label: route.formattedDistance,
                            ),
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: route.formattedDuration,
                            ),
                          ] else if (straightLineDistance != null)
                            _InfoChip(
                              icon: Icons.straighten_rounded,
                              label:
                                  '${DistanceCalculator.format(straightLineDistance!)} direct',
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _RouteOriginBanner(
                        origin: origin,
                        locationError: locationError,
                        onChangeStartLocation: onChangeStartLocation,
                      ),
                      if (routeState.isLoading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 5),
                        Text(
                          'Calculating live route...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (routeState.hasError) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                routeState.error.toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            TextButton(
                              onPressed: onRetryRoute,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onDirections ?? onCenter,
                              icon: Icon(
                                onDirections == null
                                    ? Icons.center_focus_strong_rounded
                                    : Icons.directions_rounded,
                              ),
                              label: Text(
                                onDirections == null
                                    ? 'Center map'
                                    : 'Directions',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Show current location',
                            onPressed: onCurrentLocation,
                            icon: const Icon(Icons.my_location_rounded),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            tooltip: 'Choose start location',
                            onPressed: onChangeStartLocation,
                            icon: const Icon(Icons.edit_location_alt_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: onExternalMaps,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: const Text('Open external Google Maps'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  IconData _travelModeIcon(RouteTravelMode mode) {
    return switch (mode) {
      RouteTravelMode.driving => Icons.directions_car_rounded,
      RouteTravelMode.walking => Icons.directions_walk_rounded,
      RouteTravelMode.bicycling => Icons.directions_bike_rounded,
      RouteTravelMode.transit => Icons.directions_transit_rounded,
    };
  }
}

class _CollapsedDestinationCard extends StatelessWidget {
  const _CollapsedDestinationCard({
    super.key,
    required this.placeName,
    required this.route,
    required this.straightLineDistance,
    required this.routeState,
    required this.onExpand,
    required this.onDirections,
    required this.onCenter,
  });

  final String placeName;
  final MapRoute? route;
  final double? straightLineDistance;
  final AsyncValue<MapRoute?> routeState;
  final VoidCallback onExpand;
  final VoidCallback? onDirections;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitle = _subtitle();

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onExpand,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onDirections != null) ...[
                IconButton.filled(
                  tooltip: 'Directions',
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_rounded),
                ),
                const SizedBox(width: 6),
              ] else
                IconButton.filledTonal(
                  tooltip: 'Center map',
                  onPressed: onCenter,
                  icon: const Icon(Icons.center_focus_strong_rounded),
                ),
              IconButton(
                tooltip: 'Expand details',
                onPressed: onExpand,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    if (routeState.isLoading) return 'Calculating live route...';
    if (route != null) {
      return '${route!.formattedDistance} · ${route!.formattedDuration}';
    }
    if (straightLineDistance != null) {
      return '${DistanceCalculator.format(straightLineDistance!)} direct';
    }
    if (routeState.hasError) return routeState.error.toString();
    return 'Tap to view map details';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RouteOriginBanner extends StatelessWidget {
  const _RouteOriginBanner({
    required this.origin,
    required this.locationError,
    required this.onChangeStartLocation,
  });

  final LocationData? origin;
  final String? locationError;
  final VoidCallback onChangeStartLocation;

  @override
  Widget build(BuildContext context) {
    final hasOrigin = origin != null;
    final text = hasOrigin
        ? origin!.source == LocationSource.gps
            ? 'Route starts from your live GPS location.'
            : 'Route starts from ${origin!.name}.'
        : locationError ??
            'Choose a starting city, hotel, or landmark to calculate route time.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasOrigin
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasOrigin
              ? AppColors.success.withValues(alpha: 0.18)
              : AppColors.warning.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasOrigin
                ? Icons.trip_origin_rounded
                : Icons.edit_location_alt_rounded,
            size: 18,
            color: hasOrigin ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: onChangeStartLocation,
            child: Text(hasOrigin ? 'Change' : 'Choose start'),
          ),
        ],
      ),
    );
  }
}

class _MapLocationPickerSheet extends StatefulWidget {
  const _MapLocationPickerSheet();

  @override
  State<_MapLocationPickerSheet> createState() =>
      _MapLocationPickerSheetState();
}

class _MapLocationPickerSheetState extends State<_MapLocationPickerSheet> {
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
            'Choose start location',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter where the tourist is starting from. Route time and distance '
            'will update from this location.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'City, hotel, landmark, or full address',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Use this location',
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            onSubmitted: _submit,
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
