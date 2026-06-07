class TourismPlace {
  final String id;
  final String name;
  final String state;
  final String city;
  final String category;
  final String? subcategory;
  final String? district;
  final String description;

  final double latitude;
  final double longitude;
  final double rating;

  final List<String> images;
  final String primaryImage;

  final bool featured;
  final bool isPopular;
  final bool isFree;

  final int tier;

  final double entryFeeForeigner;
  final double entryFeeIndian;

  final String? timings;
  final String? bestSeason;
  final List<String> bestMonths;

  final List<String> safetyGuidelines;
  final List<String> touristTips;

  final int? visitDurationMinutes;
  final String? address;

  const TourismPlace({
    required this.id,
    required this.name,
    required this.state,
    required this.city,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.images,
    required this.primaryImage,
    required this.featured,
    required this.isPopular,
    required this.isFree,
    required this.tier,
    required this.entryFeeForeigner,
    required this.entryFeeIndian,
    this.timings,
    this.bestSeason,
    required this.bestMonths,
    required this.safetyGuidelines,
    required this.touristTips,
    this.visitDurationMinutes,
    this.address,
    this.subcategory,
    this.district,
  });

  factory TourismPlace.fromJson(
    Map<String, dynamic> json,
  ) {
    final imageList =
        (json['images'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    final foreignerFee =
        ((json['entry_fee_foreigner'] ??
                    0)
                as num)
            .toDouble();

    final indianFee =
        ((json['entry_fee_indian'] ??
                    0)
                as num)
            .toDouble();

    return TourismPlace(
      id:
          json['place_id']
                  ?.toString() ??
              '',

      name:
          json['place_name'] ??
              'Unknown Place',

      state:
          json['state'] ?? '',

      city:
          json['city'] ?? '',

      district:
          json['district'],

      category:
          json['category'] ??
              'Historical',

      subcategory:
          json['subcategory'],

      description:
          json['description'] ??
              '',

      latitude:
          ((json['latitude'] ??
                      0)
                  as num)
              .toDouble(),

      longitude:
          ((json['longitude'] ??
                      0)
                  as num)
              .toDouble(),

      rating:
          ((json['rating'] ??
                      0)
                  as num)
              .toDouble(),

      images: imageList,

      primaryImage:
          imageList.isNotEmpty
              ? imageList.first
              : '',

      featured:
          json['featured'] ??
              false,

      isPopular:
          json['is_popular'] ??
              false,

      isFree:
          foreignerFee == 0,

      tier:
          json['tier'] ?? 2,

      entryFeeForeigner:
          foreignerFee,

      entryFeeIndian:
          indianFee,

      timings:
          json['timings'],

      bestSeason:
          json['best_season'],

      bestMonths:
          (json['best_months']
                      as List?)
                  ?.map((e) =>
                      e.toString())
                  .toList() ??
              [],

      safetyGuidelines:
          (json['safety_guidelines']
                      as List?)
                  ?.map((e) =>
                      e.toString())
                  .toList() ??
              [],

      touristTips:
          (json['tourist_tips']
                      as List?)
                  ?.map((e) =>
                      e.toString())
                  .toList() ??
              [],

      visitDurationMinutes:
          json[
              'visit_duration_minutes'],

      address:
          json['address'],
    );
  }

  String get formattedEntryFee {
    if (isFree) {
      return 'Free';
    }

    return '₹${entryFeeForeigner.toInt()}';
  }
}