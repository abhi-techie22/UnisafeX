import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';

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

    if (_containsAny(query, ['emergency', 'police', 'ambulance', 'danger'])) {
      return const TravelAssistantReply(
        text: 'For an immediate emergency in India, call 112. For police call '
            '100, ambulance 108, and the tourist helpline 1363. Move to a '
            'well-lit public place and share your live location with someone '
            'you trust.',
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
            'Safety scores are guidance, not a guarantee.',
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
      final picks = scoped.take(count * 2).toList();
      if (picks.isNotEmpty) {
        final lines = <String>[];
        for (var day = 0; day < count; day++) {
          final dayPlaces = picks.skip(day * 2).take(2).toList();
          if (dayPlaces.isNotEmpty) {
            lines.add(
              'Day ${day + 1}: ${dayPlaces.map((item) => item.name).join(' → ')}',
            );
          }
        }
        return TravelAssistantReply(
          text: 'Here is a practical $count-day starting plan'
              '${city == null ? '' : ' for $city'}:\n${lines.join('\n')}\n'
              'Open a place card for fees, timings, safety tips and directions.',
          places: picks,
        );
      }
    }

    final recommendations = scoped.take(4).toList();
    final location = city ?? 'India';
    return TravelAssistantReply(
      text: 'Top UniSafeX recommendations for $location are '
          '${recommendations.map((item) => item.name).join(', ')}. Ask me '
          'about safety, scams, taxi/metro advice, entry fees, timings, best '
          'season, free places, hotels, food safety, or a 1–5 day itinerary.',
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

  int? _extractDays(String query) {
    final match = RegExp(r'\b([1-5])\s*(?:day|days)\b').firstMatch(query);
    return int.tryParse(match?.group(1) ?? '');
  }

  bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);

  String _duration(int? minutes) {
    if (minutes == null) return 'about 1–2 hours';
    if (minutes < 60) return '$minutes minutes';
    final hours = minutes / 60;
    return '${hours.toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} hours';
  }
}
