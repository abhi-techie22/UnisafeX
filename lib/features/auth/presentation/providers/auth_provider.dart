import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.isAnonymous;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final user = Supabase.instance.client.auth.currentUser;
    state = AsyncValue.data(user);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } on AuthException catch (e) {
      state = const AsyncValue.data(null);
      throw Exception(e.message);
    } catch (e) {
      state = const AsyncValue.data(null);
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } on AuthException catch (e) {
      state = const AsyncValue.data(null);
      throw Exception(e.message);
    } catch (e) {
      state = const AsyncValue.data(null);
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
