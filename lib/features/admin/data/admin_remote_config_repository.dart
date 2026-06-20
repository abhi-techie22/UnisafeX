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

class AdminTeamMember {
  const AdminTeamMember({
    required this.userId,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String email;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminTeamMember.fromJson(Map<String, dynamic> json) {
    return AdminTeamMember(
      userId: json['user_id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'admin',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class AdminActivityLog {
  const AdminActivityLog({
    required this.id,
    this.actorUserId,
    required this.entityType,
    this.entityId,
    required this.action,
    this.afterData,
    this.createdAt,
  });

  final String id;
  final String? actorUserId;
  final String entityType;
  final String? entityId;
  final String action;
  final Map<String, dynamic>? afterData;
  final DateTime? createdAt;

  String get title =>
      afterData?['title']?.toString() ??
      afterData?['name']?.toString() ??
      afterData?['email']?.toString() ??
      entityType;

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id']?.toString() ?? '',
      actorUserId: json['actor_user_id']?.toString(),
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id']?.toString(),
      action: json['action'] as String? ?? '',
      afterData: json['after_data'] is Map
          ? Map<String, dynamic>.from(json['after_data'] as Map)
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    this.userId,
    this.userEmail,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.status,
    this.adminResponse,
    this.assignedTo,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  final String id;
  final String? userId;
  final String? userEmail;
  final String title;
  final String message;
  final String category;
  final String priority;
  final String status;
  final String? adminResponse;
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userEmail: json['user_email'] as String?,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'open',
      adminResponse: json['admin_response'] as String?,
      assignedTo: json['assigned_to']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
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
    return _rows(rows).map(AppFeatureFlag.fromJson).toList();
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
    await logActivity(
      entityType: 'feature_flag',
      entityId: flag.key,
      action: 'updated feature flag',
      afterData: {'title': flag.key, 'enabled': flag.enabled},
    );
  }

  Future<List<HomeBanner>> getHomeBanners({bool admin = false}) async {
    dynamic query = _client.from('home_banners').select();
    if (!admin) query = query.eq('is_active', true);
    final rows = await query.order('priority').order('created_at');
    return _rows(rows).map(HomeBanner.fromJson).toList();
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
    await logActivity(
      entityType: 'home_banner',
      entityId: id,
      action: id == null || id.isEmpty ? 'created banner' : 'updated banner',
      afterData: {'title': title.trim(), 'type': bannerType},
    );
  }

  Future<void> deleteHomeBanner(String id) async {
    if (id.trim().isEmpty) return;
    await _client.from('home_banners').delete().eq('id', id);
    await logActivity(
      entityType: 'home_banner',
      entityId: id,
      action: 'deleted banner',
    );
  }

  Future<List<TravelAlert>> getTravelAlerts({bool admin = false}) async {
    dynamic query = _client.from('travel_alerts').select();
    if (!admin) query = query.eq('is_active', true);
    final rows = await query.order('created_at', ascending: false);
    return _rows(rows).map(TravelAlert.fromJson).toList();
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
    await logActivity(
      entityType: 'travel_alert',
      entityId: id,
      action: id == null || id.isEmpty ? 'created alert' : 'updated alert',
      afterData: {'title': title.trim(), 'severity': severity},
    );
  }

  Future<void> deleteTravelAlert(String id) async {
    if (id.trim().isEmpty) return;
    await _client.from('travel_alerts').delete().eq('id', id);
    await logActivity(
      entityType: 'travel_alert',
      entityId: id,
      action: 'deleted alert',
    );
  }

  Future<List<UserProfile>> getProfiles() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    return _rows(rows).map(UserProfile.fromJson).toList();
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

  Future<List<AdminTeamMember>> getTeamMembers() async {
    final rows =
        await _client.from('admin_users').select().order('role').order('email');
    return _rows(rows).map(AdminTeamMember.fromJson).toList();
  }

  Future<void> addTeamMember({
    required String email,
    required String role,
  }) async {
    await _client.rpc(
      'add_admin_by_email',
      params: {'p_email': email.trim().toLowerCase(), 'p_role': role},
    );
    await logActivity(
      entityType: 'admin_user',
      entityId: email.trim().toLowerCase(),
      action: 'added team member',
      afterData: {'email': email.trim().toLowerCase(), 'role': role},
    );
  }

  Future<void> updateTeamMember(AdminTeamMember member) async {
    await _client.from('admin_users').update({
      'role': member.role,
      'is_active': member.isActive,
    }).eq('user_id', member.userId);
    await logActivity(
      entityType: 'admin_user',
      entityId: member.userId,
      action: member.isActive ? 'updated team member' : 'deactivated member',
      afterData: {'email': member.email, 'role': member.role},
    );
  }

  Future<List<AdminActivityLog>> getActivityLog() async {
    final rows = await _client
        .from('tourism_content_audit_log')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return _rows(rows).map(AdminActivityLog.fromJson).toList();
  }

  Future<void> logActivity({
    required String entityType,
    String? entityId,
    required String action,
    Map<String, dynamic>? afterData,
  }) async {
    try {
      await _client.from('tourism_content_audit_log').insert({
        'actor_user_id': _client.auth.currentUser?.id,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'after_data': afterData,
      });
    } catch (_) {
      // Activity should never block the primary admin action.
    }
  }

  Future<List<SupportTicket>> getSupportTickets({bool admin = false}) async {
    dynamic query = _client.from('support_tickets').select();
    if (!admin) {
      query = query.eq('user_id', _client.auth.currentUser?.id ?? '');
    }
    final rows = await query.order('updated_at', ascending: false).limit(200);
    return _rows(rows).map(SupportTicket.fromJson).toList();
  }

  Future<void> createSupportTicket({
    required String title,
    required String message,
    required String category,
    required String priority,
  }) async {
    final user = _client.auth.currentUser;
    await _client.from('support_tickets').insert({
      'user_id': user?.id,
      'user_email': user?.email,
      'title': title.trim(),
      'message': message.trim(),
      'category': category,
      'priority': priority,
    });
  }

  Future<void> updateSupportTicket({
    required String id,
    required String status,
    String? adminResponse,
    String? assignedTo,
  }) async {
    await _client.from('support_tickets').update({
      'status': status,
      'admin_response': _emptyToNull(adminResponse),
      'assigned_to': _emptyToNull(assignedTo),
      'updated_by': _client.auth.currentUser?.id,
      if (status == 'resolved' || status == 'closed')
        'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    await logActivity(
      entityType: 'support_ticket',
      entityId: id,
      action: 'updated support ticket',
      afterData: {'title': id, 'status': status},
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

  List<Map<String, dynamic>> _rows(Object? rows) {
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
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

final adminTeamMembersProvider = FutureProvider<List<AdminTeamMember>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getTeamMembers();
});

final adminActivityLogProvider = FutureProvider<List<AdminActivityLog>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getActivityLog();
});

final adminSupportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getSupportTickets(
        admin: true,
      );
});

final mySupportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.watch(adminRemoteConfigRepositoryProvider).getSupportTickets();
});
