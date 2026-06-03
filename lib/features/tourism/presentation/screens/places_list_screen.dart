import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/shimmer_loader.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class PlacesListScreen extends ConsumerStatefulWidget {
  final String? category;
  final String title;

  const PlacesListScreen({super.key, this.category, required this.title});

  @override
  ConsumerState<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends ConsumerState<PlacesListScreen> {
  String? _activeCategory;
  bool? _freeOnly;
  bool _popularOnly = false;

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final placesAsync = ref.watch(
      placesByFilterProvider(FilterParams(
        category: _activeCategory,
        isFree: _freeOnly,
        isPopular: _popularOnly ? true : null,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filters row
          if (_activeCategory != null || _freeOnly == true || _popularOnly)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_activeCategory != null)
                    _ActiveFilter(
                      label: _activeCategory!,
                      onRemove: () =>
                          setState(() => _activeCategory = null),
                    ),
                  if (_freeOnly == true)
                    _ActiveFilter(
                      label: 'Free Entry',
                      onRemove: () =>
                          setState(() => _freeOnly = null),
                    ),
                  if (_popularOnly)
                    _ActiveFilter(
                      label: 'Popular',
                      onRemove: () =>
                          setState(() => _popularOnly = false),
                    ),
                ],
              ),
            ),

          Expanded(
            child: placesAsync.when(
              data: (places) => places.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: places.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _PlaceListTile(
                        place: places[i],
                        onTap: () => context.push(
                          AppRoutes.placeDetail,
                          extra: places[i],
                        ),
                      ),
                    ),
              loading: () => _buildLoading(),
              error: (e, _) => _buildError(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        activeCategory: _activeCategory,
        isFree: _freeOnly,
        isPopular: _popularOnly,
        onApply: (cat, free, popular) {
          setState(() {
            _activeCategory = cat;
            _freeOnly = free;
            _popularOnly = popular;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text('No places found',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => ShimmerLoader(
        width: double.infinity,
        height: 100,
        borderRadius: 14,
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(placesByFilterProvider),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class FilterParams {
  final String? category;
  final bool? isFree;
  final bool? isPopular;

  const FilterParams({this.category, this.isFree, this.isPopular});

  @override
  bool operator ==(Object other) =>
      other is FilterParams &&
      other.category == category &&
      other.isFree == isFree &&
      other.isPopular == isPopular;

  @override
  int get hashCode => Object.hash(category, isFree, isPopular);
}

final placesByFilterProvider =
    FutureProvider.family<List<TourismPlace>, FilterParams>((ref, params) async {
  return ref.read(tourismRepositoryProvider).getPlacesWithFilters(
        category: params.category,
        isFree: params.isFree,
        isPopular: params.isPopular,
      );
});

class _PlaceListTile extends StatelessWidget {
  final TourismPlace place;
  final VoidCallback onTap;

  const _PlaceListTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Image.network(
              place.primaryImage,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                color: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.image_outlined, color: AppColors.grey400),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${place.city}, ${place.state}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _categoryColor(place.category).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            place.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _categoryColor(place.category),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDark ? AppColors.grey600 : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Historical': return AppColors.historical;
      case 'Nature': return AppColors.nature;
      case 'Spiritual': return AppColors.spiritual;
      case 'Adventure': return AppColors.adventure;
      default: return AppColors.primary;
    }
  }
}

class _ActiveFilter extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilter({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? activeCategory;
  final bool? isFree;
  final bool isPopular;
  final Function(String?, bool?, bool) onApply;

  const _FilterSheet({
    required this.activeCategory,
    required this.isFree,
    required this.isPopular,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _category;
  bool? _free;
  bool _popular = false;

  final List<String> categories = [
    'Historical', 'Nature', 'Spiritual', 'Adventure',
    'Photography', 'Food', 'Shopping', 'Wildlife',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.activeCategory;
    _free = widget.isFree;
    _popular = widget.isPopular;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey700 : AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final selected = _category == cat;
              return GestureDetector(
                onTap: () => setState(() => _category = selected ? null : cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.12)
                        : (isDark ? AppColors.grey800 : AppColors.grey100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.primary : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Text('More Filters', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          _FilterToggle(
            label: 'Free Entry Only',
            value: _free ?? false,
            onChanged: (v) => setState(() => _free = v ? true : null),
          ),
          _FilterToggle(
            label: 'Popular Only',
            value: _popular,
            onChanged: (v) => setState(() => _popular = v),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _free = null;
                      _popular = false;
                    });
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_category, _free, _popular),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterToggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
