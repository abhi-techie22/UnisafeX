import 'package:flutter_test/flutter_test.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
import 'package:unisafex/features/booking/domain/delhi_metro_network.dart';

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
        isNot(contains('Amazon Pay Metro')),
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
      expect(
        partners.map((partner) => partner.name),
        contains('Amazon Pay Metro'),
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

    test('keeps flight booking partners available for local-looking routes',
        () {
      final partners = availableTravelPartnersForRoute(
        mode: TravelTransportMode.flight,
        origin: 'Delhi',
        destination: 'India Gate, Delhi',
      );

      expect(partners.map((partner) => partner.name), contains('Skyscanner'));
      expect(partners.map((partner) => partner.name), contains('KAYAK'));
    });

    test('never leaves a supported travel mode without partners', () {
      for (final mode in TravelTransportMode.values) {
        final partners = availableTravelPartnersForRoute(
          mode: mode,
          origin: 'Delhi',
          destination: 'Agra',
        );

        expect(partners, isNotEmpty, reason: '${mode.name} should be usable');
      }
    });
  });

  group('buildDelhiMetroRoutePlan', () {
    test('builds a direct route on one line', () {
      final route = buildDelhiMetroRoutePlan(
        origin: 'Rajiv Chowk',
        destination: 'Kashmere Gate',
      );

      expect(route, isNotNull);
      expect(route!.isDirect, isTrue);
      expect(route.legs.single.line.name, 'Yellow Line');
    });

    test('shows interchange stations when lines change', () {
      final route = buildDelhiMetroRoutePlan(
        origin: 'Rajiv Chowk',
        destination: 'Lajpat Nagar',
      );

      expect(route, isNotNull);
      expect(route!.isDirect, isFalse);
      expect(route.interchanges, isNotEmpty);
      expect(route.legs.length, greaterThan(1));
    });
  });
}
