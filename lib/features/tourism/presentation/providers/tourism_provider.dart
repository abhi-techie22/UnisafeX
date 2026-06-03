import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

class TourismRepository {
  final SupabaseClient _client;

  TourismRepository(this._client);

  Future<List<TourismPlace>> getFeaturedPlaces() async {
    final response = await _client
        .from('tourism_places')
        .select()
        .eq('featured', true)
        .order('rating', ascending: false)
        .limit(10);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getPopularPlaces() async {
    final response = await _client
        .from('tourism_places')
        .select()
        .eq('is_popular', true)
        .order('rating', ascending: false)
        .limit(20);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getPlacesByCategory(String category) async {
    final response = await _client
        .from('tourism_places')
        .select()
        .eq('category', category)
        .order('rating', ascending: false)
        .limit(AppConstants.pageSize);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getPlacesByCity(String city) async {
    final response = await _client
        .from('tourism_places')
        .select()
        .ilike('city', '%$city%')
        .order('rating', ascending: false)
        .limit(20);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getTrendingPlaces() async {
    final response = await _client
        .from('tourism_places')
        .select()
        .eq('tier', 1)
        .order('rating', ascending: false)
        .limit(10);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> searchPlaces(String query) async {
    final response = await _client
        .from('tourism_places')
        .select()
        .or('place_name.ilike.%$query%,city.ilike.%$query%,state.ilike.%$query%,category.ilike.%$query%')
        .order('rating', ascending: false)
        .limit(30);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    // Using Supabase PostGIS if available, or fallback to bounding box
    final latDelta = radiusKm / 111.0;
    final lngDelta = radiusKm / (111.0 * (1 / (latitude.abs() * (3.14159 / 180)).abs().clamp(0.0001, 1.0)));

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
  }

  Future<List<TourismPlace>> getPlacesWithFilters({
    String? category,
    bool? isFree,
    bool? isPopular,
    String? bestSeason,
    int? page,
  }) async {
    var query = _client.from('tourism_places').select();

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (isFree == true) {
      query = query.or('entry_fee_foreigner.is.null,entry_fee_foreigner.eq.0');
    }
    if (isPopular == true) {
      query = query.eq('is_popular', true);
    }
    if (bestSeason != null && bestSeason.isNotEmpty) {
      query = query.ilike('best_season', '%$bestSeason%');
    }

    final from = (page ?? 0) * AppConstants.pageSize;
    final to = from + AppConstants.pageSize - 1;

    final response = await query
        .order('rating', ascending: false)
        .range(from, to);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<TourismPlace?> getPlaceById(String id) async {
    final response = await _client
        .from('tourism_places')
        .select()
        .eq('place_id', id)
        .single();

    return TourismPlace.fromJson(response);
  }

  Future<List<TourismPlace>> getMustVisitPlaces() async {
    final response = await _client
        .from('tourism_places')
        .select()
        .eq('tier', 1)
        .eq('featured', true)
        .order('rating', ascending: false)
        .limit(8);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getAllPlaces({int page = 0}) async {
    final from = page * AppConstants.pageSize;
    final to = from + AppConstants.pageSize - 1;

    final response = await _client
        .from('tourism_places')
        .select()
        .order('rating', ascending: false)
        .range(from, to);

    return (response as List).map((e) => TourismPlace.fromJson(e)).toList();
  }
}

final tourismRepositoryProvider = Provider<TourismRepository>((ref) {
  return TourismRepository(Supabase.instance.client);
});

final featuredPlacesProvider = FutureProvider<List<TourismPlace>>((ref) async {
  return ref.read(tourismRepositoryProvider).getFeaturedPlaces();
});

final popularPlacesProvider = FutureProvider<List<TourismPlace>>((ref) async {
  return ref.read(tourismRepositoryProvider).getPopularPlaces();
});

final trendingPlacesProvider = FutureProvider<List<TourismPlace>>((ref) async {
  return ref.read(tourismRepositoryProvider).getTrendingPlaces();
});

final mustVisitPlacesProvider = FutureProvider<List<TourismPlace>>((ref) async {
  return ref.read(tourismRepositoryProvider).getMustVisitPlaces();
});

final placesByCategoryProvider =
    FutureProvider.family<List<TourismPlace>, String>((ref, category) async {
  return ref.read(tourismRepositoryProvider).getPlacesByCategory(category);
});

final placesByCityProvider =
    FutureProvider.family<List<TourismPlace>, String>((ref, city) async {
  return ref.read(tourismRepositoryProvider).getPlacesByCity(city);
});

final searchPlacesProvider =
    FutureProvider.family<List<TourismPlace>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.read(tourismRepositoryProvider).searchPlaces(query);
});

class NearbyParams {
  final double lat;
  final double lng;
  final double radiusKm;

  const NearbyParams({
    required this.lat,
    required this.lng,
    this.radiusKm = 50,
  });
}

final nearbyPlacesProvider =
    FutureProvider.family<List<TourismPlace>, NearbyParams>((ref, params) async {
  return ref.read(tourismRepositoryProvider).getNearbyPlaces(
        latitude: params.lat,
        longitude: params.lng,
        radiusKm: params.radiusKm,
      );
});
