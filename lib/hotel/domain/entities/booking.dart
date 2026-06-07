/// Represents a hotel booking made through UniSafeX.
class Booking {
  final String id;
  final String userId;
  final String hotelId;
  final String hotelName;
  final String? hotelImageUrl;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final double totalPrice;
  final String currency;
  final BookingStatus status;
  final String affiliateId;
  final String partnerSource;
  final String? partnerBookingId;
  final String? confirmationCode;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const Booking({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.hotelName,
    this.hotelImageUrl,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    this.guests = 2,
    required this.totalPrice,
    this.currency = 'INR',
    this.status = BookingStatus.pending,
    required this.affiliateId,
    required this.partnerSource,
    this.partnerBookingId,
    this.confirmationCode,
    required this.createdAt,
    this.metadata = const {},
  });

  int get nights => checkOut.difference(checkIn).inDays;

  String get formattedTotal {
    final symbol = currency == 'INR' ? '₹' : '\$';
    return '$symbol${totalPrice.toStringAsFixed(0)}';
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.redirected:
        return 'Redirected';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'hotel_id': hotelId,
        'hotel_name': hotelName,
        'hotel_image_url': hotelImageUrl,
        'room_type': roomType,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'guests': guests,
        'total_price': totalPrice,
        'currency': currency,
        'status': status.name,
        'affiliate_id': affiliateId,
        'partner_source': partnerSource,
        'partner_booking_id': partnerBookingId,
        'confirmation_code': confirmationCode,
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        hotelId: json['hotel_id'] as String,
        hotelName: json['hotel_name'] as String? ?? '',
        hotelImageUrl: json['hotel_image_url'] as String?,
        roomType: json['room_type'] as String? ?? '',
        checkIn: DateTime.parse(json['check_in'] as String),
        checkOut: DateTime.parse(json['check_out'] as String),
        guests: json['guests'] as int? ?? 2,
        totalPrice: (json['total_price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'INR',
        status: BookingStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => BookingStatus.pending,
        ),
        affiliateId: json['affiliate_id'] as String? ?? '',
        partnerSource: json['partner_source'] as String? ?? '',
        partnerBookingId: json['partner_booking_id'] as String?,
        confirmationCode: json['confirmation_code'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

enum BookingStatus { pending, confirmed, cancelled, completed, redirected }
