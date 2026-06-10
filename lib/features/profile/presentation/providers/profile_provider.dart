import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<UserProfile?> getProfile(String userId) async {
    _requireMatchingAuthenticatedUser(userId);
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    _requireMatchingAuthenticatedUser(profile.userId);
    final data = profile.toJson();

    final updated = await _client
        .from('profiles')
        .update(data)
        .eq('user_id', profile.userId)
        .select()
        .maybeSingle();

    if (updated != null) {
      return UserProfile.fromJson(updated);
    }

    final inserted =
        await _client.from('profiles').insert(data).select().single();

    return UserProfile.fromJson(inserted);
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    _requireMatchingAuthenticatedUser(userId);
    final ext = imageFile.path.split('.').last;
    final fileName = 'profiles/$userId/avatar.$ext';

    await _client.storage.from('user-media').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('user-media').getPublicUrl(fileName);
  }

  void _requireMatchingAuthenticatedUser(String userId) {
    final sessionUser = _client.auth.currentSession?.user;
    if (sessionUser == null) {
      throw const AuthException(
        'You must be signed in before accessing a profile.',
      );
    }
    if (userId.isEmpty || sessionUser.id != userId) {
      throw const AuthException(
        'The profile user does not match the authenticated user.',
      );
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).getProfile(user.id);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _repo;
  final String? _userId;

  ProfileNotifier(this._repo, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId == null) {
      state = const AsyncValue.data(null);
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final userId = _userId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final profile = await _repo.getProfile(userId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    if (_userId == null) {
      throw const AuthException(
        'You must confirm your email and sign in before saving your profile.',
      );
    }
    if (profile.userId != _userId) {
      throw const AuthException(
        'The profile user does not match the authenticated user.',
      );
    }
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
    final userId = _userId;
    if (userId == null) {
      throw const AuthException(
        'You must be signed in before uploading a profile image.',
      );
    }
    final current = state.value;
    if (current == null) return;

    final url = await _repo.uploadProfileImage(userId, imageFile);
    final updated = current.copyWith(profileImageUrl: url);
    final saved = await _repo.upsertProfile(updated);
    state = AsyncValue.data(saved);
  }

  Future<void> refresh() => _loadProfile();
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final user = ref.watch(currentUserProvider);
  final repo = ref.read(profileRepositoryProvider);
  return ProfileNotifier(repo, user?.id);
});
