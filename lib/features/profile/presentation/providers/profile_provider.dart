import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final data = {
      ...profile.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('profiles')
        .upsert(data, onConflict: 'user_id')
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last;
      final fileName = 'profiles/$userId/avatar.$ext';

      await _client.storage
          .from('user-media')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage
          .from('user-media')
          .getPublicUrl(fileName);

      return url;
    } catch (_) {
      return null;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).getProfile(user.id);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repo;
  final String _userId;

  ProfileNotifier(this._repo, this._userId) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _repo.getProfile(_userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repo.upsertProfile(profile);
      state = AsyncValue.data(saved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> uploadImage(File imageFile) async {
    final current = state.value;
    if (current == null) return;

    try {
      final url = await _repo.uploadProfileImage(_userId, imageFile);
      if (url != null) {
        final updated = current.copyWith(profileImageUrl: url);
        final saved = await _repo.upsertProfile(updated);
        state = AsyncValue.data(saved);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() => _loadProfile();
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(profileRepositoryProvider);
  return ProfileNotifier(repo, user?.id ?? '');
});
