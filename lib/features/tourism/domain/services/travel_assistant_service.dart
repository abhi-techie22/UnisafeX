import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/entities/trip_plan.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';
import 'package:unisafex/features/tourism/domain/services/trip_planner_service.dart';

class TravelAssistantReply {
  const TravelAssistantReply({
    required this.text,
    this.places = const [],
  });

  final String text;
  final List<TourismPlace> places;
}

class TravelAssistantService {
  const TravelAssistantService();

  TravelAssistantReply answer(
    String question,
    List<TourismPlace> allPlaces,
  ) {
    final query = question.toLowerCase().trim();
    if (allPlaces.isEmpty) {
      return const TravelAssistantReply(
        text: 'I cannot access destination data right now. Please try again '
            'when you are online.',
      );
    }

    final city = _findCity(query, allPlaces);
    final requestedLocation = _requestedLocation(query);
    final place = _findPlace(query, allPlaces);
    final scoped = _scopedPlaces(city, allPlaces);
    final category = _findCategory(query, allPlaces);

    if (_containsAny(query, ['emergency', 'police', 'ambulance', 'danger'])) {
      return const TravelAssistantReply(
        text: 'For an immediate emergency in India, call 112. For police call '
            '100, ambulance 108, and the tourist helpline 1363. Move to a '
            'well-lit public place and share your live location with someone '
            'you trust. Keep your hotel address, passport copy, and live map '
            'location ready before moving.',
      );
    }

    if (place != null &&
        _containsAny(query, ['summarize', 'about', 'details', 'explain'])) {
      return TravelAssistantReply(
        text: _placeBrief(place),
        places: [place],
      );
    }

    if (_containsAny(query, ['scam', 'overcharge', 'fraud', 'avoid'])) {
      return const TravelAssistantReply(
        text: 'Common tourist risk points in India are unofficial guides, '
            'overpriced taxis, fake “closed today” claims, and cash-only ticket '
            'pressure. Use official counters, registered transport, digital '
            'payments where possible, and verify opening times before leaving.',
      );
    }

    if (_containsAny(query, ['hidden gem', 'less crowded', 'quiet'])) {
      final gems = scoped.where((item) => item.isHiddenGem).take(5).toList();
      if (gems.isNotEmpty) {
        return TravelAssistantReply(
          text:
              'Less-crowded UniSafeX picks${city == null ? '' : ' in $city'}: '
              '${gems.map((item) => item.name).join(', ')}. Visit in daylight, '
              'pre-book transport, and check local conditions before choosing '
              'a very quiet site.',
          places: gems,
        );
      }
    }

    if (_containsAny(query, ['photo', 'photography', 'instagram', 'view'])) {
      final picks = scoped
          .where(
              (item) => item.images.isNotEmpty || item.primaryImage.isNotEmpty)
          .take(5)
          .toList();
      if (picks.isNotEmpty) {
        return TravelAssistantReply(
          text: 'Most photo-ready UniSafeX picks'
              '${city == null ? '' : ' in $city'} are '
              '${picks.map((item) => item.name).join(', ')}. Go early for '
              'softer light, keep valuables zipped, and check whether camera '
              'fees apply at ticketed monuments.',
          places: picks,
        );
      }
    }

    if (_containsAny(query, ['family', 'kids', 'children', 'elderly'])) {
      final familyPicks = [...scoped]..sort((a, b) {
          final aScore = _familyScore(a);
          final bScore = _familyScore(b);
          return bScore.compareTo(aScore);
        });
      final picks = familyPicks.take(4).toList();
      if (picks.isNotEmpty) {
        return TravelAssistantReply(
          text: 'Family-friendly picks${city == null ? '' : ' in $city'}: '
              '${picks.map((item) => item.name).join(', ')}. I prioritized '
              'shorter visits, clear timings, safety notes, and well-known '
              'locations. Keep water, sun protection, and transport booked for '
              'the return journey.',
          places: picks,
        );
      }
    }

    if (_containsAny(query, ['open now', 'today', 'currently open'])) {
      final openPicks =
          scoped.where((item) => item.isLikelyOpenNow).take(4).toList();
      if (openPicks.isNotEmpty) {
        return TravelAssistantReply(
          text: 'Places that look practical for a visit today'
              '${city == null ? '' : ' in $city'}: '
              '${openPicks.map((item) => item.name).join(', ')}. Timings are '
              'a planning signal, so confirm once before leaving.',
          places: openPicks,
        );
      }
    }

    if (category != null &&
        _containsAny(query, ['best', 'top', 'recommend', 'show', 'find'])) {
      final picks =
          scoped.where((item) => item.category == category).take(5).toList();
      if (picks.isNotEmpty) {
        return TravelAssistantReply(
          text: 'Best $category places${city == null ? '' : ' in $city'} from '
              'UniSafeX are ${picks.map((item) => item.name).join(', ')}. '
              'I ranked them by rating, popularity and available visitor data.',
          places: picks,
        );
      }
    }

    if (_containsAny(query, ['taxi', 'metro', 'transport', 'cab', 'uber'])) {
      final target = place ?? (scoped.isNotEmpty ? scoped.first : null);
      return TravelAssistantReply(
        text: target == null
            ? 'For city travel, prefer metro where available, prepaid airport '
                'taxis, hotel-arranged cabs, or trusted ride-hailing apps. '
                'Share your live location during late travel.'
            : 'For ${target.name}, plan transport before you leave. Prefer '
                'metro/prepaid taxi/trusted ride-hailing where available, and '
                'open the map card for coordinates and route distance.',
        places: target == null ? const [] : [target],
      );
    }

    if (_containsAny(
        query, ['hotel', 'stay', 'accommodation', 'nearby hotel'])) {
      final picks = scoped.take(3).toList();
      return TravelAssistantReply(
        text: 'Hotel booking is not connected to a live partner API yet. For '
            'now, choose stays near well-connected areas, check recent foreign '
            'traveler reviews, confirm passport/visa check-in rules, and keep '
            'your first night flexible. I can still shortlist safe destination '
            'areas from UniSafeX data.',
        places: picks,
      );
    }

    if (_containsAny(query, ['food', 'eat', 'restaurant', 'water'])) {
      return const TravelAssistantReply(
        text: 'For food safety, prefer busy restaurants, sealed bottled water, '
            'freshly cooked meals, and card/UPI-friendly places. Be careful '
            'with raw salads, ice, and very spicy street food on your first day.',
      );
    }

    if (place != null &&
        _containsAny(query, ['fee', 'cost', 'price', 'ticket'])) {
      return TravelAssistantReply(
        text: place.isFree
            ? '${place.name} is listed as free entry. Carry identification and '
                'check for any separate camera or activity charges.'
            : 'The listed foreign visitor entry fee for ${place.name} is '
                '${place.formattedEntryFee}. Prices can change, so confirm at '
                'the official counter before visiting.',
        places: [place],
      );
    }

    if (_containsAny(
      query,
      [
        'total cost',
        'total estimate',
        'cost estimate',
        'travel cost',
        'estimate',
        'fare',
        'expense',
      ],
    )) {
      final count = (_extractDays(query) ?? 2).clamp(1, 5);
      final planCity =
          city ?? place?.city ?? (scoped.isNotEmpty ? scoped.first.city : null);
      if (planCity != null) {
        final style = _styleFromQuery(query);
        final plan = const TripPlannerService().generate(
          city: planCity,
          days: count,
          style: style,
          places: allPlaces,
        );
        final picks = plan.itinerary
            .expand((day) => day.stops)
            .map((stop) => stop.place)
            .toList();
        return TravelAssistantReply(
          text: 'Estimated ${style.label.toLowerCase()} cost for $count day'
              '${count == 1 ? '' : 's'} in $planCity: '
              '${_money(plan.totalEstimateInr)}. Entry fees are about '
              '${_money(plan.totalEntryFeesInr)}, and local travel between '
              'planned stops is about ${_money(plan.estimatedTransportFareInr)}. '
              'Food, hotels, shopping, surge pricing, guide fees, and airport '
              'transfers are not included.',
          places: picks.take(4).toList(),
        );
      }
    }

    if (place != null &&
        _containsAny(query, ['time', 'open', 'close', 'timing'])) {
      return TravelAssistantReply(
        text: '${place.name} timings: ${place.timings ?? 'not available'}. '
            'Allow ${_duration(place.visitDurationMinutes)} for the visit.',
        places: [place],
      );
    }

    if (_containsAny(
      query,
      ['safe', 'safety', 'night', 'woman', 'women', 'solo'],
    )) {
      final ranked = [...scoped]..sort(
          (a, b) => SafetyScoreService.calculate(b)
              .compareTo(SafetyScoreService.calculate(a)),
        );
      final recommendations = ranked.take(3).toList();
      final location = city ?? 'these destinations';
      final names = recommendations.map((item) => item.name).join(', ');
      return TravelAssistantReply(
        text: 'For $location, the strongest safety-aware options in UniSafeX '
            'are $names. Prefer daylight visits, use registered transport, '
            'avoid isolated areas after dark, and call 112 in an emergency. '
            'Safety scores are guidance, not a guarantee.\n\n'
            '${_safetyChecklist()}',
        places: recommendations,
      );
    }

    if (_containsAny(query, ['compare', 'vs', 'versus', 'better'])) {
      final candidates = allPlaces
          .where((item) => query.contains(item.name.toLowerCase()))
          .take(2)
          .toList();
      if (candidates.length >= 2) {
        final a = candidates[0];
        final b = candidates[1];
        return TravelAssistantReply(
          text: '${a.name} is better for ${a.category.toLowerCase()} lovers, '
              '${a.formattedEntryFee} entry, and about '
              '${_duration(a.visitDurationMinutes)}. ${b.name} is better for '
              '${b.category.toLowerCase()} interest, ${b.formattedEntryFee} '
              'entry, and about ${_duration(b.visitDurationMinutes)}. Choose '
              'the higher safety-score place for a first solo visit.',
          places: candidates,
        );
      }
    }

    if (_containsAny(query, ['best time', 'season', 'month', 'weather'])) {
      final target = place ?? (scoped.isNotEmpty ? scoped.first : null);
      if (target != null) {
        final months = target.bestMonths.isEmpty
            ? ''
            : ' Recommended months: ${target.bestMonths.join(', ')}.';
        return TravelAssistantReply(
          text: 'The best time listed for ${target.name} is '
              '${target.bestSeason ?? 'the cooler, drier months'}.$months',
          places: [target],
        );
      }
    }

    if (_containsAny(query, ['free', 'no entry fee', 'budget'])) {
      final freePlaces = scoped.where((item) => item.isFree).take(4).toList();
      if (freePlaces.isNotEmpty) {
        return TravelAssistantReply(
          text: 'Good free-entry choices${city == null ? '' : ' in $city'} '
              'include ${freePlaces.map((item) => item.name).join(', ')}. '
              'Keep a little budget for transport, food, and optional charges.',
          places: freePlaces,
        );
      }
    }

    final days = _extractDays(query);
    if (_containsAny(query, ['itinerary', 'plan', 'visit', 'things to do']) ||
        days != null) {
      if (requestedLocation != null && city == null) {
        return TravelAssistantReply(
          text: 'I do not have enough verified UniSafeX places for '
              '$requestedLocation yet. Try another city, or ask for top places '
              'in India while the destination catalog is expanded.',
        );
      }
      final count = (days ?? 2).clamp(1, 5);
      final planCity = city ?? (scoped.isNotEmpty ? scoped.first.city : null);
      if (planCity != null) {
        final style = _styleFromQuery(query);
        final plan = const TripPlannerService().generate(
          city: planCity,
          days: count,
          style: style,
          places: allPlaces,
        );
        final lines = plan.itinerary
            .where((day) => day.stops.isNotEmpty)
            .map(
              (day) =>
                  'Day ${day.day}: ${day.stops.map((stop) => stop.place.name).join(' → ')}',
            )
            .toList();
        final picks = plan.itinerary
            .expand((day) => day.stops)
            .map((stop) => stop.place)
            .toList();
        if (lines.isEmpty) {
          return const TravelAssistantReply(
            text: 'I need more city data to build that plan.',
          );
        }
        return TravelAssistantReply(
          text: 'Here is a smart ${style.label.toLowerCase()} $count-day plan '
              'for $planCity using the full UniSafeX catalog:\n'
              '${lines.join('\n')}\n\n'
              'Estimated entry + local travel: ${_money(plan.totalEstimateInr)} '
              '(${_money(plan.totalEntryFeesInr)} entry, '
              '${_money(plan.estimatedTransportFareInr)} travel).\n\n'
              'Open cards for images, fees, timings, safety tips and map directions. '
              'For a richer day-by-day view, open Smart Trip Planner.',
          places: picks,
        );
      }
    }

    final recommendations = scoped.take(4).toList();
    final location = city ?? 'India';
    final cityCount = allPlaces.map((item) => item.city).toSet().length;
    return TravelAssistantReply(
      text: 'Top UniSafeX recommendations for $location are '
          '${recommendations.map((item) => item.name).join(', ')}. Ask me '
          'about safety, scams, taxi/metro advice, entry fees, timings, best '
          'season, free places, hidden gems, photo spots, family travel, '
          'hotels, food safety, categories, total trip estimates, or a 1–5 day itinerary. I can reason over ${allPlaces.length} '
          'places across $cityCount cities.',
      places: recommendations,
    );
  }

  List<TourismPlace> _scopedPlaces(
    String? city,
    List<TourismPlace> places,
  ) {
    final result = city == null
        ? [...places]
        : places
            .where((item) => item.city.toLowerCase() == city.toLowerCase())
            .toList();
    result.sort((a, b) => b.rating.compareTo(a.rating));
    return result;
  }

  String? _findCity(String query, List<TourismPlace> places) {
    final cities = places.map((item) => item.city).toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final city in cities) {
      if (city.isEmpty) continue;
      final normalizedCity = city.toLowerCase();
      if (query.contains(normalizedCity)) return city;
      final cityWords = normalizedCity.split(RegExp(r'\s+'));
      if (cityWords.length > 1 &&
          cityWords.any((word) => word.length > 3 && query.contains(word))) {
        return city;
      }
    }
    return null;
  }

  String? _requestedLocation(String query) {
    final match = RegExp(
      r'\b(?:in|for|visit)\s+([a-z][a-z ]{2,30}?)(?:\s+in\s+\d|\s+\d|\?|$)',
    ).firstMatch(query);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty || value == 'india') return null;
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  TourismPlace? _findPlace(String query, List<TourismPlace> places) {
    final sorted = [...places]
      ..sort((a, b) => b.name.length.compareTo(a.name.length));
    for (final place in sorted) {
      if (query.contains(place.name.toLowerCase())) return place;
    }
    return null;
  }

  String? _findCategory(String query, List<TourismPlace> places) {
    final categories = places.map((item) => item.category).toSet().toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final category in categories) {
      if (category.isEmpty) continue;
      if (query.contains(category.toLowerCase())) return category;
    }
    return null;
  }

  TravelStyle _styleFromQuery(String query) {
    if (_containsAny(query, ['budget', 'cheap', 'free'])) {
      return TravelStyle.budget;
    }
    if (_containsAny(query, ['luxury', 'premium', 'comfortable'])) {
      return TravelStyle.luxury;
    }
    return TravelStyle.balanced;
  }

  int? _extractDays(String query) {
    final match = RegExp(r'\b([1-5])\s*(?:day|days)\b').firstMatch(query);
    return int.tryParse(match?.group(1) ?? '');
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  double _familyScore(TourismPlace place) {
    final duration = place.visitDurationMinutes ?? 120;
    final durationScore = duration <= 150 ? 2.0 : 0.6;
    final detailScore = [
      place.timings?.isNotEmpty == true,
      place.safetyGuidelines.isNotEmpty,
      place.touristTips.isNotEmpty,
      place.address?.isNotEmpty == true,
    ].where((value) => value).length;
    return place.rating * 2 +
        durationScore +
        detailScore * 0.45 +
        (place.featured ? 1 : 0) +
        (place.isPopular ? 0.8 : 0);
  }

  String _placeBrief(TourismPlace place) {
    final safetyScore = SafetyScoreService.calculate(place);
    return '${place.name} is a ${place.category.toLowerCase()} destination in '
        '${place.city}, ${place.state}. Entry: ${place.formattedEntryFee}. '
        'Timing: ${place.timings ?? 'not listed'}. Recommended duration: '
        '${_duration(place.visitDurationMinutes)}. Safety score: '
        '$safetyScore/100.\n\n'
        'Why visit: ${place.description.isEmpty ? 'Strong local heritage value.' : place.description}\n\n'
        'Tourist tip: ${place.touristTips.isNotEmpty ? place.touristTips.first : 'Carry ID, water, and confirm timings before leaving.'}';
  }

  String _safetyChecklist() {
    return 'Quick safety checklist: share live location, keep passport copy '
        'separate, use official ticket counters, avoid isolated night visits, '
        'and prefer registered transport.';
  }

  String _duration(int? minutes) {
    if (minutes == null) return 'about 1–2 hours';
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} hours';
  }

  String _money(num value) => '₹${value.round()}';
}
