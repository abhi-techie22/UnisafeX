import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/heritage/domain/heritage_monument.dart';

class HeritageQuery {
  const HeritageQuery({
    this.search = '',
    this.state,
    this.region,
    this.district,
    this.type,
    this.protectionStatus,
    this.freeOnly = false,
    this.featuredOnly = false,
    this.page = 0,
    this.includeInactive = false,
  });

  final String search;
  final String? state;
  final String? region;
  final String? district;
  final String? type;
  final String? protectionStatus;
  final bool freeOnly;
  final bool featuredOnly;
  final int page;
  final bool includeInactive;

  @override
  bool operator ==(Object other) =>
      other is HeritageQuery &&
      search == other.search &&
      state == other.state &&
      region == other.region &&
      district == other.district &&
      type == other.type &&
      protectionStatus == other.protectionStatus &&
      freeOnly == other.freeOnly &&
      featuredOnly == other.featuredOnly &&
      page == other.page &&
      includeInactive == other.includeInactive;

  @override
  int get hashCode => Object.hash(
        search,
        state,
        region,
        district,
        type,
        protectionStatus,
        freeOnly,
        featuredOnly,
        page,
        includeInactive,
      );
}

class HeritageRepository {
  HeritageRepository(this._client);

  static const pageSize = 30;
  final SupabaseClient _client;

  Future<List<HeritageMonument>> getMonuments(HeritageQuery filters) async {
    var query = _client.from('heritage_monuments').select();
    if (!filters.includeInactive) query = query.eq('is_active', true);
    if (filters.search.trim().isNotEmpty) {
      final value = filters.search.trim().replaceAll(',', ' ');
      query = query.or(
        'monument_name.ilike.%$value%,locality.ilike.%$value%,'
        'district.ilike.%$value%,state_ut.ilike.%$value%',
      );
    }
    if (filters.state?.isNotEmpty == true) {
      query = query.eq('state_ut', filters.state!);
    }
    if (filters.region?.isNotEmpty == true) {
      query = query.eq('region', filters.region!);
    }
    if (filters.district?.isNotEmpty == true) {
      query = query.ilike('district', '%${filters.district!.trim()}%');
    }
    if (filters.type?.isNotEmpty == true) {
      query = query.eq('monument_type', filters.type!);
    }
    if (filters.protectionStatus?.isNotEmpty == true) {
      query = query.eq('protection_status', filters.protectionStatus!);
    }
    if (filters.freeOnly) {
      query = query.ilike('visitor_category', '%Free Entry%');
    }
    if (filters.featuredOnly) {
      query = query.eq('featured', true);
    }
    final from = filters.page * pageSize;
    final rows = await query
        .order('featured', ascending: false)
        .order('monument_name')
        .range(from, from + pageSize - 1);
    return rows.map(HeritageMonument.fromJson).toList();
  }

  Future<Map<String, List<String>>> getFilterOptions() async {
    final rows = await _client
        .from('heritage_monuments')
        .select('state_ut, region, monument_type, protection_status')
        .eq('is_active', true)
        .limit(4000);
    final states = <String>{};
    final regions = <String>{};
    final types = <String>{};
    final protectionStatuses = <String>{};
    for (final row in rows) {
      final state = row['state_ut'] as String?;
      final region = row['region'] as String?;
      final type = row['monument_type'] as String?;
      final protectionStatus = row['protection_status'] as String?;
      if (state?.isNotEmpty == true) states.add(state!);
      if (region?.isNotEmpty == true) regions.add(region!);
      if (type?.isNotEmpty == true) types.add(type!);
      if (protectionStatus?.isNotEmpty == true) {
        protectionStatuses.add(protectionStatus!);
      }
    }
    return {
      'states': states.toList()..sort(),
      'regions': regions.toList()..sort(),
      'types': types.toList()..sort(),
      'protectionStatuses': protectionStatuses.toList()..sort(),
    };
  }

  Future<List<MonumentVisitorStat>> getForeignVisitorInsights() async {
    final rows = await _client
        .from('monument_visitor_stats')
        .select('monument_name, state_ut, fiscal_year, foreign_visitors')
        .not('foreign_visitors', 'is', null)
        .order('foreign_visitors', ascending: false)
        .limit(5);
    return rows.map(MonumentVisitorStat.fromJson).toList();
  }

  Future<bool> isAdmin() async {
    final value = await _client.rpc('is_unisafex_admin');
    return value == true;
  }

  Future<void> saveMonument({
    int? id,
    required String name,
    required String state,
    String? locality,
    String? district,
    String? type,
    String? description,
    String? imageUrl,
    String? timings,
    double? entryFeeIndian,
    double? entryFeeForeigner,
    double? rating,
    bool featured = false,
    bool isActive = true,
  }) async {
    final data = {
      'monument_name': name.trim(),
      'state_ut': state.trim(),
      'locality': _emptyToNull(locality),
      'district': _emptyToNull(district),
      'monument_type': _emptyToNull(type),
      'description': _emptyToNull(description),
      'image_url': _emptyToNull(imageUrl),
      'timings': _emptyToNull(timings),
      'entry_fee_indian': entryFeeIndian,
      'entry_fee_foreigner': entryFeeForeigner,
      'rating': rating,
      'featured': featured,
      'is_active': isActive,
    };
    if (id == null) {
      await _client.from('heritage_monuments').insert(data);
    } else {
      await _client.from('heritage_monuments').update(data).eq('id', id);
    }
  }

  String? _emptyToNull(String? value) =>
      value?.trim().isEmpty == true ? null : value?.trim();
}

final heritageRepositoryProvider = Provider(
  (ref) => HeritageRepository(ref.watch(supabaseClientProvider)),
);

final isAdminProvider = FutureProvider<bool>(
  (ref) async {
    ref.watch(currentUserProvider);
    if (ref.read(currentUserProvider) == null) return false;
    return ref.read(heritageRepositoryProvider).isAdmin();
  },
);

final heritageFilterOptionsProvider = FutureProvider(
  (ref) => ref.read(heritageRepositoryProvider).getFilterOptions(),
);

final foreignVisitorInsightsProvider = FutureProvider(
  (ref) => ref.read(heritageRepositoryProvider).getForeignVisitorInsights(),
);

final heritageMonumentsProvider =
    FutureProvider.family<List<HeritageMonument>, HeritageQuery>(
  (ref, query) => ref.read(heritageRepositoryProvider).getMonuments(query),
);
