import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';
import 'package:unisafex/features/guide/presentation/providers/guide_request_provider.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';
import 'package:unisafex/features/maps/data/map_access_config_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _search = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(isAdminProvider);
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin_console'.tr()),
          actions: [
            IconButton(
              tooltip: 'sign_out'.tr(),
              onPressed: () => _confirmAdminSignOut(context),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Places'),
              Tab(icon: Icon(Icons.campaign_rounded), text: 'Banners'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Flags'),
              Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Alerts'),
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Users'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'Guides'),
              Tab(icon: Icon(Icons.map_rounded), text: 'Maps'),
            ],
          ),
        ),
        body: access.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (allowed) {
            if (!allowed) {
              return Center(child: Text('admin_access_denied'.tr()));
            }
            final places = ref.watch(
              adminTourismPlacesProvider(
                AdminTourismPlacesParams(search: _search.text, page: _page),
              ),
            );
            return TabBarView(
              children: [
                const _AdminDashboardOverviewTab(),
                _buildPlacesTab(places),
                const _HomeBannersAdminTab(),
                const _FeatureFlagsAdminTab(),
                const _TravelAlertsAdminTab(),
                const _UsersAdminTab(),
                const _GuideRequestsAdminTab(),
                const _MapAccessAdminTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlacesTab(AsyncValue<List<TourismPlace>> places) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'admin_live_updates'.tr(),
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _editPlace(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add place'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => setState(() => _page = 0),
            decoration: InputDecoration(
              hintText: 'search_places_hint'.tr(),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: places.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (items) => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: items.length + 1,
              itemBuilder: (_, index) {
                if (index == items.length) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed:
                            _page == 0 ? null : () => setState(() => _page--),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text('${_page + 1}'),
                      ),
                      IconButton.filled(
                        onPressed: items.length == AppConstants.pageSize
                            ? () => setState(() => _page++)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  );
                }
                final place = items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: _AdminPlaceThumb(place: place),
                    title: Text(place.name),
                    subtitle: Text(
                      '${place.city}, ${place.state} · ${place.category}\n'
                      'Rating ${place.rating.toStringAsFixed(1)} · '
                      '${place.formattedLikes} likes · '
                      '${place.featured ? 'Featured' : place.isPopular ? 'Popular' : 'Standard'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editPlace(place),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editPlace([TourismPlace? place]) async {
    final name = TextEditingController(text: place?.name);
    final description = TextEditingController(text: place?.description);
    final state = TextEditingController(text: place?.state);
    final city = TextEditingController(text: place?.city);
    final district = TextEditingController(text: place?.district);
    final category = TextEditingController(text: place?.category);
    final subcategory = TextEditingController(text: place?.subcategory);
    final latitude = TextEditingController(text: place?.latitude.toString());
    final longitude = TextEditingController(text: place?.longitude.toString());
    final images = TextEditingController(text: _adminListToText(place?.images));
    final timings = TextEditingController(text: place?.timings);
    final bestSeason = TextEditingController(text: place?.bestSeason);
    final bestMonths =
        TextEditingController(text: _adminListToText(place?.bestMonths));
    final safety = TextEditingController(
      text: _adminListToText(place?.safetyGuidelines),
    );
    final tips = TextEditingController(
      text: _adminListToText(place?.touristTips),
    );
    final indianFee = TextEditingController(
      text: place?.entryFeeIndian.toString(),
    );
    final foreignerFee = TextEditingController(
      text: place?.entryFeeForeigner.toString(),
    );
    final rating = TextEditingController(text: place?.rating.toString());
    final likes = TextEditingController(text: place?.likesCount.toString());
    final tier = TextEditingController(text: place?.tier.toString());
    final duration = TextEditingController(
      text: place?.visitDurationMinutes?.toString(),
    );
    final address = TextEditingController(text: place?.address);
    var featured = place?.featured ?? false;
    var popular = place?.isPopular ?? false;
    final saved = await showModalBottomSheet<bool>(
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
                Text(
                  place == null ? 'Add destination' : 'Edit destination',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Update exactly what users see in Home, details, planner and AI.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: 'name'.tr()),
                ),
                TextField(
                  controller: description,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: 'about'.tr()),
                ),
                TextField(
                  controller: state,
                  decoration: InputDecoration(labelText: 'state'.tr()),
                ),
                TextField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextField(
                  controller: district,
                  decoration: InputDecoration(labelText: 'district'.tr()),
                ),
                TextField(
                  controller: category,
                  decoration: InputDecoration(labelText: 'category'.tr()),
                ),
                TextField(
                  controller: subcategory,
                  decoration: const InputDecoration(labelText: 'Subcategory'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Latitude'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Longitude'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: address,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: 'address'.tr()),
                ),
                TextField(
                  controller: images,
                  minLines: 2,
                  maxLines: 5,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Photo URLs',
                    hintText: 'Paste one image URL per line',
                  ),
                ),
                const SizedBox(height: 6),
                _AdminPhotoPreview(controller: images),
                TextField(
                  controller: timings,
                  decoration: InputDecoration(labelText: 'timings'.tr()),
                ),
                TextField(
                  controller: bestSeason,
                  decoration: InputDecoration(labelText: 'best_season'.tr()),
                ),
                TextField(
                  controller: bestMonths,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Best months',
                    hintText: 'October\\nNovember\\nDecember',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: indianFee,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Indian fee',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: foreignerFee,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Foreigner fee',
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rating,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Rating 0-5'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: likes,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Likes count'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tier,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Tier 1-3'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration minutes',
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: safety,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Safety guidelines',
                    hintText: 'One guideline per line',
                  ),
                ),
                TextField(
                  controller: tips,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Tourist tips',
                    hintText: 'One tip per line',
                  ),
                ),
                SwitchListTile(
                  value: featured,
                  title: Text('featured_destinations'.tr()),
                  onChanged: (value) => setSheetState(() => featured = value),
                ),
                SwitchListTile(
                  value: popular,
                  title: const Text('Popular place'),
                  onChanged: (value) => setSheetState(() => popular = value),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty ||
                          state.text.trim().isEmpty ||
                          city.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name, city and state are required.'),
                          ),
                        );
                        return;
                      }
                      final parsedLatitude = double.tryParse(latitude.text);
                      final parsedLongitude = double.tryParse(longitude.text);
                      if (parsedLatitude == null || parsedLongitude == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Valid latitude and longitude required.'),
                          ),
                        );
                        return;
                      }
                      await ref.read(tourismRepositoryProvider).saveAdminPlace(
                            id: place?.id,
                            name: name.text,
                            description: description.text,
                            state: state.text,
                            city: city.text,
                            category: category.text,
                            district: district.text,
                            subcategory: subcategory.text,
                            latitude: parsedLatitude,
                            longitude: parsedLongitude,
                            images: _adminLines(images.text),
                            entryFeeIndian:
                                double.tryParse(indianFee.text) ?? 0,
                            entryFeeForeigner:
                                double.tryParse(foreignerFee.text) ?? 0,
                            timings: timings.text,
                            bestSeason: bestSeason.text,
                            bestMonths: _adminLines(bestMonths.text),
                            safetyGuidelines: _adminLines(safety.text),
                            touristTips: _adminLines(tips.text),
                            tier: int.tryParse(tier.text) ?? 2,
                            featured: featured,
                            rating: double.tryParse(rating.text) ?? 4.2,
                            isPopular: popular,
                            likesCount: int.tryParse(likes.text) ?? 1000,
                            visitDurationMinutes: int.tryParse(duration.text),
                            address: address.text,
                          );
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    child: Text('save'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    description.dispose();
    state.dispose();
    city.dispose();
    district.dispose();
    category.dispose();
    subcategory.dispose();
    latitude.dispose();
    longitude.dispose();
    images.dispose();
    timings.dispose();
    bestSeason.dispose();
    bestMonths.dispose();
    safety.dispose();
    tips.dispose();
    indianFee.dispose();
    foreignerFee.dispose();
    rating.dispose();
    likes.dispose();
    tier.dispose();
    duration.dispose();
    address.dispose();
    if (saved == true) {
      ref.invalidate(adminTourismPlacesProvider);
      ref.invalidate(featuredPlacesProvider);
      ref.invalidate(popularPlacesProvider);
      ref.invalidate(trendingPlacesProvider);
      ref.invalidate(mustVisitPlacesProvider);
      ref.invalidate(explorerPlacesProvider);
    }
  }

  void _confirmAdminSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('sign_out_question'.tr()),
        content: Text('sign_out_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.authSelection);
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text('sign_out'.tr()),
          ),
        ],
      ),
    );
  }
}

String _adminListToText(List<String>? values) {
  if (values == null || values.isEmpty) return '';
  return values.join('\n');
}

List<String> _adminLines(String value) {
  return value
      .split(RegExp(r'[\n,]'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

class _AdminPlaceThumb extends StatelessWidget {
  const _AdminPlaceThumb({required this.place});

  final TourismPlace place;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: place.primaryImage.isEmpty
            ? Container(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.image_outlined),
              )
            : Image.network(
                place.primaryImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
      ),
    );
  }
}

class _AdminPhotoPreview extends StatefulWidget {
  const _AdminPhotoPreview({required this.controller});

  final TextEditingController controller;

  @override
  State<_AdminPhotoPreview> createState() => _AdminPhotoPreviewState();
}

class _AdminPhotoPreviewState extends State<_AdminPhotoPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final urls = _adminLines(widget.controller.text);
    if (urls.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No photos added yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.take(8).length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            urls[index],
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 76,
              height: 76,
              color: AppColors.grey200,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardOverviewTab extends ConsumerWidget {
  const _AdminDashboardOverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardStatsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 36),
              SizedBox(height: 12),
              Text(
                'UniSafeX Admin Control Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Control places, banners, feature flags, alerts and users without app updates.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        stats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Dashboard stats unavailable. $error'),
            ),
          ),
          data: (stats) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AdminStatCard(
                label: 'Places',
                value: stats.places,
                icon: Icons.account_balance_rounded,
              ),
              _AdminStatCard(
                label: 'Banners',
                value: stats.banners,
                icon: Icons.campaign_rounded,
              ),
              _AdminStatCard(
                label: 'Alerts',
                value: stats.alerts,
                icon: Icons.warning_amber_rounded,
              ),
              _AdminStatCard(
                label: 'Users',
                value: stats.users,
                icon: Icons.people_alt_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBannersAdminTab extends ConsumerWidget {
  const _HomeBannersAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(adminHomeBannersProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _AdminSectionHeader(
          title: 'Home Banner Manager',
          subtitle:
              'Festival, hotel, flight, featured city and emergency banners.',
          actionLabel: 'Add banner',
          onAction: () => _editBanner(context, ref),
        ),
        banners.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) => items.isEmpty
              ? const _AdminEmptyCard(text: 'No banners yet.')
              : Column(
                  children: items
                      .map(
                        (banner) => Card(
                          child: ListTile(
                            leading: Icon(
                              _bannerIcon(banner.bannerType),
                              color: banner.isActive
                                  ? AppColors.primary
                                  : AppColors.grey500,
                            ),
                            title: Text(banner.title),
                            subtitle: Text(
                              '${banner.bannerType} · priority ${banner.priority} · '
                              '${banner.isActive ? 'active' : 'hidden'}',
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _editBanner(context, ref, banner),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _editBanner(
    BuildContext context,
    WidgetRef ref, [
    HomeBanner? banner,
  ]) async {
    final title = TextEditingController(text: banner?.title);
    final subtitle = TextEditingController(text: banner?.subtitle);
    final image = TextEditingController(text: banner?.imageUrl);
    final actionLabel = TextEditingController(text: banner?.actionLabel);
    final actionRoute = TextEditingController(text: banner?.actionRoute);
    final city = TextEditingController(text: banner?.city);
    final state = TextEditingController(text: banner?.state);
    final priority = TextEditingController(text: '${banner?.priority ?? 100}');
    var type = banner?.bannerType ?? 'featured_city';
    var active = banner?.isActive ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _AdminFormSheet(
          title: banner == null ? 'Add banner' : 'Edit banner',
          children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
                controller: subtitle,
                decoration: const InputDecoration(labelText: 'Subtitle')),
            TextField(
                controller: image,
                decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(
                controller: actionLabel,
                decoration: const InputDecoration(labelText: 'Action label')),
            TextField(
                controller: actionRoute,
                decoration: const InputDecoration(labelText: 'Action route')),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Banner type'),
              items: const [
                DropdownMenuItem(value: 'festival', child: Text('Festival')),
                DropdownMenuItem(
                    value: 'hotel_promo', child: Text('Hotel promo')),
                DropdownMenuItem(
                    value: 'flight_promo', child: Text('Flight promo')),
                DropdownMenuItem(
                    value: 'featured_city', child: Text('Featured city')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
              ],
              onChanged: (value) => setSheetState(() => type = value ?? type),
            ),
            TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City optional')),
            TextField(
                controller: state,
                decoration: const InputDecoration(labelText: 'State optional')),
            TextField(
              controller: priority,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            SwitchListTile(
              value: active,
              title: const Text('Active'),
              onChanged: (value) => setSheetState(() => active = value),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                await ref
                    .read(adminRemoteConfigRepositoryProvider)
                    .saveHomeBanner(
                      id: banner?.id,
                      title: title.text,
                      subtitle: subtitle.text,
                      imageUrl: image.text,
                      actionLabel: actionLabel.text,
                      actionRoute: actionRoute.text,
                      bannerType: type,
                      city: city.text,
                      state: state.text,
                      priority: int.tryParse(priority.text) ?? 100,
                      isActive: active,
                    );
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save banner'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      title,
      subtitle,
      image,
      actionLabel,
      actionRoute,
      city,
      state,
      priority,
    ]) {
      controller.dispose();
    }
    if (saved == true) {
      ref.invalidate(adminHomeBannersProvider);
      ref.invalidate(activeHomeBannersProvider);
    }
  }

  IconData _bannerIcon(String type) {
    return switch (type) {
      'festival' => Icons.celebration_rounded,
      'hotel_promo' => Icons.hotel_rounded,
      'flight_promo' => Icons.flight_takeoff_rounded,
      'emergency' => Icons.warning_amber_rounded,
      _ => Icons.location_city_rounded,
    };
  }
}

class _FeatureFlagsAdminTab extends ConsumerWidget {
  const _FeatureFlagsAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(adminFeatureFlagsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const _AdminSectionHeader(
          title: 'Feature Flags',
          subtitle: 'Turn app features on or off from Supabase.',
        ),
        flags.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) => Column(
            children: items
                .map(
                  (flag) => Card(
                    child: SwitchListTile(
                      value: flag.enabled,
                      title: Text(flag.key),
                      subtitle: Text(flag.description ?? ''),
                      onChanged: (enabled) async {
                        await ref
                            .read(adminRemoteConfigRepositoryProvider)
                            .saveFeatureFlag(
                              AppFeatureFlag(
                                key: flag.key,
                                enabled: enabled,
                                description: flag.description,
                              ),
                            );
                        ref.invalidate(adminFeatureFlagsProvider);
                        ref.invalidate(publicFeatureFlagsProvider);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TravelAlertsAdminTab extends ConsumerWidget {
  const _TravelAlertsAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(adminTravelAlertsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _AdminSectionHeader(
          title: 'Notifications / Travel Alerts',
          subtitle: 'Create city, state or India-wide alerts for travelers.',
          actionLabel: 'Add alert',
          onAction: () => _editAlert(context, ref),
        ),
        alerts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) => items.isEmpty
              ? const _AdminEmptyCard(text: 'No alerts yet.')
              : Column(
                  children: items
                      .map(
                        (alert) => Card(
                          child: ListTile(
                            leading: Icon(
                              _alertIcon(alert.severity),
                              color: _alertColor(alert.severity),
                            ),
                            title: Text(alert.title),
                            subtitle: Text(
                              '${alert.severity} · ${alert.city ?? alert.state ?? 'India'} · '
                              '${alert.isActive ? 'active' : 'hidden'}',
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => _editAlert(context, ref, alert),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _editAlert(
    BuildContext context,
    WidgetRef ref, [
    TravelAlert? alert,
  ]) async {
    final title = TextEditingController(text: alert?.title);
    final message = TextEditingController(text: alert?.message);
    final city = TextEditingController(text: alert?.city);
    final state = TextEditingController(text: alert?.state);
    var severity = alert?.severity ?? 'info';
    var active = alert?.isActive ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _AdminFormSheet(
          title: alert == null ? 'Add travel alert' : 'Edit travel alert',
          children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title')),
            TextField(
              controller: message,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            DropdownButtonFormField<String>(
              initialValue: severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: const [
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'warning', child: Text('Warning')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
              ],
              onChanged: (value) =>
                  setSheetState(() => severity = value ?? severity),
            ),
            TextField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City optional')),
            TextField(
                controller: state,
                decoration: const InputDecoration(labelText: 'State optional')),
            SwitchListTile(
              value: active,
              title: const Text('Active'),
              onChanged: (value) => setSheetState(() => active = value),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty || message.text.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(adminRemoteConfigRepositoryProvider)
                    .saveTravelAlert(
                      id: alert?.id,
                      title: title.text,
                      message: message.text,
                      severity: severity,
                      city: city.text,
                      state: state.text,
                      isActive: active,
                    );
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save alert'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    message.dispose();
    city.dispose();
    state.dispose();
    if (saved == true) {
      ref.invalidate(adminTravelAlertsProvider);
      ref.invalidate(activeTravelAlertsProvider);
    }
  }
}

class _UsersAdminTab extends ConsumerWidget {
  const _UsersAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(adminProfilesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const _AdminSectionHeader(
          title: 'Users / Profiles',
          subtitle:
              'Read-only user profile overview for support and operations.',
        ),
        profiles.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) => items.isEmpty
              ? const _AdminEmptyCard(text: 'No profiles yet.')
              : Column(
                  children: items
                      .map(
                        (profile) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(profile.initials),
                            ),
                            title: Text(profile.displayName),
                            subtitle: Text(
                              '${profile.email ?? 'No email'}\n'
                              '${profile.currentLocation ?? 'No location'} · '
                              '${profile.visaType ?? 'No visa'}',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _AdminFormSheet extends StatelessWidget {
  const _AdminFormSheet({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            ...children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminErrorCard extends StatelessWidget {
  const _AdminErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
            'Could not load admin data. Apply the remote config SQL migration first.\n\n$error'),
      ),
    );
  }
}

class _AdminEmptyCard extends StatelessWidget {
  const _AdminEmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(text),
      ),
    );
  }
}

IconData _alertIcon(String severity) {
  return switch (severity) {
    'emergency' => Icons.emergency_rounded,
    'warning' => Icons.warning_amber_rounded,
    _ => Icons.info_outline_rounded,
  };
}

Color _alertColor(String severity) {
  return switch (severity) {
    'emergency' => AppColors.error,
    'warning' => AppColors.warning,
    _ => AppColors.primary,
  };
}

enum _AdminGuideFilter {
  all('All'),
  active('Active'),
  pending('Pending'),
  processing('Processing'),
  confirmed('Confirmed'),
  booked('Booked'),
  rejected('Rejected'),
  completed('Completed');

  const _AdminGuideFilter(this.label);

  final String label;
}

class _GuideRequestsAdminTab extends ConsumerStatefulWidget {
  const _GuideRequestsAdminTab();

  @override
  ConsumerState<_GuideRequestsAdminTab> createState() =>
      _GuideRequestsAdminTabState();
}

class _GuideRequestsAdminTabState
    extends ConsumerState<_GuideRequestsAdminTab> {
  final _search = TextEditingController();
  _AdminGuideFilter _filter = _AdminGuideFilter.active;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminGuideRequestsProvider);
    final profiles = ref.watch(adminGuideProfilesProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminGuideRequestsProvider),
      child: requests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const _AdminGuideHeader(total: 0),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  'Guide requests could not be loaded. Apply the '
                  'guide_requests SQL in Supabase first.\n\n$error',
                ),
              ),
            ),
          ],
        ),
        data: (items) {
          final filtered = _filterRequests(items);
          final active = filtered.where(_isActiveAdminRequest).toList();
          final history =
              filtered.where((item) => !_isActiveAdminRequest(item)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _AdminGuideHeader(total: items.length),
              const SizedBox(height: 12),
              profiles.when(
                data: (items) => _SavedGuidesStrip(
                  profiles: items,
                  onEdit: (profile) => _editSavedGuide(context, ref, profile),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              _AdminGuideFilterBar(
                controller: _search,
                filter: _filter,
                total: filtered.length,
                onChanged: () => setState(() {}),
                onFilterChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _AdminGuideEmpty()
              else if (filtered.isEmpty)
                const _AdminGuideFilteredEmpty()
              else ...[
                if (active.isNotEmpty) ...[
                  _AdminGuideSectionTitle(
                    title: 'Active work queue',
                    count: active.length,
                  ),
                  ...active.map(_requestCard),
                ],
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _AdminGuideSectionTitle(
                    title: 'Request history',
                    count: history.length,
                  ),
                  ...history.map(_requestCard),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  List<GuideRequest> _filterRequests(List<GuideRequest> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((request) {
      final statusMatches = switch (_filter) {
        _AdminGuideFilter.all => true,
        _AdminGuideFilter.active => _isActiveAdminRequest(request),
        _AdminGuideFilter.pending =>
          request.status == GuideRequestStatus.pending,
        _AdminGuideFilter.processing =>
          request.status == GuideRequestStatus.processing,
        _AdminGuideFilter.confirmed =>
          request.status == GuideRequestStatus.confirmed,
        _AdminGuideFilter.booked => request.bookingStatus == 'booked',
        _AdminGuideFilter.rejected =>
          request.status == GuideRequestStatus.rejected,
        _AdminGuideFilter.completed =>
          request.status == GuideRequestStatus.completed,
      };
      if (!statusMatches) return false;
      if (query.isEmpty) return true;
      final haystack = [
        request.placeName,
        request.city,
        request.userEmail,
        request.guideName,
        request.contactNote,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Widget _requestCard(GuideRequest request) {
    return _AdminGuideRequestCard(
      request: request,
      savedGuides: ref.read(adminGuideProfilesProvider).valueOrNull ?? const [],
      onApplyGuide: (profile) async {
        await ref.read(guideRequestRepositoryProvider).applyGuideProfile(
              requestId: request.id,
              profile: profile,
              adminNote: 'Assigned ${profile.name} from saved guides',
            );
        ref.invalidate(adminGuideRequestsProvider);
      },
      onEditGuide: () => _editGuideDetails(context, ref, request),
      onStatusChanged: (status) async {
        await ref.read(guideRequestRepositoryProvider).updateStatus(
              requestId: request.id,
              status: status,
              adminNote: 'Updated from UniSafeX admin dashboard',
            );
        ref.invalidate(adminGuideRequestsProvider);
      },
    );
  }

  Future<void> _editSavedGuide(
    BuildContext context,
    WidgetRef ref,
    GuideProfile profile,
  ) async {
    final saved = await _showGuideProfileSheet(
      context: context,
      ref: ref,
      profile: profile,
      title: 'Edit saved guide',
      subtitle: 'Update this guide for future one-click assignments.',
    );
    if (saved == true) {
      ref.invalidate(adminGuideProfilesProvider);
      ref.invalidate(adminGuideRequestsProvider);
    }
  }

  Future<void> _editGuideDetails(
    BuildContext context,
    WidgetRef ref,
    GuideRequest request,
  ) async {
    final note = TextEditingController(text: request.adminNote);
    var confirmRequest = request.status != GuideRequestStatus.confirmed;
    var selectedProfileId = request.guideProfileId;

    final saved = await _showGuideProfileSheet(
      context: context,
      ref: ref,
      profile: request.hasAssignedGuide
          ? GuideProfile(
              id: request.guideProfileId ?? '',
              name: request.guideName ?? '',
              photoUrl: request.guidePhotoUrl,
              phone: request.guidePhone,
              languages: request.guideLanguages,
              experienceYears: request.guideExperienceYears,
              bio: request.guideBio,
              chargeAmount: request.guideChargeAmount,
              chargeCurrency: request.guideChargeCurrency ?? 'INR',
              meetingPoint: request.guideMeetingPoint,
            )
          : null,
      title: 'Assign guide profile',
      subtitle: '${request.placeName} · ${request.userEmail ?? ''}',
      noteController: note,
      confirmRequest: confirmRequest,
      selectedProfileId: selectedProfileId,
      onConfirmChanged: (value) => confirmRequest = value,
      onSelectedProfileChanged: (value) => selectedProfileId = value,
      onSave: ({
        required String guideName,
        required String guidePhotoUrl,
        required String guidePhone,
        required String guideLanguages,
        required int? guideExperienceYears,
        required String guideBio,
        required double? guideChargeAmount,
        required String guideChargeCurrency,
        required String guideMeetingPoint,
      }) async {
        await ref.read(guideRequestRepositoryProvider).updateGuideDetails(
              requestId: request.id,
              guideProfileId: selectedProfileId,
              guideName: guideName,
              guidePhotoUrl: guidePhotoUrl,
              guidePhone: guidePhone,
              guideLanguages: guideLanguages,
              guideExperienceYears: guideExperienceYears,
              guideBio: guideBio,
              guideChargeAmount: guideChargeAmount,
              guideChargeCurrency: guideChargeCurrency,
              guideMeetingPoint: guideMeetingPoint,
              adminNote: note.text,
              confirmRequest: confirmRequest,
            );
      },
    );

    note.dispose();

    if (saved == true) {
      ref.invalidate(adminGuideProfilesProvider);
      ref.invalidate(adminGuideRequestsProvider);
    }
  }

  Future<bool?> _showGuideProfileSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    GuideProfile? profile,
    TextEditingController? noteController,
    bool? confirmRequest,
    String? selectedProfileId,
    ValueChanged<bool>? onConfirmChanged,
    ValueChanged<String?>? onSelectedProfileChanged,
    Future<void> Function({
      required String guideName,
      required String guidePhotoUrl,
      required String guidePhone,
      required String guideLanguages,
      required int? guideExperienceYears,
      required String guideBio,
      required double? guideChargeAmount,
      required String guideChargeCurrency,
      required String guideMeetingPoint,
    })? onSave,
  }) async {
    final savedProfiles =
        ref.read(adminGuideProfilesProvider).valueOrNull ?? [];
    final name = TextEditingController(text: profile?.name);
    final photo = TextEditingController(text: profile?.photoUrl);
    final phone = TextEditingController(text: profile?.phone);
    final languages = TextEditingController(text: profile?.languages);
    final experience = TextEditingController(
      text: profile?.experienceYears?.toString(),
    );
    final bio = TextEditingController(text: profile?.bio);
    final charge = TextEditingController(
      text: profile?.chargeAmount?.toString(),
    );
    final currency =
        TextEditingController(text: profile?.chargeCurrency ?? 'INR');
    final meeting = TextEditingController(text: profile?.meetingPoint);
    var localConfirm = confirmRequest ?? false;
    var localSelectedProfileId =
        selectedProfileId?.isNotEmpty == true ? selectedProfileId : null;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(subtitle),
                const SizedBox(height: 16),
                if (savedProfiles.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: localSelectedProfileId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Use saved guide',
                      prefixIcon: Icon(Icons.verified_user_rounded),
                    ),
                    items: savedProfiles
                        .map(
                          (profile) => DropdownMenuItem(
                            value: profile.id,
                            child: Text(
                              '${profile.name} · ${profile.formattedCharge}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final profile = savedProfiles.firstWhere(
                        (item) => item.id == value,
                      );
                      setSheetState(() {
                        localSelectedProfileId = value;
                        name.text = profile.name;
                        photo.text = profile.photoUrl ?? '';
                        phone.text = profile.phone ?? '';
                        languages.text = profile.languages ?? '';
                        experience.text =
                            profile.experienceYears?.toString() ?? '';
                        bio.text = profile.bio ?? '';
                        charge.text = profile.chargeAmount?.toString() ?? '';
                        currency.text = profile.chargeCurrency;
                        meeting.text = profile.meetingPoint ?? '';
                      });
                      onSelectedProfileChanged?.call(value);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Guide name'),
                ),
                TextField(
                  controller: photo,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'Guide photo URL'),
                ),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Guide phone'),
                ),
                TextField(
                  controller: languages,
                  decoration: const InputDecoration(
                    labelText: 'Languages',
                    hintText: 'English, Hindi, French...',
                  ),
                ),
                TextField(
                  controller: experience,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Experience years'),
                ),
                TextField(
                  controller: bio,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Guide short bio'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: charge,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Guide charges'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        controller: currency,
                        textCapitalization: TextCapitalization.characters,
                        decoration:
                            const InputDecoration(labelText: 'Currency'),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: meeting,
                  decoration: const InputDecoration(labelText: 'Meeting point'),
                ),
                if (noteController != null)
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Admin note'),
                  ),
                if (confirmRequest != null)
                  SwitchListTile(
                    value: localConfirm,
                    title: const Text('Confirm request after saving'),
                    subtitle: const Text(
                      'User will see this verified guide card and booking button.',
                    ),
                    onChanged: (value) {
                      setSheetState(() => localConfirm = value);
                      onConfirmChanged?.call(value);
                    },
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (name.text.trim().isEmpty ||
                          charge.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Guide name and charges required.'),
                          ),
                        );
                        return;
                      }
                      if (onSave != null) {
                        await onSave(
                          guideName: name.text,
                          guidePhotoUrl: photo.text,
                          guidePhone: phone.text,
                          guideLanguages: languages.text,
                          guideExperienceYears: int.tryParse(experience.text),
                          guideBio: bio.text,
                          guideChargeAmount: double.tryParse(charge.text),
                          guideChargeCurrency: currency.text,
                          guideMeetingPoint: meeting.text,
                        );
                      } else {
                        await ref
                            .read(guideRequestRepositoryProvider)
                            .saveGuideProfile(
                              profileId: profile?.id.isNotEmpty == true
                                  ? profile!.id
                                  : null,
                              name: name.text,
                              photoUrl: photo.text,
                              phone: phone.text,
                              languages: languages.text,
                              experienceYears: int.tryParse(experience.text),
                              bio: bio.text,
                              chargeAmount: double.tryParse(charge.text),
                              chargeCurrency: currency.text,
                              meetingPoint: meeting.text,
                            );
                      }
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: Text(onSave == null
                        ? 'Save guide'
                        : 'Save and assign guide'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    name.dispose();
    photo.dispose();
    phone.dispose();
    languages.dispose();
    experience.dispose();
    bio.dispose();
    charge.dispose();
    currency.dispose();
    meeting.dispose();
    return saved;
  }
}

class _MapAccessAdminTab extends ConsumerStatefulWidget {
  const _MapAccessAdminTab();

  @override
  ConsumerState<_MapAccessAdminTab> createState() => _MapAccessAdminTabState();
}

class _MapAccessAdminTabState extends ConsumerState<_MapAccessAdminTab> {
  MapAccessConfig? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(mapAccessConfigProvider);
    final config = _draft ?? configState.valueOrNull ?? const MapAccessConfig();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(Icons.map_rounded, color: Colors.white, size: 34),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Maps access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Control in-app maps from Supabase. If Google Cloud '
                      'quota is tight, switch users to external directions.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (configState.hasError)
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Map settings table is not ready yet. Apply the app_settings '
                'SQL migration in Supabase, then reload admin.\n\n'
                '${configState.error}',
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: config.inAppMapsEnabled,
                  title: const Text('Use in-app Google Maps for users'),
                  subtitle: const Text(
                    'Off = users see a redirect screen and open external '
                    'Google Maps directions. This avoids loading the map SDK.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _draft = config.copyWith(
                        inAppMapsEnabled: value,
                        routeOverlayEnabled:
                            value ? config.routeOverlayEnabled : false,
                      );
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  value: config.routeOverlayEnabled,
                  title: const Text('Route overlay, time and center controls'),
                  subtitle: const Text(
                    'Off = hide center/start navigation and avoid route '
                    'calculation calls. Basic destination map can still show.',
                  ),
                  onChanged: config.inAppMapsEnabled
                      ? (value) {
                          setState(() {
                            _draft = config.copyWith(
                              routeOverlayEnabled: value,
                            );
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MapModeStatusCard(config: config),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(config),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(MapAccessConfig config) async {
    setState(() => _saving = true);
    try {
      await ref.read(mapAccessConfigRepositoryProvider).save(config);
      ref.invalidate(mapAccessConfigProvider);
      if (!mounted) return;
      setState(() => _draft = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map access settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save map settings. $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MapModeStatusCard extends StatelessWidget {
  const _MapModeStatusCard({required this.config});

  final MapAccessConfig config;

  @override
  Widget build(BuildContext context) {
    final text = config.inAppMapsEnabled
        ? config.routeOverlayEnabled
            ? 'Users see in-app map + route navigation.'
            : 'Users see in-app destination map only.'
        : 'Users are sent to external Google Maps directions.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.inAppMapsEnabled
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _AdminGuideFilterBar extends StatelessWidget {
  const _AdminGuideFilterBar({
    required this.controller,
    required this.filter,
    required this.total,
    required this.onChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final _AdminGuideFilter filter;
  final int total;
  final VoidCallback onChanged;
  final ValueChanged<_AdminGuideFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Find guide requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _InfoChip(
                  icon: Icons.filter_alt_rounded,
                  label: '$total shown',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: 'Search place, city, email, guide...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          controller.clear();
                          onChanged();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _AdminGuideFilter.values
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: filter == item,
                          label: Text(item.label),
                          onSelected: (_) => onFilterChanged(item),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminGuideSectionTitle extends StatelessWidget {
  const _AdminGuideSectionTitle({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.list_alt_rounded, label: '$count'),
        ],
      ),
    );
  }
}

class _AdminGuideFilteredEmpty extends StatelessWidget {
  const _AdminGuideFilteredEmpty();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Text('No guide requests match this search or filter.'),
      ),
    );
  }
}

bool _isActiveAdminRequest(GuideRequest request) {
  if (request.status == GuideRequestStatus.rejected ||
      request.status == GuideRequestStatus.completed ||
      request.bookingStatus == 'booked') {
    return false;
  }
  return true;
}

class _AdminGuideHeader extends StatelessWidget {
  final int total;

  const _AdminGuideHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded,
              color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total guide requests',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'New guide requests are saved here with user email, place, '
                  'travelers and 7-day confirmation target.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminGuideEmpty extends StatelessWidget {
  const _AdminGuideEmpty();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 34, color: AppColors.grey400),
            SizedBox(height: 10),
            Text('No guide requests yet'),
            SizedBox(height: 4),
            Text(
              'When users request Delhi guides, they will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedGuidesStrip extends StatelessWidget {
  final List<GuideProfile> profiles;
  final ValueChanged<GuideProfile> onEdit;

  const _SavedGuidesStrip({
    required this.profiles,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Saved guide profiles will appear here after you assign your first guide.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saved guide profiles',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _SavedGuideProfileCard(
              profile: profiles[index],
              onEdit: () => onEdit(profiles[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedGuideProfileCard extends StatelessWidget {
  final GuideProfile profile;
  final VoidCallback onEdit;

  const _SavedGuideProfileCard({
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: profile.photoUrl?.isNotEmpty == true
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl?.isNotEmpty == true
                ? null
                : const Icon(Icons.verified_user_rounded,
                    color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const Icon(Icons.verified_rounded,
                        size: 15, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  profile.formattedCharge,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.languages ?? 'Languages pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit saved guide',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _AdminGuideRequestCard extends StatelessWidget {
  final GuideRequest request;
  final List<GuideProfile> savedGuides;
  final ValueChanged<GuideProfile> onApplyGuide;
  final VoidCallback onEditGuide;
  final ValueChanged<GuideRequestStatus> onStatusChanged;

  const _AdminGuideRequestCard({
    required this.request,
    required this.savedGuides,
    required this.onApplyGuide,
    required this.onEditGuide,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.person_pin_circle_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.placeName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.city} · ${request.travelers} traveler(s)',
                      ),
                      if (request.userEmail?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(request.userEmail!),
                      ],
                    ],
                  ),
                ),
                _AdminStatusMenu(
                  status: request.status,
                  onChanged: onStatusChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.event_available_rounded,
                  label: 'By ${_formatAdminDate(request.expectedBy)}',
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: 'Requested ${_formatAdminDate(request.requestedAt)}',
                ),
              ],
            ),
            if (request.contactNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('User note: ${request.contactNote}'),
            ],
            if (request.adminNote?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('Admin note: ${request.adminNote}'),
            ],
            if (request.hasAssignedGuide) ...[
              const SizedBox(height: 10),
              _AdminGuideProfileSummary(request: request),
            ],
            if (request.status != GuideRequestStatus.rejected &&
                savedGuides.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Quick assign saved guide',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: savedGuides.take(4).map((profile) {
                  return ActionChip(
                    avatar: const Icon(Icons.verified_rounded, size: 16),
                    label: Text(profile.name),
                    onPressed: () => onApplyGuide(profile),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.status != GuideRequestStatus.rejected) ...[
                  if (savedGuides.isNotEmpty)
                    PopupMenuButton<GuideProfile>(
                      onSelected: onApplyGuide,
                      itemBuilder: (context) => savedGuides
                          .map(
                            (profile) => PopupMenuItem(
                              value: profile,
                              child: Text(
                                '${profile.name} · ${profile.formattedCharge}',
                              ),
                            ),
                          )
                          .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 7),
                            Text(
                              'Use saved guide',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: onEditGuide,
                    icon: const Icon(Icons.badge_rounded),
                    label: Text(
                      request.hasAssignedGuide
                          ? 'Edit guide profile'
                          : 'Assign guide',
                    ),
                  ),
                ] else
                  const _InfoChip(
                    icon: Icons.block_rounded,
                    label: 'Rejected - no guide assignment',
                  ),
                OutlinedButton.icon(
                  onPressed: () => _openWhatsapp(request),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp admin'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openEmail(request),
                  icon: const Icon(Icons.email_rounded),
                  label: const Text('Email admin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsapp(GuideRequest request) async {
    final message = Uri.encodeComponent(
      'UniSafeX guide request\n'
      'Place: ${request.placeName}, ${request.city}\n'
      'Travelers: ${request.travelers}\n'
      'User: ${request.userEmail ?? 'Not available'}\n'
      'Expected by: ${_formatAdminDate(request.expectedBy)}',
    );
    await launchUrl(
      Uri.parse(
        'https://wa.me/${GuideRequestDefaults.adminWhatsappInternational}'
        '?text=$message',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _openEmail(GuideRequest request) async {
    final subject = Uri.encodeComponent('UniSafeX guide request');
    final body = Uri.encodeComponent(
      'Place: ${request.placeName}, ${request.city}\n'
      'Travelers: ${request.travelers}\n'
      'User: ${request.userEmail ?? 'Not available'}\n'
      'Requested: ${_formatAdminDate(request.requestedAt)}\n'
      'Expected by: ${_formatAdminDate(request.expectedBy)}\n'
      'Note: ${request.contactNote}',
    );
    await launchUrl(
      Uri.parse(
        'mailto:${GuideRequestDefaults.adminEmail}'
        '?subject=$subject&body=$body',
      ),
    );
  }
}

class _AdminStatusMenu extends StatelessWidget {
  final GuideRequestStatus status;
  final ValueChanged<GuideRequestStatus> onChanged;

  const _AdminStatusMenu({
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<GuideRequestStatus>(
      initialValue: status,
      onSelected: onChanged,
      itemBuilder: (context) => GuideRequestStatus.values
          .map(
            (value) => PopupMenuItem(
              value: value,
              child: Text(_statusLabel(value)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor(status).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _statusLabel(status),
          style: TextStyle(
            color: _statusColor(status),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AdminGuideProfileSummary extends StatelessWidget {
  final GuideRequest request;

  const _AdminGuideProfileSummary({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: request.guidePhotoUrl?.isNotEmpty == true
                ? NetworkImage(request.guidePhotoUrl!)
                : null,
            child: request.guidePhotoUrl?.isNotEmpty == true
                ? null
                : const Icon(Icons.badge_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.guideName ?? 'Assigned guide',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${request.formattedGuideCharge}'
                  '${request.bookingStatus == 'booked' ? ' · Booked' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (request.guidePhone?.isNotEmpty == true)
                  Text(
                    request.guidePhone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.grey600),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _statusLabel(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => 'Pending',
    GuideRequestStatus.processing => 'Processing',
    GuideRequestStatus.confirmed => 'Confirmed',
    GuideRequestStatus.rejected => 'Rejected',
    GuideRequestStatus.completed => 'Completed',
  };
}

Color _statusColor(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => AppColors.warning,
    GuideRequestStatus.processing => AppColors.primary,
    GuideRequestStatus.confirmed => AppColors.success,
    GuideRequestStatus.rejected => AppColors.error,
    GuideRequestStatus.completed => AppColors.success,
  };
}

String _formatAdminDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}
