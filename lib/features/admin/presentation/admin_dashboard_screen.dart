import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisafex/core/theme/app_theme.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text('admin_console'.tr())),
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
                        style:
                            const TextStyle(color: Colors.white, height: 1.4),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                              onPressed: _page == 0
                                  ? null
                                  : () => setState(() => _page--),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Text('${_page + 1}'),
                            ),
                            IconButton.filled(
                              onPressed:
                                  items.length == HeritageRepository.pageSize
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
        },
      ),
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
