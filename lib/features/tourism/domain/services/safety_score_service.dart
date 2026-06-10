import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

class SafetyScoreService {
  const SafetyScoreService._();

  static int calculate(TourismPlace place) {
    var score = 45;
    score += ((place.rating.clamp(0, 5) / 5) * 25).round();
    if (place.isPopular) score += 10;
    if (place.featured) score += 8;
    if (place.safetyGuidelines.isNotEmpty) score += 8;
    if (place.touristTips.isNotEmpty) score += 4;
    return score.clamp(0, 100);
  }

  static String label(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 55) return 'Moderate';
    return 'Use caution';
  }
}
