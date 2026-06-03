import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

class Favorite {
  final String id;
  final String userId;
  final String placeId;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      placeId: json['place_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
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
        .map((e) => TourismPlace.fromJson(e['tourism_places']))
        .toList();
  }

  Future<void> addFavorite(String userId, String placeId) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'place_id': placeId,
    });
  }

  Future<void> removeFavorite(String userId, String placeId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('place_id', placeId);
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(Supabase.instance.client);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Favorite>>> {
  final FavoritesRepository _repo;
  final String? _userId; // ✅ nullable now

  FavoritesNotifier(this._repo, this._userId)
      : super(const AsyncValue.data([])) { // ✅ default to empty, not loading
    if (_userId != null && _userId!.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_userId == null || _userId!.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      state = const AsyncValue.loading();
      final favs = await _repo.getFavorites(_userId!);
      state = AsyncValue.data(favs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFavorite(String placeId) async {
    if (_userId == null || _userId!.isEmpty) return; // ✅ guard
    try {
      await _repo.addFavorite(_userId!, placeId);
      await _load();
    } catch (_) {}
  }

  Future<void> removeFavorite(String placeId) async {
    if (_userId == null || _userId!.isEmpty) return; // ✅ guard
    try {
      await _repo.removeFavorite(_userId!, placeId);
      final current = state.value ?? [];
      state = AsyncValue.data(
          current.where((f) => f.placeId != placeId).toList());
    } catch (_) {}
  }

  Future<void> refresh() => _load();
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Favorite>>>(
        (ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(favoritesRepositoryProvider);
  // ✅ pass null instead of empty string when guest
  return FavoritesNotifier(repo, user?.id);
});

final favoritePlacesProvider = FutureProvider<List<TourismPlace>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return []; // ✅ already correct
  return ref.read(favoritesRepositoryProvider).getFavoritePlaces(user.id);
});