import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _savedPlacesKey = 'tourism_saved_place_ids';

class SavedPlacesNotifier extends StateNotifier<Set<String>> {
  SavedPlacesNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getStringList(_savedPlacesKey)?.toSet() ?? <String>{};
  }

  Future<void> toggle(String placeId) async {
    final updated = {...state};
    updated.contains(placeId) ? updated.remove(placeId) : updated.add(placeId);
    state = updated;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_savedPlacesKey, updated.toList());
  }

  bool contains(String placeId) => state.contains(placeId);
}

final savedPlacesProvider =
    StateNotifierProvider<SavedPlacesNotifier, Set<String>>(
  (ref) => SavedPlacesNotifier(),
);
