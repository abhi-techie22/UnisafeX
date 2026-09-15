import 'package:unisafex/features/booking/domain/booking_partner.dart';

enum TravelHubType { railwayStation, airport }

class TravelHub {
  const TravelHub({
    required this.name,
    required this.code,
    required this.city,
    required this.state,
    required this.type,
  });

  final String name;
  final String code;
  final String city;
  final String state;
  final TravelHubType type;

  String get routeValue => '$name ($code), $city';

  String get searchText => '$name $code $city $state'.toLowerCase();
}

const railwayStationTravelHubs = [
  TravelHub(
    name: 'New Delhi Railway Station',
    code: 'NDLS',
    city: 'New Delhi',
    state: 'Delhi',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Hazrat Nizamuddin',
    code: 'NZM',
    city: 'New Delhi',
    state: 'Delhi',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Anand Vihar Terminal',
    code: 'ANVT',
    city: 'Delhi',
    state: 'Delhi',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Agra Cantt',
    code: 'AGC',
    city: 'Agra',
    state: 'Uttar Pradesh',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Jaipur Junction',
    code: 'JP',
    city: 'Jaipur',
    state: 'Rajasthan',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Mumbai CSMT',
    code: 'CSMT',
    city: 'Mumbai',
    state: 'Maharashtra',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Mumbai Central',
    code: 'MMCT',
    city: 'Mumbai',
    state: 'Maharashtra',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Pune Junction',
    code: 'PUNE',
    city: 'Pune',
    state: 'Maharashtra',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Ahmedabad Junction',
    code: 'ADI',
    city: 'Ahmedabad',
    state: 'Gujarat',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Varanasi Junction',
    code: 'BSB',
    city: 'Varanasi',
    state: 'Uttar Pradesh',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Howrah Junction',
    code: 'HWH',
    city: 'Kolkata',
    state: 'West Bengal',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Sealdah',
    code: 'SDAH',
    city: 'Kolkata',
    state: 'West Bengal',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Chennai Central',
    code: 'MAS',
    city: 'Chennai',
    state: 'Tamil Nadu',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'KSR Bengaluru City',
    code: 'SBC',
    city: 'Bengaluru',
    state: 'Karnataka',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Hyderabad Deccan',
    code: 'HYB',
    city: 'Hyderabad',
    state: 'Telangana',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Secunderabad Junction',
    code: 'SC',
    city: 'Hyderabad',
    state: 'Telangana',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Ernakulam Junction',
    code: 'ERS',
    city: 'Kochi',
    state: 'Kerala',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Lucknow Charbagh',
    code: 'LKO',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Bhopal Junction',
    code: 'BPL',
    city: 'Bhopal',
    state: 'Madhya Pradesh',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Chandigarh Junction',
    code: 'CDG',
    city: 'Chandigarh',
    state: 'Chandigarh',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Amritsar Junction',
    code: 'ASR',
    city: 'Amritsar',
    state: 'Punjab',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Patna Junction',
    code: 'PNBE',
    city: 'Patna',
    state: 'Bihar',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Madgaon Junction',
    code: 'MAO',
    city: 'Goa',
    state: 'Goa',
    type: TravelHubType.railwayStation,
  ),
  TravelHub(
    name: 'Mysuru Junction',
    code: 'MYS',
    city: 'Mysuru',
    state: 'Karnataka',
    type: TravelHubType.railwayStation,
  ),
];

const airportTravelHubs = [
  TravelHub(
    name: 'Indira Gandhi International Airport',
    code: 'DEL',
    city: 'Delhi',
    state: 'Delhi',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Chhatrapati Shivaji Maharaj International Airport',
    code: 'BOM',
    city: 'Mumbai',
    state: 'Maharashtra',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Kempegowda International Airport',
    code: 'BLR',
    city: 'Bengaluru',
    state: 'Karnataka',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Rajiv Gandhi International Airport',
    code: 'HYD',
    city: 'Hyderabad',
    state: 'Telangana',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Chennai International Airport',
    code: 'MAA',
    city: 'Chennai',
    state: 'Tamil Nadu',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Netaji Subhas Chandra Bose International Airport',
    code: 'CCU',
    city: 'Kolkata',
    state: 'West Bengal',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Dabolim Airport',
    code: 'GOI',
    city: 'Goa',
    state: 'Goa',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Manohar International Airport',
    code: 'GOX',
    city: 'Goa',
    state: 'Goa',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Jaipur International Airport',
    code: 'JAI',
    city: 'Jaipur',
    state: 'Rajasthan',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Cochin International Airport',
    code: 'COK',
    city: 'Kochi',
    state: 'Kerala',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Sardar Vallabhbhai Patel International Airport',
    code: 'AMD',
    city: 'Ahmedabad',
    state: 'Gujarat',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Pune International Airport',
    code: 'PNQ',
    city: 'Pune',
    state: 'Maharashtra',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Lal Bahadur Shastri International Airport',
    code: 'VNS',
    city: 'Varanasi',
    state: 'Uttar Pradesh',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Chaudhary Charan Singh International Airport',
    code: 'LKO',
    city: 'Lucknow',
    state: 'Uttar Pradesh',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Sri Guru Ram Dass Jee International Airport',
    code: 'ATQ',
    city: 'Amritsar',
    state: 'Punjab',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Chandigarh Airport',
    code: 'IXC',
    city: 'Chandigarh',
    state: 'Chandigarh',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Jay Prakash Narayan Airport',
    code: 'PAT',
    city: 'Patna',
    state: 'Bihar',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Raja Bhoj Airport',
    code: 'BHO',
    city: 'Bhopal',
    state: 'Madhya Pradesh',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Sheikh ul-Alam International Airport',
    code: 'SXR',
    city: 'Srinagar',
    state: 'Jammu and Kashmir',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Kushok Bakula Rimpochee Airport',
    code: 'IXL',
    city: 'Leh',
    state: 'Ladakh',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Biju Patnaik International Airport',
    code: 'BBI',
    city: 'Bhubaneswar',
    state: 'Odisha',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Devi Ahilya Bai Holkar Airport',
    code: 'IDR',
    city: 'Indore',
    state: 'Madhya Pradesh',
    type: TravelHubType.airport,
  ),
  TravelHub(
    name: 'Lokpriya Gopinath Bordoloi International Airport',
    code: 'GAU',
    city: 'Guwahati',
    state: 'Assam',
    type: TravelHubType.airport,
  ),
];

List<TravelHub> travelHubsForMode(TravelTransportMode mode) {
  return switch (mode) {
    TravelTransportMode.train => railwayStationTravelHubs,
    TravelTransportMode.flight => airportTravelHubs,
    _ => const [],
  };
}

TravelHub? travelHubForRouteValue(
  List<TravelHub> hubs,
  String value,
) {
  final normalized = _normalizeHubValue(value);
  if (normalized.isEmpty) return null;
  for (final hub in hubs) {
    final code = hub.code.toLowerCase();
    if (normalized == _normalizeHubValue(hub.routeValue) ||
        normalized == _normalizeHubValue(hub.name) ||
        normalized == code ||
        normalized.contains(' $code ') ||
        normalized.contains(_normalizeHubValue(hub.name))) {
      return hub;
    }
  }
  return null;
}

String _normalizeHubValue(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
