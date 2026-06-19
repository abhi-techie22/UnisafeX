import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';

class FeatureFlags {
  const FeatureFlags(this.values);

  final Map<String, bool> values;

  bool enabled(String key, {bool fallback = false}) => values[key] ?? fallback;

  bool get hotels => enabled('feature_hotels_enabled');
  bool get flights => enabled('feature_flights_enabled');
  bool get aiAssistant =>
      enabled('feature_ai_assistant_enabled', fallback: true);
  bool get sos => enabled('feature_sos_enabled', fallback: true);
  bool get festivalCampaign =>
      enabled('feature_festival_campaign_enabled', fallback: true);
  bool get audioGuide => enabled('feature_audio_guide_enabled', fallback: true);
  bool get tripPlanner =>
      enabled('feature_trip_planner_enabled', fallback: true);
}

class AppFeatureFlag {
  const AppFeatureFlag({
    required this.key,
    required this.enabled,
    this.description,
  });

  final String key;
  final bool enabled;
  final String? description;

  factory AppFeatureFlag.fromJson(Map<String, dynamic> json) {
    return AppFeatureFlag(
      key: json['key'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }
}

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.actionLabel,
    this.actionRoute,
    required this.bannerType,
    this.city,
    this.state,
    required this.priority,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? actionLabel;
  final String? actionRoute;
  final String bannerType;
  final String? city;
  final String? state;
  final int priority;
  final bool isActive;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      actionLabel: json['action_label'] as String?,
      actionRoute: json['action_route'] as String?,
      bannerType: json['banner_type'] as String? ?? 'featured_city',
      city: json['city'] as String?,
      state: json['state'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 100,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class TravelAlert {
  const TravelAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.city,
    this.state,
    required this.isActive,
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final String? city;
  final String? state;
  final bool isActive;

  factory TravelAlert.fromJson(Map<String, dynamic> json) {
    return TravelAlert(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      city: json['city'] as String?,
      state: json['state'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.places,
    required this.banners,
    required this.alerts,
    required this.users,
  });

  final int places;
  final int banners;
  final int alerts;
  final int users;
}

class AdminRemoteConfigRepository {
  const AdminRemoteConfigRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppFeatureFlag>> getFeatureFlags() async {
    final rows = await _client
        .from('app_feature_flags')
        .select('key, enabled, description')
        .order('key');
    return rows.map(AppFeatureFlag.fromJson).toList();
  }

  Future<FeatureFlags> getPublicFeatureFlags() async {
    final flags = await getFeatureFlags();
    return FeatureFlags({for (final flag in flags) flag.key: flag.enabled});
  }

  Future<void> saveFeatureFlag(AppFeatureFlag flag) async {
    await _client.from('app_feature_flags').upsert({
      'key': flag.key,
      'enabled': flag.enabled,
      'description': flag.description,
      'updated_by': _client.auth.currentUser?.id,
    });
  }

  Future<List<HomeBanner>> getHomeBanners({bool admin = false}) async {
    dynamic query = _client.from('home_banners').select();
    if (!admin) query = query.eq('is_active', true);
    final rows = await query.order('priority').order('created_at');
    return rows.map(HomeBanner.fromJson).toList();
  }

  Future<void> saveHomeBanner({
    String? id,
    required String title,
    String? subtitle,
    String? imageUrl,
    String? actionLabel,
    String? actionRoute,
    required String bannerType,
    String? city,
    String? state,
    required int priority,
    required bool isActive,
  }) async {
    final data = {
      'title': title.trim(),
      'subtitle': _emptyToNull(subtitle),
      'image_url': _emptyToNull(imageUrl),
      'action_label': _emptyToNull(actionLabel),
      'action_route': _emptyToNull(actionRoute),
      'banner_type': bannerType,
      'city': _emptyToNull(city),
      'state': _emptyToNull(state),
      'priority': priority,
      'is_active': isActive,
      'updated_by': _client.auth.currentUser?.id,
      if (id == null) 'created_by': _client.auth.currentUser?.id,
    };
    if (id == null || id.isEmpty) {
      await _client.from('home_banners').insert(data);
    } else {
      await _client.from('home_banners').update(data).eq('id', id);
    }
  }

  Future<List<TravelAlert>> getTravelAlerts({bool admin = false}) async {
    dynamic query = _client.from('travel_alerts').select();
    if (!admin) query = query.eq('is_active', true);
    final rows = await query.order('created_at', ascending: false);
    return rows.map(TravelAlert.fromJson).toList();
  }

  Future<void> saveTravelAlert({
    String? id,
    required String title,
    required String message,
    required String severity,
    String? city,
    String? state,
    required bool isActive,
  }) async {
    final data = {
      'title': title.trim(),
      'message': message.trim(),
      'severity': severity,
      'city': _emptyToNull(city),
      'state': _emptyToNull(state),
      'is_active': isActive,
      'updated_by': _client.auth.currentUser?.id,
      if (id == null) 'created_by': _client.auth.currentUser?.id,
    };
    if (id == null || id.isEmpty) {
      await _client.from('travel_alerts').insert(data);
    } else {
      await _client.from('travel_alerts').update(data).eq('id', id);
    }
  }

  Future<List<UserProfile>> getProfiles() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return rows.map(UserProfile.fromJson).toList();
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    final places = await _count('tourism_places');
    final banners = await _count('home_banners');
    final alerts = await _count('travel_alerts');
    final users = await _count('profiles');
    return AdminDashboardStats(
      places: places,
      banners: banners,
      alerts: alerts,
      users: users,
    );
  }

  Future<int> _count(String table) async {
    try {
      return await _client.from(table).count(CountOption.exact);
    } catch (_) {
      return 0;
    }
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final adminRemoteConfigRepositoryProvider =
    Provider<AdminRemoteConfigRepository>((ref) {
  return AdminRemoteConfigRepository(ref.watch(supabaseClientProvider));
});

final publicFeatureFlagsProvider = FutureProvider<FeatureFlags>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getPublicFeatureFlags();
});

final adminFeatureFlagsProvider = FutureProvider<List<AppFeatureFlag>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getFeatureFlags();
});

final activeHomeBannersProvider = FutureProvider<List<HomeBanner>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getHomeBanners();
});

final adminHomeBannersProvider = FutureProvider<List<HomeBanner>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getHomeBanners(
        admin: true,
      );
});

final activeTravelAlertsProvider = FutureProvider<List<TravelAlert>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getTravelAlerts();
});

final adminTravelAlertsProvider = FutureProvider<List<TravelAlert>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getTravelAlerts(
        admin: true,
      );
});

final adminProfilesProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getProfiles();
});

final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getDashboardStats();
});
