import 'package:flutter/material.dart';

enum BookingCategory { hotel, flight }

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
