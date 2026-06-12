import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/core/utils/google_maps_launcher.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';

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
    final distance = location == null
        ? null
        : DistanceCalculator.calculate(
            lat1: location.latitude,
            lon1: location.longitude,
            lat2: widget.latitude,
            lon2: widget.longitude,
          );

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
            markers: {
              Marker(
                markerId: const MarkerId('destination'),
                position: _destination,
                infoWindow: InfoWindow(
                  title: widget.placeName,
                  snippet: widget.address,
                ),
              ),
            },
            onMapCreated: (controller) => _mapController = controller,
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
                placeName: widget.placeName,
                address: widget.address,
                latitude: widget.latitude,
                longitude: widget.longitude,
                distance: distance,
                onCenter: _centerDestination,
                onCurrentLocation:
                    locationState.isLoading ? null : _showCurrentLocation,
                onExternalMaps: _openExternalMaps,
              ),
            ),
          ),
        ],
      ),
    );
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
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.onCenter,
    required this.onCurrentLocation,
    required this.onExternalMaps,
  });

  final String placeName;
  final String? address;
  final double latitude;
  final double longitude;
  final double? distance;
  final VoidCallback onCenter;
  final VoidCallback? onCurrentLocation;
  final VoidCallback onExternalMaps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayAddress = address?.trim().isNotEmpty == true
        ? address!.trim()
        : 'Address not available';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Material(
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
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.pin_drop_outlined,
                    label:
                        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                  ),
                  if (distance != null)
                    _InfoChip(
                      icon: Icons.near_me_outlined,
                      label: DistanceCalculator.format(distance!),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCenter,
                      icon: const Icon(Icons.center_focus_strong_rounded),
                      label: const Text('Center map'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Show current location',
                    onPressed: onCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
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
    );
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
