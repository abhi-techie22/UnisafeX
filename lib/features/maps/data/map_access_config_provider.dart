import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';

class MapAccessConfig {
  const MapAccessConfig({
    this.inAppMapsEnabled = true,
    this.routeOverlayEnabled = true,
  });

  final bool inAppMapsEnabled;
  final bool routeOverlayEnabled;

  bool get fallbackOnly => !inAppMapsEnabled;

  MapAccessConfig copyWith({
    bool? inAppMapsEnabled,
    bool? routeOverlayEnabled,
  }) {
    return MapAccessConfig(
      inAppMapsEnabled: inAppMapsEnabled ?? this.inAppMapsEnabled,
      routeOverlayEnabled: routeOverlayEnabled ?? this.routeOverlayEnabled,
    );
  }

  factory MapAccessConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MapAccessConfig();
    return MapAccessConfig(
      inAppMapsEnabled: json['in_app_maps_enabled'] as bool? ?? true,
      routeOverlayEnabled: json['route_overlay_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'in_app_maps_enabled': inAppMapsEnabled,
      'route_overlay_enabled': routeOverlayEnabled,
    };
  }
}

class MapAccessConfigRepository {
  const MapAccessConfigRepository(this._client);

  static const settingsKey = 'maps_config';

  final SupabaseClient _client;

  Future<MapAccessConfig> fetch() async {
    try {
      final row = await _client
          .from('app_settings')
          .select('value')
          .eq('key', settingsKey)
          .maybeSingle();
      final value = row?['value'];
      if (value is Map) {
        return MapAccessConfig.fromJson(Map<String, dynamic>.from(value));
      }
    } catch (_) {
      // Keep maps working before the app_settings migration is applied.
    }
    return const MapAccessConfig();
  }

  Future<void> save(MapAccessConfig config) async {
    await _client.from('app_settings').upsert({
      'key': settingsKey,
      'value': config.toJson(),
    });
  }
}

final mapAccessConfigRepositoryProvider =
    Provider<MapAccessConfigRepository>((ref) {
  return MapAccessConfigRepository(ref.watch(supabaseClientProvider));
});

final mapAccessConfigProvider = FutureProvider<MapAccessConfig>((ref) {
  return ref.watch(mapAccessConfigRepositoryProvider).fetch();
});
