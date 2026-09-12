import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

class Favorite {
  final String id;
  final String userId;
  final String placeId;
  final String status;
  final String? notes;
  final DateTime? plannedVisitDate;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.status,
    this.notes,
    this.plannedVisitDate,
    this.completedAt,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      status: json['status']?.toString() ?? 'saved',
      notes: json['notes']?.toString(),
      plannedVisitDate: json['planned_visit_date'] == null
          ? null
          : DateTime.tryParse(json['planned_visit_date'].toString()),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.tryParse(json['completed_at'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isCompleted => status == 'completed' || completedAt != null;
}

class FavoritesRepository {
  final SupabaseClient _client;

  FavoritesRepository(this._client);

  Future<List<Favorite>> getFavorites(String userId) async {
    final response = await _client
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Favorite.fromJson(e)).toList();
  }

  Future<List<TourismPlace>> getFavoritePlaces(String userId) async {
    final response = await _client
        .from('favorites')
        .select('tourism_places(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => e['tourism_places'])
        .whereType<Map>()
        .map((row) => TourismPlace.fromJson(Map<String, dynamic>.from(row)))
        .where((place) => !place.isHidden)
        .toList();
  }

  Future<void> addFavorite(String userId, String placeId) async {
    await _client.from('favorites').upsert(
      {
        'user_id': userId,
        'place_id': placeId,
        'status': 'saved',
      },
      onConflict: 'user_id,place_id',
    );
  }

  Future<void> updateBucketStatus({
    required String userId,
    required String placeId,
    required bool completed,
  }) async {
    await _client.from('favorites').upsert(
      {
        'user_id': userId,
        'place_id': placeId,
        'status': completed ? 'completed' : 'saved',
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      },
      onConflict: 'user_id,place_id',
    );
  }

  Future<void> updateBucketNotes({
    required String userId,
    required String placeId,
    String? notes,
    DateTime? plannedVisitDate,
  }) async {
    await _client.from('favorites').upsert(
      {
        'user_id': userId,
        'place_id': placeId,
        'status': 'planned',
        'notes': _emptyToNull(notes),
        'planned_visit_date': plannedVisitDate?.toIso8601String(),
      },
      onConflict: 'user_id,place_id',
    );
  }

  Future<void> removeFavorite(String userId, String placeId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('place_id', placeId);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(supabaseClientProvider));
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Favorite>>> {
  final FavoritesRepository _repo;
  final String? _userId; // ✅ nullable now

  FavoritesNotifier(this._repo, this._userId)
      : super(const AsyncValue.data([])) {
    final userId = _userId;
    if (userId != null && userId.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final favs = await _repo.getFavorites(userId);
      state = AsyncValue.data(favs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFavorite(String placeId) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _repo.addFavorite(userId, placeId);
      await _load();
    } catch (_) {}
  }

  Future<void> removeFavorite(String placeId) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _repo.removeFavorite(userId, placeId);
      final current = state.value ?? [];
      state =
          AsyncValue.data(current.where((f) => f.placeId != placeId).toList());
    } catch (_) {}
  }

  Future<void> setCompleted(String placeId, bool completed) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _repo.updateBucketStatus(
        userId: userId,
        placeId: placeId,
        completed: completed,
      );
      await _load();
    } catch (_) {}
  }

  Future<void> saveBucketNotes({
    required String placeId,
    String? notes,
    DateTime? plannedVisitDate,
  }) async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) return;
    try {
      await _repo.updateBucketNotes(
        userId: userId,
        placeId: placeId,
        notes: notes,
        plannedVisitDate: plannedVisitDate,
      );
      await _load();
    } catch (_) {}
  }

  Future<void> refresh() => _load();
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Favorite>>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(favoritesRepositoryProvider);
  return FavoritesNotifier(repo, user?.id);
});

final favoritePlacesProvider = FutureProvider<List<TourismPlace>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(favoritesRepositoryProvider).getFavoritePlaces(user.id);
});
