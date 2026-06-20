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

    final selected = _balancedSelection(cityPlaces, days * 3);
    final itinerary = <TripPlanDay>[];

    for (var day = 0; day < days; day++) {
      final stops = <TripPlanStop>[];
      final remaining = selected.skip(day * 3).take(3).toList();
      final dayPlaces = _routeOrder(remaining);
      for (final place in dayPlaces) {
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

  List<TourismPlace> _balancedSelection(
    List<TourismPlace> places,
    int count,
  ) {
    final selected = <TourismPlace>[];
    final usedCategories = <String, int>{};

    for (final place in places) {
      if (selected.length >= count) break;
      final categoryUses = usedCategories[place.category] ?? 0;
      final hasRoomForCategory =
          categoryUses < 2 || selected.length > count / 2;
      if (!hasRoomForCategory) continue;
      selected.add(place);
      usedCategories[place.category] = categoryUses + 1;
    }

    if (selected.length < count) {
      for (final place in places) {
        if (selected.length >= count) break;
        if (selected.any((item) => item.id == place.id)) continue;
        selected.add(place);
      }
    }

    return selected;
  }

  List<TourismPlace> _routeOrder(List<TourismPlace> places) {
    if (places.length <= 2) return places;
    final remaining = [...places];
    remaining.sort((a, b) => b.rating.compareTo(a.rating));
    final ordered = <TourismPlace>[remaining.removeAt(0)];
    while (remaining.isNotEmpty) {
      remaining.sort(
        (a, b) => _distance(ordered.last, a).compareTo(
          _distance(ordered.last, b),
        ),
      );
      ordered.add(remaining.removeAt(0));
    }
    return ordered;
  }

  double _score(TourismPlace place, TravelStyle style) {
    final fee = place.entryFeeForeigner;
    final styleBoost = switch (style) {
      TravelStyle.budget => fee == 0 ? 2.0 : 1 / (1 + fee / 500),
      TravelStyle.balanced => place.isPopular ? 1.5 : 1,
      TravelStyle.luxury => place.featured ? 2.0 : 1,
    };
    final detailBoost = [
      place.timings?.isNotEmpty == true,
      place.bestSeason?.isNotEmpty == true,
      place.safetyGuidelines.isNotEmpty,
      place.touristTips.isNotEmpty,
      place.visitDurationMinutes != null,
      place.latitude != 0 && place.longitude != 0,
    ].where((value) => value).length;
    return place.rating * 2 +
        styleBoost +
        detailBoost * 0.35 +
        (place.isPopular ? 1 : 0) +
        (place.featured ? 0.8 : 0) +
        (place.likesCount / 100000).clamp(0, 1);
  }

  String _reason(TourismPlace place, TravelStyle style) {
    if (place.isFree && style == TravelStyle.budget) {
      return 'Free entry keeps this day affordable, and the app has enough '
          'visitor details to plan it with confidence.';
    }
    if (place.featured) {
      return 'A featured UniSafeX highlight with strong visitor information.';
    }
    if (place.category == 'Nature') {
      return 'A refreshing change of pace with strong photo value.';
    }
    if (place.safetyGuidelines.isNotEmpty) {
      return 'Well documented for international visitors and easy to plan.';
    }
    if (place.bestSeason?.isNotEmpty == true) {
      return 'Good seasonal information makes this stop easier to schedule.';
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
