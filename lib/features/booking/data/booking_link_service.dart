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
    final uri = buildTravelSearch(
      mode: TravelTransportMode.flight,
      origin: origin,
      destination: destination,
      departure: departure,
      travellers: travellers,
      partner: partner,
    );
    if (returnDate == null) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'return': _date(returnDate),
      },
    );
  }

  static Uri buildTravelSearch({
    required TravelTransportMode mode,
    required String origin,
    required String destination,
    required DateTime departure,
    required int travellers,
    BookingPartner? partner,
  }) {
    final trimmedOrigin = origin.trim();
    final trimmedDestination = destination.trim();
    final baseUrl = _travelPartnerUrl(mode, partner);

    if (partner != null &&
        !isTravelPartnerAvailableForRoute(
          partner: partner,
          mode: mode,
          origin: trimmedOrigin,
          destination: trimmedDestination,
        )) {
      return _mapsDirectionsUri(
        origin: trimmedOrigin,
        destination: trimmedDestination,
        mode: mode,
      );
    }

    if (_isMapsPartner(baseUrl)) {
      return _mapsDirectionsUri(
        origin: trimmedOrigin,
        destination: trimmedDestination,
        mode: mode,
      );
    }

    if (partner?.name == 'Uber') {
      return Uri.parse(baseUrl).replace(
        queryParameters: {
          'action': 'setPickup',
          'pickup[formatted_address]': trimmedOrigin,
          'dropoff[formatted_address]': trimmedDestination,
        },
      );
    }

    final baseUri = Uri.parse(baseUrl);
    return baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'from': trimmedOrigin,
        'to': trimmedDestination,
        'origin': trimmedOrigin,
        'destination': trimmedDestination,
        'date': _date(departure),
        'travellers': '$travellers',
        'mode': mode.name,
        if (mode == TravelTransportMode.flight) 'departure': _date(departure),
        if (mode == TravelTransportMode.flight) 'adults': '$travellers',
        if (BookingPartnerConfig.hasTravelAffiliate)
          'ref': BookingPartnerConfig.travelAffiliateId,
        if (mode == TravelTransportMode.flight &&
            BookingPartnerConfig.hasFlightAffiliate)
          'marker': BookingPartnerConfig.flightPartnerId,
      },
    );
  }

  static Uri buildPlaceTicketSearch({
    required String placeName,
    String? city,
    String? state,
  }) {
    final locationParts = [
      placeName.trim(),
      if (city?.trim().isNotEmpty == true) city!.trim(),
      if (state?.trim().isNotEmpty == true) state!.trim(),
      'official online ticket',
    ];
    final query = locationParts.join(' ');
    final baseUri = Uri.parse(BookingPartnerConfig.placeTicketPartnerUrl);
    return baseUri.replace(
      queryParameters: {
        ...baseUri.queryParameters,
        'q': query,
        if (BookingPartnerConfig.hasPlaceTicketAffiliate)
          'partner_id': BookingPartnerConfig.placeTicketAffiliateId,
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

  static String _travelPartnerUrl(
    TravelTransportMode mode,
    BookingPartner? partner,
  ) {
    if (BookingPartnerConfig.travelPartnerUrlConfigured) {
      return BookingPartnerConfig.travelPartnerUrl;
    }
    if (mode == TravelTransportMode.flight) return _flightPartnerUrl(partner);

    return switch (partner?.name) {
      'AbhiBus' => 'https://www.abhibus.com/bus-ticket-booking',
      'MakeMyTrip Bus' => 'https://www.makemytrip.com/bus-tickets/',
      'redBus' => 'https://www.redbus.in/bus-tickets/',
      'Delhi Metro' => 'https://www.delhimetrorail.com/',
      'Metro Rail Info' => 'https://metrorailapp.com/',
      'IRCTC' => 'https://www.irctc.co.in/nget/train-search',
      'ConfirmTkt' => 'https://www.confirmtkt.com/',
      'MakeMyTrip Train' => 'https://www.makemytrip.com/railways/',
      'Uber' => 'https://m.uber.com/ul/',
      'Ola' => 'https://book.olacabs.com/',
      'Rapido' => 'https://www.rapido.bike/',
      'Namma Yatri' => 'https://nammayatri.in/',
      _ => 'https://www.google.com/maps/dir/',
    };
  }

  static bool _isMapsPartner(String url) {
    final host = Uri.parse(url).host;
    return host.contains('google.com') && url.contains('/maps/dir');
  }

  static Uri _mapsDirectionsUri({
    required String origin,
    required String destination,
    required TravelTransportMode mode,
  }) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': origin,
      'destination': destination,
      'travelmode': switch (mode) {
        TravelTransportMode.bus ||
        TravelTransportMode.metro ||
        TravelTransportMode.train =>
          'transit',
        TravelTransportMode.flight ||
        TravelTransportMode.cab ||
        TravelTransportMode.auto =>
          'driving',
      },
    });
  }
}
