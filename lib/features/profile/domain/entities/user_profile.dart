import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String userId;
  final String? fullName;
  final String? gender;
  final String? nationality;
  final String? country;
  final String? countryCode;
  final String? currentLocation;
  final String? passportCountry;
  final String? visaType;
  final DateTime? visaExpiry;
  final String? travelPurpose;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isProfileComplete;

  const UserProfile({
    required this.userId,
    this.fullName,
    this.gender,
    this.nationality,
    this.country,
    this.countryCode,
    this.currentLocation,
    this.passportCountry,
    this.visaType,
    this.visaExpiry,
    this.travelPurpose,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
    this.isProfileComplete = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      nationality: json['nationality'] as String?,
      country: json['country'] as String?,
      countryCode: json['country_code'] as String?,
      currentLocation: json['current_location'] as String?,
      passportCountry: json['passport_country'] as String?,
      visaType: json['visa_type'] as String?,
      visaExpiry: json['visa_expiry'] != null
          ? DateTime.tryParse(json['visa_expiry'] as String)
          : null,
      travelPurpose: json['travel_purpose'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'gender': gender,
      'nationality': nationality,
      'country': country,
      'country_code': countryCode,
      'current_location': currentLocation,
      'passport_country': passportCountry,
      'visa_type': visaType,
      'visa_expiry': visaExpiry?.toIso8601String().split('T').first,
      'travel_purpose': travelPurpose,
      'profile_image_url': profileImageUrl,
      'is_profile_complete': isProfileComplete,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? gender,
    String? nationality,
    String? country,
    String? countryCode,
    String? currentLocation,
    String? passportCountry,
    String? visaType,
    DateTime? visaExpiry,
    String? travelPurpose,
    String? profileImageUrl,
    bool? isProfileComplete,
  }) {
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      currentLocation: currentLocation ?? this.currentLocation,
      passportCountry: passportCountry ?? this.passportCountry,
      visaType: visaType ?? this.visaType,
      visaExpiry: visaExpiry ?? this.visaExpiry,
      travelPurpose: travelPurpose ?? this.travelPurpose,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  String get displayName => fullName ?? 'Traveler';

  String get initials {
    if (fullName == null || fullName!.isEmpty) return 'T';
    final parts = fullName!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName![0].toUpperCase();
  }

  @override
  List<Object?> get props => [userId];
}
