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
  final String? guideName;
  final String? guideProfileId;
  final String? guidePhotoUrl;
  final String? guidePhone;
  final String? guideLanguages;
  final int? guideExperienceYears;
  final String? guideBio;
  final double? guideChargeAmount;
  final String? guideChargeCurrency;
  final String? guideMeetingPoint;
  final String bookingStatus;
  final DateTime? bookedAt;

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
    this.guideName,
    this.guideProfileId,
    this.guidePhotoUrl,
    this.guidePhone,
    this.guideLanguages,
    this.guideExperienceYears,
    this.guideBio,
    this.guideChargeAmount,
    this.guideChargeCurrency,
    this.guideMeetingPoint,
    this.bookingStatus = 'not_booked',
    this.bookedAt,
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
      bookingStatus: 'not_booked',
    );
  }

  factory GuideRequest.fromJson(Map<String, dynamic> json) {
    final requestedAtValue = json['requested_at'] ?? json['requestedAt'];
    final expectedByValue = json['expected_by'] ?? json['expectedBy'];
    final bookedAtValue = json['booked_at'] ?? json['bookedAt'];
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
      guideName: (json['guide_name'] ?? json['guideName'])?.toString(),
      guideProfileId:
          (json['guide_profile_id'] ?? json['guideProfileId'])?.toString(),
      guidePhotoUrl:
          (json['guide_photo_url'] ?? json['guidePhotoUrl'])?.toString(),
      guidePhone: (json['guide_phone'] ?? json['guidePhone'])?.toString(),
      guideLanguages:
          (json['guide_languages'] ?? json['guideLanguages'])?.toString(),
      guideExperienceYears: ((json['guide_experience_years'] ??
              json['guideExperienceYears']) as num?)
          ?.toInt(),
      guideBio: (json['guide_bio'] ?? json['guideBio'])?.toString(),
      guideChargeAmount:
          ((json['guide_charge_amount'] ?? json['guideChargeAmount']) as num?)
              ?.toDouble(),
      guideChargeCurrency:
          (json['guide_charge_currency'] ?? json['guideChargeCurrency'])
              ?.toString(),
      guideMeetingPoint:
          (json['guide_meeting_point'] ?? json['guideMeetingPoint'])
              ?.toString(),
      bookingStatus:
          (json['booking_status'] ?? json['bookingStatus'])?.toString() ??
              'not_booked',
      bookedAt: DateTime.tryParse(bookedAtValue?.toString() ?? ''),
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
      'guideName': guideName,
      'guideProfileId': guideProfileId,
      'guidePhotoUrl': guidePhotoUrl,
      'guidePhone': guidePhone,
      'guideLanguages': guideLanguages,
      'guideExperienceYears': guideExperienceYears,
      'guideBio': guideBio,
      'guideChargeAmount': guideChargeAmount,
      'guideChargeCurrency': guideChargeCurrency,
      'guideMeetingPoint': guideMeetingPoint,
      'bookingStatus': bookingStatus,
      'bookedAt': bookedAt?.toIso8601String(),
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

  bool get hasAssignedGuide =>
      guideName?.trim().isNotEmpty == true &&
      guideChargeAmount != null &&
      guideChargeAmount! > 0;

  bool get canBook =>
      status == GuideRequestStatus.confirmed &&
      hasAssignedGuide &&
      bookingStatus != 'booked';

  String get formattedGuideCharge {
    final amount = guideChargeAmount;
    if (amount == null) return 'Charges pending';
    final currency = guideChargeCurrency?.trim().isNotEmpty == true
        ? guideChargeCurrency!.trim()
        : 'INR';
    final pretty = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$currency $pretty';
  }
}

class GuideRequestDefaults {
  static const adminWhatsapp = '9625119731';
  static const adminWhatsappInternational = '919625119731';
  static const adminEmail = 'abhishek.work962511@gmail.com';
}

class GuideProfile {
  final String id;
  final String name;
  final String? photoUrl;
  final String? phone;
  final String? languages;
  final int? experienceYears;
  final String? bio;
  final double? chargeAmount;
  final String chargeCurrency;
  final String? meetingPoint;
  final bool isActive;

  const GuideProfile({
    required this.id,
    required this.name,
    this.photoUrl,
    this.phone,
    this.languages,
    this.experienceYears,
    this.bio,
    this.chargeAmount,
    this.chargeCurrency = 'INR',
    this.meetingPoint,
    this.isActive = true,
  });

  factory GuideProfile.fromJson(Map<String, dynamic> json) {
    return GuideProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Guide',
      photoUrl: json['photo_url']?.toString(),
      phone: json['phone']?.toString(),
      languages: json['languages']?.toString(),
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      bio: json['bio']?.toString(),
      chargeAmount: (json['charge_amount'] as num?)?.toDouble(),
      chargeCurrency: json['charge_currency']?.toString() ?? 'INR',
      meetingPoint: json['meeting_point']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toRequestUpdateJson() {
    return {
      'guide_profile_id': id,
      'guide_name': name,
      'guide_photo_url': photoUrl,
      'guide_phone': phone,
      'guide_languages': languages,
      'guide_experience_years': experienceYears,
      'guide_bio': bio,
      'guide_charge_amount': chargeAmount,
      'guide_charge_currency': chargeCurrency,
      'guide_meeting_point': meetingPoint,
    };
  }

  String get formattedCharge {
    final amount = chargeAmount;
    if (amount == null) return 'Charges pending';
    final pretty = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$chargeCurrency $pretty';
  }
}
