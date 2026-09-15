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
  final double totalEntryFeesInr;
  final double totalRouteDistanceKm;
  final int estimatedTransportFareInr;
  final int totalEstimateInr;

  const TripPlan({
    required this.city,
    required this.days,
    required this.style,
    required this.itinerary,
    this.totalEntryFeesInr = 0,
    this.totalRouteDistanceKm = 0,
    this.estimatedTransportFareInr = 0,
    this.totalEstimateInr = 0,
  });
}

class TripPlanDay {
  final int day;
  final List<TripPlanStop> stops;
  final double entryFeesInr;
  final double routeDistanceKm;
  final int estimatedTransportFareInr;

  const TripPlanDay({
    required this.day,
    required this.stops,
    this.entryFeesInr = 0,
    this.routeDistanceKm = 0,
    this.estimatedTransportFareInr = 0,
  });
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
