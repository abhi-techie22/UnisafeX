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
      final place =
          TourismPlace.fromJson(Map<String, dynamic>.from(row as Map));
      final key = '${place.name.toLowerCase()}|${place.city.toLowerCase()}';
      final existing = unique[key];
      if (existing == null || _isBetterDuplicate(place, existing)) {
        unique[key] = place;
      }
    }
    return unique.values.toList();
  }

  bool _isBetterDuplicate(TourismPlace candidate, TourismPlace existing) {
    if (candidate.images.length != existing.images.length) {
      return candidate.images.length > existing.images.length;
    }
    if (candidate.likesCount != existing.likesCount) {
      return candidate.likesCount > existing.likesCount;
    }
    if (candidate.rating != existing.rating) {
      return candidate.rating > existing.rating;
    }
    return candidate.featured && !existing.featured;
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

  Future<List<TourismPlace>> getPlannerPlaces() async {
    try {
      const batchSize = 1000;
      final all = <TourismPlace>[];

      for (var page = 0; page < 8; page++) {
        final from = page * batchSize;
        final to = from + batchSize - 1;
        final response = await _client
            .from('tourism_places')
            .select()
            .order('state')
            .order('city')
            .order('featured', ascending: false)
            .order('is_popular', ascending: false)
            .order('rating', ascending: false)
            .range(from, to);
        final batch = _placesFrom(response);
        all.addAll(batch);
        if ((response as List).length < batchSize) break;
      }

      final unique = <String, TourismPlace>{};
      for (final place in all) {
        final key = '${place.name.toLowerCase()}|${place.city.toLowerCase()}';
        final existing = unique[key];
        if (existing == null || _isBetterDuplicate(place, existing)) {
          unique[key] = place;
        }
      }

      return unique.values.toList()
        ..sort((a, b) {
          final city = a.city.compareTo(b.city);
          if (city != 0) return city;
          return b.rating.compareTo(a.rating);
        });
    } catch (e) {
      print('Planner places error: $e');
      return [];
    }
  }

  Future<int> likePlace(String placeId) async {
    final response = await _client.rpc<int>(
      'like_tourism_place',
      params: {'p_place_id': placeId},
    );
    return response;
  }

  Future<List<TourismPlace>> getAdminPlaces({
    String search = '',
    int page = 0,
  }) async {
    try {
      var query = _client.from('tourism_places').select();
      final trimmed = search.trim().replaceAll(',', ' ');

      if (trimmed.isNotEmpty) {
        query = query.or(
          'place_name.ilike.%$trimmed%,city.ilike.%$trimmed%,'
          'district.ilike.%$trimmed%,state.ilike.%$trimmed%,'
          'category.ilike.%$trimmed%,subcategory.ilike.%$trimmed%',
        );
      }

      final from = page * AppConstants.pageSize;
      final to = from + AppConstants.pageSize - 1;
      final response = await query
          .order('featured', ascending: false)
          .order('is_popular', ascending: false)
          .order('rating', ascending: false)
          .range(from, to);

      return _placesFrom(response);
    } catch (e) {
      print('Admin places error: $e');
      return [];
    }
  }

  Future<void> saveAdminPlace({
    String? id,
    required String name,
    required String description,
    required String state,
    required String city,
    required String category,
    String? district,
    String? subcategory,
    required double latitude,
    required double longitude,
    required List<String> images,
    required double entryFeeIndian,
    required double entryFeeForeigner,
    String? timings,
    String? bestSeason,
    required List<String> bestMonths,
    required List<String> safetyGuidelines,
    required List<String> touristTips,
    required int tier,
    required bool featured,
    required double rating,
    required bool isPopular,
    required int likesCount,
    int? visitDurationMinutes,
    String? address,
  }) async {
    final data = <String, dynamic>{
      'place_name': name.trim(),
      'description': _emptyToNull(description),
      'state': state.trim(),
      'district': _emptyToNull(district),
      'city': city.trim(),
      'category': category.trim().isEmpty ? 'Historical' : category.trim(),
      'subcategory': _emptyToNull(subcategory),
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'entry_fee_indian': entryFeeIndian,
      'entry_fee_foreigner': entryFeeForeigner,
      'timings': _emptyToNull(timings),
      'best_season': _emptyToNull(bestSeason),
      'best_months': bestMonths,
      'safety_guidelines': safetyGuidelines,
      'tourist_tips': touristTips,
      'tier': tier.clamp(1, 3),
      'featured': featured,
      'rating': rating.clamp(0, 5),
      'is_popular': isPopular,
      'likes_count': likesCount < 0 ? 0 : likesCount,
      'visit_duration_minutes': visitDurationMinutes,
      'address': _emptyToNull(address),
    };

    if (id == null || id.trim().isEmpty) {
      await _client.from('tourism_places').insert(data);
    } else {
      await _client.from('tourism_places').update(data).eq('place_id', id);
    }
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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

final plannerPlacesProvider = FutureProvider<List<TourismPlace>>((ref) {
  return ref.read(tourismRepositoryProvider).getPlannerPlaces();
});

final likePlaceProvider = FutureProvider.family<int, String>((ref, placeId) {
  return ref.read(tourismRepositoryProvider).likePlace(placeId);
});

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

class AdminTourismPlacesParams {
  final String search;
  final int page;

  const AdminTourismPlacesParams({
    this.search = '',
    this.page = 0,
  });

  @override
  bool operator ==(Object other) {
    return other is AdminTourismPlacesParams &&
        other.search == search &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(search, page);
}

final adminTourismPlacesProvider =
    FutureProvider.family<List<TourismPlace>, AdminTourismPlacesParams>(
  (ref, params) {
    return ref.read(tourismRepositoryProvider).getAdminPlaces(
          search: params.search,
          page: params.page,
        );
  },
);
