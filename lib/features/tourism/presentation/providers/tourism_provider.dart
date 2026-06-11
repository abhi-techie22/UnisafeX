import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

class TourismRepository {
  final SupabaseClient _client;

  TourismRepository(this._client);

  List<TourismPlace> _placesFrom(dynamic response) {
    final unique = <String, TourismPlace>{};
    for (final row in response as List) {
      final place = TourismPlace.fromJson(row as Map<String, dynamic>);
      final key = '${place.name.toLowerCase()}|${place.city.toLowerCase()}';
      unique.putIfAbsent(key, () => place);
    }
    return unique.values.toList();
  }

  // FEATURED PLACES
  Future<List<TourismPlace>> getFeaturedPlaces() async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .order(
            'rating',
            ascending: false,
          )
          .limit(10);

      return _placesFrom(response);
    } catch (e) {
      print(
        'Featured error: $e',
      );
      return [];
    }
  }

  // POPULAR PLACES
  Future<List<TourismPlace>> getPopularPlaces() async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .order(
            'rating',
            ascending: false,
          )
          .limit(200);

      print(
        'SUPABASE DATA: ${response.length}',
      );

      return _placesFrom(response);
    } catch (e) {
      print(
        'Popular error: $e',
      );
      return [];
    }
  }

  // TRENDING
  Future<List<TourismPlace>> getTrendingPlaces() async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .order(
            'rating',
            ascending: false,
          )
          .limit(20);

      return _placesFrom(response);
    } catch (e) {
      print(
        'Trending error: $e',
      );
      return [];
    }
  }

  // MUST VISIT
  Future<List<TourismPlace>> getMustVisitPlaces() async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .order(
            'rating',
            ascending: false,
          )
          .limit(20);

      return _placesFrom(response);
    } catch (e) {
      print(
        'Must visit error: $e',
      );
      return [];
    }
  }

  // CATEGORY
  Future<List<TourismPlace>> getPlacesByCategory(
    String category,
  ) async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .eq(
            'category',
            category,
          )
          .order(
            'rating',
            ascending: false,
          )
          .limit(50);

      return _placesFrom(response);
    } catch (e) {
      print(
        'Category error: $e',
      );
      return [];
    }
  }

  // CITY
  Future<List<TourismPlace>> getPlacesByCity(
    String city,
  ) async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .ilike(
            'city',
            '%$city%',
          )
          .order(
            'rating',
            ascending: false,
          )
          .limit(50);

      return _placesFrom(response);
    } catch (e) {
      print(
        'City error: $e',
      );
      return [];
    }
  }

  // SEARCH
  Future<List<TourismPlace>> searchPlaces(
    String query,
  ) async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .or(
            'place_name.ilike.%$query%,city.ilike.%$query%,state.ilike.%$query%,category.ilike.%$query%',
          )
          .order(
            'rating',
            ascending: false,
          )
          .limit(100);

      return _placesFrom(response);
    } catch (e) {
      print(
        'Search error: $e',
      );
      return [];
    }
  }

  // FILTERS
  Future<List<TourismPlace>> getPlacesWithFilters({
    String? category,
    bool? isFree,
    bool? isPopular,
    String? bestSeason,
    int? page,
  }) async {
    try {
      dynamic query = _client
          .from(
            'tourism_places',
          )
          .select();

      if (category != null && category.isNotEmpty) {
        query = query.eq(
          'category',
          category,
        );
      }

      if (isFree == true) {
        query = query.or(
          'entry_fee_foreigner.eq.0,entry_fee_foreigner.is.null',
        );
      }

      // only apply if requested
      if (isPopular == true) {
        query = query.eq(
          'is_popular',
          true,
        );
      }

      if (bestSeason != null && bestSeason.isNotEmpty) {
        query = query.ilike(
          'best_season',
          '%$bestSeason%',
        );
      }

      final from = (page ?? 0) * AppConstants.pageSize;

      final to = from + AppConstants.pageSize - 1;

      final response = await query
          .order(
            'rating',
            ascending: false,
          )
          .range(
            from,
            to,
          );

      return _placesFrom(response);
    } catch (e) {
      print(
        'Filter error: $e',
      );
      return [];
    }
  }

  // NEARBY
  Future<List<TourismPlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
  }) async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .limit(200);

      final places = _placesFrom(response)
          .where((place) => place.latitude != 0 && place.longitude != 0)
          .toList()
        ..sort(
          (a, b) => DistanceCalculator.calculate(
            lat1: latitude,
            lon1: longitude,
            lat2: a.latitude,
            lon2: a.longitude,
          ).compareTo(
            DistanceCalculator.calculate(
              lat1: latitude,
              lon1: longitude,
              lat2: b.latitude,
              lon2: b.longitude,
            ),
          ),
        );

      return places;
    } catch (e) {
      print(
        'Nearby error: $e',
      );
      return [];
    }
  }

  // BY ID
  Future<TourismPlace?> getPlaceById(
    String id,
  ) async {
    try {
      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .eq(
            'place_id',
            id,
          )
          .single();

      return TourismPlace.fromJson(
        response,
      );
    } catch (e) {
      print(
        'Place by ID error: $e',
      );
      return null;
    }
  }

  // ALL PLACES
  Future<List<TourismPlace>> getAllPlaces({
    int page = 0,
  }) async {
    try {
      final from = page * AppConstants.pageSize;

      final to = from + AppConstants.pageSize - 1;

      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .order(
            'rating',
            ascending: false,
          )
          .range(
            from,
            to,
          );

      return _placesFrom(response);
    } catch (e) {
      print(
        'All places error: $e',
      );
      return [];
    }
  }
}

// PROVIDERS

final tourismRepositoryProvider = Provider<TourismRepository>(
  (ref) {
    return TourismRepository(
      Supabase.instance.client,
    );
  },
);

final featuredPlacesProvider = FutureProvider<List<TourismPlace>>(
  (ref) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getFeaturedPlaces();
  },
);

final popularPlacesProvider = FutureProvider<List<TourismPlace>>(
  (ref) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getPopularPlaces();
  },
);

final trendingPlacesProvider = FutureProvider<List<TourismPlace>>(
  (ref) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getTrendingPlaces();
  },
);

final mustVisitPlacesProvider = FutureProvider<List<TourismPlace>>(
  (ref) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getMustVisitPlaces();
  },
);

final placesByCategoryProvider =
    FutureProvider.family<List<TourismPlace>, String>(
  (
    ref,
    category,
  ) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getPlacesByCategory(
          category,
        );
  },
);

final placesByCityProvider = FutureProvider.family<List<TourismPlace>, String>(
  (
    ref,
    city,
  ) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getPlacesByCity(
          city,
        );
  },
);

final searchPlacesProvider = FutureProvider.family<List<TourismPlace>, String>(
  (
    ref,
    query,
  ) async {
    if (query.isEmpty) {
      return [];
    }

    return ref
        .read(
          tourismRepositoryProvider,
        )
        .searchPlaces(
          query,
        );
  },
);

class NearbyParams {
  final double lat;
  final double lng;
  final double radiusKm;

  const NearbyParams({
    required this.lat,
    required this.lng,
    this.radiusKm = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyParams &&
          lat == other.lat &&
          lng == other.lng &&
          radiusKm == other.radiusKm;

  @override
  int get hashCode => Object.hash(lat, lng, radiusKm);
}

final nearbyPlacesProvider =
    FutureProvider.family<List<TourismPlace>, NearbyParams>(
  (
    ref,
    params,
  ) async {
    return ref
        .read(
          tourismRepositoryProvider,
        )
        .getNearbyPlaces(
          latitude: params.lat,
          longitude: params.lng,
          radiusKm: params.radiusKm,
        );
  },
);
