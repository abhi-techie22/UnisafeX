import 'dart:convert';

enum GuideRequestStatus {
  pending,
  processing,
  confirmed,
}

class GuideRequest {
  final String id;
  final String placeId;
  final String placeName;
  final String city;
  final DateTime requestedAt;
  final DateTime expectedBy;
  final GuideRequestStatus status;
  final int travelers;
  final String contactNote;

  const GuideRequest({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.city,
    required this.requestedAt,
    required this.expectedBy,
    required this.status,
    required this.travelers,
    required this.contactNote,
  });

  factory GuideRequest.create({
    required String placeId,
    required String placeName,
    required String city,
    required int travelers,
    required String contactNote,
  }) {
    final now = DateTime.now();
    return GuideRequest(
      id: 'guide-${now.microsecondsSinceEpoch}',
      placeId: placeId,
      placeName: placeName,
      city: city,
      requestedAt: now,
      expectedBy: now.add(const Duration(days: 7)),
      status: GuideRequestStatus.processing,
      travelers: travelers,
      contactNote: contactNote,
    );
  }

  factory GuideRequest.fromJson(Map<String, dynamic> json) {
    return GuideRequest(
      id: json['id']?.toString() ?? '',
      placeId: json['placeId']?.toString() ?? '',
      placeName: json['placeName']?.toString() ?? 'Delhi guide request',
      city: json['city']?.toString() ?? 'Delhi',
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
          DateTime.now(),
      expectedBy: DateTime.tryParse(json['expectedBy']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      status: GuideRequestStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => GuideRequestStatus.processing,
      ),
      travelers: (json['travelers'] as num?)?.toInt() ?? 1,
      contactNote: json['contactNote']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'placeName': placeName,
      'city': city,
      'requestedAt': requestedAt.toIso8601String(),
      'expectedBy': expectedBy.toIso8601String(),
      'status': status.name,
      'travelers': travelers,
      'contactNote': contactNote,
    };
  }

  String encode() => jsonEncode(toJson());
}
