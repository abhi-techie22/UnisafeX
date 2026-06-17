import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';

const _guideRequestsKey = 'guide_requests_v1';

class GuideRequestNotifier extends StateNotifier<List<GuideRequest>> {
  GuideRequestNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getStringList(_guideRequestsKey) ?? const [];
    state = encoded
        .map((value) => GuideRequest.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            ))
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  Future<GuideRequest> createRequest({
    required String placeId,
    required String placeName,
    required String city,
    required int travelers,
    required String contactNote,
  }) async {
    final request = GuideRequest.create(
      placeId: placeId,
      placeName: placeName,
      city: city,
      travelers: travelers,
      contactNote: contactNote,
    );
    state = [request, ...state];
    await _persist();
    return request;
  }

  Future<void> remove(String requestId) async {
    state = state.where((request) => request.id != requestId).toList();
    await _persist();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _guideRequestsKey,
      state.map((request) => request.encode()).toList(),
    );
  }
}

final guideRequestsProvider =
    StateNotifierProvider<GuideRequestNotifier, List<GuideRequest>>(
  (ref) => GuideRequestNotifier(),
);
