import 'package:unisafex/features/profile/domain/entities/user_profile.dart';

int profileCompletionPercent(UserProfile? profile) {
  if (profile == null) return 0;

  final checks = [
    profile.fullName?.trim().isNotEmpty == true,
    profile.nationality?.trim().isNotEmpty == true,
    profile.country?.trim().isNotEmpty == true,
    profile.currentLocation?.trim().isNotEmpty == true,
    profile.passportCountry?.trim().isNotEmpty == true,
    profile.visaType?.trim().isNotEmpty == true,
    profile.visaExpiry != null,
    profile.travelPurpose?.trim().isNotEmpty == true,
    profile.profileImageUrl?.trim().isNotEmpty == true,
  ];

  final completed = checks.where((value) => value).length;
  return ((completed / checks.length) * 100).round();
}
