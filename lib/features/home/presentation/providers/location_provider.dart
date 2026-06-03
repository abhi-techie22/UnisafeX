import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String name;
  final String? city;
  final String? state;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.city,
    this.state,
  });
}

class LocationNotifier extends StateNotifier<AsyncValue<LocationData?>> {
  LocationNotifier() : super(const AsyncValue.data(null)) {
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    state = const AsyncValue.loading();
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          state = const AsyncValue.data(LocationData(
            latitude: 20.5937,
            longitude: 78.9629,
            name: 'India',
          ));
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      String locationName = 'India';
      String? city;
      String? stateName;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality;
          stateName = place.administrativeArea;
          locationName = city ?? stateName ?? 'India';
        }
      } catch (_) {}

      state = AsyncValue.data(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        name: locationName,
        city: city,
        state: stateName,
      ));
    } catch (e, st) {
      state = const AsyncValue.data(LocationData(
        latitude: 20.5937,
        longitude: 78.9629,
        name: 'India',
      ));
    }
  }

  Future<void> refresh() => _fetchLocation();
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<LocationData?>>(
        (ref) => LocationNotifier());
