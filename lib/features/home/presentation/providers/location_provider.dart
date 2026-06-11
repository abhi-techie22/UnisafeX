import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String name;
  final String? city;
  final String? state;
  final double accuracyMeters;
  final DateTime capturedAt;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.city,
    this.state,
    required this.accuracyMeters,
    required this.capturedAt,
  });
}

enum LocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  String get message => switch (failure) {
        LocationFailure.servicesDisabled =>
          'Location services are turned off. Enable GPS to see nearby places.',
        LocationFailure.permissionDenied =>
          'Location permission was denied. Allow it to calculate real distances.',
        LocationFailure.permissionDeniedForever =>
          'Location permission is blocked. Enable it in device settings.',
        LocationFailure.unavailable =>
          'Your current location could not be detected. Please try again.',
      };

  @override
  String toString() => message;
}

class LocationNotifier extends StateNotifier<AsyncValue<LocationData?>> {
  LocationNotifier() : super(const AsyncValue.data(null)) {
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    state = const AsyncValue.loading();
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) {
        throw const LocationException(LocationFailure.servicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationFailure.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(LocationFailure.permissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
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
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
      ));
    } on LocationException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        const LocationException(LocationFailure.unavailable),
        stackTrace,
      );
    }
  }

  Future<void> refresh() => _fetchLocation();

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<LocationData?>>(
        (ref) => LocationNotifier());
