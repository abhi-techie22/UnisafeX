import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
import 'package:unisafex/features/booking/domain/booking_partner_config.dart';

class BookingLinkService {
  BookingLinkService._();

  static Uri buildHotelSearch({
    required String destination,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int rooms,
  }) {
    final baseUri = Uri.parse(BookingPartnerConfig.hotelPartnerUrl);
    return baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'ss': destination.trim(),
        'checkin': _date(checkIn),
        'checkout': _date(checkOut),
        'group_adults': '$adults',
        'no_rooms': '$rooms',
        'group_children': '0',
        if (BookingPartnerConfig.hasHotelAffiliate)
          'aid': BookingPartnerConfig.hotelAffiliateId,
      },
    );
  }

  static Uri buildFlightSearch({
    required String origin,
    required String destination,
    required DateTime departure,
    DateTime? returnDate,
    required int travellers,
    BookingPartner? partner,
  }) {
    final baseUri = Uri.parse(_flightPartnerUrl(partner));
    return baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'origin': origin.trim(),
        'destination': destination.trim(),
        'departure': _date(departure),
        if (returnDate != null) 'return': _date(returnDate),
        'adults': '$travellers',
        if (BookingPartnerConfig.hasFlightAffiliate)
          'marker': BookingPartnerConfig.flightPartnerId,
      },
    );
  }

  static Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _flightPartnerUrl(BookingPartner? partner) {
    if (BookingPartnerConfig.flightPartnerUrlConfigured) {
      return BookingPartnerConfig.flightPartnerUrl;
    }
    return switch (partner?.name) {
      'KAYAK' => 'https://www.kayak.co.in/flights',
      'Expedia' => 'https://www.expedia.co.in/Flights-Search',
      'Trip.com' => 'https://www.trip.com/flights/',
      _ => 'https://www.skyscanner.co.in/transport/flights/',
    };
  }
}
