import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_filters.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/safety_score_service.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class PlacesListScreen extends ConsumerStatefulWidget {
  final String? category;
  final String title;

  const PlacesListScreen({super.key, this.category, required this.title});

  @override
  ConsumerState<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends ConsumerState<PlacesListScreen> {
  late TourismFilters _filters =
      TourismFilters(category: widget.category, popularOnly: false);
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placesAsync = ref.watch(popularPlacesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: Badge(
              isLabelVisible: _filters.hasActiveFilters,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _filters = _filters.copyWith(query: value)),
              decoration: InputDecoration(
                hintText: 'Search places or cities',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filters.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(
                              () => _filters = _filters.copyWith(query: ''));
                        },
                      ),
              ),
            ),
          ),
          if (_filters.hasActiveFilters)
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  if (_filters.city != null) _FilterTag(label: _filters.city!),
                  if (_filters.category != null)
                    _FilterTag(label: _filters.category!),
                  if (_filters.popularOnly) const _FilterTag(label: 'Popular'),
                  if (_filters.hiddenGemsOnly)
                    const _FilterTag(label: 'Hidden gems'),
                  if (_filters.freeOnly) const _FilterTag(label: 'Free entry'),
                  if (_filters.foreignerFriendlyOnly)
                    const _FilterTag(label: 'Foreigner-friendly'),
                  if (_filters.openNowOnly) const _FilterTag(label: 'Open now'),
                  if (_filters.minimumRating > 0)
                    _FilterTag(
                        label: '${_filters.minimumRating.toStringAsFixed(1)}+'),
                ],
              ),
            ),
          Expanded(
            child: placesAsync.when(
              data: (places) {
                final filtered = _applyFilters(places);
                if (filtered.isEmpty) return const _EmptyResults();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final place = filtered[index];
                    return _PlaceListCard(
                      place: place,
                      onTap: () => context.push(
                        AppRoutes.placeDetail,
                        extra: place,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Unable to load places: $error')),
            ),
          ),
        ],
      ),
    );
  }

  List<TourismPlace> _applyFilters(List<TourismPlace> places) {
    final query = _filters.query.trim().toLowerCase();
    return places.where((place) {
      if (query.isNotEmpty &&
          !place.name.toLowerCase().contains(query) &&
          !place.city.toLowerCase().contains(query) &&
          !place.state.toLowerCase().contains(query)) {
        return false;
      }
      if (_filters.city != null && place.city != _filters.city) return false;
      if (_filters.category != null && place.category != _filters.category) {
        return false;
      }
      if (_filters.popularOnly && !place.isPopular) return false;
      if (_filters.hiddenGemsOnly && !place.isHiddenGem) return false;
      if (_filters.freeOnly && !place.isFree) return false;
      if (_filters.foreignerFriendlyOnly && !place.isForeignerFriendly) {
        return false;
      }
      if (_filters.openNowOnly && !place.isLikelyOpenNow) return false;
      if (place.rating < _filters.minimumRating) return false;
      return true;
    }).toList();
  }

  Future<void> _showFilters(BuildContext context) async {
    final places = ref.read(popularPlacesProvider).value ?? [];
    final result = await showModalBottomSheet<TourismFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdvancedFilterSheet(
        initial: _filters,
        cities: (places.map((place) => place.city).toSet().toList()..sort()),
      ),
    );
    if (result != null) setState(() => _filters = result);
  }
}

class _AdvancedFilterSheet extends StatefulWidget {
  final TourismFilters initial;
  final List<String> cities;

  const _AdvancedFilterSheet({required this.initial, required this.cities});

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late TourismFilters filters = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Refine your journey',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      setState(() => filters = const TourismFilters()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: filters.city,
              decoration: const InputDecoration(labelText: 'City'),
              items: widget.cities
                  .map((city) =>
                      DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => filters = filters.copyWith(city: value)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: filters.category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppConstants.placeCategories
                  .map((category) =>
                      DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => filters = filters.copyWith(category: value)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _choice('Popular', filters.popularOnly, (value) {
                  filters = filters.copyWith(popularOnly: value);
                }),
                _choice('Hidden gems', filters.hiddenGemsOnly, (value) {
                  filters = filters.copyWith(hiddenGemsOnly: value);
                }),
                _choice('Free entry', filters.freeOnly, (value) {
                  filters = filters.copyWith(freeOnly: value);
                }),
                _choice('Foreigner-friendly', filters.foreignerFriendlyOnly,
                    (value) {
                  filters = filters.copyWith(foreignerFriendlyOnly: value);
                }),
                _choice('Open now', filters.openNowOnly, (value) {
                  filters = filters.copyWith(openNowOnly: value);
                }),
              ],
            ),
            const SizedBox(height: 22),
            Text('Minimum rating: ${filters.minimumRating.toStringAsFixed(1)}'),
            Slider(
              value: filters.minimumRating,
              min: 0,
              max: 5,
              divisions: 10,
              onChanged: (value) => setState(
                () => filters = filters.copyWith(minimumRating: value),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, filters),
                child: const Text('Show matching places'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) => setState(() => onChanged(value)),
    );
  }
}

class _PlaceListCard extends StatelessWidget {
  final TourismPlace place;
  final VoidCallback onTap;

  const _PlaceListCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = SafetyScoreService.calculate(place);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                place.primaryImage,
                width: 112,
                height: 116,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 112,
                  height: 116,
                  child: Icon(Icons.image_outlined),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('${place.city}, ${place.state}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: AppColors.accent),
                        Text(' ${place.rating.toStringAsFixed(1)}'),
                        const Spacer(),
                        Icon(Icons.shield_outlined,
                            size: 16,
                            color: score >= 70
                                ? AppColors.success
                                : AppColors.warning),
                        Text(' $score'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  final String label;

  const _FilterTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(label: Text(label)),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.travel_explore, size: 52, color: AppColors.grey400),
          const SizedBox(height: 14),
          Text('No matching places',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Try removing one or two filters.'),
        ],
      ),
    );
  }
}
