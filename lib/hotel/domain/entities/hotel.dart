/// Core Hotel entity — provider-agnostic, used throughout the module.
class Hotel {
  final String id;
  final String name;
  final String city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double rating;
  final int? reviewCount;
  final double pricePerNight;
  final String currency;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<String> amenities;
  final String? description;
  final HotelTier tier;
  final String partnerSource;       // amadeus | expedia | booking | mock
  final String? partnerHotelId;     // ID from the upstream partner
  final String? affiliateUrl;       // Direct affiliate/redirect URL
  final double? distanceKm;         // Distance from search point
  final bool isSaved;

  const Hotel({
    required this.id,
    required this.name,
    required this.city,
    this.state,
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.address,
    this.rating = 0.0,
    this.reviewCount,
    required this.pricePerNight,
    this.currency = 'INR',
    this.imageUrl,
    this.imageUrls = const [],
    this.amenities = const [],
    this.description,
    this.tier = HotelTier.midRange,
    required this.partnerSource,
    this.partnerHotelId,
    this.affiliateUrl,
    this.distanceKm,
    this.isSaved = false,
  });

  Hotel copyWith({
    String? id,
    String? name,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    String? address,
    double? rating,
    int? reviewCount,
    double? pricePerNight,
    String? currency,
    String? imageUrl,
    List<String>? imageUrls,
    List<String>? amenities,
    String? description,
    HotelTier? tier,
    String? partnerSource,
    String? partnerHotelId,
    String? affiliateUrl,
    double? distanceKm,
    bool? isSaved,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      tier: tier ?? this.tier,
      partnerSource: partnerSource ?? this.partnerSource,
      partnerHotelId: partnerHotelId ?? this.partnerHotelId,
      affiliateUrl: affiliateUrl ?? this.affiliateUrl,
      distanceKm: distanceKm ?? this.distanceKm,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Formatted price string
  String get formattedPrice {
    final symbol = currency == 'INR' ? '₹' : '\$';
    return '$symbol${pricePerNight.toStringAsFixed(0)}';
  }

  /// Tier label
  String get tierLabel {
    switch (tier) {
      case HotelTier.budget:
        return 'Budget';
      case HotelTier.midRange:
        return 'Premium';
      case HotelTier.luxury:
        return 'Luxury';
      case HotelTier.ultraLuxury:
        return 'Ultra Luxury';
    }
  }
}

enum HotelTier { budget, midRange, luxury, ultraLuxury }

extension HotelTierExt on double {
  HotelTier get toTier {
    if (this < 2000) return HotelTier.budget;
    if (this < 7000) return HotelTier.midRange;
    if (this < 20000) return HotelTier.luxury;
    return HotelTier.ultraLuxury;
  }
}
