import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(currentSessionProvider)?.user;
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
  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _authSubscription;

  AuthNotifier(this._client)
      : super(AsyncValue.data(_client.auth.currentSession?.user)) {
    _authSubscription = _client.auth.onAuthStateChange.listen((authState) {
      state = AsyncValue.data(authState.session?.user);
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<User> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (response.session == null || user == null) {
        throw const AuthException('Sign in did not create a valid session.');
      }
      state = AsyncValue.data(user);
      return user;
    } on AuthException {
      state = const AsyncValue.data(null);
      rethrow;
    } catch (_) {
      state = const AsyncValue.data(null);
      throw const AuthException(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo:
            kIsWeb ? Uri.base.origin : AppConstants.authCallbackUrl,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthException('Account creation did not return a user.');
      }

      final hasSession = response.session != null;
      state = AsyncValue.data(hasSession ? user : null);
      return SignUpResult(user: user, requiresEmailConfirmation: !hasSession);
    } on AuthException {
      state = const AsyncValue.data(null);
      rethrow;
    } catch (_) {
      state = const AsyncValue.data(null);
      throw const AuthException(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException {
      rethrow;
    }
  }
}

class SignUpResult {
  final User user;
  final bool requiresEmailConfirmation;

  const SignUpResult({
    required this.user,
    required this.requiresEmailConfirmation,
  });
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider));
});
