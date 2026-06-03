import 'package:equatable/equatable.dart';

class TourismPlace extends Equatable {
  final String id;
  final String name;
  final String description;
  final String state;
  final String district;
  final String city;
  final String category;
  final String? subcategory;
  final double latitude;
  final double longitude;
  final List<String> images;
  final double? entryFeeIndian;
  final double? entryFeeForeigner;
  final String? timings;
  final String? bestSeason;
  final List<String> bestMonths;
  final List<String> safetyGuidelines;
  final List<String> touristTips;
  final int tier;
  final bool featured;
  final double rating;
  final bool isPopular;
  final int? visitDurationMinutes;
  final String? address;

  const TourismPlace({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
    required this.district,
    required this.city,
    required this.category,
    this.subcategory,
    required this.latitude,
    required this.longitude,
    this.images = const [],
    this.entryFeeIndian,
    this.entryFeeForeigner,
    this.timings,
    this.bestSeason,
    this.bestMonths = const [],
    this.safetyGuidelines = const [],
    this.touristTips = const [],
    this.tier = 2,
    this.featured = false,
    this.rating = 0.0,
    this.isPopular = false,
    this.visitDurationMinutes,
    this.address,
  });

  factory TourismPlace.fromJson(Map<String, dynamic> json) {
    return TourismPlace(
      id: json['place_id'] as String,
      name: json['place_name'] as String,
      description: json['description'] as String? ?? '',
      state: json['state'] as String? ?? '',
      district: json['district'] as String? ?? '',
      city: json['city'] as String? ?? '',
      category: json['category'] as String? ?? 'Historical',
      subcategory: json['subcategory'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      entryFeeIndian: (json['entry_fee_indian'] as num?)?.toDouble(),
      entryFeeForeigner: (json['entry_fee_foreigner'] as num?)?.toDouble(),
      timings: json['timings'] as String?,
      bestSeason: json['best_season'] as String?,
      bestMonths: (json['best_months'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      safetyGuidelines: (json['safety_guidelines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      touristTips: (json['tourist_tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tier: json['tier'] as int? ?? 2,
      featured: json['featured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isPopular: json['is_popular'] as bool? ?? false,
      visitDurationMinutes: json['visit_duration_minutes'] as int?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': id,
      'place_name': name,
      'description': description,
      'state': state,
      'district': district,
      'city': city,
      'category': category,
      'subcategory': subcategory,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'entry_fee_indian': entryFeeIndian,
      'entry_fee_foreigner': entryFeeForeigner,
      'timings': timings,
      'best_season': bestSeason,
      'best_months': bestMonths,
      'safety_guidelines': safetyGuidelines,
      'tourist_tips': touristTips,
      'tier': tier,
      'featured': featured,
      'rating': rating,
      'is_popular': isPopular,
      'visit_duration_minutes': visitDurationMinutes,
      'address': address,
    };
  }

  String get primaryImage => images.isNotEmpty
      ? images.first
      : 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800';

  String get formattedEntryFee {
    if (entryFeeForeigner == null || entryFeeForeigner == 0) return 'Free';
    return '₹${entryFeeForeigner!.toInt()} for foreigners';
  }

  bool get isFree => entryFeeForeigner == null || entryFeeForeigner == 0;

  @override
  List<Object?> get props => [id];
}
