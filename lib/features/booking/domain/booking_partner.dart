import 'package:flutter/material.dart';

enum BookingCategory { hotel, flight, travel, placeTicket }

enum TravelTransportMode { bus, metro, train, cab, auto, flight }

extension TravelTransportModeDetails on TravelTransportMode {
  String get label {
    return switch (this) {
      TravelTransportMode.bus => 'Bus',
      TravelTransportMode.metro => 'Metro',
      TravelTransportMode.train => 'Train',
      TravelTransportMode.cab => 'Cab',
      TravelTransportMode.auto => 'Auto',
      TravelTransportMode.flight => 'Flight',
    };
  }

  String get description {
    return switch (this) {
      TravelTransportMode.bus => 'Intercity bus tickets and operators',
      TravelTransportMode.metro => 'City metro route and fare guidance',
      TravelTransportMode.train => 'Rail search and reserved train tickets',
      TravelTransportMode.cab => 'City and airport cab bookings',
      TravelTransportMode.auto => 'Auto-rickshaw and local ride options',
      TravelTransportMode.flight => 'Domestic and international flights',
    };
  }
}

class BookingPartner {
  const BookingPartner({
    required this.name,
    required this.shortName,
    required this.description,
    required this.color,
    required this.category,
  });

  final String name;
  final String shortName;
  final String description;
  final Color color;
  final BookingCategory category;
}

const hotelBookingPartners = [
  BookingPartner(
    name: 'Booking.com',
    shortName: 'B',
    description: 'Wide hotel and stay selection',
    color: Color(0xFF003B95),
    category: BookingCategory.hotel,
  ),
  BookingPartner(
    name: 'Agoda',
    shortName: 'A',
    description: 'Popular across Asia',
    color: Color(0xFFE12D2D),
    category: BookingCategory.hotel,
  ),
  BookingPartner(
    name: 'Expedia',
    shortName: 'E',
    description: 'Hotels and travel packages',
    color: Color(0xFF172F7C),
    category: BookingCategory.hotel,
  ),
  BookingPartner(
    name: 'Trip.com',
    shortName: 'T',
    description: 'International travel inventory',
    color: Color(0xFF287DFA),
    category: BookingCategory.hotel,
  ),
];

const flightBookingPartners = [
  BookingPartner(
    name: 'Skyscanner',
    shortName: 'S',
    description: 'Compare international routes',
    color: Color(0xFF0770E3),
    category: BookingCategory.flight,
  ),
  BookingPartner(
    name: 'KAYAK',
    shortName: 'K',
    description: 'Flexible flight comparison',
    color: Color(0xFFFF690F),
    category: BookingCategory.flight,
  ),
  BookingPartner(
    name: 'Expedia',
    shortName: 'E',
    description: 'Flights and travel packages',
    color: Color(0xFF172F7C),
    category: BookingCategory.flight,
  ),
  BookingPartner(
    name: 'Trip.com',
    shortName: 'T',
    description: 'International and India routes',
    color: Color(0xFF287DFA),
    category: BookingCategory.flight,
  ),
];

const busBookingPartners = [
  BookingPartner(
    name: 'redBus',
    shortName: 'R',
    description: 'Intercity bus routes across India',
    color: Color(0xFFD84E55),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'AbhiBus',
    shortName: 'A',
    description: 'Bus tickets and operator comparison',
    color: Color(0xFFE0222A),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'MakeMyTrip Bus',
    shortName: 'M',
    description: 'Bus tickets with travel bundles',
    color: Color(0xFF1463FF),
    category: BookingCategory.travel,
  ),
];

const metroBookingPartners = [
  BookingPartner(
    name: 'Google Maps Transit',
    shortName: 'G',
    description: 'Metro, walking, and transit directions',
    color: Color(0xFF1A73E8),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'Delhi Metro',
    shortName: 'D',
    description: 'Delhi NCR metro routes and fare info',
    color: Color(0xFF155CA2),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'Metro Rail Info',
    shortName: 'M',
    description: 'Indian city metro route planning',
    color: Color(0xFF0B8F6F),
    category: BookingCategory.travel,
  ),
];

const trainBookingPartners = [
  BookingPartner(
    name: 'IRCTC',
    shortName: 'I',
    description: 'Official Indian Railways ticketing',
    color: Color(0xFF233A8B),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'ConfirmTkt',
    shortName: 'C',
    description: 'Train availability and alternatives',
    color: Color(0xFF0A8FDC),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'MakeMyTrip Train',
    shortName: 'M',
    description: 'Rail search with travel planning',
    color: Color(0xFF1463FF),
    category: BookingCategory.travel,
  ),
];

const cabBookingPartners = [
  BookingPartner(
    name: 'Uber',
    shortName: 'U',
    description: 'Cab rides and airport transfers',
    color: Color(0xFF111111),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'Ola',
    shortName: 'O',
    description: 'Local city cab bookings',
    color: Color(0xFF65A532),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'Google Maps Driving',
    shortName: 'G',
    description: 'Driving route before choosing a ride',
    color: Color(0xFF1A73E8),
    category: BookingCategory.travel,
  ),
];

const autoBookingPartners = [
  BookingPartner(
    name: 'Rapido',
    shortName: 'R',
    description: 'Auto and bike taxi availability',
    color: Color(0xFFF9C935),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'Namma Yatri',
    shortName: 'N',
    description: 'Open mobility auto-rickshaw rides',
    color: Color(0xFF5A32F0),
    category: BookingCategory.travel,
  ),
  BookingPartner(
    name: 'Google Maps Local',
    shortName: 'G',
    description: 'Local route before booking an auto',
    color: Color(0xFF1A73E8),
    category: BookingCategory.travel,
  ),
];

List<BookingPartner> travelPartnersForMode(TravelTransportMode mode) {
  return switch (mode) {
    TravelTransportMode.bus => busBookingPartners,
    TravelTransportMode.metro => metroBookingPartners,
    TravelTransportMode.train => trainBookingPartners,
    TravelTransportMode.cab => cabBookingPartners,
    TravelTransportMode.auto => autoBookingPartners,
    TravelTransportMode.flight => flightBookingPartners,
  };
}
