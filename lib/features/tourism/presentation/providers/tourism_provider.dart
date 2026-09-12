import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/utils/distance_calculator.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_filters.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

void _debugLog(Object? message) {
  assert(() {
    debugPrint('$message');
    return true;
  }());
}

class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    this.reviewerName,
    this.reviewerAvatarUrl,
    this.title,
    this.body,
    this.imageUrls = const <String>[],
    this.visitDate,
    this.status = 'pending',
    this.adminReply,
    this.adminReplyAt,
    this.helpfulCount = 0,
    this.likedByMe = false,
    required this.createdAt,
  });

  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String? reviewerName;
  final String? reviewerAvatarUrl;
  final String? title;
  final String? body;
  final List<String> imageUrls;
  final DateTime? visitDate;
  final String status;
  final String? adminReply;
  final DateTime? adminReplyAt;
  final int helpfulCount;
  final bool likedByMe;
  final DateTime createdAt;

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      id: json['id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      rating: ((json['rating'] ?? 0) as num).toInt(),
      reviewerName: json['reviewer_name']?.toString(),
      reviewerAvatarUrl: json['reviewer_avatar_url']?.toString(),
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      imageUrls: (json['image_urls'] as List?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList() ??
          const <String>[],
      visitDate: json['visit_date'] == null
          ? null
          : DateTime.tryParse(json['visit_date'].toString()),
      status: json['status']?.toString() ?? 'pending',
      adminReply: json['admin_reply']?.toString(),
      adminReplyAt: json['admin_reply_at'] == null
          ? null
          : DateTime.tryParse(json['admin_reply_at'].toString()),
      helpfulCount: ((json['helpful_count'] ?? 0) as num).toInt(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isApproved => status == 'approved';

  bool get hasAdminReply => adminReply?.trim().isNotEmpty == true;

  PlaceReview copyWith({
    int? helpfulCount,
    bool? likedByMe,
  }) {
    return PlaceReview(
      id: id,
      placeId: placeId,
      userId: userId,
      rating: rating,
      reviewerName: reviewerName,
      reviewerAvatarUrl: reviewerAvatarUrl,
      title: title,
      body: body,
      imageUrls: imageUrls,
      visitDate: visitDate,
      status: status,
      adminReply: adminReply,
      adminReplyAt: adminReplyAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      likedByMe: likedByMe ?? this.likedByMe,
      createdAt: createdAt,
    );
  }

  String get displayReviewerName {
    final value = reviewerName?.trim();
    return value == null || value.isEmpty ? 'UniSafeX traveler' : value;
  }
}

class PlaceReviewReply {
  const PlaceReviewReply({
    required this.id,
    required this.reviewId,
    required this.placeId,
    required this.userId,
    this.replierName,
    this.replierAvatarUrl,
    required this.body,
    this.status = 'approved',
    this.isAdminReply = false,
    required this.createdAt,
  });

  final String id;
  final String reviewId;
  final String placeId;
  final String userId;
  final String? replierName;
  final String? replierAvatarUrl;
  final String body;
  final String status;
  final bool isAdminReply;
  final DateTime createdAt;

  factory PlaceReviewReply.fromJson(Map<String, dynamic> json) {
    return PlaceReviewReply(
      id: json['id']?.toString() ?? '',
      reviewId: json['review_id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      replierName: json['replier_name']?.toString(),
      replierAvatarUrl: json['replier_avatar_url']?.toString(),
      body: json['body']?.toString() ?? '',
      status: json['status']?.toString() ?? 'approved',
      isAdminReply: json['is_admin_reply'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get displayReplierName {
    final value = replierName?.trim();
    return value == null || value.isEmpty ? 'UniSafeX traveler' : value;
  }
}

class ReviewModerationConfig {
  const ReviewModerationConfig({
    this.reviewsRequireApproval = true,
    this.imagesRequireApproval = true,
  });

  final bool reviewsRequireApproval;
  final bool imagesRequireApproval;

  factory ReviewModerationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewModerationConfig();
    return ReviewModerationConfig(
      reviewsRequireApproval: json['reviews_require_approval'] as bool? ?? true,
      imagesRequireApproval: json['images_require_approval'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviews_require_approval': reviewsRequireApproval,
      'images_require_approval': imagesRequireApproval,
    };
  }

  ReviewModerationConfig copyWith({
    bool? reviewsRequireApproval,
    bool? imagesRequireApproval,
  }) {
    return ReviewModerationConfig(
      reviewsRequireApproval:
          reviewsRequireApproval ?? this.reviewsRequireApproval,
      imagesRequireApproval:
          imagesRequireApproval ?? this.imagesRequireApproval,
    );
  }
}

class PlaceLikeState {
  const PlaceLikeState({
    required this.likesCount,
    required this.liked,
  });

  final int likesCount;
  final bool liked;

  factory PlaceLikeState.fromJson(Map<String, dynamic> json) {
    return PlaceLikeState(
      likesCount: ((json['likes_count'] ?? 1000) as num).toInt(),
      liked: json['liked'] as bool? ?? false,
    );
  }
}

class ReviewHelpfulState {
  const ReviewHelpfulState({
    required this.helpfulCount,
    required this.liked,
  });

  final int helpfulCount;
  final bool liked;

  factory ReviewHelpfulState.fromJson(Map<String, dynamic> json) {
    return ReviewHelpfulState(
      helpfulCount: ((json['helpful_count'] ?? 0) as num).toInt(),
      liked: json['liked'] as bool? ?? false,
    );
  }
}

class _ReviewerSnapshot {
  const _ReviewerSnapshot({
    required this.name,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
}

class TourismRepository {
  final SupabaseClient _client;

  TourismRepository(this._client);

  List<TourismPlace> _placesFrom(
    dynamic response, {
    bool dedupe = true,
  }) {
    if (!dedupe) {
      return (response as List)
          .map((row) => TourismPlace.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    }
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
    if (candidate.isHidden != existing.isHidden) {
      return !candidate.isHidden;
    }
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
          .eq('is_hidden', false)
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
      _debugLog(
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
          .eq('is_hidden', false)
          .eq('is_popular', true)
          .order(
            'tier',
          )
          .order(
            'rating',
            ascending: false,
          )
          .limit(80);

      _debugLog(
        'SUPABASE DATA: ${response.length}',
      );

      return _placesFrom(response);
    } catch (e) {
      _debugLog(
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
          .eq('is_hidden', false)
          .eq('is_popular', true)
          .order(
            'rating',
            ascending: false,
          )
          .limit(16);

      return _placesFrom(response);
    } catch (e) {
      _debugLog(
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
          .eq('is_hidden', false)
          .eq('featured', true)
          .order(
            'rating',
            ascending: false,
          )
          .limit(12);

      return _placesFrom(response);
    } catch (e) {
      _debugLog(
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
          .eq('is_hidden', false)
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
      _debugLog(
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
          .eq('is_hidden', false)
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
      _debugLog(
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
          .eq('is_hidden', false)
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
      _debugLog(
        'Search error: $e',
      );
      return [];
    }
  }

  // FILTERS
  Future<List<TourismPlace>> getExplorerPlaces(TourismFilters filters) async {
    try {
      var query = _client.from('tourism_places').select();
      query = query.eq('is_hidden', false);
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
      _debugLog(
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
            .eq('is_hidden', false)
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
      _debugLog('Planner places error: $e');
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

  Future<PlaceLikeState> getPlaceLikeState(String placeId) async {
    final user = _client.auth.currentUser;
    final placeRows = await _client
        .from('tourism_places')
        .select('likes_count')
        .eq('place_id', placeId)
        .eq('is_hidden', false)
        .limit(1);
    final placeData = placeRows.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(placeRows.first as Map);
    var liked = false;
    if (user != null && !user.isAnonymous) {
      final likeRows = await _client
          .from('tourism_place_likes')
          .select('id')
          .eq('place_id', placeId)
          .eq('user_id', user.id)
          .limit(1);
      liked = likeRows.isNotEmpty;
    }
    return PlaceLikeState(
      likesCount: ((placeData['likes_count'] ?? 1000) as num).toInt(),
      liked: liked,
    );
  }

  Future<PlaceLikeState> togglePlaceLike(String placeId) async {
    final response = await _client.rpc<dynamic>(
      'toggle_tourism_place_like',
      params: {'p_place_id': placeId},
    );
    return PlaceLikeState.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<PlaceReview>> getApprovedReviews(String placeId) async {
    final rows = await _client
        .from('tourism_place_reviews')
        .select()
        .eq('place_id', placeId)
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .limit(30);
    final reviews = (rows as List)
        .map((row) => PlaceReview.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous || reviews.isEmpty) {
      return reviews;
    }
    final reviewIds = reviews.map((review) => review.id).toList();
    final likeRows = await _client
        .from('tourism_place_review_likes')
        .select('review_id')
        .eq('user_id', user.id)
        .inFilter('review_id', reviewIds);
    final likedReviewIds = (likeRows as List)
        .map((row) => (row as Map)['review_id']?.toString())
        .whereType<String>()
        .toSet();
    return reviews
        .map(
          (review) => review.copyWith(
            likedByMe: likedReviewIds.contains(review.id),
          ),
        )
        .toList();
  }

  Future<List<PlaceReview>> getAdminReviews({String status = 'pending'}) async {
    dynamic query = _client.from('tourism_place_reviews').select();
    if (status != 'all') {
      query = query.eq('status', status);
    }
    final rows = await query.order('created_at', ascending: false).limit(200);
    return (rows as List)
        .map((row) => PlaceReview.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<PlaceReview?> getMyReview(String placeId) async {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    final row = await _client
        .from('tourism_place_reviews')
        .select()
        .eq('place_id', placeId)
        .eq('user_id', user.id)
        .maybeSingle();
    return row == null ? null : PlaceReview.fromJson(row);
  }

  Future<Map<String, List<PlaceReviewReply>>> getApprovedReviewReplies(
    String placeId,
  ) async {
    final rows = await _client
        .from('tourism_place_review_replies')
        .select()
        .eq('place_id', placeId)
        .eq('status', 'approved')
        .order('created_at', ascending: true)
        .limit(300);
    final repliesByReview = <String, List<PlaceReviewReply>>{};
    for (final row in rows as List) {
      final reply = PlaceReviewReply.fromJson(
        Map<String, dynamic>.from(row as Map),
      );
      repliesByReview.putIfAbsent(reply.reviewId, () => []).add(reply);
    }
    return repliesByReview;
  }

  Future<String> saveReview({
    required String placeId,
    required int rating,
    String? title,
    String? body,
    List<String> imageUrls = const <String>[],
    DateTime? visitDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Login required to review a place');
    }
    final moderation = await getReviewModerationConfig();
    final reviewer = await _reviewerSnapshot(user.id);
    final needsApproval = moderation.reviewsRequireApproval ||
        (imageUrls.isNotEmpty && moderation.imagesRequireApproval);
    await _client.from('tourism_place_reviews').upsert(
      {
        'place_id': placeId,
        'user_id': user.id,
        'rating': rating.clamp(1, 5),
        'reviewer_name': reviewer.name,
        'reviewer_avatar_url': reviewer.avatarUrl,
        'title': _emptyToNull(title),
        'body': _emptyToNull(body),
        'image_urls': imageUrls,
        'visit_date': visitDate?.toIso8601String(),
        'status': needsApproval ? 'pending' : 'approved',
      },
      onConflict: 'user_id,place_id',
    );
    return needsApproval ? 'pending' : 'approved';
  }

  Future<ReviewHelpfulState> toggleReviewHelpful(String reviewId) async {
    final response = await _client.rpc<dynamic>(
      'toggle_tourism_place_review_like',
      params: {'p_review_id': reviewId},
    );
    return ReviewHelpfulState.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> saveReviewReply({
    required String reviewId,
    required String placeId,
    required String body,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Login required to reply to reviews');
    }
    final replyBody = _emptyToNull(body);
    if (replyBody == null) {
      throw StateError('Reply cannot be empty');
    }
    final replier = await _reviewerSnapshot(user.id);
    await _client.from('tourism_place_review_replies').insert({
      'review_id': reviewId,
      'place_id': placeId,
      'user_id': user.id,
      'replier_name': replier.name,
      'replier_avatar_url': replier.avatarUrl,
      'body': replyBody,
      'status': 'approved',
    });
  }

  Future<String> uploadReviewImageBytes({
    required Uint8List bytes,
    required String extension,
    required String placeId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Login required to upload review images');
    }
    final normalizedExtension = extension.trim().isEmpty
        ? 'jpg'
        : extension.trim().toLowerCase().replaceAll('.', '');
    final allowedTypes = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    if (!allowedTypes.containsKey(normalizedExtension)) {
      throw StateError('Only JPG, PNG and WEBP review images are allowed.');
    }
    final safePlace = placeId.replaceAll(RegExp(r'[^a-zA-Z0-9-]+'), '-');
    final fileName =
        'reviews/${user.id}/$safePlace/${DateTime.now().microsecondsSinceEpoch}.$normalizedExtension';
    await _client.storage.from('user-media').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: allowedTypes[normalizedExtension]!,
          ),
        );
    return _client.storage.from('user-media').getPublicUrl(fileName);
  }

  Future<ReviewModerationConfig> getReviewModerationConfig() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', 'review_moderation')
          .maybeSingle();
      final value = row?['value'];
      if (value is Map) {
        return ReviewModerationConfig.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    } catch (_) {}
    return const ReviewModerationConfig();
  }

  Future<void> saveReviewModerationConfig(
    ReviewModerationConfig config,
  ) async {
    await _client.from('app_settings').upsert({
      'key': 'review_moderation',
      'value': config.toJson(),
    });
  }

  Future<void> updateReviewStatus({
    required String reviewId,
    required String status,
    String? adminNote,
  }) async {
    await _client.from('tourism_place_reviews').update({
      'status': status,
      'admin_note': _emptyToNull(adminNote),
      'reviewed_by': _client.auth.currentUser?.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', reviewId);
  }

  Future<void> updateReviewReply({
    required String reviewId,
    String? adminReply,
  }) async {
    final reply = _emptyToNull(adminReply);
    await _client.from('tourism_place_reviews').update({
      'admin_reply': reply,
      'admin_reply_by': reply == null ? null : _client.auth.currentUser?.id,
      'admin_reply_at': reply == null ? null : DateTime.now().toIso8601String(),
    }).eq('id', reviewId);
  }

  Future<List<TourismPlace>> getAdminPlaces({
    String search = '',
    String city = '',
    String state = '',
    String category = '',
    String group = 'all',
    int page = 0,
  }) async {
    try {
      final trimmed = search.trim().replaceAll(',', ' ');
      final cityFilter = city.trim();
      final stateFilter = state.trim();
      final categoryFilter = category.trim();

      const batchSize = 1000;
      final rows = <dynamic>[];
      for (var batch = 0; batch < 8; batch++) {
        final from = batch * batchSize;
        final to = from + batchSize - 1;
        final response = await _client
            .from('tourism_places')
            .select()
            .order('featured', ascending: false)
            .order('is_popular', ascending: false)
            .order('rating', ascending: false)
            .range(from, to);
        rows.addAll(response as List);
        if (response.length < batchSize) break;
      }

      var places = _placesFrom(rows, dedupe: false).where((place) {
        if (trimmed.isNotEmpty && !_matchesAdminPlaceSearch(place, trimmed)) {
          return false;
        }
        if (cityFilter.isNotEmpty &&
            !place.city.toLowerCase().contains(cityFilter.toLowerCase())) {
          return false;
        }
        if (stateFilter.isNotEmpty &&
            !place.state.toLowerCase().contains(stateFilter.toLowerCase())) {
          return false;
        }
        if (categoryFilter.isNotEmpty &&
            !place.category
                .toLowerCase()
                .contains(categoryFilter.toLowerCase())) {
          return false;
        }
        return switch (group) {
          'featured' => place.featured,
          'popular' => place.isPopular,
          'free' => place.entryFeeForeigner == 0,
          'hidden_gems' => place.isHiddenGem,
          'missing_photos' => place.images.isEmpty,
          'hidden' => place.isHidden,
          _ => true,
        };
      }).toList();

      places.sort((a, b) {
        if (a.isHidden != b.isHidden) return a.isHidden ? 1 : -1;
        if (a.featured != b.featured) return a.featured ? -1 : 1;
        if (a.isPopular != b.isPopular) return a.isPopular ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });

      final from = page * AppConstants.pageSize;
      places = places.skip(from).take(AppConstants.pageSize).toList();

      return places;
    } catch (e) {
      _debugLog('Admin places error: $e');
      return [];
    }
  }

  bool _matchesAdminPlaceSearch(TourismPlace place, String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    final haystack = [
      place.name,
      place.city,
      place.state,
      place.district ?? '',
      place.category,
      place.subcategory ?? '',
      place.description,
      place.address ?? '',
      place.bestSeason ?? '',
    ].join(' ').toLowerCase();
    return terms.every(haystack.contains);
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
    required bool isHidden,
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
      'is_hidden': isHidden,
      'likes_count': likesCount < 0 ? 0 : likesCount,
      'visit_duration_minutes': visitDurationMinutes,
      'address': _emptyToNull(address),
    };

    if (id == null || id.trim().isEmpty) {
      await _client.from('tourism_places').insert(data);
    } else {
      await _client.from('tourism_places').update(data).eq('place_id', id);
    }
    await _syncDuplicatePlaceImages(
      name: name,
      city: city,
      state: state,
      images: images,
    );
    await _logAdminActivity(
      entityType: 'tourism_place',
      entityId: id,
      action: id == null || id.trim().isEmpty
          ? 'created destination'
          : 'updated destination',
      afterData: {
        'name': name.trim(),
        'city': city.trim(),
        'is_hidden': isHidden,
      },
    );
  }

  Future<void> setAdminPlaceHidden({
    required String id,
    required bool hidden,
  }) async {
    await _client
        .from('tourism_places')
        .update({'is_hidden': hidden}).eq('place_id', id);
    await _logAdminActivity(
      entityType: 'tourism_place',
      entityId: id,
      action: hidden ? 'hid destination' : 'showed destination',
      afterData: {'is_hidden': hidden},
    );
  }

  Future<String> uploadAdminPlaceImageBytes({
    required Uint8List bytes,
    required String extension,
    String? placeName,
    String? imageType,
  }) async {
    final normalizedExtension = extension.trim().isEmpty
        ? 'jpg'
        : extension.trim().toLowerCase().replaceAll('.', '');
    final allowedTypes = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    if (!allowedTypes.containsKey(normalizedExtension)) {
      throw StateError(
          'Only JPG, PNG and WEBP destination images are allowed.');
    }
    final safeName = (placeName ?? 'destination')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final safeType = (imageType ?? 'gallery')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final fileName =
        'places/${safeName.isEmpty ? 'destination' : safeName}/${safeType.isEmpty ? 'gallery' : safeType}/${DateTime.now().microsecondsSinceEpoch}.$normalizedExtension';
    final contentType = allowedTypes[normalizedExtension]!;

    await _client.storage.from('tourism-media').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
          ),
        );

    return _client.storage.from('tourism-media').getPublicUrl(fileName);
  }

  Future<_ReviewerSnapshot> _reviewerSnapshot(String userId) async {
    try {
      final rows = await _client
          .from('profiles')
          .select('full_name, profile_image_url')
          .eq('user_id', userId)
          .limit(1);
      if (rows.isNotEmpty) {
        final profile = Map<String, dynamic>.from(rows.first as Map);
        final name = _emptyToNull(profile['full_name']?.toString());
        final avatar = _emptyToNull(profile['profile_image_url']?.toString());
        if (name != null || avatar != null) {
          return _ReviewerSnapshot(
            name: name ?? _fallbackReviewerName(),
            avatarUrl: avatar,
          );
        }
      }
    } catch (_) {
      // Reviews should still save if profile lookup is unavailable.
    }
    return _ReviewerSnapshot(name: _fallbackReviewerName());
  }

  String _fallbackReviewerName() {
    final email = _client.auth.currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'UniSafeX traveler';
  }

  Future<void> _syncDuplicatePlaceImages({
    required String name,
    required String city,
    required String state,
    required List<String> images,
  }) async {
    final cleanedImages =
        images.map((url) => url.trim()).where((url) => url.isNotEmpty).toList();
    if (cleanedImages.isEmpty) return;
    try {
      await _client
          .from('tourism_places')
          .update({'images': cleanedImages})
          .ilike('place_name', name.trim())
          .ilike('city', city.trim())
          .ilike('state', state.trim());
    } catch (error) {
      _debugLog('Duplicate place image sync skipped: $error');
    }
  }

  Future<void> _logAdminActivity({
    required String entityType,
    String? entityId,
    required String action,
    Map<String, dynamic>? afterData,
  }) async {
    try {
      await _client.from('tourism_content_audit_log').insert({
        'actor_user_id': _client.auth.currentUser?.id,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'after_data': afterData,
      });
    } catch (_) {
      // Admin audit logging should not block destination saves.
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
          .select()
          .eq('is_hidden', false);

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
      _debugLog(
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
          .eq('is_hidden', false)
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
      _debugLog(
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
          .eq('is_hidden', false)
          .single();

      return TourismPlace.fromJson(
        response,
      );
    } catch (e) {
      _debugLog(
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
          .eq('is_hidden', false)
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
      _debugLog(
        'All places error: $e',
      );
      return [];
    }
  }

  Future<List<TourismPlace>> getFullMapPlaces() async {
    try {
      const batchSize = 1000;
      final rows = <dynamic>[];
      for (var batch = 0; batch < 5; batch++) {
        final from = batch * batchSize;
        final to = from + batchSize - 1;
        final response = await _client
            .from('tourism_places')
            .select()
            .eq('is_hidden', false)
            .neq('latitude', 0)
            .neq('longitude', 0)
            .order('rating', ascending: false)
            .range(from, to);
        rows.addAll(response as List);
        if (response.length < batchSize) break;
      }
      return _placesFrom(rows);
    } catch (e) {
      _debugLog('Full map places error: $e');
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

final placeLikeStateProvider =
    FutureProvider.family<PlaceLikeState, String>((ref, placeId) {
  return ref.read(tourismRepositoryProvider).getPlaceLikeState(placeId);
});

final placeReviewsProvider =
    FutureProvider.family<List<PlaceReview>, String>((ref, placeId) {
  return ref.read(tourismRepositoryProvider).getApprovedReviews(placeId);
});

final placeReviewRepliesProvider =
    FutureProvider.family<Map<String, List<PlaceReviewReply>>, String>(
        (ref, placeId) {
  return ref.read(tourismRepositoryProvider).getApprovedReviewReplies(placeId);
});

final myPlaceReviewProvider =
    FutureProvider.family<PlaceReview?, String>((ref, placeId) {
  return ref.read(tourismRepositoryProvider).getMyReview(placeId);
});

final adminPlaceReviewsProvider =
    FutureProvider.family<List<PlaceReview>, String>((ref, status) {
  return ref.read(tourismRepositoryProvider).getAdminReviews(status: status);
});

final reviewModerationConfigProvider =
    FutureProvider<ReviewModerationConfig>((ref) {
  return ref.read(tourismRepositoryProvider).getReviewModerationConfig();
});

final fullMapPlacesProvider = FutureProvider<List<TourismPlace>>((ref) {
  return ref.read(tourismRepositoryProvider).getFullMapPlaces();
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
  final String city;
  final String state;
  final String category;
  final String group;
  final int page;

  const AdminTourismPlacesParams({
    this.search = '',
    this.city = '',
    this.state = '',
    this.category = '',
    this.group = 'all',
    this.page = 0,
  });

  @override
  bool operator ==(Object other) {
    return other is AdminTourismPlacesParams &&
        other.search == search &&
        other.city == city &&
        other.state == state &&
        other.category == category &&
        other.group == group &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(search, city, state, category, group, page);
}

final adminTourismPlacesProvider =
    FutureProvider.family<List<TourismPlace>, AdminTourismPlacesParams>(
  (ref, params) {
    return ref.read(tourismRepositoryProvider).getAdminPlaces(
          search: params.search,
          city: params.city,
          state: params.state,
          category: params.category,
          group: params.group,
          page: params.page,
        );
  },
);
