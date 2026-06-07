import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';

/// DTO for Amadeus Hotel Offers response.
class AmadeusHotelDto {
  final String hotelId;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? cityCode;
  final double? rating;
  final List<AmadeusOfferDto> offers;

  const AmadeusHotelDto({
    required this.hotelId,
    required this.name,
    this.latitude,
    this.longitude,
    this.address,
    this.cityCode,
    this.rating,
    this.offers = const [],
  });

  factory AmadeusHotelDto.fromJson(Map<String, dynamic> json) {
    final hotel = json['hotel'] as Map<String, dynamic>? ?? {};
    final geo = hotel['geoCode'] as Map<String, dynamic>?;
    final addr = hotel['address'] as Map<String, dynamic>?;
    final ratingRaw = hotel['rating'];

    List<AmadeusOfferDto> offers = [];
    if (json['offers'] is List) {
      offers = (json['offers'] as List)
          .map((o) => AmadeusOfferDto.fromJson(o as Map<String, dynamic>))
          .toList();
    }

    return AmadeusHotelDto(
      hotelId: hotel['hotelId']?.toString() ?? '',
      name: hotel['name']?.toString() ?? '',
      latitude: (geo?['latitude'] as num?)?.toDouble(),
      longitude: (geo?['longitude'] as num?)?.toDouble(),
      address: addr != null
          ? '${addr['lines']?.first ?? ''}, ${addr['cityName'] ?? ''}'
          : null,
      cityCode: hotel['cityCode']?.toString(),
      rating: ratingRaw != null ? double.tryParse(ratingRaw.toString()) : null,
      offers: offers,
    );
  }

  /// Map to domain Hotel entity
  Hotel toEntity(String city) {
    final bestOffer = offers.isNotEmpty ? offers.first : null;
    final price = bestOffer?.priceTotal ?? 0.0;
    return Hotel(
      id: 'amadeus_$hotelId',
      name: name,
      city: city,
      latitude: latitude,
      longitude: longitude,
      address: address,
      rating: rating ?? 0.0,
      pricePerNight: price,
      currency: bestOffer?.currency ?? 'INR',
      tier: price.toTier,
      partnerSource: 'amadeus',
      partnerHotelId: hotelId,
    );
  }
}

class AmadeusOfferDto {
  final String offerId;
  final double priceTotal;
  final String currency;
  final String? roomType;
  final int bedCount;
  final bool breakfastIncluded;
  final bool refundable;

  const AmadeusOfferDto({
    required this.offerId,
    required this.priceTotal,
    required this.currency,
    this.roomType,
    this.bedCount = 1,
    this.breakfastIncluded = false,
    this.refundable = true,
  });

  factory AmadeusOfferDto.fromJson(Map<String, dynamic> json) {
    final price = json['price'] as Map<String, dynamic>? ?? {};
    final room = json['room'] as Map<String, dynamic>?;
    final beds = room?['typeEstimated'] as Map<String, dynamic>?;
    final policies = json['policies'] as Map<String, dynamic>?;
    final cancellation = policies?['cancellations'] as List?;

    return AmadeusOfferDto(
      offerId: json['id']?.toString() ?? '',
      priceTotal:
          double.tryParse(price['total']?.toString() ?? '0') ?? 0.0,
      currency: price['currency']?.toString() ?? 'INR',
      roomType: beds?['category']?.toString(),
      bedCount: (beds?['beds'] as int?) ?? 1,
      breakfastIncluded: json['boardType']?.toString() == 'BREAKFAST',
      refundable: cancellation?.isEmpty ?? true,
    );
  }

  Room toEntity(String hotelId) => Room(
        id: 'amadeus_offer_$offerId',
        hotelId: hotelId,
        name: roomType ?? 'Standard Room',
        pricePerNight: priceTotal,
        currency: currency,
        bedCount: bedCount,
        bedType: bedCount > 1 ? 'Twin' : 'Double',
        breakfastIncluded: breakfastIncluded,
        refundable: refundable,
        partnerRateId: offerId,
      );
}

/// DTO for Amadeus auth token response
class AmadeusTokenDto {
  final String accessToken;
  final int expiresIn;
  final DateTime issuedAt;

  const AmadeusTokenDto({
    required this.accessToken,
    required this.expiresIn,
    required this.issuedAt,
  });

  factory AmadeusTokenDto.fromJson(Map<String, dynamic> json) =>
      AmadeusTokenDto(
        accessToken: json['access_token'] as String,
        expiresIn: json['expires_in'] as int? ?? 1799,
        issuedAt: DateTime.now(),
      );

  bool get isExpired =>
      DateTime.now().isAfter(issuedAt.add(Duration(seconds: expiresIn - 30)));
}
