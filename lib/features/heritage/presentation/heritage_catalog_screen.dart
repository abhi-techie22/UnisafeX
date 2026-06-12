import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';
import 'package:unisafex/features/heritage/domain/heritage_monument.dart';

class HeritageCatalogScreen extends ConsumerStatefulWidget {
  const HeritageCatalogScreen({super.key});

  @override
  ConsumerState<HeritageCatalogScreen> createState() =>
      _HeritageCatalogScreenState();
}

class _HeritageCatalogScreenState extends ConsumerState<HeritageCatalogScreen> {
  final _search = TextEditingController();
  String? _state;
  String? _region;
  String? _district;
  String? _type;
  String? _protectionStatus;
  bool _freeOnly = false;
  bool _featuredOnly = false;
  int _page = 0;

  bool get _hasFilters =>
      _state != null ||
      _region != null ||
      _district?.isNotEmpty == true ||
      _type != null ||
      _protectionStatus != null ||
      _freeOnly ||
      _featuredOnly;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = HeritageQuery(
      search: _search.text,
      state: _state,
      region: _region,
      district: _district,
      type: _type,
      protectionStatus: _protectionStatus,
      freeOnly: _freeOnly,
      featuredOnly: _featuredOnly,
      page: _page,
    );
    final monuments = ref.watch(heritageMonumentsProvider(query));
    final options = ref.watch(heritageFilterOptionsProvider);
    final visitorInsights = ref.watch(foreignVisitorInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('heritage_catalog'.tr()),
        actions: [
          IconButton(
            onPressed: () => _showFilters(options.value),
            icon: Badge(
              isLabelVisible: _hasFilters,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(() => _page = 0),
              decoration: InputDecoration(
                hintText: 'search_places_hint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _page = 0);
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (_hasFilters) _ActiveFilters(labels: _filterLabels),
          visitorInsights.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : _VisitorInsights(items: items),
          ),
          Expanded(
            child: monuments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('${'unable_to_load'.tr()}: $error')),
              data: (items) => items.isEmpty
                  ? Center(child: Text('no_results'.tr()))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, index) {
                        if (index < items.length) {
                          return _MonumentCard(
                            monument: items[index],
                            onTap: () => context.push(
                              AppRoutes.heritageDetail,
                              extra: items[index],
                            ),
                          );
                        }
                        return _PaginationControls(
                          page: _page,
                          hasNext: items.length == HeritageRepository.pageSize,
                          onPrevious:
                              _page == 0 ? null : () => setState(() => _page--),
                          onNext: items.length == HeritageRepository.pageSize
                              ? () => setState(() => _page++)
                              : null,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _filterLabels => [
        if (_state != null) _state!,
        if (_region != null) _region!,
        if (_district?.isNotEmpty == true) _district!,
        if (_type != null) _type!,
        if (_protectionStatus != null) _protectionStatus!,
        if (_freeOnly) 'free_entry'.tr(),
        if (_featuredOnly) 'popular_places'.tr(),
      ];

  Future<void> _showFilters(Map<String, List<String>>? options) async {
    if (options == null) return;
    var state = _state;
    var region = _region;
    var district = _district ?? '';
    var type = _type;
    var protection = _protectionStatus;
    var freeOnly = _freeOnly;
    var featuredOnly = _featuredOnly;
    final districtController = TextEditingController(text: district);

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('filters'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 18),
                _Dropdown(
                  label: 'state'.tr(),
                  value: state,
                  values: options['states']!,
                  onChanged: (value) => setSheetState(() => state = value),
                ),
                const SizedBox(height: 12),
                _Dropdown(
                  label: 'region'.tr(),
                  value: region,
                  values: options['regions']!,
                  onChanged: (value) => setSheetState(() => region = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: districtController,
                  decoration: InputDecoration(labelText: 'district'.tr()),
                  onChanged: (value) => district = value,
                ),
                const SizedBox(height: 12),
                _Dropdown(
                  label: 'category'.tr(),
                  value: type,
                  values: options['types']!,
                  onChanged: (value) => setSheetState(() => type = value),
                ),
                const SizedBox(height: 12),
                _Dropdown(
                  label: 'protection_status'.tr(),
                  value: protection,
                  values: options['protectionStatuses']!,
                  onChanged: (value) => setSheetState(() => protection = value),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: freeOnly,
                  title: Text('free_entry'.tr()),
                  onChanged: (value) => setSheetState(() => freeOnly = value),
                ),
                SwitchListTile(
                  value: featuredOnly,
                  title: Text('popular_places'.tr()),
                  onChanged: (value) =>
                      setSheetState(() => featuredOnly = value),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('clear_filters'.tr()),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('apply_filters'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    districtController.dispose();
    if (applied == null) return;
    setState(() {
      if (applied) {
        _state = state;
        _region = region;
        _district = district.trim().isEmpty ? null : district.trim();
        _type = type;
        _protectionStatus = protection;
        _freeOnly = freeOnly;
        _featuredOnly = featuredOnly;
      } else {
        _state = null;
        _region = null;
        _district = null;
        _type = null;
        _protectionStatus = null;
        _freeOnly = false;
        _featuredOnly = false;
      }
      _page = 0;
    });
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      );
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) => Chip(label: Text(labels[index])),
        ),
      );
}

class _MonumentCard extends StatelessWidget {
  const _MonumentCard({required this.monument, required this.onTap});
  final HeritageMonument monument;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _HeritageImage(url: monument.imageUrl, height: 165),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        monument.monumentType ?? 'heritage_catalog'.tr(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monument.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 17),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            [
                              monument.locality,
                              monument.district,
                              monument.state
                            ]
                                .whereType<String>()
                                .where((value) => value.isNotEmpty)
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _HeritageImage extends StatelessWidget {
  const _HeritageImage({required this.url, required this.height});
  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url?.isNotEmpty == true) {
      return Image.network(
        url!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _localImage(),
      );
    }
    return _localImage();
  }

  Widget _localImage() => Image.asset(
        'assets/images/heritage_placeholder.jpg',
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
}

class _VisitorInsights extends StatelessWidget {
  const _VisitorInsights({required this.items});
  final List<MonumentVisitorStat> items;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern(context.locale.toString());
    return SizedBox(
      height: 108,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            width: 218,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.monumentName,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Text(
                  '${number.format(item.foreignVisitors)} '
                  '${'foreign_visitors'.tr()} · ${item.fiscalYear}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.page,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });
  final int page;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('${page + 1}'),
          ),
          IconButton.filled(
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );
}
