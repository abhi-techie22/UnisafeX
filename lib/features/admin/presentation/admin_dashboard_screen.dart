import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';
import 'package:unisafex/features/tourism/data/services/currency_service.dart';
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
  final _placeCity = TextEditingController();
  final _placeState = TextEditingController();
  final _placeCategory = TextEditingController();
  int _page = 0;
  String _placeGroup = 'all';

  @override
  void dispose() {
    _search.dispose();
    _placeCity.dispose();
    _placeState.dispose();
    _placeCategory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(isAdminProvider);
    return DefaultTabController(
      length: 14,
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
              Tab(icon: Icon(Icons.group_add_rounded), text: 'Team'),
              Tab(icon: Icon(Icons.support_rounded), text: 'Support'),
              Tab(icon: Icon(Icons.rate_review_rounded), text: 'Reviews'),
              Tab(icon: Icon(Icons.timeline_rounded), text: 'Activity'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'Guides'),
              Tab(
                  icon: Icon(Icons.currency_exchange_rounded),
                  text: 'Currency'),
              Tab(icon: Icon(Icons.mark_email_read_rounded), text: 'Auth'),
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
                AdminTourismPlacesParams(
                  search: _search.text,
                  city: _placeCity.text,
                  state: _placeState.text,
                  category: _placeCategory.text,
                  group: _placeGroup,
                  page: _page,
                ),
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
                const _TeamAdminTab(),
                const _SupportTicketsAdminTab(),
                const _ReviewsAdminTab(),
                const _ActivityAdminTab(),
                const _GuideRequestsAdminTab(),
                const _CurrencyRatesAdminTab(),
                const _AuthAccessAdminTab(),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => _refreshPlaceFilters(),
                  decoration: InputDecoration(
                    hintText: 'search_places_hint'.tr(),
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Add place',
                onPressed: () => _editPlace(),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _AdminPlaceFilters(
            city: _placeCity,
            state: _placeState,
            category: _placeCategory,
            group: _placeGroup,
            onGroupChanged: (value) {
              setState(() {
                _placeGroup = value;
                _page = 0;
              });
            },
            onTextChanged: _refreshPlaceFilters,
            onClear: _clearPlaceFilters,
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
                    title: Row(
                      children: [
                        Expanded(child: Text(place.name)),
                        if (place.isHidden)
                          const Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(Icons.visibility_off_outlined),
                            label: Text('Hidden'),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${place.city}, ${place.state} · ${place.category}\n'
                      'Rating ${place.rating.toStringAsFixed(1)} · '
                      '${place.formattedLikes} likes · '
                      '${place.featured ? 'Featured' : place.isPopular ? 'Popular' : 'Standard'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPlace(place);
                        } else if (value == 'visibility') {
                          _togglePlaceHidden(place);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'visibility',
                          child: ListTile(
                            leading: Icon(
                              place.isHidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            title: Text(
                              place.isHidden
                                  ? 'Show to travelers'
                                  : 'Hide from travelers',
                            ),
                          ),
                        ),
                      ],
                    ),
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

  void _refreshPlaceFilters() {
    setState(() => _page = 0);
  }

  void _clearPlaceFilters() {
    setState(() {
      _search.clear();
      _placeCity.clear();
      _placeState.clear();
      _placeCategory.clear();
      _placeGroup = 'all';
      _page = 0;
    });
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
    var hidden = place?.isHidden ?? false;
    var uploadingImage = false;
    var selectedImageType = _adminImageTypes.first;
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place == null
                                ? 'Add destination'
                                : 'Edit destination',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Update Home cards, details, planner, AI and guide listings from one place.',
                            style:
                                TextStyle(color: Colors.white70, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminEditorSection(
                      title: 'Basic Details',
                      subtitle: 'Main content shown to travelers.',
                      icon: Icons.edit_location_alt_outlined,
                      children: [
                        TextField(
                          controller: name,
                          decoration: InputDecoration(labelText: 'name'.tr()),
                        ),
                        TextField(
                          controller: description,
                          maxLines: 4,
                          decoration: InputDecoration(labelText: 'about'.tr()),
                        ),
                        _AdminTwoColumnFields(
                          left: TextField(
                            controller: state,
                            decoration:
                                InputDecoration(labelText: 'state'.tr()),
                          ),
                          right: TextField(
                            controller: city,
                            decoration:
                                const InputDecoration(labelText: 'City'),
                          ),
                        ),
                        _AdminTwoColumnFields(
                          left: TextField(
                            controller: district,
                            decoration:
                                InputDecoration(labelText: 'district'.tr()),
                          ),
                          right: TextField(
                            controller: category,
                            decoration:
                                InputDecoration(labelText: 'category'.tr()),
                          ),
                        ),
                        TextField(
                          controller: subcategory,
                          decoration:
                              const InputDecoration(labelText: 'Subcategory'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AdminEditorSection(
                      title: 'Location',
                      subtitle:
                          'Coordinates power map, nearby distance and route.',
                      icon: Icons.map_outlined,
                      children: [
                        _AdminTwoColumnFields(
                          left: TextField(
                              controller: latitude,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration:
                                  const InputDecoration(labelText: 'Latitude')),
                          right: TextField(
                              controller: longitude,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                  labelText: 'Longitude')),
                        ),
                        TextField(
                          controller: address,
                          maxLines: 2,
                          decoration:
                              InputDecoration(labelText: 'address'.tr()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AdminEditorSection(
                      title: 'Photos',
                      subtitle:
                          'Pick from your folder or paste existing public image URLs.',
                      icon: Icons.photo_library_outlined,
                      children: [
                        _AdminPhotoPreview(controller: images),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedImageType,
                          decoration: const InputDecoration(
                            labelText: 'Image type',
                            prefixIcon: Icon(Icons.category_outlined),
                            helperText:
                                'Choose how this uploaded photo should be used.',
                          ),
                          items: _adminImageTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setSheetState(
                            () =>
                                selectedImageType = value ?? selectedImageType,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: uploadingImage
                                    ? null
                                    : () async {
                                        final picker = ImagePicker();
                                        final files =
                                            await picker.pickMultiImage(
                                          imageQuality: 88,
                                          maxWidth: 1800,
                                        );
                                        if (files.isEmpty) return;
                                        setSheetState(
                                            () => uploadingImage = true);
                                        try {
                                          final next = _adminLines(images.text)
                                            ..addAll(
                                              await Future.wait(
                                                files.map((file) async {
                                                  final bytes =
                                                      await file.readAsBytes();
                                                  final extension =
                                                      file.name.split('.').last;
                                                  return ref
                                                      .read(
                                                          tourismRepositoryProvider)
                                                      .uploadAdminPlaceImageBytes(
                                                        bytes: bytes,
                                                        extension: extension,
                                                        placeName: name.text,
                                                        imageType:
                                                            selectedImageType,
                                                      );
                                                }),
                                              ),
                                            );
                                          images.text = next.join('\n');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '${files.length} image${files.length == 1 ? '' : 's'} uploaded and added. Press Save to update this destination.',
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (error) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Could not upload image. Apply the tourism-media storage migration first. $error',
                                                ),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (context.mounted) {
                                            setSheetState(
                                              () => uploadingImage = false,
                                            );
                                          }
                                        }
                                      },
                                icon: uploadingImage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.upload_file_outlined),
                                label: Text(
                                  uploadingImage
                                      ? 'Uploading images...'
                                      : 'Upload images from folder',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              tooltip: 'Clear photos',
                              onPressed: images.text.trim().isEmpty
                                  ? null
                                  : () => images.clear(),
                              icon: const Icon(Icons.delete_sweep_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: images,
                          minLines: 2,
                          maxLines: 5,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Photo URLs / uploaded image URLs',
                            hintText:
                                'Upload from folder or paste one public image URL per line',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AdminEditorSection(
                      title: 'Visitor Information',
                      subtitle: 'Fees, timing, season and duration.',
                      icon: Icons.confirmation_number_outlined,
                      children: [
                        TextField(
                          controller: timings,
                          decoration:
                              InputDecoration(labelText: 'timings'.tr()),
                        ),
                        _AdminTwoColumnFields(
                          left: TextField(
                            controller: bestSeason,
                            decoration:
                                InputDecoration(labelText: 'best_season'.tr()),
                          ),
                          right: TextField(
                            controller: duration,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration minutes',
                            ),
                          ),
                        ),
                        TextField(
                          controller: bestMonths,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Best months',
                            hintText: 'October\\nNovember\\nDecember',
                          ),
                        ),
                        _AdminTwoColumnFields(
                          left: TextField(
                            controller: indianFee,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Indian fee',
                            ),
                          ),
                          right: TextField(
                            controller: foreignerFee,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Foreigner fee',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _AdminEditorSection(
                      title: 'Ranking & Guidance',
                      subtitle:
                          'Control popularity, safety, tips and Home groups.',
                      icon: Icons.auto_graph_outlined,
                      children: [
                        _AdminTwoColumnFields(
                          left: TextField(
                            controller: rating,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(labelText: 'Rating 0-5'),
                          ),
                          right: TextField(
                            controller: likes,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Likes count'),
                          ),
                        ),
                        TextField(
                          controller: tier,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Tier 1-3'),
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
                          contentPadding: EdgeInsets.zero,
                          title: Text('featured_destinations'.tr()),
                          onChanged: (value) =>
                              setSheetState(() => featured = value),
                        ),
                        SwitchListTile(
                          value: popular,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Popular place'),
                          onChanged: (value) =>
                              setSheetState(() => popular = value),
                        ),
                        SwitchListTile(
                          value: hidden,
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.visibility_off_outlined),
                          title: const Text('Hide from traveler app'),
                          subtitle: const Text(
                            'Admins can still find and edit this place.',
                          ),
                          onChanged: (value) =>
                              setSheetState(() => hidden = value),
                        ),
                      ],
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
                                content:
                                    Text('Name, city and state are required.'),
                              ),
                            );
                            return;
                          }
                          final parsedLatitude = double.tryParse(latitude.text);
                          final parsedLongitude =
                              double.tryParse(longitude.text);
                          if (parsedLatitude == null ||
                              parsedLongitude == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Valid latitude and longitude required.'),
                              ),
                            );
                            return;
                          }
                          await ref
                              .read(tourismRepositoryProvider)
                              .saveAdminPlace(
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
                                isHidden: hidden,
                                likesCount: int.tryParse(likes.text) ?? 1000,
                                visitDurationMinutes:
                                    int.tryParse(duration.text),
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
      ref.invalidate(plannerPlacesProvider);
      ref.invalidate(placesByCategoryProvider);
      ref.invalidate(placesByCityProvider);
      ref.invalidate(searchPlacesProvider);
      ref.invalidate(nearbyPlacesProvider);
    }
  }

  Future<void> _togglePlaceHidden(TourismPlace place) async {
    await ref.read(tourismRepositoryProvider).setAdminPlaceHidden(
          id: place.id,
          hidden: !place.isHidden,
        );
    ref.invalidate(adminTourismPlacesProvider);
    ref.invalidate(featuredPlacesProvider);
    ref.invalidate(popularPlacesProvider);
    ref.invalidate(trendingPlacesProvider);
    ref.invalidate(mustVisitPlacesProvider);
    ref.invalidate(explorerPlacesProvider);
    ref.invalidate(plannerPlacesProvider);
    ref.invalidate(placesByCategoryProvider);
    ref.invalidate(placesByCityProvider);
    ref.invalidate(searchPlacesProvider);
    ref.invalidate(nearbyPlacesProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          place.isHidden
              ? '${place.name} is visible to travelers.'
              : '${place.name} is hidden from travelers.',
        ),
      ),
    );
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

class _AdminPlaceFilters extends StatelessWidget {
  const _AdminPlaceFilters({
    required this.city,
    required this.state,
    required this.category,
    required this.group,
    required this.onGroupChanged,
    required this.onTextChanged,
    required this.onClear,
  });

  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController category;
  final String group;
  final ValueChanged<String> onGroupChanged;
  final VoidCallback onTextChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasAdvanced = city.text.trim().isNotEmpty ||
        state.text.trim().isNotEmpty ||
        category.text.trim().isNotEmpty;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _AdminFilterChoiceChip(
                          label: 'All',
                          selected: group == 'all',
                          onTap: () => onGroupChanged('all'),
                        ),
                        _AdminFilterChoiceChip(
                          label: 'Featured',
                          selected: group == 'featured',
                          onTap: () => onGroupChanged('featured'),
                        ),
                        _AdminFilterChoiceChip(
                          label: 'Popular',
                          selected: group == 'popular',
                          onTap: () => onGroupChanged('popular'),
                        ),
                        _AdminFilterChoiceChip(
                          label: 'Free',
                          selected: group == 'free',
                          onTap: () => onGroupChanged('free'),
                        ),
                        _AdminFilterChoiceChip(
                          label: 'Hidden gems',
                          selected: group == 'hidden_gems',
                          onTap: () => onGroupChanged('hidden_gems'),
                        ),
                        _AdminFilterChoiceChip(
                          label: 'No photos',
                          selected: group == 'missing_photos',
                          onTap: () => onGroupChanged('missing_photos'),
                        ),
                        _AdminFilterChoiceChip(
                          label: 'Hidden',
                          selected: group == 'hidden',
                          onTap: () => onGroupChanged('hidden'),
                        ),
                      ]
                          .map(
                            (chip) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: chip,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Clear filters',
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            if (hasAdvanced) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (city.text.trim().isNotEmpty)
                    InputChip(
                      label: Text(city.text.trim()),
                      onDeleted: () {
                        city.clear();
                        onTextChanged();
                      },
                    ),
                  if (state.text.trim().isNotEmpty)
                    InputChip(
                      label: Text(state.text.trim()),
                      onDeleted: () {
                        state.clear();
                        onTextChanged();
                      },
                    ),
                  if (category.text.trim().isNotEmpty)
                    InputChip(
                      label: Text(category.text.trim()),
                      onDeleted: () {
                        category.clear();
                        onTextChanged();
                      },
                    ),
                ],
              ),
            ],
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                dense: true,
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.tune_rounded, color: AppColors.primary),
                title: Text(
                  'City, state, category',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 720;
                      final fields = [
                        TextField(
                          controller: city,
                          onChanged: (_) => onTextChanged(),
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        TextField(
                          controller: state,
                          onChanged: (_) => onTextChanged(),
                          decoration: const InputDecoration(
                            labelText: 'State',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                        ),
                        TextField(
                          controller: category,
                          onChanged: (_) => onTextChanged(),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                        ),
                      ];

                      if (compact) {
                        return Column(
                          children: fields.expand(
                            (field) sync* {
                              yield field;
                              if (field != fields.last) {
                                yield const SizedBox(height: 10);
                              }
                            },
                          ).toList(),
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: 10),
                          Expanded(child: fields[1]),
                          const SizedBox(width: 10),
                          Expanded(child: fields[2]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminFilterChoiceChip extends StatelessWidget {
  const _AdminFilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.35)
            : Theme.of(context).dividerColor,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
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

class _AdminEditorSection extends StatelessWidget {
  const _AdminEditorSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                foregroundColor: AppColors.primary,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children.expand((child) sync* {
            yield child;
            if (child != children.last) yield const SizedBox(height: 10);
          }),
        ],
      ),
    );
  }
}

class _AdminTwoColumnFields extends StatelessWidget {
  const _AdminTwoColumnFields({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              left,
              const SizedBox(height: 10),
              right,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 10),
            Expanded(child: right),
          ],
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${urls.length} photo${urls.length == 1 ? '' : 's'} added',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    urls[index],
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: AppColors.grey200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Material(
                    color: AppColors.error,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _removePhoto(index),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _removePhoto(int index) {
    final urls = _adminLines(widget.controller.text);
    if (index < 0 || index >= urls.length) return;
    urls.removeAt(index);
    widget.controller.text = urls.join('\n');
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
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editBanner(context, ref, banner);
                                } else if (value == 'delete') {
                                  _confirmDeleteBanner(context, ref, banner);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Future<void> _confirmDeleteBanner(
    BuildContext context,
    WidgetRef ref,
    HomeBanner banner,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete home banner?'),
        content: Text(
          'This will permanently remove "${banner.title}" from home banners.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(adminRemoteConfigRepositoryProvider)
        .deleteHomeBanner(banner.id);
    ref.invalidate(adminHomeBannersProvider);
    ref.invalidate(activeHomeBannersProvider);
    ref.invalidate(adminDashboardStatsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Home banner deleted.')),
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
      ref.invalidate(adminDashboardStatsProvider);
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
          data: (items) {
            final bookingFlags = items
                .where(
                  (flag) =>
                      flag.key == 'feature_hotels_enabled' ||
                      flag.key == 'feature_flights_enabled',
                )
                .toList();
            final otherFlags = items
                .where(
                  (flag) =>
                      flag.key != 'feature_hotels_enabled' &&
                      flag.key != 'feature_flights_enabled',
                )
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BookingFeatureFlagsCard(
                  flags: bookingFlags,
                  onToggle: (flag, enabled) => _saveFlag(ref, flag, enabled),
                ),
                const SizedBox(height: 12),
                Text(
                  'Other app features',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                ...otherFlags.map(
                  (flag) => Card(
                    child: SwitchListTile(
                      value: flag.enabled,
                      title: Text(_featureFlagTitle(flag.key)),
                      subtitle: Text(flag.description ?? flag.key),
                      secondary: Icon(_featureFlagIcon(flag.key)),
                      onChanged: (enabled) => _saveFlag(ref, flag, enabled),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveFlag(
    WidgetRef ref,
    AppFeatureFlag flag,
    bool enabled,
  ) async {
    await ref.read(adminRemoteConfigRepositoryProvider).saveFeatureFlag(
          AppFeatureFlag(
            key: flag.key,
            enabled: enabled,
            description: flag.description,
          ),
        );
    ref.invalidate(adminFeatureFlagsProvider);
    ref.invalidate(publicFeatureFlagsProvider);
  }
}

class _BookingFeatureFlagsCard extends StatelessWidget {
  const _BookingFeatureFlagsCard({
    required this.flags,
    required this.onToggle,
  });

  final List<AppFeatureFlag> flags;
  final Future<void> Function(AppFeatureFlag flag, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final hotels = _flag(
      key: 'feature_hotels_enabled',
      description: 'Show hotel booking features',
    );
    final flights = _flag(
      key: 'feature_flights_enabled',
      description: 'Show flight booking features',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF173F35), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.luggage_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Booking features',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Hide or show booking buttons on Home and protect direct routes.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          _BookingFeatureSwitch(
            title: 'Hotel booking',
            subtitle: hotels.enabled ? 'Visible to users' : 'Hidden from users',
            icon: Icons.bed_rounded,
            value: hotels.enabled,
            onChanged: (enabled) => onToggle(hotels, enabled),
          ),
          const SizedBox(height: 10),
          _BookingFeatureSwitch(
            title: 'Flight booking',
            subtitle:
                flights.enabled ? 'Visible to users' : 'Hidden from users',
            icon: Icons.flight_takeoff_rounded,
            value: flights.enabled,
            onChanged: (enabled) => onToggle(flights, enabled),
          ),
        ],
      ),
    );
  }

  AppFeatureFlag _flag({
    required String key,
    required String description,
  }) {
    for (final flag in flags) {
      if (flag.key == key) return flag;
    }
    return AppFeatureFlag(
      key: key,
      enabled: true,
      description: description,
    );
  }
}

class _BookingFeatureSwitch extends StatelessWidget {
  const _BookingFeatureSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accentLight,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

String _featureFlagTitle(String key) {
  return switch (key) {
    'feature_ai_assistant_enabled' => 'AI Travel Assistant',
    'feature_sos_enabled' => 'SOS / Emergency',
    'feature_festival_campaign_enabled' => 'Festival Campaigns',
    'feature_audio_guide_enabled' => 'Audio Guide',
    'feature_trip_planner_enabled' => 'Smart Trip Planner',
    _ => key
        .replaceAll('feature_', '')
        .replaceAll('_enabled', '')
        .replaceAll('_', ' '),
  };
}

IconData _featureFlagIcon(String key) {
  return switch (key) {
    'feature_ai_assistant_enabled' => Icons.auto_awesome_rounded,
    'feature_sos_enabled' => Icons.sos_rounded,
    'feature_festival_campaign_enabled' => Icons.celebration_rounded,
    'feature_audio_guide_enabled' => Icons.volume_up_rounded,
    'feature_trip_planner_enabled' => Icons.route_rounded,
    _ => Icons.tune_rounded,
  };
}

enum _AdminAlertFilter {
  all('All'),
  active('Active'),
  hidden('Hidden'),
  info('Info'),
  warning('Warning'),
  emergency('Emergency');

  const _AdminAlertFilter(this.label);

  final String label;
}

class _TravelAlertsAdminTab extends ConsumerStatefulWidget {
  const _TravelAlertsAdminTab();

  @override
  ConsumerState<_TravelAlertsAdminTab> createState() =>
      _TravelAlertsAdminTabState();
}

class _TravelAlertsAdminTabState extends ConsumerState<_TravelAlertsAdminTab> {
  final _search = TextEditingController();
  _AdminAlertFilter _filter = _AdminAlertFilter.active;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          data: (items) {
            final filtered = _filterAlerts(items);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminSearchFilterCard<_AdminAlertFilter>(
                  controller: _search,
                  hintText: 'Search title, message, city, state...',
                  total: filtered.length,
                  values: _AdminAlertFilter.values,
                  selected: _filter,
                  labelFor: (filter) => filter.label,
                  onChanged: () => setState(() {}),
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const _AdminEmptyCard(text: 'No alerts yet.')
                else if (filtered.isEmpty)
                  const _AdminEmptyCard(
                    text: 'No alerts match this search or filter.',
                  )
                else
                  ...filtered.map(
                    (alert) => Card(
                      child: ListTile(
                        leading: Icon(
                          _alertIcon(alert.severity),
                          color: _alertColor(alert.severity),
                        ),
                        title: Text(alert.title),
                        subtitle: Text(
                          '${alert.severity} · ${alert.city ?? alert.state ?? 'India'} · '
                          '${alert.isActive ? 'visible on Home' : 'hidden'}\n'
                          '${alert.message}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editAlert(context, ref, alert);
                            } else if (value == 'delete') {
                              _confirmDeleteAlert(context, ref, alert);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _editAlert(context, ref, alert),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<TravelAlert> _filterAlerts(List<TravelAlert> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((alert) {
      final filterMatches = switch (_filter) {
        _AdminAlertFilter.all => true,
        _AdminAlertFilter.active => alert.isActive,
        _AdminAlertFilter.hidden => !alert.isActive,
        _AdminAlertFilter.info => alert.severity == 'info',
        _AdminAlertFilter.warning => alert.severity == 'warning',
        _AdminAlertFilter.emergency => alert.severity == 'emergency',
      };
      if (!filterMatches) return false;
      if (query.isEmpty) return true;
      final text = [
        alert.title,
        alert.message,
        alert.severity,
        alert.city,
        alert.state,
      ].whereType<String>().join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Future<void> _confirmDeleteAlert(
    BuildContext context,
    WidgetRef ref,
    TravelAlert alert,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete travel alert?'),
        content: Text(
          'This will permanently remove "${alert.title}" from admin and Home.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(adminRemoteConfigRepositoryProvider).deleteTravelAlert(
          alert.id,
        );
    ref.invalidate(adminTravelAlertsProvider);
    ref.invalidate(activeTravelAlertsProvider);
    ref.invalidate(adminDashboardStatsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Travel alert deleted.')),
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

enum _AdminUserFilter {
  all('All'),
  completed('Complete'),
  incomplete('Incomplete'),
  hasEmail('Has email'),
  missingEmail('Missing email'),
  hasLocation('Has location');

  const _AdminUserFilter(this.label);

  final String label;
}

class _UsersAdminTab extends ConsumerStatefulWidget {
  const _UsersAdminTab();

  @override
  ConsumerState<_UsersAdminTab> createState() => _UsersAdminTabState();
}

class _UsersAdminTabState extends ConsumerState<_UsersAdminTab> {
  final _search = TextEditingController();
  _AdminUserFilter _filter = _AdminUserFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          data: (items) {
            final filtered = _filterUsers(items);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminSearchFilterCard<_AdminUserFilter>(
                  controller: _search,
                  hintText: 'Search name, email, country, city, visa...',
                  total: filtered.length,
                  values: _AdminUserFilter.values,
                  selected: _filter,
                  labelFor: (filter) => filter.label,
                  onChanged: () => setState(() {}),
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const _AdminEmptyCard(text: 'No profiles yet.')
                else if (filtered.isEmpty)
                  const _AdminEmptyCard(
                    text: 'No users match this search or filter.',
                  )
                else
                  ...filtered.map(
                    (profile) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(profile.initials),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(profile.displayName)),
                            _InfoChip(
                              icon: profile.isProfileComplete
                                  ? Icons.verified_rounded
                                  : Icons.pending_actions_rounded,
                              label: profile.isProfileComplete
                                  ? 'Complete'
                                  : 'Incomplete',
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${profile.email ?? 'No email'}\n'
                          '${profile.currentLocation ?? 'No location'} · '
                          '${profile.country ?? profile.nationality ?? 'No country'} · '
                          '${profile.visaType ?? 'No visa'}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<UserProfile> _filterUsers(List<UserProfile> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((profile) {
      final filterMatches = switch (_filter) {
        _AdminUserFilter.all => true,
        _AdminUserFilter.completed => profile.isProfileComplete,
        _AdminUserFilter.incomplete => !profile.isProfileComplete,
        _AdminUserFilter.hasEmail => profile.email?.trim().isNotEmpty == true,
        _AdminUserFilter.missingEmail =>
          profile.email?.trim().isNotEmpty != true,
        _AdminUserFilter.hasLocation =>
          profile.currentLocation?.trim().isNotEmpty == true,
      };
      if (!filterMatches) return false;
      if (query.isEmpty) return true;
      final text = [
        profile.fullName,
        profile.email,
        profile.currentLocation,
        profile.country,
        profile.nationality,
        profile.visaType,
        profile.travelPurpose,
      ].whereType<String>().join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }
}

class _AdminSearchFilterCard<T> extends StatelessWidget {
  const _AdminSearchFilterCard({
    required this.controller,
    required this.hintText,
    required this.total,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    required this.onSelected,
  });

  final TextEditingController controller;
  final String hintText;
  final int total;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final VoidCallback onChanged;
  final ValueChanged<T> onSelected;

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
                    'Filter results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _InfoChip(icon: Icons.filter_alt_rounded, label: '$total'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: hintText,
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
                children: values
                    .map(
                      (value) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: value == selected,
                          label: Text(labelFor(value)),
                          onSelected: (_) => onSelected(value),
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

String _adminDate(DateTime? value) {
  if (value == null) return 'Unknown time';
  return DateFormat('dd MMM, HH:mm').format(value.toLocal());
}

const List<String> _adminImageTypes = [
  'Hero',
  'Exterior',
  'Interior',
  'Entrance',
  'Architecture detail',
  'Close-up',
  'Landscape',
  'Gallery',
];

class _TeamAdminTab extends ConsumerWidget {
  const _TeamAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(adminTeamMembersProvider);
    final activity = ref.watch(adminActivityLogProvider);
    final isOwner = ref.watch(isAdminOwnerProvider).valueOrNull ?? false;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _AdminSectionHeader(
          title: 'Team Members',
          subtitle: isOwner
              ? 'Owner-only area. Add trusted team accounts and control dashboard access.'
              : 'Only the UniSafeX owner can add members or change dashboard access.',
          actionLabel: isOwner ? 'Add member' : null,
          onAction: isOwner ? () => _addMember(context, ref) : null,
        ),
        if (!isOwner) ...[
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Team changes are locked. Ask the primary owner to add, remove, or promote admins.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        members.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) => items.isEmpty
              ? const _AdminEmptyCard(text: 'No team members yet.')
              : Column(
                  children: items
                      .map(
                        (member) => _TeamMemberProgressCard(
                          member: member,
                          logs: _logsForMember(
                            activity.valueOrNull ?? const [],
                            member,
                          ),
                          activityLoading: activity.isLoading,
                          isOwner: isOwner,
                          onAction: (value) async {
                            if (value == 'disable') {
                              await _updateMember(
                                context,
                                ref,
                                member,
                                active: false,
                              );
                            } else if (value == 'enable') {
                              await _updateMember(
                                context,
                                ref,
                                member,
                                active: true,
                              );
                            } else {
                              await _updateMember(
                                context,
                                ref,
                                member,
                                role: value,
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final email = TextEditingController();
    var role = 'editor';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _AdminFormSheet(
          title: 'Add team member',
          children: [
            const Text(
              'Team member must already have a UniSafeX account with this email.',
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Member email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'editor', child: Text('Editor')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(
                  value: 'owner',
                  child: Text('Owner - full access'),
                ),
              ],
              onChanged: (value) => setSheetState(() => role = value ?? role),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (email.text.trim().isEmpty) return;
                await ref
                    .read(adminRemoteConfigRepositoryProvider)
                    .addTeamMember(
                      email: email.text,
                      role: role,
                    );
                if (context.mounted) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Add member'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    if (saved == true) {
      ref.invalidate(adminTeamMembersProvider);
      ref.invalidate(adminActivityLogProvider);
    }
  }

  Future<void> _updateMember(
    BuildContext context,
    WidgetRef ref,
    AdminTeamMember member, {
    String? role,
    bool? active,
  }) async {
    await ref.read(adminRemoteConfigRepositoryProvider).updateTeamMember(
          AdminTeamMember(
            userId: member.userId,
            email: member.email,
            role: role ?? member.role,
            isActive: active ?? member.isActive,
            createdAt: member.createdAt,
            updatedAt: member.updatedAt,
          ),
        );
    ref.invalidate(adminTeamMembersProvider);
    ref.invalidate(adminActivityLogProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Team member updated.')),
    );
  }
}

List<AdminActivityLog> _logsForMember(
  List<AdminActivityLog> logs,
  AdminTeamMember member,
) {
  final memberId = member.userId.trim();
  if (memberId.isEmpty) return const [];
  return logs.where((log) => log.actorUserId == memberId).toList();
}

String _memberDisplayName(String email) {
  final name = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ').trim();
  if (name.isEmpty) return 'Team member';
  return name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _TeamMemberProgressCard extends StatelessWidget {
  const _TeamMemberProgressCard({
    required this.member,
    required this.logs,
    required this.activityLoading,
    required this.isOwner,
    required this.onAction,
  });

  final AdminTeamMember member;
  final List<AdminActivityLog> logs;
  final bool activityLoading;
  final bool isOwner;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final latest = logs.isEmpty ? null : logs.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  child: Text(
                    member.email.isEmpty ? '?' : member.email[0].toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _memberDisplayName(member.email),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        member.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (member.isPrimaryOwner)
                  const _InfoChip(
                    icon: Icons.verified_user_rounded,
                    label: 'Locked owner',
                  )
                else if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editor',
                        child: Text('Make editor'),
                      ),
                      const PopupMenuItem(
                        value: 'admin',
                        child: Text('Make admin'),
                      ),
                      const PopupMenuItem(
                        value: 'owner',
                        child: Text('Give full ownership'),
                      ),
                      PopupMenuItem(
                        value: member.isActive ? 'disable' : 'enable',
                        child: Text(
                          member.isActive ? 'Disable access' : 'Enable access',
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.lock_outline_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.admin_panel_settings_outlined,
                  label: member.role.toUpperCase(),
                ),
                _InfoChip(
                  icon: member.isActive
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  label: member.isActive ? 'Active' : 'Disabled',
                ),
                _InfoChip(
                  icon: Icons.task_alt_rounded,
                  label: activityLoading
                      ? 'Loading progress'
                      : '${logs.length} change${logs.length == 1 ? '' : 's'}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              latest == null
                  ? 'No tracked admin work yet.'
                  : 'Last work: ${latest.action} · ${latest.title} · ${_adminDate(latest.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketsAdminTab extends ConsumerStatefulWidget {
  const _SupportTicketsAdminTab();

  @override
  ConsumerState<_SupportTicketsAdminTab> createState() =>
      _SupportTicketsAdminTabState();
}

class _SupportTicketsAdminTabState
    extends ConsumerState<_SupportTicketsAdminTab> {
  final _search = TextEditingController();
  String _status = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(adminSupportTicketsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const _AdminSectionHeader(
          title: 'Support Center',
          subtitle:
              'Resolve user problems from inside the admin panel. Replies show in Help & Support.',
        ),
        tickets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) {
            final filtered = _filter(items);
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search ticket, email, category...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final status in const [
                              'all',
                              'open',
                              'in_progress',
                              'waiting_user',
                              'resolved',
                              'closed',
                            ])
                              ChoiceChip(
                                selected: _status == status,
                                label: Text(status.replaceAll('_', ' ')),
                                onSelected: (_) =>
                                    setState(() => _status = status),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const _AdminEmptyCard(text: 'No support tickets yet.')
                else if (filtered.isEmpty)
                  const _AdminEmptyCard(text: 'No ticket matches the filter.')
                else
                  ...filtered.map(
                    (ticket) => Card(
                      child: ListTile(
                        leading: Icon(
                          ticket.priority == 'urgent'
                              ? Icons.priority_high_rounded
                              : Icons.support_agent_rounded,
                          color: ticket.priority == 'urgent'
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                        title: Text(ticket.title),
                        subtitle: Text(
                          '${ticket.status} · ${ticket.category} · ${ticket.userEmail ?? 'unknown user'}\n'
                          '${ticket.message}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _editTicket(context, ticket),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<SupportTicket> _filter(List<SupportTicket> items) {
    final query = _search.text.trim().toLowerCase();
    return items.where((ticket) {
      if (_status != 'all' && ticket.status != _status) return false;
      if (query.isEmpty) return true;
      return [
        ticket.title,
        ticket.message,
        ticket.category,
        ticket.priority,
        ticket.status,
        ticket.userEmail,
      ].whereType<String>().join(' ').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _editTicket(BuildContext context, SupportTicket ticket) async {
    final response = TextEditingController(text: ticket.adminResponse);
    var status = ticket.status;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _AdminFormSheet(
          title: ticket.title,
          children: [
            Text('${ticket.userEmail ?? 'Unknown user'} · ${ticket.category}'),
            Text(ticket.message),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('In progress')),
                DropdownMenuItem(
                    value: 'waiting_user', child: Text('Waiting user')),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (value) =>
                  setSheetState(() => status = value ?? status),
            ),
            TextField(
              controller: response,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Admin response',
                hintText: 'Explain what was fixed or what user should do next',
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                await ref
                    .read(adminRemoteConfigRepositoryProvider)
                    .updateSupportTicket(
                      id: ticket.id,
                      status: status,
                      adminResponse: response.text,
                    );
                if (context.mounted) Navigator.pop(context, true);
              },
              icon: const Icon(Icons.done_rounded),
              label: const Text('Save response'),
            ),
          ],
        ),
      ),
    );
    response.dispose();
    if (saved == true) {
      ref.invalidate(adminSupportTicketsProvider);
      ref.invalidate(adminActivityLogProvider);
    }
  }
}

class _ReviewsAdminTab extends ConsumerStatefulWidget {
  const _ReviewsAdminTab();

  @override
  ConsumerState<_ReviewsAdminTab> createState() => _ReviewsAdminTabState();
}

class _ReviewsAdminTabState extends ConsumerState<_ReviewsAdminTab> {
  String _status = 'pending';

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(adminPlaceReviewsProvider(_status));
    final config = ref.watch(reviewModerationConfigProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const _AdminSectionHeader(
          title: 'Review Queue',
          subtitle:
              'Check traveler reviews and uploaded photos before they become public.',
        ),
        config.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (value) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require review approval'),
                    subtitle: const Text(
                      'New reviews stay pending until an admin approves them.',
                    ),
                    value: value.reviewsRequireApproval,
                    onChanged: (enabled) => _saveConfig(
                      value.copyWith(reviewsRequireApproval: enabled),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require image approval'),
                    subtitle: const Text(
                      'Review photos stay hidden until the review is approved.',
                    ),
                    value: value.imagesRequireApproval,
                    onChanged: (enabled) => _saveConfig(
                      value.copyWith(imagesRequireApproval: enabled),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in const [
                'pending',
                'approved',
                'rejected',
                'all',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _status == status,
                    label: Text(status),
                    onSelected: (_) => setState(() => _status = status),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        reviews.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) {
            if (items.isEmpty) {
              return const _AdminEmptyCard(text: 'No reviews in this queue.');
            }
            return Column(
              children: items
                  .map(
                    (review) => _AdminReviewCard(
                      review: review,
                      onApprove: () => _updateReview(review, 'approved'),
                      onReject: () => _updateReview(review, 'rejected'),
                      onReply: () => _showReplyDialog(review),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveConfig(ReviewModerationConfig config) async {
    await ref
        .read(tourismRepositoryProvider)
        .saveReviewModerationConfig(config);
    ref.invalidate(reviewModerationConfigProvider);
  }

  Future<void> _updateReview(PlaceReview review, String status) async {
    await ref.read(tourismRepositoryProvider).updateReviewStatus(
          reviewId: review.id,
          status: status,
        );
    ref.invalidate(adminPlaceReviewsProvider(_status));
    ref.invalidate(placeReviewsProvider(review.placeId));
  }

  Future<void> _showReplyDialog(PlaceReview review) async {
    final controller = TextEditingController(text: review.adminReply ?? '');
    final reply = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reply to review'),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            labelText: 'Official UniSafeX reply',
            hintText: 'Write a short helpful response from the team',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Clear'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            icon: const Icon(Icons.reply_rounded),
            label: const Text('Save reply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reply == null) return;
    await ref.read(tourismRepositoryProvider).updateReviewReply(
          reviewId: review.id,
          adminReply: reply,
        );
    ref.invalidate(adminPlaceReviewsProvider(_status));
    ref.invalidate(placeReviewsProvider(review.placeId));
  }
}

class _AdminReviewCard extends StatelessWidget {
  const _AdminReviewCard({
    required this.review,
    required this.onApprove,
    required this.onReject,
    required this.onReply,
  });

  final PlaceReview review;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReply;

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
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage:
                      review.reviewerAvatarUrl?.trim().isNotEmpty == true
                          ? NetworkImage(review.reviewerAvatarUrl!.trim())
                          : null,
                  child: review.reviewerAvatarUrl?.trim().isNotEmpty == true
                      ? null
                      : Text(
                          review.displayReviewerName.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.title?.trim().isNotEmpty == true
                            ? review.title!.trim()
                            : 'Review for ${review.placeId}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        review.displayReviewerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(review.status)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 17,
                  color: AppColors.accent,
                ),
              ),
            ),
            if (review.body?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(review.body!.trim()),
            ],
            if (review.hasAdminReply) ...[
              const SizedBox(height: 10),
              _AdminReviewReply(reply: review.adminReply!.trim()),
            ],
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      review.imageUrls[index],
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 92,
                        height: 92,
                        color: AppColors.primary.withValues(alpha: 0.08),
                        child: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: review.status == 'approved' ? null : onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: review.status == 'rejected' ? null : onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
                OutlinedButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply_rounded),
                  label: Text(review.hasAdminReply ? 'Edit reply' : 'Reply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminReviewReply extends StatelessWidget {
  const _AdminReviewReply({required this.reply});

  final String reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded,
              color: AppColors.primary, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Official UniSafeX reply',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(reply),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyRatesAdminTab extends ConsumerStatefulWidget {
  const _CurrencyRatesAdminTab();

  @override
  ConsumerState<_CurrencyRatesAdminTab> createState() =>
      _CurrencyRatesAdminTabState();
}

class _CurrencyRatesAdminTabState
    extends ConsumerState<_CurrencyRatesAdminTab> {
  static const _defaultCodes = [
    'USD',
    'INR',
    'EUR',
    'GBP',
    'AUD',
    'CAD',
    'AED',
    'SGD',
    'JPY',
    'THB',
  ];

  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  bool _fetching = false;
  String? _loadedSignature;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(adminCurrencyRatesConfigProvider);
    final config = configState.valueOrNull ?? const CurrencyRatesConfig();
    _hydrateControllers(config);
    final codes = _controllers.keys.toList()..sort();

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
              Icon(Icons.currency_exchange_rounded,
                  color: Colors.white, size: 34),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live currency values',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Update USD-based rates used by the Travel Toolkit. '
                      'Users receive these values immediately from Supabase.',
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
                'Currency settings are not ready yet. Apply the currency '
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Base currency: USD',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: config.updatedAt == null
                          ? 'Not saved'
                          : _adminDate(config.updatedAt),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter how much 1 USD equals in each currency. Keep USD = 1.',
                ),
                const SizedBox(height: 16),
                ...codes.map(_rateField),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _saving ? null : _saveRates,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save rates'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _fetching ? null : _fetchLiveRates,
                      icon: _fetching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_sync_rounded),
                      label: Text(_fetching ? 'Fetching...' : 'Fetch live'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addCurrency,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add currency'),
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

  Widget _rateField(String code) {
    final removable = code != 'USD';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controllers[code],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: code,
          helperText: code == 'USD' ? 'Base rate must stay 1' : null,
          prefixIcon: const Icon(Icons.payments_outlined),
          suffixIcon: removable
              ? IconButton(
                  tooltip: 'Remove $code',
                  onPressed: () => _removeCurrency(code),
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        ),
      ),
    );
  }

  void _hydrateControllers(CurrencyRatesConfig config) {
    final signature = config.toJson().toString();
    if (_controllers.isNotEmpty && _loadedSignature == signature) return;
    if (_controllers.isNotEmpty && _loadedSignature != null) return;
    final rates = {
      ...config.rates,
      for (final code in _defaultCodes) code: config.rates[code] ?? 0,
      'USD': 1.0,
    };
    for (final entry in rates.entries) {
      _controllers[entry.key] = TextEditingController(
        text: entry.value == 0 ? '' : entry.value.toString(),
      );
    }
    _loadedSignature = signature;
  }

  Map<String, double> _readRates() {
    final rates = <String, double>{'USD': 1};
    for (final entry in _controllers.entries) {
      final code = entry.key.trim().toUpperCase();
      final value = double.tryParse(entry.value.text.trim());
      if (code.isEmpty || value == null || value <= 0) continue;
      rates[code] = code == 'USD' ? 1 : value;
    }
    return rates;
  }

  Future<void> _saveRates() async {
    final rates = _readRates();
    if (rates.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid currency rate.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRemoteConfigRepositoryProvider)
          .saveCurrencyRatesConfig(
            CurrencyRatesConfig(
              base: 'USD',
              rates: rates,
              updatedAt: DateTime.now(),
              source: 'admin',
            ),
          );
      ref.invalidate(adminCurrencyRatesConfigProvider);
      ref.invalidate(adminActivityLogProvider);
      if (!mounted) return;
      setState(() {
        _loadedSignature = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Currency rates saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save currency rates. $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _fetchLiveRates() async {
    setState(() => _fetching = true);
    try {
      final rates = await CurrencyService().fetchLiveRates('USD');
      setState(() {
        for (final entry in rates.rates.entries) {
          final controller = _controllers.putIfAbsent(
            entry.key,
            () => TextEditingController(),
          );
          controller.text = entry.value.toString();
        }
        _controllers['USD']?.text = '1';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Live currency rates loaded. Press Save.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch live rates. $error')),
      );
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _addCurrency() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add currency'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          maxLength: 3,
          decoration: const InputDecoration(
            labelText: 'Currency code',
            hintText: 'USD, EUR, INR',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim().toUpperCase()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.length != 3 || _controllers.containsKey(code)) {
      return;
    }
    setState(() => _controllers[code] = TextEditingController());
  }

  void _removeCurrency(String code) {
    final controller = _controllers.remove(code);
    controller?.dispose();
    setState(() {});
  }
}

class _AuthAccessAdminTab extends ConsumerStatefulWidget {
  const _AuthAccessAdminTab();

  @override
  ConsumerState<_AuthAccessAdminTab> createState() =>
      _AuthAccessAdminTabState();
}

class _AuthAccessAdminTabState extends ConsumerState<_AuthAccessAdminTab> {
  static final Uri _supabaseEmailProviderUrl = Uri.parse(
    'https://supabase.com/dashboard/project/anslzankezcrxvuoidxj/auth/providers',
  );

  AuthAccessConfig? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(authAccessConfigProvider);
    final config =
        _draft ?? configState.valueOrNull ?? const AuthAccessConfig();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 34),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email confirmation control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Save app login behavior here, then match the real '
                      'Supabase Auth provider setting.',
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
                'Auth settings table is not ready yet. Apply the app_settings '
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
                  value: config.emailConfirmationRequired,
                  title: const Text('Require email confirmation in app flow'),
                  subtitle: Text(
                    config.emailConfirmationRequired
                        ? 'ON: registration asks users to confirm email before sign in.'
                        : 'OFF: app expects instant login after signup. Supabase Email provider must also have Confirm email OFF.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _draft = config.copyWith(
                        emailConfirmationRequired: value,
                        showResendConfirmation: value,
                      );
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  value: config.showResendConfirmation,
                  title: const Text('Show resend confirmation on login'),
                  subtitle: const Text(
                    'Hide this when email confirmation is disabled.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _draft = config.copyWith(showResendConfirmation: value);
                    });
                  },
                ),
                const Divider(),
                SwitchListTile(
                  value: config.guestLoginEnabled,
                  title: const Text('Show guest login button'),
                  subtitle: Text(
                    config.guestLoginEnabled
                        ? 'ON: visitors can explore limited app features without signing in.'
                        : 'OFF: auth screen only shows email, Google and create account.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _draft = config.copyWith(guestLoginEnabled: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _AuthModeStatusCard(config: config),
                const SizedBox(height: 12),
                Card(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Important: Flutter cannot safely turn Supabase email '
                      'confirmation ON/OFF with the public anon key. For real '
                      'instant signup, open Supabase Auth > Providers > Email '
                      'and turn Confirm email OFF. Never put service-role keys '
                      'inside the app.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(config),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save app setting'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openSupabaseEmailProvider,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open Supabase Email provider'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _draft = config.copyWith(
                            emailConfirmationRequired: false,
                            showResendConfirmation: false,
                          );
                        });
                      },
                      icon: const Icon(Icons.flash_on_rounded),
                      label: const Text('Set app to instant signup'),
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

  Future<void> _save(AuthAccessConfig config) async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRemoteConfigRepositoryProvider).saveAuthAccessConfig(
            config,
          );
      ref.invalidate(authAccessConfigProvider);
      ref.invalidate(adminActivityLogProvider);
      if (!mounted) return;
      setState(() => _draft = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth app settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save auth settings. $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openSupabaseEmailProvider() async {
    await launchUrl(_supabaseEmailProviderUrl);
  }
}

class _AuthModeStatusCard extends StatelessWidget {
  const _AuthModeStatusCard({required this.config});

  final AuthAccessConfig config;

  @override
  Widget build(BuildContext context) {
    final instant = !config.emailConfirmationRequired;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (instant ? AppColors.success : AppColors.primary)
            .withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (instant ? AppColors.success : AppColors.primary)
              .withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            instant ? Icons.flash_on_rounded : Icons.verified_user_rounded,
            color: instant ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              instant
                  ? 'App mode: instant signup. Users can continue immediately only after Supabase Confirm email is OFF.'
                  : 'App mode: secure email confirmation. Users confirm email before signing in.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityAdminTab extends ConsumerWidget {
  const _ActivityAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(adminActivityLogProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const _AdminSectionHeader(
          title: 'Team Progress',
          subtitle: 'See recent admin changes and who changed app content.',
        ),
        activity.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _AdminErrorCard(error: error),
          data: (items) => items.isEmpty
              ? const _AdminEmptyCard(text: 'No activity recorded yet.')
              : Column(
                  children: items
                      .map(
                        (item) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.history_rounded,
                              color: AppColors.primary,
                            ),
                            title: Text(item.action),
                            subtitle: Text(
                              '${item.entityType} · ${item.title}\n'
                              '${_adminDate(item.createdAt)} · ${item.actorUserId ?? 'system'}',
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
