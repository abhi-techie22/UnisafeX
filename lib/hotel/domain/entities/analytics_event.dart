/// Analytics event tracked for every significant user action in the hotel module.
class AnalyticsEvent {
  final String id;
  final String? userId;
  final HotelAnalyticsType eventType;
  final String? hotelId;
  final String? sessionId;
  final Map<String, dynamic> metadata; // city, price, partner, device, etc.
  final DateTime createdAt;

  const AnalyticsEvent({
    required this.id,
    this.userId,
    required this.eventType,
    this.hotelId,
    this.sessionId,
    this.metadata = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'event_type': eventType.name,
        'hotel_id': hotelId,
        'session_id': sessionId,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        eventType: HotelAnalyticsType.values.firstWhere(
          (t) => t.name == json['event_type'],
          orElse: () => HotelAnalyticsType.hotelView,
        ),
        hotelId: json['hotel_id'] as String?,
        sessionId: json['session_id'] as String?,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

enum HotelAnalyticsType {
  hotelSearch,
  hotelView,
  hotelClick,
  bookingStarted,
  bookingCompleted,
  bookingFailed,
  affiliateRedirect,
  filterApplied,
  savedHotel,
}
