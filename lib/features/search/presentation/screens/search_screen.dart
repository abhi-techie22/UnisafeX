import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/shimmer_loader.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';
import 'package:unisafex/features/tourism/presentation/widgets/category_chip.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = ref.watch(_searchQueryProvider);
    final hasQuery = query.isNotEmpty;

    final results = hasQuery
        ? ref.watch(searchPlacesProvider(query))
        : _selectedCategory != null
            ? ref.watch(placesByCategoryProvider(_selectedCategory!))
            : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) {
                    ref.read(_searchQueryProvider.notifier).state = v;
                  },
                  decoration: InputDecoration(
                    hintText: 'search_places_hint'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _controller.clear();
                              ref.read(_searchQueryProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? AppColors.grey800 : AppColors.grey100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  _controller.clear();
                  ref.read(_searchQueryProvider.notifier).state = '';
                  context.go(AppRoutes.home);
                },
                child: Text('cancel'.tr()),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          if (!hasQuery) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'browse_by_category'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: AppConstants.placeCategories
                    .map((cat) => CategoryChip(
                          label: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory =
                                _selectedCategory == cat ? null : cat;
                          }),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Results
          Expanded(
            child: results == null
                ? _buildSearchHome(context)
                : results.when(
                    data: (places) => places.isEmpty
                        ? _buildNoResults(query)
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: places.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final place = places[i];
                              return GestureDetector(
                                onTap: () => context.push(
                                  AppRoutes.placeDetail,
                                  extra: place,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.cardDark
                                        : AppColors.cardLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        place.primaryImage,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 52,
                                          height: 52,
                                          color: AppColors.primary
                                              .withOpacity(0.1),
                                          child: const Icon(
                                              Icons.image_outlined,
                                              size: 20,
                                              color: AppColors.grey400),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      place.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${place.city}, ${place.state} · ${place.category}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            size: 13, color: AppColors.accent),
                                        const SizedBox(width: 3),
                                        Text(
                                          place.rating.toStringAsFixed(1),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).animate().fadeIn(duration: 300.ms),
                    loading: () => ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, __) => ShimmerLoader(
                        width: double.infinity,
                        height: 72,
                        borderRadius: 14,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text('error_occurred'.tr()),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHome(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentSearches = [
      'Taj Mahal',
      'Kerala Backwaters',
      'Rajasthan',
      'Goa Beaches',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'popular_searches'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((s) {
              return GestureDetector(
                onTap: () {
                  _controller.text = s;
                  ref.read(_searchQueryProvider.notifier).state = s;
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: isDark ? AppColors.grey400 : AppColors.grey500,
                      ),
                      const SizedBox(width: 6),
                      Text(s, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text('no_results_for'.tr(args: [query]),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('try_different_search'.tr(),
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
