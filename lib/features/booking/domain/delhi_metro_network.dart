import 'dart:collection';

import 'package:flutter/material.dart';

class DelhiMetroLine {
  const DelhiMetroLine({
    required this.id,
    required this.name,
    required this.color,
    required this.stations,
  });

  final String id;
  final String name;
  final Color color;
  final List<String> stations;
}

class DelhiMetroRouteLeg {
  const DelhiMetroRouteLeg({
    required this.line,
    required this.fromStation,
    required this.toStation,
    required this.stationCount,
  });

  final DelhiMetroLine line;
  final String fromStation;
  final String toStation;
  final int stationCount;
}

class DelhiMetroRoutePlan {
  const DelhiMetroRoutePlan({
    required this.fromStation,
    required this.toStation,
    required this.legs,
    required this.interchanges,
    required this.totalStations,
  });

  final String fromStation;
  final String toStation;
  final List<DelhiMetroRouteLeg> legs;
  final List<String> interchanges;
  final int totalStations;

  bool get isDirect => interchanges.isEmpty;
}

class _DelhiMetroEdge {
  const _DelhiMetroEdge({
    required this.from,
    required this.to,
    required this.line,
  });

  final String from;
  final String to;
  final DelhiMetroLine line;
}

const delhiMetroLines = [
  DelhiMetroLine(
    id: 'red',
    name: 'Red Line',
    color: Color(0xFFC62828),
    stations: [
      'Rithala',
      'Rohini West',
      'Netaji Subhash Place',
      'Shastri Nagar',
      'Inderlok',
      'Kashmere Gate',
      'Tis Hazari',
      'Pul Bangash',
      'Pratap Nagar',
      'Shastri Park',
      'Shahdara',
      'Dilshad Garden',
      'Shaheed Sthal',
    ],
  ),
  DelhiMetroLine(
    id: 'yellow',
    name: 'Yellow Line',
    color: Color(0xFFF4C430),
    stations: [
      'Samaypur Badli',
      'Rohini Sector 18-19',
      'Haiderpur Badli Mor',
      'Jahangirpuri',
      'Azadpur',
      'Model Town',
      'GTB Nagar',
      'Vishwavidyalaya',
      'Vidhan Sabha',
      'Civil Lines',
      'Kashmere Gate',
      'Chandni Chowk',
      'Chawri Bazar',
      'New Delhi',
      'Rajiv Chowk',
      'Patel Chowk',
      'Central Secretariat',
      'Udyog Bhawan',
      'Lok Kalyan Marg',
      'Jor Bagh',
      'INA',
      'AIIMS',
      'Green Park',
      'Hauz Khas',
      'Malviya Nagar',
      'Saket',
      'Qutub Minar',
      'Chhatarpur',
      'Sultanpur',
      'Ghitorni',
      'Arjan Garh',
      'Guru Dronacharya',
      'Sikandarpur',
      'MG Road',
      'IFFCO Chowk',
      'Millennium City Centre Gurugram',
    ],
  ),
  DelhiMetroLine(
    id: 'blue',
    name: 'Blue Line',
    color: Color(0xFF1565C0),
    stations: [
      'Dwarka Sector 21',
      'Dwarka Sector 8',
      'Dwarka Sector 9',
      'Dwarka Sector 10',
      'Dwarka Sector 11',
      'Dwarka Sector 12',
      'Dwarka Sector 13',
      'Dwarka Sector 14',
      'Dwarka',
      'Dwarka Mor',
      'Nawada',
      'Uttam Nagar West',
      'Uttam Nagar East',
      'Janakpuri West',
      'Janakpuri East',
      'Tilak Nagar',
      'Subhash Nagar',
      'Tagore Garden',
      'Rajouri Garden',
      'Ramesh Nagar',
      'Moti Nagar',
      'Kirti Nagar',
      'Shadipur',
      'Patel Nagar',
      'Rajendra Place',
      'Karol Bagh',
      'Jhandewalan',
      'RK Ashram Marg',
      'Rajiv Chowk',
      'Barakhamba Road',
      'Mandi House',
      'Supreme Court',
      'Indraprastha',
      'Yamuna Bank',
      'Akshardham',
      'Mayur Vihar Phase-1',
      'Mayur Vihar Extension',
      'New Ashok Nagar',
      'Noida Sector 15',
      'Noida Sector 16',
      'Noida Sector 18',
      'Botanical Garden',
      'Golf Course',
      'Noida City Centre',
      'Noida Sector 34',
      'Noida Sector 52',
      'Noida Sector 61',
      'Noida Sector 59',
      'Noida Sector 62',
      'Noida Electronic City',
    ],
  ),
  DelhiMetroLine(
    id: 'blue_branch',
    name: 'Blue Branch',
    color: Color(0xFF1976D2),
    stations: [
      'Yamuna Bank',
      'Laxmi Nagar',
      'Nirman Vihar',
      'Preet Vihar',
      'Karkarduma',
      'Anand Vihar ISBT',
      'Kaushambi',
      'Vaishali',
    ],
  ),
  DelhiMetroLine(
    id: 'green',
    name: 'Green Line',
    color: Color(0xFF2E7D32),
    stations: [
      'Inderlok',
      'Ashok Park Main',
      'Punjabi Bagh West',
      'Shivaji Park',
      'Madipur',
      'Paschim Vihar East',
      'Paschim Vihar West',
      'Peeragarhi',
      'Udyog Nagar',
      'Surajmal Stadium',
      'Nangloi',
      'Nangloi Railway Station',
      'Rajdhani Park',
      'Mundka',
      'Mundka Industrial Area',
      'Ghevra',
      'Tikri Kalan',
      'Tikri Border',
      'Pandit Shree Ram Sharma',
      'Bahadurgarh City',
      'Brigadier Hoshiyar Singh',
    ],
  ),
  DelhiMetroLine(
    id: 'green_branch',
    name: 'Green Branch',
    color: Color(0xFF43A047),
    stations: [
      'Ashok Park Main',
      'Satguru Ram Singh Marg',
      'Kirti Nagar',
    ],
  ),
  DelhiMetroLine(
    id: 'violet',
    name: 'Violet Line',
    color: Color(0xFF7B1FA2),
    stations: [
      'Kashmere Gate',
      'Lal Quila',
      'Jama Masjid',
      'Delhi Gate',
      'ITO',
      'Mandi House',
      'Janpath',
      'Central Secretariat',
      'Khan Market',
      'Jawaharlal Nehru Stadium',
      'Jangpura',
      'Lajpat Nagar',
      'Moolchand',
      'Kailash Colony',
      'Nehru Place',
      'Kalkaji Mandir',
      'Govind Puri',
      'Harkesh Nagar Okhla',
      'Jasola Apollo',
      'Sarita Vihar',
      'Mohan Estate',
      'Tughlakabad',
      'Badarpur Border',
      'Sarai',
      'NHPC Chowk',
      'Mewala Maharajpur',
      'Sector 28',
      'Badkal Mor',
      'Old Faridabad',
      'Neelam Chowk Ajronda',
      'Bata Chowk',
      'Escorts Mujesar',
      'Sant Surdas',
      'Raja Nahar Singh Ballabhgarh',
    ],
  ),
  DelhiMetroLine(
    id: 'pink',
    name: 'Pink Line',
    color: Color(0xFFE91E63),
    stations: [
      'Majlis Park',
      'Azadpur',
      'Shalimar Bagh',
      'Netaji Subhash Place',
      'Shakurpur',
      'Punjabi Bagh West',
      'ESI Hospital',
      'Rajouri Garden',
      'Mayapuri',
      'Naraina Vihar',
      'Delhi Cantt',
      'Durgabai Deshmukh South Campus',
      'Sir Vishweshwaraiah Moti Bagh',
      'Bhikaji Cama Place',
      'Sarojini Nagar',
      'INA',
      'South Extension',
      'Lajpat Nagar',
      'Vinobapuri',
      'Ashram',
      'Sarai Kale Khan Nizamuddin',
      'Mayur Vihar Phase-1',
      'Mayur Vihar Pocket 1',
      'Trilokpuri Sanjay Lake',
      'East Vinod Nagar Mayur Vihar-II',
      'Mandawali West Vinod Nagar',
      'IP Extension',
      'Anand Vihar ISBT',
      'Karkarduma',
      'Karkarduma Court',
      'Krishna Nagar',
      'East Azad Nagar',
      'Welcome',
      'Jafrabad',
      'Maujpur Babarpur',
      'Gokulpuri',
      'Johri Enclave',
      'Shiv Vihar',
    ],
  ),
  DelhiMetroLine(
    id: 'magenta',
    name: 'Magenta Line',
    color: Color(0xFFD81B60),
    stations: [
      'Janakpuri West',
      'Dabri Mor Janakpuri South',
      'Dashrath Puri',
      'Palam',
      'Sadar Bazaar Cantonment',
      'Terminal 1 IGI Airport',
      'Shankar Vihar',
      'Vasant Vihar',
      'Munirka',
      'RK Puram',
      'IIT Delhi',
      'Hauz Khas',
      'Panchsheel Park',
      'Chirag Delhi',
      'Greater Kailash',
      'Nehru Enclave',
      'Kalkaji Mandir',
      'Okhla NSIC',
      'Sukhdev Vihar',
      'Jamia Millia Islamia',
      'Okhla Vihar',
      'Jasola Vihar Shaheen Bagh',
      'Kalindi Kunj',
      'Okhla Bird Sanctuary',
      'Botanical Garden',
    ],
  ),
  DelhiMetroLine(
    id: 'grey',
    name: 'Grey Line',
    color: Color(0xFF757575),
    stations: [
      'Dwarka',
      'Nangli',
      'Najafgarh',
      'Dhansa Bus Stand',
    ],
  ),
  DelhiMetroLine(
    id: 'airport',
    name: 'Airport Express',
    color: Color(0xFFFF9800),
    stations: [
      'New Delhi',
      'Shivaji Stadium',
      'Dhaula Kuan',
      'Delhi Aerocity',
      'Airport (T-3)',
      'Dwarka Sector 21',
      'Yashobhoomi Dwarka Sector 25',
    ],
  ),
];

List<String> get delhiMetroStationNames {
  final names = <String>{};
  for (final line in delhiMetroLines) {
    names.addAll(line.stations);
  }
  return names.toList()..sort();
}

DelhiMetroLine delhiMetroLineById(String id) {
  return delhiMetroLines.firstWhere(
    (line) => line.id == id,
    orElse: () => delhiMetroLines.first,
  );
}

List<DelhiMetroLine> delhiMetroLinesForStation(String stationName) {
  final station = _stationLookup()[_normalizeStation(stationName)];
  if (station == null) return const [];
  return delhiMetroLines
      .where((line) => line.stations.contains(station))
      .toList(growable: false);
}

DelhiMetroRoutePlan? buildDelhiMetroRoutePlan({
  required String origin,
  required String destination,
}) {
  final lookup = _stationLookup();
  final fromStation = lookup[_normalizeStation(origin)];
  final toStation = lookup[_normalizeStation(destination)];
  if (fromStation == null || toStation == null) return null;
  if (fromStation == toStation) {
    return DelhiMetroRoutePlan(
      fromStation: fromStation,
      toStation: toStation,
      legs: const [],
      interchanges: const [],
      totalStations: 0,
    );
  }

  final graph = _stationGraph();
  final queue = Queue<String>()..add(fromStation);
  final visited = <String>{fromStation};
  final previousStation = <String, String>{};
  final previousLine = <String, DelhiMetroLine>{};

  while (queue.isNotEmpty) {
    final station = queue.removeFirst();
    if (station == toStation) break;
    for (final edge in graph[station] ?? const <_DelhiMetroEdge>[]) {
      if (!visited.add(edge.to)) continue;
      previousStation[edge.to] = station;
      previousLine[edge.to] = edge.line;
      queue.add(edge.to);
    }
  }

  if (!previousStation.containsKey(toStation)) return null;

  final reversedEdges = <_DelhiMetroEdge>[];
  var current = toStation;
  while (current != fromStation) {
    final previous = previousStation[current]!;
    final line = previousLine[current]!;
    reversedEdges.add(
      _DelhiMetroEdge(from: previous, to: current, line: line),
    );
    current = previous;
  }
  final edges = reversedEdges.reversed.toList(growable: false);
  if (edges.isEmpty) return null;

  final legs = <DelhiMetroRouteLeg>[];
  final interchanges = <String>[];
  var legLine = edges.first.line;
  var legStart = fromStation;
  var stationCount = 0;

  for (final edge in edges) {
    if (edge.line.id != legLine.id) {
      legs.add(
        DelhiMetroRouteLeg(
          line: legLine,
          fromStation: legStart,
          toStation: edge.from,
          stationCount: stationCount,
        ),
      );
      interchanges.add(edge.from);
      legLine = edge.line;
      legStart = edge.from;
      stationCount = 0;
    }
    stationCount += 1;
  }
  legs.add(
    DelhiMetroRouteLeg(
      line: legLine,
      fromStation: legStart,
      toStation: toStation,
      stationCount: stationCount,
    ),
  );

  return DelhiMetroRoutePlan(
    fromStation: fromStation,
    toStation: toStation,
    legs: legs,
    interchanges: interchanges,
    totalStations: edges.length,
  );
}

Map<String, String> _stationLookup() {
  final lookup = <String, String>{};
  for (final line in delhiMetroLines) {
    for (final station in line.stations) {
      lookup[_normalizeStation(station)] = station;
    }
  }
  lookup['huda city centre'] = 'Millennium City Centre Gurugram';
  lookup['huda city center'] = 'Millennium City Centre Gurugram';
  lookup['airport t3'] = 'Airport (T-3)';
  lookup['igi airport t3'] = 'Airport (T-3)';
  lookup['cp'] = 'Rajiv Chowk';
  lookup['connaught place'] = 'Rajiv Chowk';
  return lookup;
}

Map<String, List<_DelhiMetroEdge>> _stationGraph() {
  final graph = <String, List<_DelhiMetroEdge>>{};
  for (final line in delhiMetroLines) {
    for (var index = 0; index < line.stations.length - 1; index += 1) {
      final from = line.stations[index];
      final to = line.stations[index + 1];
      graph.putIfAbsent(from, () => []).add(
            _DelhiMetroEdge(from: from, to: to, line: line),
          );
      graph.putIfAbsent(to, () => []).add(
            _DelhiMetroEdge(from: to, to: from, line: line),
          );
    }
  }
  return graph;
}

String _normalizeStation(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
