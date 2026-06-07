/// Tracks every affiliate click/redirect for commission attribution.
class AffiliateClick {
  final String id;
  final String clickId;          // UUID v4, unique per click
  final String? userId;
  final String hotelId;
  final String partnerSource;    // amadeus | expedia | booking
  final String affiliateId;      // UniSafeX partner affiliate ID
  final String? sessionId;
  final ClickOutcome outcome;
  final double? commissionAmount;
  final String? bookingId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AffiliateClick({
    required this.id,
    required this.clickId,
    this.userId,
    required this.hotelId,
    required this.partnerSource,
    required this.affiliateId,
    this.sessionId,
    this.outcome = ClickOutcome.clicked,
    this.commissionAmount,
    this.bookingId,
    required this.createdAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'click_id': clickId,
        'user_id': userId,
        'hotel_id': hotelId,
        'partner_source': partnerSource,
        'affiliate_id': affiliateId,
        'session_id': sessionId,
        'outcome': outcome.name,
        'commission_amount': commissionAmount,
        'booking_id': bookingId,
        'created_at': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AffiliateClick.fromJson(Map<String, dynamic> json) => AffiliateClick(
        id: json['id'] as String,
        clickId: json['click_id'] as String,
        userId: json['user_id'] as String?,
        hotelId: json['hotel_id'] as String,
        partnerSource: json['partner_source'] as String,
        affiliateId: json['affiliate_id'] as String,
        sessionId: json['session_id'] as String?,
        outcome: ClickOutcome.values.firstWhere(
          (o) => o.name == json['outcome'],
          orElse: () => ClickOutcome.clicked,
        ),
        commissionAmount: (json['commission_amount'] as num?)?.toDouble(),
        bookingId: json['booking_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}

enum ClickOutcome { clicked, viewed, bookingStarted, bookingCompleted, bookingFailed }
