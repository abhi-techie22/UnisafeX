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
  final LocationSource source;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.city,
    this.state,
    required this.accuracyMeters,
    required this.capturedAt,
    required this.source,
  });
}

enum LocationSource { gps, selected }

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
        source: LocationSource.gps,
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

  Future<bool> selectLocation(String query) async {
    final value = query.trim();
    if (value.isEmpty) return false;

    final previous = state;
    state = const AsyncValue.loading();
    try {
      final known = _knownLocations[value.toLowerCase()];
      if (known != null) {
        state = AsyncValue.data(
          LocationData(
            latitude: known.$1,
            longitude: known.$2,
            name: known.$3,
            city: known.$3,
            state: known.$4,
            accuracyMeters: 0,
            capturedAt: DateTime.now(),
            source: LocationSource.selected,
          ),
        );
        return true;
      }

      final matches = await locationFromAddress(value);
      if (matches.isEmpty) {
        state = previous;
        return false;
      }

      final match = matches.first;
      String name = value;
      String? city;
      String? stateName;
      try {
        final placemarks = await placemarkFromCoordinates(
          match.latitude,
          match.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea;
          stateName = place.administrativeArea;
          name = [
            if (city?.isNotEmpty == true) city!,
            if (stateName?.isNotEmpty == true && stateName != city) stateName!,
          ].join(', ');
          if (name.isEmpty) name = value;
        }
      } catch (_) {}

      state = AsyncValue.data(
        LocationData(
          latitude: match.latitude,
          longitude: match.longitude,
          name: name,
          city: city,
          state: stateName,
          accuracyMeters: 0,
          capturedAt: DateTime.now(),
          source: LocationSource.selected,
        ),
      );
      return true;
    } catch (_) {
      state = previous;
      return false;
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  static const _knownLocations = <String, (double, double, String, String)>{
    'new delhi': (28.6139, 77.2090, 'New Delhi', 'Delhi'),
    'delhi': (28.6139, 77.2090, 'New Delhi', 'Delhi'),
    'mumbai': (19.0760, 72.8777, 'Mumbai', 'Maharashtra'),
    'jaipur': (26.9124, 75.7873, 'Jaipur', 'Rajasthan'),
    'agra': (27.1767, 78.0081, 'Agra', 'Uttar Pradesh'),
    'goa': (15.2993, 74.1240, 'Goa', 'Goa'),
    'varanasi': (25.3176, 82.9739, 'Varanasi', 'Uttar Pradesh'),
    'bengaluru': (12.9716, 77.5946, 'Bengaluru', 'Karnataka'),
    'bangalore': (12.9716, 77.5946, 'Bengaluru', 'Karnataka'),
    'kochi': (9.9312, 76.2673, 'Kochi', 'Kerala'),
  };
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<LocationData?>>(
        (ref) => LocationNotifier());
