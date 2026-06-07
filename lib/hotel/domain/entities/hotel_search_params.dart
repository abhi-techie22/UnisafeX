/// Parameters passed to any hotel search — provider-agnostic.
class HotelSearchParams {
  final String city;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int rooms;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final HotelSortBy sortBy;
  final List<HotelTierFilter> tiers;

  const HotelSearchParams({
    required this.city,
    this.latitude,
    this.longitude,
    this.radiusKm = 10,
    required this.checkIn,
    required this.checkOut,
    this.adults = 2,
    this.rooms = 1,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sortBy = HotelSortBy.recommended,
    this.tiers = const [],
  });

  int get nights => checkOut.difference(checkIn).inDays;

  bool get isNearbySearch => latitude != null && longitude != null;

  HotelSearchParams copyWith({
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? rooms,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    HotelSortBy? sortBy,
    List<HotelTierFilter>? tiers,
  }) {
    return HotelSearchParams(
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      adults: adults ?? this.adults,
      rooms: rooms ?? this.rooms,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      tiers: tiers ?? this.tiers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HotelSearchParams &&
      other.city == city &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut &&
      other.adults == adults;

  @override
  int get hashCode =>
      Object.hash(city, checkIn, checkOut, adults);
}

enum HotelSortBy { recommended, priceLow, priceHigh, rating, distance }

enum HotelTierFilter { budget, midRange, luxury, ultraLuxury }
