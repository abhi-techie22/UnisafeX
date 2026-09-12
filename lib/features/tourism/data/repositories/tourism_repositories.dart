import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

void _debugLog(Object? message) {
  assert(() {
    debugPrint('$message');
    return true;
  }());
}

class TourismRepository {
  final SupabaseClient _client;

  TourismRepository(this._client);

  Future<List<TourismPlace>> getFeaturedPlaces() async {
    try {
      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .eq('featured', true)
          .order('rating', ascending: false)
          .limit(10);

      _debugLog('Featured places loaded: ${response.length}');

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getFeaturedPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getPopularPlaces() async {
    try {
      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .eq('is_popular', true)
          .order('rating', ascending: false)
          .limit(20);

      _debugLog('Popular places loaded: ${response.length}');

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getPopularPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getPlacesByCategory(String category) async {
    try {
      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .eq('category', category)
          .order('rating', ascending: false)
          .limit(AppConstants.pageSize);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getPlacesByCategory: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getPlacesByCity(String city) async {
    try {
      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .ilike('city', '%$city%')
          .order('rating', ascending: false)
          .limit(20);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getPlacesByCity: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getTrendingPlaces() async {
    try {
      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .eq('tier', 1)
          .order('rating', ascending: false)
          .limit(10);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getTrendingPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> searchPlaces(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .or('place_name.ilike.%$query%,city.ilike.%$query%,state.ilike.%$query%,category.ilike.%$query%')
          .order('rating', ascending: false)
          .limit(30);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR searchPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    try {
      final latDelta = radiusKm / 111.0;

      final lngDelta = radiusKm /
          (111.0 *
              (1 /
                  (latitude.abs() * (3.14159 / 180)).abs().clamp(0.0001, 1.0)));

      final response = await _client
          .from('tourism_places')
          .select()
          .gte('latitude', latitude - latDelta)
          .lte('latitude', latitude + latDelta)
          .gte('longitude', longitude - lngDelta)
          .lte('longitude', longitude + lngDelta)
          .order('rating', ascending: false)
          .limit(20);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getNearbyPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getPlacesWithFilters({
    String? category,
    bool? isFree,
    bool? isPopular,
    String? bestSeason,
    int? page,
  }) async {
    try {
      var query =
          _client.from('tourism_places').select().eq('is_hidden', false);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (isFree == true) {
        query =
            query.or('entry_fee_foreigner.is.null,entry_fee_foreigner.eq.0');
      }

      if (isPopular == true) {
        query = query.eq('is_popular', true);
      }

      if (bestSeason != null && bestSeason.isNotEmpty) {
        query = query.ilike('best_season', '%$bestSeason%');
      }

      final from = (page ?? 0) * AppConstants.pageSize;
      final to = from + AppConstants.pageSize - 1;

      final response =
          await query.order('rating', ascending: false).range(from, to);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getPlacesWithFilters: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<TourismPlace?> getPlaceById(String id) async {
    try {
      _debugLog('DEBUG Place ID: "$id"');

      if (id.trim().isEmpty) {
        _debugLog('ERROR: Empty ID');
        return null;
      }

      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .eq('place_id', id)
          .maybeSingle();

      if (response == null) {
        _debugLog('No place found');
        return null;
      }

      return TourismPlace.fromJson(response);
    } catch (e, stackTrace) {
      _debugLog('ERROR getPlaceById: $e');
      _debugLog(stackTrace);
      return null;
    }
  }

  Future<List<TourismPlace>> getMustVisitPlaces() async {
    try {
      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .eq('tier', 1)
          .eq('featured', true)
          .order('rating', ascending: false)
          .limit(8);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getMustVisitPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }

  Future<List<TourismPlace>> getAllPlaces({int page = 0}) async {
    try {
      final from = page * AppConstants.pageSize;
      final to = from + AppConstants.pageSize - 1;

      final response = await _client
          .from('tourism_places')
          .select()
          .eq('is_hidden', false)
          .order('rating', ascending: false)
          .range(from, to);

      return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
    } catch (e, stackTrace) {
      _debugLog('ERROR getAllPlaces: $e');
      _debugLog(stackTrace);
      return [];
    }
  }
}

final tourismRepositoryProvider = Provider<TourismRepository>((ref) {
  return TourismRepository(Supabase.instance.client);
});
