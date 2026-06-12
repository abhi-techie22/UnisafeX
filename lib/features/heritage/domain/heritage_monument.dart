class HeritageMonument {
  const HeritageMonument({
    required this.id,
    required this.name,
    required this.state,
    required this.isActive,
    this.sourceId,
    this.locality,
    this.district,
    this.region,
    this.asiCircle,
    this.monumentType,
    this.protectionStatus,
    this.visitorCategory,
    this.description,
    this.rating,
    this.featured = false,
  });

  final int id;
  final int? sourceId;
  final String name;
  final String state;
  final String? locality;
  final String? district;
  final String? region;
  final String? asiCircle;
  final String? monumentType;
  final String? protectionStatus;
  final String? visitorCategory;
  final String? description;
  final double? rating;
  final bool featured;
  final bool isActive;

  factory HeritageMonument.fromJson(Map<String, dynamic> json) {
    return HeritageMonument(
      id: (json['id'] as num).toInt(),
      sourceId: (json['source_id'] as num?)?.toInt(),
      name: json['monument_name'] as String? ?? 'Unknown monument',
      state: json['state_ut'] as String? ?? '',
      locality: json['locality'] as String?,
      district: json['district'] as String?,
      region: json['region'] as String?,
      asiCircle: json['asi_circle'] as String?,
      monumentType: json['monument_type'] as String?,
      protectionStatus: json['protection_status'] as String?,
      visitorCategory: json['visitor_category'] as String?,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      featured: json['featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class MonumentVisitorStat {
  const MonumentVisitorStat({
    required this.monumentName,
    required this.foreignVisitors,
    required this.fiscalYear,
    this.state,
  });

  final String monumentName;
  final int foreignVisitors;
  final String fiscalYear;
  final String? state;

  factory MonumentVisitorStat.fromJson(Map<String, dynamic> json) {
    return MonumentVisitorStat(
      monumentName: json['monument_name'] as String? ?? '',
      foreignVisitors: (json['foreign_visitors'] as num?)?.toInt() ?? 0,
      fiscalYear: json['fiscal_year'] as String? ?? '',
      state: json['state_ut'] as String?,
    );
  }
}
