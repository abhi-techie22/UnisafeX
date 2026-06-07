/// A specific room/rate option within a hotel.
class Room {
  final String id;
  final String hotelId;
  final String name;
  final String? description;
  final double pricePerNight;
  final String currency;
  final int maxOccupancy;
  final int bedCount;
  final String bedType;
  final List<String> amenities;
  final String? imageUrl;
  final bool isAvailable;
  final bool breakfastIncluded;
  final bool refundable;
  final String? cancellationPolicy;
  final String partnerRateId;   // Upstream rate plan ID

  const Room({
    required this.id,
    required this.hotelId,
    required this.name,
    this.description,
    required this.pricePerNight,
    this.currency = 'INR',
    this.maxOccupancy = 2,
    this.bedCount = 1,
    this.bedType = 'Double',
    this.amenities = const [],
    this.imageUrl,
    this.isAvailable = true,
    this.breakfastIncluded = false,
    this.refundable = true,
    this.cancellationPolicy,
    required this.partnerRateId,
  });

  String get formattedPrice {
    final symbol = currency == 'INR' ? '₹' : '\$';
    return '$symbol${pricePerNight.toStringAsFixed(0)}';
  }
}
