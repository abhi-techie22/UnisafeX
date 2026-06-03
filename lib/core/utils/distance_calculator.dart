import 'dart:math' as math;

class DistanceCalculator {
  DistanceCalculator._();

  /// Returns distance in kilometers between two coordinates
  static double calculate({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const p = math.pi / 180;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  /// Returns a human-readable distance string
  static String format(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).toInt()} m away';
    } else if (distanceKm < 10.0) {
      return '${distanceKm.toStringAsFixed(1)} km away';
    } else {
      return '${distanceKm.toInt()} km away';
    }
  }

  /// Returns an approximate driving time in minutes
  static int estimateDriveMinutes(double distanceKm) {
    // Average speed assumption: 40 km/h in Indian conditions
    return ((distanceKm / 40.0) * 60).ceil();
  }
}
