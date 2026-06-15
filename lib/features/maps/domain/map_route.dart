import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RouteTravelMode {
  driving('DRIVE', 'Drive'),
  walking('WALK', 'Walk'),
  bicycling('BICYCLE', 'Bicycle'),
  transit('TRANSIT', 'Transit');

  const RouteTravelMode(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class MapRouteStep {
  const MapRouteStep({
    required this.instruction,
    required this.distanceMeters,
  });

  final String instruction;
  final int distanceMeters;
}

class MapRoute {
  const MapRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
    required this.steps,
  });

  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> points;
  final List<MapRouteStep> steps;

  double get distanceKilometers => distanceMeters / 1000;

  String get formattedDistance {
    if (distanceMeters < 1000) return '$distanceMeters m';
    return '${distanceKilometers.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final minutes = (durationSeconds / 60).ceil();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours hr';
    return '$hours hr $remainingMinutes min';
  }
}
