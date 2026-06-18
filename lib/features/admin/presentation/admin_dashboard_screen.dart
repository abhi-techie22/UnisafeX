import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';
import 'package:unisafex/features/guide/presentation/providers/guide_request_provider.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';
import 'package:unisafex/features/heritage/domain/heritage_monument.dart';
import 'package:unisafex/features/maps/data/map_access_config_provider.dart';

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
      length: 3,
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
            tabs: [
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Places'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'Guides'),
              Tab(icon: Icon(Icons.map_rounded), text: 'Maps'),
            ],
          ),
        ),
        floatingActionButton: access.value == true
            ? FloatingActionButton.extended(
                onPressed: () => _editMonument(),
                icon: const Icon(Icons.add_rounded),
                label: Text('add_monument'.tr()),
              )
            : null,
        body: access.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (allowed) {
            if (!allowed) {
              return Center(child: Text('admin_access_denied'.tr()));
            }
            final query = HeritageQuery(
              search: _search.text,
              page: _page,
              includeInactive: true,
            );
            final monuments = ref.watch(heritageMonumentsProvider(query));
            return TabBarView(
              children: [
                _buildPlacesTab(monuments),
                const _GuideRequestsAdminTab(),
                const _MapAccessAdminTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlacesTab(AsyncValue<List<HeritageMonument>> monuments) {
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
          child: monuments.when(
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
                        onPressed: items.length == HeritageRepository.pageSize
                            ? () => setState(() => _page++)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  );
                }
                final monument = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      monument.isActive
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: monument.isActive
                          ? AppColors.success
                          : AppColors.grey500,
                    ),
                    title: Text(monument.name),
                    subtitle: Text(
                      '${monument.state} · '
                      '${monument.monumentType ?? 'category'.tr()}',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editMonument(monument),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editMonument([HeritageMonument? monument]) async {
    final name = TextEditingController(text: monument?.name);
    final state = TextEditingController(text: monument?.state);
    final locality = TextEditingController(text: monument?.locality);
    final district = TextEditingController(text: monument?.district);
    final type = TextEditingController(text: monument?.monumentType);
    final description = TextEditingController(text: monument?.description);
    final imageUrl = TextEditingController(text: monument?.imageUrl);
    final timings = TextEditingController(text: monument?.timings);
    final indianFee = TextEditingController(
      text: monument?.entryFeeIndian?.toString(),
    );
    final foreignerFee = TextEditingController(
      text: monument?.entryFeeForeigner?.toString(),
    );
    var active = monument?.isActive ?? true;
    var featured = monument?.featured ?? false;
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
                  monument == null ? 'add_monument'.tr() : 'edit_monument'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: 'name'.tr()),
                ),
                TextField(
                  controller: state,
                  decoration: InputDecoration(labelText: 'state'.tr()),
                ),
                TextField(
                  controller: locality,
                  decoration: InputDecoration(labelText: 'locality'.tr()),
                ),
                TextField(
                  controller: district,
                  decoration: InputDecoration(labelText: 'district'.tr()),
                ),
                TextField(
                  controller: type,
                  decoration: InputDecoration(labelText: 'category'.tr()),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'about'.tr()),
                ),
                TextField(
                  controller: imageUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                ),
                TextField(
                  controller: timings,
                  decoration: InputDecoration(labelText: 'timings'.tr()),
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
                SwitchListTile(
                  value: featured,
                  title: Text('featured_destinations'.tr()),
                  onChanged: (value) => setSheetState(() => featured = value),
                ),
                SwitchListTile(
                  value: active,
                  title: Text('published'.tr()),
                  onChanged: (value) => setSheetState(() => active = value),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty ||
                          state.text.trim().isEmpty) {
                        return;
                      }
                      await ref.read(heritageRepositoryProvider).saveMonument(
                            id: monument?.id,
                            name: name.text,
                            state: state.text,
                            locality: locality.text,
                            district: district.text,
                            type: type.text,
                            description: description.text,
                            imageUrl: imageUrl.text,
                            timings: timings.text,
                            entryFeeIndian: double.tryParse(indianFee.text),
                            entryFeeForeigner:
                                double.tryParse(foreignerFee.text),
                            featured: featured,
                            isActive: active,
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
    state.dispose();
    locality.dispose();
    district.dispose();
    type.dispose();
    description.dispose();
    imageUrl.dispose();
    timings.dispose();
    indianFee.dispose();
    foreignerFee.dispose();
    if (saved == true) {
      ref.invalidate(heritageMonumentsProvider);
      ref.invalidate(heritageFilterOptionsProvider);
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
