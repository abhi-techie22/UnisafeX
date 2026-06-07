import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../services/amadeus_api_service.dart';
import '../services/mock_hotel_service.dart';
import '../services/hotel_supabase_service.dart';
import '../services/booking_affiliate_service.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/affiliate_click.dart';
import '../../domain/entities/analytics_event.dart';
import '../../domain/entities/hotel_search_params.dart';

/// Central repository that orchestrates:
/// 1. Try Amadeus API (real data)
/// 2. Fallback to MockHotelService (when keys absent or API fails)
/// 3. Persist to Supabase (bookings, analytics, affiliate clicks)
/// 4. Generate affiliate URLs via BookingAffiliateService
class HotelRepository {
  final MockHotelService _mockService;
  final HotelSupabaseService _supabaseService;
  final BookingAffiliateService _affiliateService;
  final AmadeusApiService? _amadeusService; // null if not configured
  final Logger _log = Logger();
  final _uuid = const Uuid();

  static const String _affiliateId = 'UNISAFEX_AFF_001';

  HotelRepository({
    required MockHotelService mockService,
    required HotelSupabaseService supabaseService,
    required BookingAffiliateService affiliateService,
    AmadeusApiService? amadeusService,
  })  : _mockService = mockService,
        _supabaseService = supabaseService,
        _affiliateService = affiliateService,
        _amadeusService = amadeusService;

  // ── Session ───────────────────────────────────────────────────
  late final String sessionId = _uuid.v4();

  // ── Search hotels ─────────────────────────────────────────────
  Future<List<Hotel>> searchHotels({
    required HotelSearchParams params,
    String? userId,
  }) async {
    // Track search event (fire-and-forget)
    _supabaseService.track(
      type: HotelAnalyticsType.hotelSearch,
      userId: userId,
      sessionId: sessionId,
      extra: {
        'city': params.city,
        'check_in': params.checkIn.toIso8601String(),
        'check_out': params.checkOut.toIso8601String(),
        'adults': params.adults,
        'is_nearby': params.isNearbySearch,
      },
    );

    List<Hotel> hotels = [];

    // Try Amadeus first
    if (_amadeusService != null) {
      try {
        hotels = params.isNearbySearch
            ? await _amadeusService!.searchByGeo(params)
            : await _amadeusService!.searchByCity(params);
        _log.d('Amadeus returned ${hotels.length} hotels');
      } catch (e) {
        _log.w('Amadeus search failed, using mock', error: e);
      }
    }

    // Fallback to mock
    if (hotels.isEmpty) {
      hotels = await _mockService.searchHotels(params);
    }

    // Attach affiliate URLs
    hotels = hotels.map((h) {
      final redirect = _affiliateService.buildHotelUrl(
        hotelSlug: _slugify(h.name),
        checkIn: params.checkIn,
        checkOut: params.checkOut,
        adults: params.adults,
        rooms: params.rooms,
        userId: userId,
      );
      return h.copyWith(affiliateUrl: redirect.url);
    }).toList();

    return hotels;
  }

  // ── Hotel detail ──────────────────────────────────────────────
  Future<Hotel?> getHotelDetail({
    required String hotelId,
    String? userId,
  }) async {
    _supabaseService.track(
      type: HotelAnalyticsType.hotelView,
      userId: userId,
      hotelId: hotelId,
      sessionId: sessionId,
    );

    return _mockService.getHotelById(hotelId);
  }

  // ── Get rooms ─────────────────────────────────────────────────
  Future<List<Room>> getHotelRooms({
    required Hotel hotel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    String? userId,
  }) async {
    // Try Amadeus if we have a partner ID and service is configured
    if (_amadeusService != null && hotel.partnerHotelId != null) {
      try {
        final rooms = await _amadeusService!.getHotelOffers(
          partnerHotelId: hotel.partnerHotelId!,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: adults,
          localHotelId: hotel.id,
        );
        if (rooms.isNotEmpty) return rooms;
      } catch (e) {
        _log.w('Amadeus room fetch failed, using mock', error: e);
      }
    }

    return _mockService.getRoomsForHotel(hotel.id);
  }

  // ── Create booking (API path) ─────────────────────────────────
  Future<Booking> createBooking({
    required Hotel hotel,
    required Room room,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String userId,
    Map<String, String> travelerInfo = const {},
  }) async {
    final bookingId = _uuid.v4();

    _supabaseService.track(
      type: HotelAnalyticsType.bookingStarted,
      userId: userId,
      hotelId: hotel.id,
      sessionId: sessionId,
      extra: {'room_type': room.name, 'partner': hotel.partnerSource},
    );

    try {
      final nights = checkOut.difference(checkIn).inDays;
      final totalPrice = room.pricePerNight * nights;

      // Try real Amadeus booking if configured + has partner ID
      String? partnerBookingId;
      String? confirmationCode;

      if (_amadeusService != null &&
          hotel.partnerSource == 'amadeus' &&
          travelerInfo.isNotEmpty) {
        try {
          final result = await _amadeusService!.createBooking(
            offerId: room.partnerRateId,
            traveler: travelerInfo,
          );
          partnerBookingId = result['data']?['id']?.toString();
          confirmationCode = result['data']?['id']?.toString();
        } catch (e) {
          _log.w('Amadeus booking failed, using mock confirmation', error: e);
        }
      }

      // Fallback: mock confirmation
      if (confirmationCode == null) {
        final mockResult = await _mockService.createMockBooking(
          hotelId: hotel.id,
          room: room,
          checkIn: checkIn,
          checkOut: checkOut,
          guests: guests,
        );
        confirmationCode = mockResult['confirmation_code'] as String?;
        partnerBookingId = mockResult['partner_booking_id'] as String?;
      }

      final booking = Booking(
        id: bookingId,
        userId: userId,
        hotelId: hotel.id,
        hotelName: hotel.name,
        hotelImageUrl: hotel.imageUrl,
        roomType: room.name,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        totalPrice: totalPrice,
        currency: room.currency,
        status: BookingStatus.confirmed,
        affiliateId: _affiliateId,
        partnerSource: hotel.partnerSource,
        partnerBookingId: partnerBookingId,
        confirmationCode: confirmationCode,
        createdAt: DateTime.now(),
        metadata: {
          'room_id': room.id,
          'partner_rate_id': room.partnerRateId,
          'session_id': sessionId,
        },
      );

      await _supabaseService.saveBooking(booking);

      _supabaseService.track(
        type: HotelAnalyticsType.bookingCompleted,
        userId: userId,
        hotelId: hotel.id,
        sessionId: sessionId,
        extra: {
          'booking_id': bookingId,
          'total': totalPrice,
          'confirmation': confirmationCode,
        },
      );

      return booking;
    } catch (e) {
      _supabaseService.track(
        type: HotelAnalyticsType.bookingFailed,
        userId: userId,
        hotelId: hotel.id,
        sessionId: sessionId,
        extra: {'error': e.toString()},
      );

      // Save failed booking for support tracking
      final failedBooking = Booking(
        id: bookingId,
        userId: userId,
        hotelId: hotel.id,
        hotelName: hotel.name,
        hotelImageUrl: hotel.imageUrl,
        roomType: room.name,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        totalPrice: room.pricePerNight * checkOut.difference(checkIn).inDays,
        currency: room.currency,
        status: BookingStatus.cancelled,
        affiliateId: _affiliateId,
        partnerSource: hotel.partnerSource,
        createdAt: DateTime.now(),
        metadata: {'error': e.toString()},
      );
      await _supabaseService.saveBooking(failedBooking);
      rethrow;
    }
  }

  // ── Affiliate redirect (Booking.com path) ─────────────────────
  Future<AffiliateClick> redirectToAffiliate({
    required Hotel hotel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int rooms,
    String? userId,
  }) async {
    final redirect = _affiliateService.buildHotelUrl(
      hotelSlug: _slugify(hotel.name),
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      rooms: rooms,
      userId: userId,
    );

    // Record the click in Supabase
    final click = await _supabaseService.recordClick(
      hotelId: hotel.id,
      partnerSource: redirect.partnerSource,
      affiliateId: redirect.affiliateId,
      userId: userId,
      sessionId: sessionId,
      extra: {
        'url': redirect.url,
        'hotel_name': hotel.name,
        'city': hotel.city,
      },
    );

    _supabaseService.track(
      type: HotelAnalyticsType.affiliateRedirect,
      userId: userId,
      hotelId: hotel.id,
      sessionId: sessionId,
      extra: {
        'click_id': click.clickId,
        'partner': redirect.partnerSource,
      },
    );

    // Open the URL
    await _affiliateService.openAffiliateLink(redirect.url);

    return click;
  }

  // ── User booking history ───────────────────────────────────────
  Future<List<Booking>> getUserBookings(String userId) async {
    return _supabaseService.getUserBookings(userId);
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
