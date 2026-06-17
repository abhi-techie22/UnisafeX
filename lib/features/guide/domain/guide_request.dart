import 'dart:convert';

enum GuideRequestStatus {
  pending,
  processing,
  confirmed,
  rejected,
  completed,
}

class GuideRequest {
  final String id;
  final String placeId;
  final String placeName;
  final String city;
  final String? userId;
  final String? userEmail;
  final DateTime requestedAt;
  final DateTime expectedBy;
  final GuideRequestStatus status;
  final int travelers;
  final String contactNote;
  final String? adminNote;
  final String? adminWhatsapp;
  final String? adminEmail;

  const GuideRequest({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.city,
    this.userId,
    this.userEmail,
    required this.requestedAt,
    required this.expectedBy,
    required this.status,
    required this.travelers,
    required this.contactNote,
    this.adminNote,
    this.adminWhatsapp,
    this.adminEmail,
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
      adminWhatsapp: GuideRequestDefaults.adminWhatsapp,
      adminEmail: GuideRequestDefaults.adminEmail,
    );
  }

  factory GuideRequest.fromJson(Map<String, dynamic> json) {
    final requestedAtValue = json['requested_at'] ?? json['requestedAt'];
    final expectedByValue = json['expected_by'] ?? json['expectedBy'];
    final statusValue = json['status']?.toString();
    return GuideRequest(
      id: json['id']?.toString() ?? '',
      placeId: (json['place_id'] ?? json['placeId'])?.toString() ?? '',
      placeName: (json['place_name'] ?? json['placeName'])?.toString() ??
          'Delhi guide request',
      city: json['city']?.toString() ?? 'Delhi',
      userId: (json['user_id'] ?? json['userId'])?.toString(),
      userEmail: (json['user_email'] ?? json['userEmail'])?.toString(),
      requestedAt: DateTime.tryParse(requestedAtValue?.toString() ?? '') ??
          DateTime.now(),
      expectedBy: DateTime.tryParse(expectedByValue?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
      status: GuideRequestStatus.values.firstWhere(
        (value) => value.name == statusValue,
        orElse: () => GuideRequestStatus.processing,
      ),
      travelers: (json['travelers'] as num?)?.toInt() ?? 1,
      contactNote:
          (json['contact_note'] ?? json['contactNote'])?.toString() ?? '',
      adminNote: (json['admin_note'] ?? json['adminNote'])?.toString(),
      adminWhatsapp:
          (json['admin_whatsapp'] ?? json['adminWhatsapp'])?.toString(),
      adminEmail: (json['admin_email'] ?? json['adminEmail'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeId': placeId,
      'placeName': placeName,
      'city': city,
      'userId': userId,
      'userEmail': userEmail,
      'requestedAt': requestedAt.toIso8601String(),
      'expectedBy': expectedBy.toIso8601String(),
      'status': status.name,
      'travelers': travelers,
      'contactNote': contactNote,
      'adminNote': adminNote,
      'adminWhatsapp': adminWhatsapp,
      'adminEmail': adminEmail,
    };
  }

  Map<String, dynamic> toInsertJson({
    required String userId,
    required String? userEmail,
  }) {
    return {
      'user_id': userId,
      'user_email': userEmail,
      'place_id': placeId,
      'place_name': placeName,
      'city': city,
      'travelers': travelers,
      'contact_note': contactNote.isEmpty ? null : contactNote,
      'admin_whatsapp': GuideRequestDefaults.adminWhatsapp,
      'admin_email': GuideRequestDefaults.adminEmail,
    };
  }

  String encode() => jsonEncode(toJson());
}

class GuideRequestDefaults {
  static const adminWhatsapp = '9625119731';
  static const adminWhatsappInternational = '919625119731';
  static const adminEmail = 'abhishek.work962511@gmail.com';
}
