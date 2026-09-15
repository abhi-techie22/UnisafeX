import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/entities/trip_plan.dart';
import 'package:unisafex/features/tourism/domain/services/trip_planner_service.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  final _destinationSearchController = TextEditingController();
  static const _plannerService = TripPlannerService();

  String? _city;
  String _destinationQuery = '';
  int _days = 2;
  TravelStyle _style = TravelStyle.balanced;
  TripPlan? _plan;
  bool _generating = false;
  List<TourismPlace>? _indexedPlaces;
  _TripPlannerIndex? _cachedIndex;

  @override
  void dispose() {
    _destinationSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(plannerPlacesProvider);
    return Scaffold(
      appBar: AppBar(title: Text('smart_trip_planner'.tr())),
      body: places.when(
        data: (items) {
          final index = _indexFor(items);
          final cities = index.cities;
          final filteredCities = _filteredCities(index);
          if (_city == null && cities.isNotEmpty) _city = cities.first;
          if (filteredCities.isNotEmpty && !filteredCities.contains(_city)) {
            _city = filteredCities.first;
          }
          final selectedCityCount =
              _city == null ? 0 : index.cityCounts[_city!] ?? 0;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _HeroCard(
                days: _days,
                totalPlaces: items.length,
                cityCount: cities.length,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _destinationSearchController,
                onChanged: (value) => setState(() {
                  _destinationQuery = value;
                  final matches = _filteredCities(index, value);
                  if (value.trim().isEmpty) return;
                  if (matches.length == 1) {
                    _setCity(matches.first);
                  }
                }),
                decoration: const InputDecoration(
                  labelText: 'Search destination',
                  hintText: 'Search by city, state or place name',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'destination-${_destinationQuery.trim().toLowerCase()}-${_city ?? ''}-${filteredCities.length}',
                ),
                initialValue: filteredCities.contains(_city)
                    ? _city
                    : filteredCities.isEmpty
                        ? null
                        : filteredCities.first,
                decoration: const InputDecoration(
                  labelText: 'Destination city',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: filteredCities
                    .map(
                      (city) => DropdownMenuItem(
                        value: city,
                        child: Text('$city (${index.cityCounts[city] ?? 0})'),
                      ),
                    )
                    .toList(),
                onChanged: filteredCities.isEmpty
                    ? null
                    : (value) => setState(() => _setCity(value)),
              ),
              const SizedBox(height: 8),
              Text(
                filteredCities.isEmpty
                    ? 'No destination matched. Try another city, state, or place name.'
                    : selectedCityCount == 0
                        ? 'Choose a city to build a route.'
                        : '$selectedCityCount places available for $_city. The planner ranks them by rating, popularity, safety data, fees, timings and route distance.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Text('number_of_days'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _days.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: 'days_count'.tr(args: ['$_days']),
                onChanged: (value) => setState(() => _days = value.round()),
              ),
              const SizedBox(height: 8),
              Text('travel_style'.tr(),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<TravelStyle>(
                  segments: TravelStyle.values
                      .map(
                        (style) => ButtonSegment(
                          value: style,
                          label: Text(style.label),
                          icon: Icon(_styleIcon(style)),
                        ),
                      )
                      .toList(),
                  selected: {_style},
                  onSelectionChanged: (selection) =>
                      setState(() => _style = selection.first),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed:
                    _city == null || filteredCities.isEmpty || _generating
                        ? null
                        : () => _generatePlan(items),
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _generating
                      ? 'Building itinerary...'
                      : 'generate_itinerary'.tr(),
                ),
              ),
              if (_plan != null) ...[
                const SizedBox(height: 28),
                _PlanSummaryCard(plan: _plan!),
                const SizedBox(height: 18),
                ..._plan!.itinerary.map(
                  (day) => _DayCard(
                    day: day,
                    onPlaceTap: (place) => context.push(
                      AppRoutes.placeDetail,
                      extra: place,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${'unable_to_load'.tr()}: $error')),
      ),
    );
  }

  IconData _styleIcon(TravelStyle style) => switch (style) {
        TravelStyle.budget => Icons.savings_outlined,
        TravelStyle.balanced => Icons.balance_outlined,
        TravelStyle.luxury => Icons.diamond_outlined,
      };

  void _setCity(String? city) {
    if (_city == city) return;
    _city = city;
    _plan = null;
  }

  Future<void> _generatePlan(List<TourismPlace> places) async {
    final city = _city;
    if (city == null || _generating) return;

    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 16));

    try {
      final plan = _plannerService.generate(
        city: city,
        days: _days,
        style: _style,
        places: places,
      );
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _generating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not build this itinerary right now.'),
        ),
      );
    }
  }

  _TripPlannerIndex _indexFor(List<TourismPlace> places) {
    if (identical(_indexedPlaces, places) && _cachedIndex != null) {
      return _cachedIndex!;
    }

    final namesByCity = <String, Set<String>>{};
    final searchByCity = <String, StringBuffer>{};
    for (final place in places) {
      final city =
          place.city.trim().isEmpty ? place.state.trim() : place.city.trim();
      if (city.isEmpty) continue;
      namesByCity.putIfAbsent(city, () => <String>{}).add(
            place.name.toLowerCase(),
          );
      searchByCity.putIfAbsent(city, StringBuffer.new)
        ..write(' ')
        ..write(place.name.toLowerCase())
        ..write(' ')
        ..write(place.state.toLowerCase())
        ..write(' ')
        ..write(place.category.toLowerCase())
        ..write(' ')
        ..write(place.district?.toLowerCase() ?? '')
        ..write(' ')
        ..write(place.address?.toLowerCase() ?? '');
    }

    final cityCounts = {
      for (final entry in namesByCity.entries) entry.key: entry.value.length,
    };
    final cities = cityCounts.keys.toList()
      ..sort((a, b) {
        final count = cityCounts[b]!.compareTo(cityCounts[a]!);
        if (count != 0) return count;
        return a.compareTo(b);
      });
    final index = _TripPlannerIndex(
      cities: cities,
      cityCounts: cityCounts,
      searchByCity: {
        for (final entry in searchByCity.entries)
          entry.key: entry.value.toString(),
      },
    );
    _indexedPlaces = places;
    _cachedIndex = index;
    return index;
  }

  List<String> _filteredCities(_TripPlannerIndex index,
      [String? overrideQuery]) {
    final query = (overrideQuery ?? _destinationQuery).trim().toLowerCase();
    if (query.isEmpty) return index.cities;
    return index.cities.where((city) {
      return city.toLowerCase().contains(query) ||
          (index.searchByCity[city]?.contains(query) ?? false);
    }).toList(growable: false);
  }
}

class _TripPlannerIndex {
  const _TripPlannerIndex({
    required this.cities,
    required this.cityCounts,
    required this.searchByCity,
  });

  final List<String> cities;
  final Map<String, int> cityCounts;
  final Map<String, String> searchByCity;
}

class _HeroCard extends StatelessWidget {
  final int days;
  final int totalPlaces;
  final int cityCount;

  const _HeroCard({
    required this.days,
    required this.totalPlaces,
    required this.cityCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.route_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 16),
          Text(
            'Build a smarter $days-day journey',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Balanced days, practical durations, and memorable places selected '
            'from the full UniSafeX destination catalog.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: '$totalPlaces places loaded'),
              _HeroPill(label: '$cityCount cities'),
              const _HeroPill(label: 'Smart route order'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final stops = plan.itinerary.fold<int>(
      0,
      (total, day) => total + day.stops.length,
    );
    final freeStops = plan.itinerary
        .expand((day) => day.stops)
        .where((stop) => stop.place.isFree)
        .length;
    final safetyReady = plan.itinerary
        .expand((day) => day.stops)
        .where((stop) => stop.place.safetyGuidelines.isNotEmpty)
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MiniInfoChip(icon: Icons.route_rounded, label: '$stops stops'),
            _MiniInfoChip(
              icon: Icons.payments_outlined,
              label: 'Entry ${_money(plan.totalEntryFeesInr)}',
            ),
            _MiniInfoChip(
              icon: Icons.local_taxi_outlined,
              label: 'Travel ${_money(plan.estimatedTransportFareInr)}',
            ),
            _MiniInfoChip(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total est. ${_money(plan.totalEstimateInr)}',
            ),
            _MiniInfoChip(
                icon: Icons.savings_outlined, label: '$freeStops free'),
            _MiniInfoChip(
              icon: Icons.shield_outlined,
              label: '$safetyReady safety ready',
            ),
            _MiniInfoChip(icon: Icons.tune_rounded, label: plan.style.label),
          ],
        ),
      ),
    );
  }

  String _money(num value) => '₹${NumberFormat('#,##0').format(value)}';
}

class _DayCard extends StatelessWidget {
  final TripPlanDay day;
  final ValueChanged<dynamic> onPlaceTap;

  const _DayCard({required this.day, required this.onPlaceTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('day_number'.tr(args: ['${day.day}']),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfoChip(
                icon: Icons.directions_car_filled_outlined,
                label: '${day.routeDistanceKm.toStringAsFixed(1)} km route',
              ),
              _MiniInfoChip(
                icon: Icons.local_taxi_outlined,
                label: 'Fare est. ${_money(day.estimatedTransportFareInr)}',
              ),
              _MiniInfoChip(
                icon: Icons.confirmation_number_outlined,
                label: 'Entry ${_money(day.entryFeesInr)}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (day.stops.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text('no_places_city'.tr()),
              ),
            ),
          ...day.stops.map(
            (stop) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onPlaceTap(stop.place),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 74,
                          height: 74,
                          child: stop.place.primaryImage.trim().isEmpty
                              ? Container(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.08),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Image.network(
                                  stop.place.primaryImage,
                                  fit: BoxFit.cover,
                                  cacheWidth: 160,
                                  cacheHeight: 160,
                                  filterQuality: FilterQuality.low,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    child: const Icon(
                                      Icons.place_outlined,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stop.place.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '${_duration(stop.place.visitDurationMinutes)}'
                              '${stop.distanceFromPreviousKm == null ? '' : ' · ${stop.distanceFromPreviousKm!.toStringAsFixed(1)} km'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 7),
                            Text(stop.reason),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _MiniInfoChip(
                                  icon: Icons.confirmation_number_outlined,
                                  label: stop.place.formattedEntryFee,
                                ),
                                if (stop.place.timings?.isNotEmpty == true)
                                  _MiniInfoChip(
                                    icon: Icons.schedule_rounded,
                                    label: stop.place.timings!,
                                  ),
                                if (stop.place.safetyGuidelines.isNotEmpty)
                                  const _MiniInfoChip(
                                    icon: Icons.shield_outlined,
                                    label: 'Safety tips ready',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _duration(int? minutes) {
    if (minutes == null) return 'Flexible visit';
    if (minutes < 60) return '$minutes min';
    return '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} hr';
  }

  String _money(num value) => '₹${NumberFormat('#,##0').format(value)}';
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
