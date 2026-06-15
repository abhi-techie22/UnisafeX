import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/maps/domain/map_route.dart';

class MapRouteException implements Exception {
  const MapRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MapRouteRepository {
  const MapRouteRepository(this._client);

  final SupabaseClient _client;

  Future<MapRoute> computeRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required RouteTravelMode travelMode,
  }) async {
    late final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'compute-route',
        body: {
          'origin': {
            'latitude': originLatitude,
            'longitude': originLongitude,
          },
          'destination': {
            'latitude': destinationLatitude,
            'longitude': destinationLongitude,
          },
          'travelMode': travelMode.apiValue,
        },
      );
    } on FunctionException catch (error) {
      throw MapRouteException(_errorMessage(error.details));
    }

    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      throw MapRouteException(_errorMessage(data));
    }
    if (data is! Map<String, dynamic>) {
      throw const MapRouteException('Route service returned invalid data.');
    }

    final encodedPolyline = data['encodedPolyline'] as String?;
    if (encodedPolyline == null || encodedPolyline.isEmpty) {
      throw const MapRouteException('No route was found for this journey.');
    }

    final rawSteps = data['steps'] as List? ?? const [];
    return MapRoute(
      distanceMeters: (data['distanceMeters'] as num?)?.toInt() ?? 0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      points: _decodePolyline(encodedPolyline),
      steps: rawSteps
          .whereType<Map>()
          .map(
            (step) => MapRouteStep(
              instruction: step['instruction']?.toString() ?? '',
              distanceMeters: (step['distanceMeters'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((step) => step.instruction.isNotEmpty)
          .toList(),
    );
  }

  String _errorMessage(Object? data) {
    if (data is Map) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          'Could not calculate this route.';
    }
    return 'Could not calculate this route.';
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(LatLng(latitude / 1e5, longitude / 1e5));
    }
    return points;
  }
}

final mapRouteRepositoryProvider = Provider<MapRouteRepository>(
  (ref) => MapRouteRepository(ref.watch(supabaseClientProvider)),
);
