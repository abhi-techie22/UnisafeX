import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';

const _guideRequestsKey = 'guide_requests_v1';

class GuideRequestRepository {
  GuideRequestRepository(this._client);

  final SupabaseClient _client;

  Future<List<GuideRequest>> getMyRequests(String userId) async {
    final rows = await _client
        .from('guide_requests')
        .select()
        .eq('user_id', userId)
        .order('requested_at', ascending: false);
    return rows
        .map<GuideRequest>(
          (row) => GuideRequest.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<GuideRequest>> getAdminRequests() async {
    final rows = await _client
        .from('guide_requests')
        .select()
        .order('requested_at', ascending: false)
        .limit(100);
    return rows
        .map<GuideRequest>(
          (row) => GuideRequest.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<GuideRequest> createRequest({
    required String userId,
    required String? userEmail,
    required String placeId,
    required String placeName,
    required String city,
    required int travelers,
    required String contactNote,
  }) async {
    final draft = GuideRequest.create(
      placeId: placeId,
      placeName: placeName,
      city: city,
      travelers: travelers,
      contactNote: contactNote,
    );
    final row = await _client
        .from('guide_requests')
        .insert(draft.toInsertJson(userId: userId, userEmail: userEmail))
        .select()
        .single();
    return GuideRequest.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> updateStatus({
    required String requestId,
    required GuideRequestStatus status,
    String? adminNote,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'admin_note': _emptyToNull(adminNote),
    };
    await _client.from('guide_requests').update(data).eq('id', requestId);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class GuideRequestNotifier extends StateNotifier<List<GuideRequest>> {
  GuideRequestNotifier(this._ref, this._repository) : super(const []) {
    load();
  }

  final Ref _ref;
  final GuideRequestRepository _repository;

  Future<void> load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = const [];
      return;
    }

    try {
      final requests = await _repository.getMyRequests(user.id);
      state = requests;
      await _persist(requests);
    } catch (_) {
      state = await _loadLocal();
    }
  }

  Future<GuideRequest> createRequest({
    required String placeId,
    required String placeName,
    required String city,
    required int travelers,
    required String contactNote,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      throw const AuthException('Please sign in to request a guide.');
    }

    final request = await _repository.createRequest(
      userId: user.id,
      userEmail: user.email,
      placeId: placeId,
      placeName: placeName,
      city: city,
      travelers: travelers,
      contactNote: contactNote,
    );
    state = [request, ...state.where((item) => item.id != request.id)];
    await _persist(state);
    _ref.invalidate(adminGuideRequestsProvider);
    return request;
  }

  Future<void> removeLocal(String requestId) async {
    state = state.where((request) => request.id != requestId).toList();
    await _persist(state);
  }

  Future<List<GuideRequest>> _loadLocal() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getStringList(_guideRequestsKey) ?? const [];
    return encoded
        .map((value) => GuideRequest.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            ))
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  Future<void> _persist(List<GuideRequest> requests) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _guideRequestsKey,
      requests.map((request) => request.encode()).toList(),
    );
  }
}

final guideRequestRepositoryProvider = Provider(
  (ref) => GuideRequestRepository(ref.watch(supabaseClientProvider)),
);

final guideRequestsProvider =
    StateNotifierProvider<GuideRequestNotifier, List<GuideRequest>>(
  (ref) {
    ref.watch(currentUserProvider);
    return GuideRequestNotifier(ref, ref.watch(guideRequestRepositoryProvider));
  },
);

final adminGuideRequestsProvider = FutureProvider<List<GuideRequest>>(
  (ref) => ref.read(guideRequestRepositoryProvider).getAdminRequests(),
);
