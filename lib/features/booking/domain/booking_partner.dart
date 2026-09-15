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
    name: 'Google Maps Transit',
    shortName: 'G',
    description: 'Local bus and public transit directions',
    color: Color(0xFF1A73E8),
    category: BookingCategory.travel,
  ),
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
    name: 'Amazon Pay Metro',
    shortName: 'A',
    description: 'Delhi Metro QR ticket partner',
    color: Color(0xFFFF9900),
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

List<BookingPartner> availableTravelPartnersForRoute({
  required TravelTransportMode mode,
  required String origin,
  required String destination,
}) {
  final partners = travelPartnersForMode(mode);
  final available = _filteredTravelPartnersForRoute(
    mode: mode,
    origin: origin,
    destination: destination,
  );
  return available.isEmpty ? partners : available;
}

List<BookingPartner> _filteredTravelPartnersForRoute({
  required TravelTransportMode mode,
  required String origin,
  required String destination,
}) {
  return travelPartnersForMode(mode)
      .where(
        (partner) => isTravelPartnerAvailableForRoute(
          partner: partner,
          mode: mode,
          origin: origin,
          destination: destination,
        ),
      )
      .toList(growable: false);
}

bool isTravelPartnerAvailableForRoute({
  required BookingPartner partner,
  required TravelTransportMode mode,
  required String origin,
  required String destination,
}) {
  if (partner.name.startsWith('Google Maps')) return true;

  return switch (partner.name) {
    'Delhi Metro' || 'Amazon Pay Metro' => _sameKnownArea(
        origin,
        destination,
        _delhiNcrArea,
      ),
    'Metro Rail Info' => _sameKnownMetroArea(origin, destination),
    'redBus' ||
    'AbhiBus' ||
    'MakeMyTrip Bus' =>
      !_sameKnownLocalArea(origin, destination),
    'Uber' || 'Ola' => _looksLikeLocalRoute(origin, destination),
    'Rapido' => _looksLikeLocalRoute(origin, destination) &&
        _routeHasAnyArea(origin, destination, _rideHailingAreas),
    'Namma Yatri' => _looksLikeLocalRoute(origin, destination) &&
        _routeHasAnyArea(origin, destination, _nammaYatriAreas),
    'Skyscanner' || 'KAYAK' || 'Expedia' || 'Trip.com' => true,
    _ => true,
  };
}

int hiddenTravelPartnerCountForRoute({
  required TravelTransportMode mode,
  required String origin,
  required String destination,
}) {
  final all = travelPartnersForMode(mode);
  final available = _filteredTravelPartnersForRoute(
    mode: mode,
    origin: origin,
    destination: destination,
  );
  return all.length - available.length;
}

const _delhiNcrArea = 'delhi_ncr';

const _metroAreaTerms = <String, List<String>>{
  _delhiNcrArea: [
    'delhi',
    'new delhi',
    'ncr',
    'noida',
    'greater noida',
    'gurgaon',
    'gurugram',
    'ghaziabad',
    'faridabad',
    'bahadurgarh',
    'ballabhgarh',
    'dwarka',
    'rohini',
    'saket',
    'hauz khas',
    'janakpuri',
    'vaishali',
    'kaushambi',
    'cyber city',
    'india gate',
    'red fort',
    'qutub minar',
    'lotus temple',
    'akshardham',
    'connaught place',
    'chandni chowk',
    'jama masjid',
    'humayun',
    'kashmere gate',
    'rajiv chowk',
  ],
  'mumbai': [
    'mumbai',
    'bombay',
    'andheri',
    'bandra',
    'thane',
    'navi mumbai',
    'powai',
    'colaba',
    'dadar',
    'gateway of india',
    'marine drive',
    'cst',
    'chhatrapati shivaji terminus',
    'juhu',
    'elephanta',
  ],
  'bengaluru': [
    'bengaluru',
    'bangalore',
    'mg road',
    'majestic',
    'indiranagar',
    'whitefield',
    'yesvantpur',
    'cubbon park',
    'lalbagh',
    'vidhana soudha',
  ],
  'kolkata': [
    'kolkata',
    'calcutta',
    'howrah',
    'salt lake',
    'dum dum',
    'new town',
    'victoria memorial',
    'park street',
    'kalighat',
  ],
  'chennai': [
    'chennai',
    'egmore',
    'tambaram',
    'guindy',
    'marina beach',
    'kapaleeshwarar',
  ],
  'hyderabad': [
    'hyderabad',
    'secunderabad',
    'hitec city',
    'miyapur',
    'charminar',
    'golconda',
    'hussain sagar',
  ],
  'kochi': ['kochi', 'ernakulam', 'aluva', 'fort kochi', 'mattancherry'],
  'pune': [
    'pune',
    'shivajinagar',
    'pimpri',
    'chinchwad',
    'shaniwar wada',
  ],
  'ahmedabad': ['ahmedabad', 'gandhinagar', 'sabarmati', 'adalaj'],
  'jaipur': ['jaipur', 'hawa mahal', 'amber fort', 'amer fort'],
  'lucknow': ['lucknow', 'bara imambara'],
  'nagpur': ['nagpur'],
  'kanpur': ['kanpur'],
  'bhopal': ['bhopal'],
  'indore': ['indore'],
};

const _tourismCityTerms = <String, List<String>>{
  ..._metroAreaTerms,
  'agra': ['agra', 'taj mahal', 'fatehpur sikri'],
  'varanasi': ['varanasi', 'banaras', 'kashi', 'sarnath'],
  'udaipur': ['udaipur'],
  'jodhpur': ['jodhpur'],
  'amritsar': ['amritsar', 'golden temple'],
  'goa': ['goa', 'panaji', 'panjim', 'calangute', 'baga'],
  'mysuru': ['mysuru', 'mysore'],
  'rishikesh': ['rishikesh'],
  'haridwar': ['haridwar'],
  'shimla': ['shimla'],
  'manali': ['manali'],
  'leh': ['leh', 'ladakh'],
  'srinagar': ['srinagar'],
  'darjeeling': ['darjeeling'],
  'gangtok': ['gangtok'],
  'bhubaneswar': ['bhubaneswar'],
  'puri': ['puri'],
  'madurai': ['madurai'],
  'hampi': ['hampi'],
  'aurangabad': ['aurangabad', 'ajanta', 'ellora'],
  'khajuraho': ['khajuraho'],
  'vadodara': ['vadodara', 'baroda'],
  'surat': ['surat'],
};

const _rideHailingAreas = {
  _delhiNcrArea,
  'mumbai',
  'bengaluru',
  'kolkata',
  'chennai',
  'hyderabad',
  'pune',
  'ahmedabad',
  'jaipur',
  'lucknow',
  'kochi',
  'mysuru',
  'bhopal',
  'indore',
};

const _nammaYatriAreas = {
  'bengaluru',
  'chennai',
  'kolkata',
  'kochi',
  'hyderabad',
  'mysuru',
};

bool _sameKnownArea(
  String origin,
  String destination,
  String requiredArea,
) {
  return _matchedArea(origin, _tourismCityTerms) == requiredArea &&
      _matchedArea(destination, _tourismCityTerms) == requiredArea;
}

bool _sameKnownMetroArea(String origin, String destination) {
  final originArea = _matchedArea(origin, _metroAreaTerms);
  final destinationArea = _matchedArea(destination, _metroAreaTerms);
  return originArea != null && originArea == destinationArea;
}

bool _sameKnownLocalArea(String origin, String destination) {
  final originArea = _matchedArea(origin, _tourismCityTerms);
  final destinationArea = _matchedArea(destination, _tourismCityTerms);
  return originArea != null && originArea == destinationArea;
}

bool _looksLikeLocalRoute(String origin, String destination) {
  final originArea = _matchedArea(origin, _tourismCityTerms);
  final destinationArea = _matchedArea(destination, _tourismCityTerms);
  if (originArea == null || destinationArea == null) return true;
  return originArea == destinationArea;
}

bool _routeHasAnyArea(
  String origin,
  String destination,
  Set<String> allowedAreas,
) {
  final originArea = _matchedArea(origin, _tourismCityTerms);
  final destinationArea = _matchedArea(destination, _tourismCityTerms);
  return allowedAreas.contains(originArea) ||
      allowedAreas.contains(destinationArea);
}

String? _matchedArea(String value, Map<String, List<String>> areaTerms) {
  final normalized = _normalizeRouteText(value);
  if (normalized.trim().isEmpty) return null;
  for (final entry in areaTerms.entries) {
    for (final term in entry.value) {
      if (normalized.contains(' ${_normalizeRouteText(term).trim()} ')) {
        return entry.key;
      }
    }
  }
  return null;
}

String _normalizeRouteText(String value) {
  return ' ${value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()} ';
}
