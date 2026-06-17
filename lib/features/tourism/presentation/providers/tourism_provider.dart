import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_filters.dart';
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
          .eq('featured', true)
          .order(
            'tier',
          )
          .order(
            'rating',
            ascending: false,
          )
          .limit(12);

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
          .eq('is_popular', true)
          .order(
            'tier',
          )
          .order(
            'rating',
            ascending: false,
          )
          .limit(80);

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
          .eq('is_popular', true)
          .order(
            'rating',
            ascending: false,
          )
          .limit(16);

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
          .eq('featured', true)
          .order(
            'rating',
            ascending: false,
          )
          .limit(12);

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
  Future<List<TourismPlace>> getExplorerPlaces(TourismFilters filters) async {
    try {
      var query = _client.from('tourism_places').select();
      final search = filters.query.trim();

      if (search.isNotEmpty) {
        final value = search.replaceAll(',', ' ');
        query = query.or(
          'place_name.ilike.%$value%,city.ilike.%$value%,'
          'district.ilike.%$value%,state.ilike.%$value%,'
          'category.ilike.%$value%,subcategory.ilike.%$value%',
        );
      }

      if (filters.city?.isNotEmpty == true) {
        query = query.ilike('city', '%${filters.city!}%');
      }

      if (filters.category?.isNotEmpty == true) {
        query = query.eq('category', filters.category!);
      }

      if (filters.popularOnly) {
        query = query.eq('is_popular', true);
      }

      if (filters.freeOnly) {
        query =
            query.or('entry_fee_foreigner.eq.0,entry_fee_foreigner.is.null');
      }

      if (filters.minimumRating > 0) {
        query = query.gte('rating', filters.minimumRating);
      }

      final response = await query
          .order('featured', ascending: false)
          .order('is_popular', ascending: false)
          .order('rating', ascending: false)
          .limit(300);

      var places = _placesFrom(response);
      if (filters.hiddenGemsOnly) {
        places = places.where((place) => place.isHiddenGem).toList();
      }
      if (filters.foreignerFriendlyOnly) {
        places = places.where((place) => place.isForeignerFriendly).toList();
      }
      if (filters.openNowOnly) {
        places = places.where((place) => place.isLikelyOpenNow).toList();
      }
      return places;
    } catch (e) {
      print(
        'Explorer places error: $e',
      );
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
      final latitudeDelta = radiusKm / 111.0;
      final longitudeDelta = radiusKm /
          (111.320 * math.cos(latitude * math.pi / 180).abs().clamp(0.1, 1.0));

      final response = await _client
          .from(
            'tourism_places',
          )
          .select()
          .gte('latitude', latitude - latitudeDelta)
          .lte('latitude', latitude + latitudeDelta)
          .gte('longitude', longitude - longitudeDelta)
          .lte('longitude', longitude + longitudeDelta)
          .order(
            'rating',
            ascending: false,
          )
          .limit(300);

      final places = _placesFrom(response).where((place) {
        if (place.latitude == 0 || place.longitude == 0) return false;
        final distance = DistanceCalculator.calculate(
          lat1: latitude,
          lon1: longitude,
          lat2: place.latitude,
          lon2: place.longitude,
        );
        return distance <= radiusKm;
      }).toList()
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

final explorerPlacesProvider =
    FutureProvider.family<List<TourismPlace>, TourismFilters>(
  (ref, filters) {
    return ref.read(tourismRepositoryProvider).getExplorerPlaces(filters);
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
