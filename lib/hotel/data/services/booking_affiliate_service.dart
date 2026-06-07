import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// Booking.com Affiliate Partner redirect service.
/// When a user clicks "Book", we redirect to Booking.com via an affiliate URL
/// that includes UniSafeX's affiliate ID for commission attribution.
///
/// Affiliate signup: https://www.booking.com/affiliate-program/
class BookingAffiliateService {
  static const String _affiliateId = 'UNISAFEX_AFF_001'; // Replace with real affiliate ID
  static const String _aid = '123456'; // Booking.com affiliate account ID
  static const String _baseUrl = 'https://www.booking.com';

  final _uuid = const Uuid();

  // ── Build affiliate URL ────────────────────────────────────────
  AffiliateRedirect buildHotelUrl({
    required String hotelSlug,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int rooms,
    String? userId,
  }) {
    final clickId = _uuid.v4();

    // Format dates for Booking.com (yyyy-mm-dd)
    final ci =
        '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
    final co =
        '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}';

    final params = {
      'aid': _aid,               // Affiliate account ID
      'checkin': ci,
      'checkout': co,
      'group_adults': adults,
      'no_rooms': rooms,
      'label': 'unisafex_$clickId',  // Tracking label
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    final url =
        '$_baseUrl/hotel/in/$hotelSlug.html?$queryString';

    return AffiliateRedirect(
      url: url,
      clickId: clickId,
      partnerSource: 'booking',
      affiliateId: _affiliateId,
    );
  }

  // ── Build search URL (city-level) ─────────────────────────────
  AffiliateRedirect buildCitySearchUrl({
    required String city,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int rooms,
    String? userId,
  }) {
    final clickId = _uuid.v4();

    final ci =
        '${checkIn.year}-${checkIn.month.toString().padLeft(2, '0')}-${checkIn.day.toString().padLeft(2, '0')}';
    final co =
        '${checkOut.year}-${checkOut.month.toString().padLeft(2, '0')}-${checkOut.day.toString().padLeft(2, '0')}';

    final url = [
      '$_baseUrl/searchresults.html',
      '?aid=$_aid',
      '&ss=${Uri.encodeComponent('$city, India')}',
      '&checkin=$ci',
      '&checkout=$co',
      '&group_adults=$adults',
      '&no_rooms=$rooms',
      '&label=unisafex_$clickId',
    ].join();

    return AffiliateRedirect(
      url: url,
      clickId: clickId,
      partnerSource: 'booking',
      affiliateId: _affiliateId,
    );
  }

  // ── Open URL in browser ────────────────────────────────────────
  Future<bool> openAffiliateLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }
}

class AffiliateRedirect {
  final String url;
  final String clickId;
  final String partnerSource;
  final String affiliateId;

  const AffiliateRedirect({
    required this.url,
    required this.clickId,
    required this.partnerSource,
    required this.affiliateId,
  });
}
