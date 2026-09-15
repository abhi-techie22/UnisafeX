class BookingPartnerConfig {
  BookingPartnerConfig._();

  static const hotelAffiliateId = String.fromEnvironment(
    'HOTEL_AFFILIATE_AID',
  );
  static const hotelPartnerUrl = String.fromEnvironment(
    'HOTEL_PARTNER_URL',
    defaultValue: 'https://www.booking.com/searchresults.html',
  );

  static const flightPartnerId = String.fromEnvironment(
    'FLIGHT_AFFILIATE_ID',
  );
  static const flightPartnerUrl = String.fromEnvironment(
    'FLIGHT_PARTNER_URL',
    defaultValue: 'https://www.aviasales.com',
  );
  static const travelAffiliateId = String.fromEnvironment(
    'TRAVEL_AFFILIATE_ID',
  );
  static const travelPartnerUrl = String.fromEnvironment(
    'TRAVEL_PARTNER_URL',
    defaultValue: '',
  );
  static const placeTicketAffiliateId = String.fromEnvironment(
    'PLACE_TICKET_AFFILIATE_ID',
  );
  static const placeTicketPartnerUrl = String.fromEnvironment(
    'PLACE_TICKET_PARTNER_URL',
    defaultValue: 'https://www.getyourguide.com/s/',
  );

  static bool get hasHotelAffiliate => hotelAffiliateId.trim().isNotEmpty;
  static bool get hasFlightAffiliate => flightPartnerId.trim().isNotEmpty;
  static bool get hasTravelAffiliate => travelAffiliateId.trim().isNotEmpty;
  static bool get hasPlaceTicketAffiliate =>
      placeTicketAffiliateId.trim().isNotEmpty;
  static bool get flightPartnerUrlConfigured =>
      flightPartnerUrl != 'https://www.aviasales.com';
  static bool get travelPartnerUrlConfigured =>
      travelPartnerUrl.trim().isNotEmpty;
  static bool get placeTicketPartnerUrlConfigured =>
      placeTicketPartnerUrl != 'https://www.getyourguide.com/s/';
}
