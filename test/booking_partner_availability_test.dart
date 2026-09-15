import 'package:flutter_test/flutter_test.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';

void main() {
  group('availableTravelPartnersForRoute', () {
    test('hides Delhi Metro outside Delhi NCR routes', () {
      final partners = availableTravelPartnersForRoute(
        mode: TravelTransportMode.metro,
        origin: 'New Delhi',
        destination: 'Agra',
      );

      expect(
        partners.map((partner) => partner.name),
        isNot(contains('Delhi Metro')),
      );
      expect(
        partners.map((partner) => partner.name),
        contains('Google Maps Transit'),
      );
    });

    test('shows Delhi Metro for Delhi NCR routes', () {
      final partners = availableTravelPartnersForRoute(
        mode: TravelTransportMode.metro,
        origin: 'Rajiv Chowk, Delhi',
        destination: 'Noida Sector 18',
      );

      expect(
        partners.map((partner) => partner.name),
        contains('Delhi Metro'),
      );
    });

    test('hides local cab and auto partners for obvious intercity routes', () {
      final cabPartners = availableTravelPartnersForRoute(
        mode: TravelTransportMode.cab,
        origin: 'Delhi',
        destination: 'Taj Mahal',
      );
      final autoPartners = availableTravelPartnersForRoute(
        mode: TravelTransportMode.auto,
        origin: 'Delhi',
        destination: 'Agra',
      );

      expect(
          cabPartners.map((partner) => partner.name), isNot(contains('Uber')));
      expect(
          cabPartners.map((partner) => partner.name), isNot(contains('Ola')));
      expect(
        autoPartners.map((partner) => partner.name),
        isNot(contains('Rapido')),
      );
      expect(
        autoPartners.map((partner) => partner.name),
        isNot(contains('Namma Yatri')),
      );
    });
  });
}
