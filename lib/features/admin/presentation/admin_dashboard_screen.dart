import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';
import 'package:unisafex/features/guide/presentation/providers/guide_request_provider.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';
import 'package:unisafex/features/heritage/domain/heritage_monument.dart';

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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin_console'.tr()),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Places'),
              Tab(icon: Icon(Icons.support_agent_rounded), text: 'Guides'),
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
}

class _GuideRequestsAdminTab extends ConsumerWidget {
  const _GuideRequestsAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(adminGuideRequestsProvider);
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
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _AdminGuideHeader(total: items.length),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _AdminGuideEmpty()
            else
              ...items.map((request) => _AdminGuideRequestCard(
                    request: request,
                    onStatusChanged: (status) async {
                      await ref
                          .read(guideRequestRepositoryProvider)
                          .updateStatus(
                            requestId: request.id,
                            status: status,
                            adminNote: 'Updated from UniSafeX admin dashboard',
                          );
                      ref.invalidate(adminGuideRequestsProvider);
                    },
                  )),
          ],
        ),
      ),
    );
  }
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

class _AdminGuideRequestCard extends StatelessWidget {
  final GuideRequest request;
  final ValueChanged<GuideRequestStatus> onStatusChanged;

  const _AdminGuideRequestCard({
    required this.request,
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
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
