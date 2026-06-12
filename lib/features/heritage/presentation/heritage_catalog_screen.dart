import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String? _type;
  int _page = 0;

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
      type: _type,
      page: _page,
    );
    final monuments = ref.watch(heritageMonumentsProvider(query));
    final options = ref.watch(heritageFilterOptionsProvider);
    final visitorInsights = ref.watch(foreignVisitorInsightsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('heritage_catalog'.tr())),
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => _showFilters(options.value),
                ),
              ),
            ),
          ),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        if (index < items.length) {
                          return _MonumentCard(monument: items[index]);
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

  Future<void> _showFilters(Map<String, List<String>>? options) async {
    if (options == null) return;
    var selectedState = _state;
    var selectedType = _type;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('filters'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: selectedState,
                decoration: InputDecoration(labelText: 'state'.tr()),
                items: options['states']!
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => selectedState = value),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(labelText: 'category'.tr()),
                items: options['types']!
                    .map((value) =>
                        DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) => setSheetState(() => selectedType = value),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _state = null;
                        _type = null;
                        _page = 0;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('clear_filters'.tr()),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _state = selectedState;
                        _type = selectedType;
                        _page = 0;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('apply_filters'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitorInsights extends StatelessWidget {
  const _VisitorInsights({required this.items});

  final List<MonumentVisitorStat> items;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern(context.locale.toString());
    return SizedBox(
      height: 118,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            width: 220,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.monumentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: onPrevious,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text('${page + 1}'),
        ),
        IconButton.filled(
          onPressed: hasNext ? onNext : null,
          tooltip: 'next'.tr(),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _MonumentCard extends StatelessWidget {
  const _MonumentCard({required this.monument});

  final HeritageMonument monument;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.account_balance_rounded, color: Colors.white),
        ),
        title: Text(monument.name),
        subtitle: Text([
          monument.locality,
          monument.district,
          monument.state,
        ].whereType<String>().where((value) => value.isNotEmpty).join(', ')),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (monument.monumentType != null)
            _Detail(label: 'category'.tr(), value: monument.monumentType!),
          if (monument.region != null)
            _Detail(label: 'region'.tr(), value: monument.region!),
          if (monument.asiCircle != null)
            _Detail(label: 'asi_circle'.tr(), value: monument.asiCircle!),
          if (monument.protectionStatus != null)
            _Detail(
              label: 'protection_status'.tr(),
              value: monument.protectionStatus!,
            ),
          if (monument.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(monument.description!),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text('$label: $value'),
      );
}
