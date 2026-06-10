import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/domain/entities/trip_plan.dart';
import 'package:unisafex/features/tourism/domain/services/trip_planner_service.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class TripPlannerScreen extends ConsumerStatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  ConsumerState<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends ConsumerState<TripPlannerScreen> {
  String? _city;
  int _days = 2;
  TravelStyle _style = TravelStyle.balanced;
  TripPlan? _plan;

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(popularPlacesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Trip Planner')),
      body: places.when(
        data: (items) {
          final cityCounts = <String, Set<String>>{};
          for (final place in items) {
            cityCounts
                .putIfAbsent(place.city, () => <String>{})
                .add(place.name.toLowerCase());
          }
          final cities = cityCounts.keys.toList()
            ..sort(
              (a, b) => cityCounts[b]!.length.compareTo(cityCounts[a]!.length),
            );
          if (_city == null && cities.isNotEmpty) _city = cities.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              _HeroCard(days: _days),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: const InputDecoration(
                  labelText: 'Destination city',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: cities
                    .map((city) =>
                        DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: (value) => setState(() => _city = value),
              ),
              const SizedBox(height: 18),
              Text('Number of days',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _days.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_days days',
                onChanged: (value) => setState(() => _days = value.round()),
              ),
              const SizedBox(height: 8),
              Text('Travel style',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SegmentedButton<TravelStyle>(
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
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _city == null
                    ? null
                    : () => setState(() {
                          _plan = const TripPlannerService().generate(
                            city: _city!,
                            days: _days,
                            style: _style,
                            places: items,
                          );
                        }),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate itinerary'),
              ),
              if (_plan != null) ...[
                const SizedBox(height: 28),
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
            Center(child: Text('Unable to load places: $error')),
      ),
    );
  }

  IconData _styleIcon(TravelStyle style) => switch (style) {
        TravelStyle.budget => Icons.savings_outlined,
        TravelStyle.balanced => Icons.balance_outlined,
        TravelStyle.luxury => Icons.diamond_outlined,
      };
}

class _HeroCard extends StatelessWidget {
  final int days;

  const _HeroCard({required this.days});

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
            'from verified UniSafeX destination data.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
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
          Text('Day ${day.day}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          if (day.stops.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No more places available for this city.'),
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
                      CircleAvatar(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.place_outlined),
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
}
