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

  static bool get hasHotelAffiliate => hotelAffiliateId.trim().isNotEmpty;
  static bool get hasFlightAffiliate => flightPartnerId.trim().isNotEmpty;
}
