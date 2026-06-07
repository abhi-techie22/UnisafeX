import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/affiliate_click.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/hotel.dart';

/// Supabase persistence layer for the hotel module.
/// Handles bookings, analytics events, affiliate clicks, and hotel cache.
class HotelSupabaseService {
  final SupabaseClient _client;
  final Logger _log = Logger();
  final _uuid = const Uuid();

  static const String _tableBookings = 'hotel_bookings';
  static const String _tableAnalytics = 'hotel_analytics_events';
  static const String _tableAffiliateClicks = 'hotel_affiliate_clicks';
  static const String _tableHotelsCache = 'hotels_cache';

  HotelSupabaseService(this._client);

  // ── Bookings ──────────────────────────────────────────────────
  Future<String> saveBooking(Booking booking) async {
    try {
      await _client.from(_tableBookings).upsert(booking.toJson());
      return booking.id;
    } catch (e) {
      _log.e('saveBooking error', error: e);
      rethrow;
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final data = await _client
          .from(_tableBookings)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((j) => Booking.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.e('getUserBookings error', error: e);
      return [];
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    try {
      await _client
          .from(_tableBookings)
          .update({'status': status.name})
          .eq('id', bookingId);
    } catch (e) {
      _log.e('updateBookingStatus error', error: e);
    }
  }

  // ── Analytics ─────────────────────────────────────────────────
  Future<void> logEvent(AnalyticsEvent event) async {
    try {
      await _client.from(_tableAnalytics).insert(event.toJson());
    } catch (e) {
      // Non-fatal — never block user flow for analytics
      _log.w('logEvent failed silently', error: e);
    }
  }

  // ── Affiliate clicks ──────────────────────────────────────────
  Future<String> saveAffiliateClick(AffiliateClick click) async {
    try {
      await _client.from(_tableAffiliateClicks).insert(click.toJson());
      return click.clickId;
    } catch (e) {
      _log.w('saveAffiliateClick failed', error: e);
      return click.clickId;
    }
  }

  Future<void> updateClickOutcome(
      String clickId, ClickOutcome outcome) async {
    try {
      await _client
          .from(_tableAffiliateClicks)
          .update({'outcome': outcome.name})
          .eq('click_id', clickId);
    } catch (e) {
      _log.w('updateClickOutcome failed', error: e);
    }
  }

  // ── Hotel cache ───────────────────────────────────────────────
  Future<void> cacheHotel(Hotel hotel) async {
    try {
      await _client.from(_tableHotelsCache).upsert({
        'id': hotel.id,
        'name': hotel.name,
        'city': hotel.city,
        'price': hotel.pricePerNight,
        'rating': hotel.rating,
        'image': hotel.imageUrl,
        'source': hotel.partnerSource,
        'partner_hotel_id': hotel.partnerHotelId,
        'cached_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _log.w('cacheHotel failed', error: e);
    }
  }

  // ── Session helpers ───────────────────────────────────────────
  String generateSessionId() => _uuid.v4();
  String generateClickId() => _uuid.v4();

  // ── Create analytics event helper ─────────────────────────────
  Future<void> track({
    required HotelAnalyticsType type,
    String? userId,
    String? hotelId,
    String? sessionId,
    Map<String, dynamic> extra = const {},
  }) async {
    final event = AnalyticsEvent(
      id: _uuid.v4(),
      userId: userId,
      eventType: type,
      hotelId: hotelId,
      sessionId: sessionId,
      metadata: extra,
      createdAt: DateTime.now(),
    );
    await logEvent(event);
  }

  // ── Create affiliate click helper ──────────────────────────────
  Future<AffiliateClick> recordClick({
    required String hotelId,
    required String partnerSource,
    required String affiliateId,
    String? userId,
    String? sessionId,
    Map<String, dynamic> extra = const {},
  }) async {
    final click = AffiliateClick(
      id: _uuid.v4(),
      clickId: _uuid.v4(),
      userId: userId,
      hotelId: hotelId,
      partnerSource: partnerSource,
      affiliateId: affiliateId,
      sessionId: sessionId,
      outcome: ClickOutcome.clicked,
      createdAt: DateTime.now(),
      metadata: extra,
    );
    await saveAffiliateClick(click);
    return click;
  }
}
