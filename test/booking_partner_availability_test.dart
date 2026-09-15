import 'package:flutter_test/flutter_test.dart';
import 'package:unisafex/features/booking/data/booking_link_service.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
import 'package:unisafex/features/booking/domain/delhi_metro_network.dart';
import 'package:unisafex/features/booking/domain/travel_hub.dart';

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

  group('travel hubs', () {
    test('recognises railway station route values', () {
      final hub = travelHubForRouteValue(
        railwayStationTravelHubs,
        'New Delhi Railway Station (NDLS), New Delhi',
      );

      expect(hub?.code, 'NDLS');
      expect(hub?.type, TravelHubType.railwayStation);
    });

    test('recognises airport route values', () {
      final hub = travelHubForRouteValue(
        airportTravelHubs,
        'Indira Gandhi International Airport (DEL), Delhi',
      );

      expect(hub?.code, 'DEL');
      expect(hub?.type, TravelHubType.airport);
    });
  });

  group('BookingLinkService current pickup', () {
    test('uses coordinates for Google Maps ride directions', () {
      final uri = BookingLinkService.buildTravelSearch(
        mode: TravelTransportMode.cab,
        origin: 'Current location - Delhi',
        destination: 'India Gate, Delhi',
        departure: DateTime(2026, 9, 22),
        travellers: 1,
        partner: cabBookingPartners.firstWhere(
          (partner) => partner.name == 'Google Maps Driving',
        ),
        originLatitude: 28.6139,
        originLongitude: 77.2090,
      );

      expect(uri.queryParameters['origin'], '28.613900,77.209000');
      expect(uri.queryParameters['destination'], 'India Gate, Delhi');
    });

    test('passes pickup coordinates to Uber links', () {
      final uri = BookingLinkService.buildTravelSearch(
        mode: TravelTransportMode.cab,
        origin: 'Current location - Delhi',
        destination: 'India Gate, Delhi',
        departure: DateTime(2026, 9, 22),
        travellers: 1,
        partner: cabBookingPartners.firstWhere(
          (partner) => partner.name == 'Uber',
        ),
        originLatitude: 28.6139,
        originLongitude: 77.2090,
      );

      expect(uri.queryParameters['pickup[latitude]'], '28.613900');
      expect(uri.queryParameters['pickup[longitude]'], '77.209000');
      expect(uri.queryParameters['dropoff[formatted_address]'],
          'India Gate, Delhi');
    });
  });
}
