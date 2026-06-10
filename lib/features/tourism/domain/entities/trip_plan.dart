import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';

enum TravelStyle { budget, balanced, luxury }

extension TravelStyleLabel on TravelStyle {
  String get label => switch (this) {
        TravelStyle.budget => 'Budget',
        TravelStyle.balanced => 'Balanced',
        TravelStyle.luxury => 'Luxury',
      };
}

class TripPlan {
  final String city;
  final int days;
  final TravelStyle style;
  final List<TripPlanDay> itinerary;

  const TripPlan({
    required this.city,
    required this.days,
    required this.style,
    required this.itinerary,
  });
}

class TripPlanDay {
  final int day;
  final List<TripPlanStop> stops;

  const TripPlanDay({required this.day, required this.stops});
}

class TripPlanStop {
  final TourismPlace place;
  final String reason;
  final double? distanceFromPreviousKm;

  const TripPlanStop({
    required this.place,
    required this.reason,
    this.distanceFromPreviousKm,
  });
}
