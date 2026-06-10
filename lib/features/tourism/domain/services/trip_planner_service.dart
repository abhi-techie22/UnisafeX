import 'dart:math' as math;

import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/entities/trip_plan.dart';

class TripPlannerService {
  const TripPlannerService();

  TripPlan generate({
    required String city,
    required int days,
    required TravelStyle style,
    required List<TourismPlace> places,
  }) {
    final uniquePlaces = <String, TourismPlace>{};
    for (final place in places.where(
      (place) => place.city.toLowerCase() == city.toLowerCase(),
    )) {
      uniquePlaces.putIfAbsent(place.name.toLowerCase(), () => place);
    }
    final cityPlaces = uniquePlaces.values.toList()
      ..sort((a, b) => _score(b, style).compareTo(_score(a, style)));

    final selected = cityPlaces.take(days * 3).toList();
    final itinerary = <TripPlanDay>[];

    for (var day = 0; day < days; day++) {
      final stops = <TripPlanStop>[];
      for (var index = day * 3;
          index < selected.length && index < (day + 1) * 3;
          index++) {
        final place = selected[index];
        final previous = stops.isEmpty ? null : stops.last.place;
        stops.add(
          TripPlanStop(
            place: place,
            reason: _reason(place, style),
            distanceFromPreviousKm:
                previous == null ? null : _distance(previous, place),
          ),
        );
      }
      itinerary.add(TripPlanDay(day: day + 1, stops: stops));
    }

    return TripPlan(
      city: city,
      days: days,
      style: style,
      itinerary: itinerary,
    );
  }

  double _score(TourismPlace place, TravelStyle style) {
    final fee = place.entryFeeForeigner;
    final styleBoost = switch (style) {
      TravelStyle.budget => fee == 0 ? 2.0 : 1 / (1 + fee / 500),
      TravelStyle.balanced => place.isPopular ? 1.5 : 1,
      TravelStyle.luxury => place.featured ? 2.0 : 1,
    };
    return place.rating * 2 + styleBoost + (place.isPopular ? 1 : 0);
  }

  String _reason(TourismPlace place, TravelStyle style) {
    if (place.isFree && style == TravelStyle.budget) {
      return 'A highly rated experience that keeps the day affordable.';
    }
    if (place.featured) {
      return 'An iconic highlight with strong visitor information.';
    }
    if (place.category == 'Nature') {
      return 'A refreshing change of pace and excellent photo opportunity.';
    }
    if (place.safetyGuidelines.isNotEmpty) {
      return 'Well documented for international visitors and easy to plan.';
    }
    return 'A well-rated stop that adds variety to your day.';
  }

  double _distance(TourismPlace a, TourismPlace b) {
    const radians = math.pi / 180;
    final lat1 = a.latitude * radians;
    final lat2 = b.latitude * radians;
    final dLat = (b.latitude - a.latitude) * radians;
    final dLon = (b.longitude - a.longitude) * radians;
    final value = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 6371 * 2 * math.atan2(math.sqrt(value), math.sqrt(1 - value));
  }
}
