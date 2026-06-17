import 'dart:async';
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

  Future<void> updateGuideDetails({
    required String requestId,
    required String guideName,
    required String guidePhotoUrl,
    required String guidePhone,
    required String guideLanguages,
    required int? guideExperienceYears,
    required String guideBio,
    required double? guideChargeAmount,
    required String guideChargeCurrency,
    required String guideMeetingPoint,
    required String adminNote,
    bool confirmRequest = true,
  }) async {
    final data = <String, dynamic>{
      'guide_name': _emptyToNull(guideName),
      'guide_photo_url': _emptyToNull(guidePhotoUrl),
      'guide_phone': _emptyToNull(guidePhone),
      'guide_languages': _emptyToNull(guideLanguages),
      'guide_experience_years': guideExperienceYears,
      'guide_bio': _emptyToNull(guideBio),
      'guide_charge_amount': guideChargeAmount,
      'guide_charge_currency': _emptyToNull(guideChargeCurrency) ?? 'INR',
      'guide_meeting_point': _emptyToNull(guideMeetingPoint),
      'admin_note': _emptyToNull(adminNote),
    };
    if (confirmRequest) data['status'] = GuideRequestStatus.confirmed.name;
    await _client.from('guide_requests').update(data).eq('id', requestId);
  }

  Future<void> bookRequest(String requestId) async {
    await _client.rpc(
      'book_guide_request',
      params: {'p_request_id': requestId},
    );
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

class GuideRequestNotifier extends StateNotifier<List<GuideRequest>> {
  GuideRequestNotifier(this._ref, this._repository) : super(const []) {
    load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => load(silent: true),
    );
  }

  final Ref _ref;
  final GuideRequestRepository _repository;
  Timer? _refreshTimer;

  Future<void> load({bool silent = false}) async {
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
      if (!silent) state = await _loadLocal();
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

  Future<void> bookRequest(String requestId) async {
    await _repository.bookRequest(requestId);
    await load();
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
