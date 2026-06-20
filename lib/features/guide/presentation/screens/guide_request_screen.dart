import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/guide/domain/guide_request.dart';
import 'package:unisafex/features/guide/presentation/providers/guide_request_provider.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_filters.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class GuideRequestScreen extends ConsumerStatefulWidget {
  const GuideRequestScreen({super.key});

  @override
  ConsumerState<GuideRequestScreen> createState() => _GuideRequestScreenState();
}

class _GuideRequestScreenState extends ConsumerState<GuideRequestScreen> {
  TourismPlace? _selectedPlace;
  int _travelers = 1;
  bool _submitting = false;
  _GuideHistoryFilter _historyFilter = _GuideHistoryFilter.all;
  final _noteController = TextEditingController();
  ProviderSubscription<List<GuideRequest>>? _guideRequestSubscription;

  @override
  void initState() {
    super.initState();
    _guideRequestSubscription = ref.listenManual<List<GuideRequest>>(
      guideRequestsProvider,
      (previous, next) => _showGuideStatusPopup(previous, next),
    );
  }

  @override
  void dispose() {
    _guideRequestSubscription?.close();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(guideRequestsProvider);
    final user = ref.watch(currentUserProvider);
    final delhiPlaces = ref.watch(
      explorerPlacesProvider(
        const TourismFilters(city: 'Delhi', popularOnly: false),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Guide Request'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _HeroCard(totalRequests: requests.length),
          const SizedBox(height: 18),
          const _AvailabilityCard(
            available: true,
            title: 'Delhi guide service is available now',
            message:
                'Request a verified local guide for Delhi destinations. Our team will complete confirmation within 7 days.',
          ),
          const SizedBox(height: 18),
          if (user == null) ...[
            _SignInRequiredCard(
              onSignIn: () => context.go(AppRoutes.login),
            ),
            const SizedBox(height: 18),
          ],
          delhiPlaces.when(
            data: (places) => _RequestForm(
              places: _prioritizedDelhiPlaces(places),
              selectedPlace: _selectedPlace,
              travelers: _travelers,
              noteController: _noteController,
              submitting: _submitting,
              enabled: user != null,
              onPlaceChanged: (place) => setState(() => _selectedPlace = place),
              onTravelersChanged: (value) => setState(() => _travelers = value),
              onSubmit: _submitRequest,
            ),
            loading: () => const _LoadingCard(),
            error: (_, __) => _UnavailableCard(onRetry: () {
              ref.invalidate(explorerPlacesProvider);
            }),
          ),
          const SizedBox(height: 18),
          const _AvailabilityCard(
            available: false,
            title: 'Other cities',
            message:
                'We are currently unavailable outside Delhi. Jaipur, Agra, Mumbai, Kerala and other city guide requests will open soon.',
          ),
          const SizedBox(height: 24),
          _HistorySection(
            requests: requests,
            filter: _historyFilter,
            onFilterChanged: (filter) {
              setState(() => _historyFilter = filter);
            },
            onRebook: _rebook,
            onBook: _bookGuide,
            onDelete: (request) async {
              await ref
                  .read(guideRequestsProvider.notifier)
                  .removeLocal(request.id);
            },
          ),
        ],
      ),
    );
  }

  List<TourismPlace> _prioritizedDelhiPlaces(List<TourismPlace> places) {
    final visible = places
        .where((place) =>
            place.city.toLowerCase().contains('delhi') ||
            place.state.toLowerCase().contains('delhi'))
        .toList();
    visible.sort((a, b) {
      final popular = b.isPopular.toString().compareTo(a.isPopular.toString());
      if (popular != 0) return popular;
      return b.rating.compareTo(a.rating);
    });
    return visible.take(40).toList();
  }

  Future<void> _submitRequest() async {
    if (ref.read(currentUserProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to request a guide.')),
      );
      context.go(AppRoutes.login);
      return;
    }

    final place = _selectedPlace;
    if (place == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Delhi place first')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm guide request'),
        content: Text(
          'Request a guide for ${place.name}, ${place.city}?\n\n'
          'Our team will review and complete confirmation within 7 days.\n\n'
          'Support: WhatsApp ${GuideRequestDefaults.adminWhatsapp} · '
          '${GuideRequestDefaults.adminEmail}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final request =
          await ref.read(guideRequestsProvider.notifier).createRequest(
                placeId: place.id,
                placeName: place.name,
                city: place.city,
                travelers: _travelers,
                contactNote: _noteController.text.trim(),
              );
      _noteController.clear();
      if (!mounted) return;
      setState(() {
        _selectedPlace = null;
        _travelers = 1;
      });
      _showConfirmation(request);
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guide request could not be saved. Please make sure the '
            'guide_requests SQL is applied in Supabase. $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _rebook(GuideRequest request) {
    setState(() {
      _travelers = request.travelers;
      _noteController.text = request.contactNote;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Select ${request.placeName} again and confirm rebook.'),
      ),
    );
  }

  Future<void> _bookGuide(GuideRequest request) async {
    try {
      await ref.read(guideRequestsProvider.notifier).bookRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${request.guideName ?? 'Guide'} booked for ${request.placeName}.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guide could not be booked right now. $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showConfirmation(GuideRequest request) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              child: Icon(Icons.check_rounded),
            ),
            const SizedBox(height: 14),
            Text(
              'Guide request received',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${request.placeName} guide request is now under review. '
              'Confirmation target: ${_formatDate(request.expectedBy)}.\n\n'
              'Admin contact: WhatsApp ${GuideRequestDefaults.adminWhatsapp} '
              'or ${GuideRequestDefaults.adminEmail}.',
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: _guideStatusProgress(request.status),
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text('Status: ${_guideStatusMessage(request.status)}'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('View history'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideStatusPopup(
    List<GuideRequest>? previous,
    List<GuideRequest> next,
  ) {
    if (previous == null || previous.isEmpty || next.isEmpty) return;
    final oldById = {for (final request in previous) request.id: request};
    for (final request in next) {
      final old = oldById[request.id];
      if (old == null || old.status == request.status) continue;
      if (!_shouldPopupForStatus(request.status)) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_guidePopupTitle(request.status)),
            content: Text(
              '${request.placeName} guide request is now '
              '${_guideStatusMessage(request.status).toLowerCase()}.\n\n'
              'You can see the full progress in Guide Request history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.guideRequest);
                },
                child: const Text('View request'),
              ),
            ],
          ),
        );
      });
      return;
    }
  }
}

class _HeroCard extends StatelessWidget {
  final int totalRequests;

  const _HeroCard({required this.totalRequests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 34),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$totalRequests requests',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Verified guide request',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book a local guide through UniSafeX. Delhi requests are reviewed by our team and completed within 7 days.',
            style: TextStyle(color: Colors.white70, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool available;
  final String title;
  final String message;

  const _AvailabilityCard({
    required this.available,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            available ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInRequiredCard extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignInRequiredCard({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.lock_person_rounded),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in to request a guide',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'This lets UniSafeX attach your email to the request so '
                    'our team can confirm the guide within 7 days.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Sign in'),
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

class _RequestForm extends StatelessWidget {
  final List<TourismPlace> places;
  final TourismPlace? selectedPlace;
  final int travelers;
  final TextEditingController noteController;
  final bool submitting;
  final bool enabled;
  final ValueChanged<TourismPlace?> onPlaceChanged;
  final ValueChanged<int> onTravelersChanged;
  final VoidCallback onSubmit;

  const _RequestForm({
    required this.places,
    required this.selectedPlace,
    required this.travelers,
    required this.noteController,
    required this.submitting,
    required this.enabled,
    required this.onPlaceChanged,
    required this.onTravelersChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request a Delhi guide',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the place, number of travelers and any special requirement.',
            ),
            const SizedBox(height: 16),
            _GuidePlaceSearchField(
              places: places,
              selectedPlace: selectedPlace,
              enabled: !submitting && enabled,
              onSelected: onPlaceChanged,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Travelers',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: travelers <= 1 || submitting || !enabled
                      ? null
                      : () => onTravelersChanged(travelers - 1),
                  icon: const Icon(Icons.remove_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    '$travelers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: travelers >= 8 || submitting || !enabled
                      ? null
                      : () => onTravelersChanged(travelers + 1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              enabled: !submitting && enabled,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes for our team',
                hintText: 'Preferred date, language, pickup area...',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: submitting ||
                        !enabled ||
                        places.isEmpty ||
                        selectedPlace == null
                    ? null
                    : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                    submitting ? 'Submitting request...' : 'Request guide'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePlaceSearchField extends StatelessWidget {
  const _GuidePlaceSearchField({
    required this.places,
    required this.selectedPlace,
    required this.enabled,
    required this.onSelected,
  });

  final List<TourismPlace> places;
  final TourismPlace? selectedPlace;
  final bool enabled;
  final ValueChanged<TourismPlace?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<TourismPlace>(
      displayStringForOption: _placeLabel,
      initialValue: TextEditingValue(
        text: selectedPlace == null ? '' : _placeLabel(selectedPlace!),
      ),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return places.take(12);
        return places.where((place) {
          final searchable = [
            place.name,
            place.city,
            place.district,
            place.state,
            place.category,
            place.address,
          ].whereType<String>().join(' ').toLowerCase();
          return searchable.contains(query);
        }).take(20);
      },
      onSelected: enabled ? onSelected : (_) {},
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onFieldSubmitted,
      ) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: 'Search Delhi place',
            hintText: 'Type monument, area, city or category',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      controller.clear();
                      onSelected(null);
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        final results = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320, maxWidth: 760),
              child: results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No Delhi guide place found.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.10),
                            foregroundColor: AppColors.primary,
                            child: const Icon(Icons.location_on_outlined),
                          ),
                          title: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (place.city.isNotEmpty) place.city,
                              if (place.district?.isNotEmpty == true)
                                place.district!,
                              place.category,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onSelectedOption(place),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }

  static String _placeLabel(TourismPlace place) {
    return '${place.name} · ${place.city.isEmpty ? 'Delhi' : place.city}';
  }
}

enum _GuideHistoryFilter {
  all('All'),
  active('Active'),
  confirmed('Confirmed'),
  booked('Booked'),
  rejected('Rejected'),
  completed('Completed');

  const _GuideHistoryFilter(this.label);

  final String label;
}

class _HistorySection extends StatelessWidget {
  final List<GuideRequest> requests;
  final _GuideHistoryFilter filter;
  final ValueChanged<_GuideHistoryFilter> onFilterChanged;
  final ValueChanged<GuideRequest> onRebook;
  final ValueChanged<GuideRequest> onBook;
  final ValueChanged<GuideRequest> onDelete;

  const _HistorySection({
    required this.requests,
    required this.filter,
    required this.onFilterChanged,
    required this.onRebook,
    required this.onBook,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visible = requests.where((request) {
      return switch (filter) {
        _GuideHistoryFilter.all => true,
        _GuideHistoryFilter.active => _isActiveGuideRequest(request),
        _GuideHistoryFilter.confirmed =>
          request.status == GuideRequestStatus.confirmed,
        _GuideHistoryFilter.booked => request.bookingStatus == 'booked',
        _GuideHistoryFilter.rejected =>
          request.status == GuideRequestStatus.rejected,
        _GuideHistoryFilter.completed =>
          request.status == GuideRequestStatus.completed,
      };
    }).toList();
    final activeRequests = visible.where(_isActiveGuideRequest).toList();
    final historyRequests =
        visible.where((request) => !_isActiveGuideRequest(request)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Guide requests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${visible.length}/${requests.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _GuideHistoryFilter.values
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
        const SizedBox(height: 12),
        if (requests.isEmpty)
          const _EmptyHistory()
        else if (visible.isEmpty)
          const _EmptyFilteredHistory()
        else ...[
          if (activeRequests.isNotEmpty) ...[
            _HistoryGroupTitle(
              title: 'Current requests',
              count: activeRequests.length,
            ),
            ...activeRequests.map(
              (request) => _GuideRequestCard(
                request: request,
                onRebook: () => onRebook(request),
                onBook: () => onBook(request),
                onDelete: () => onDelete(request),
              ),
            ),
          ],
          if (historyRequests.isNotEmpty) ...[
            const SizedBox(height: 4),
            _HistoryGroupTitle(
              title: 'History',
              count: historyRequests.length,
            ),
            ...historyRequests.map(
              (request) => _GuideRequestCard(
                request: request,
                onRebook: () => onRebook(request),
                onBook: () => onBook(request),
                onDelete: () => onDelete(request),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

bool _isActiveGuideRequest(GuideRequest request) {
  if (request.status == GuideRequestStatus.rejected ||
      request.status == GuideRequestStatus.completed ||
      request.bookingStatus == 'booked') {
    return false;
  }
  return true;
}

class _HistoryGroupTitle extends StatelessWidget {
  const _HistoryGroupTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          _MiniCountPill(count: count),
        ],
      ),
    );
  }
}

class _MiniCountPill extends StatelessWidget {
  const _MiniCountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyFilteredHistory extends StatelessWidget {
  const _EmptyFilteredHistory();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('No requests match this filter.'),
      ),
    );
  }
}

class _GuideRequestCard extends StatelessWidget {
  final GuideRequest request;
  final VoidCallback onRebook;
  final VoidCallback onBook;
  final VoidCallback onDelete;

  const _GuideRequestCard({
    required this.request,
    required this.onRebook,
    required this.onBook,
    required this.onDelete,
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
                  child: Icon(Icons.support_agent_rounded),
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
                          '${request.city} · ${request.travelers} traveler(s)'),
                    ],
                  ),
                ),
                _StatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _guideStatusProgress(request.status),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _guideStatusIcon(request.status),
                  size: 18,
                  color: _guideStatusColor(request.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_guideStatusMessage(request.status)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Requested ${_formatDate(request.requestedAt)} · Confirmation by ${_formatDate(request.expectedBy)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (request.contactNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: ${request.contactNote}'),
            ],
            const SizedBox(height: 12),
            if (request.status == GuideRequestStatus.confirmed &&
                request.hasAssignedGuide)
              _AssignedGuideCard(request: request, onBook: onBook)
            else if (request.status != GuideRequestStatus.rejected &&
                request.status != GuideRequestStatus.completed)
              _GuidePreparingCard(request: request),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onRebook,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Book again'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final GuideRequestStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      GuideRequestStatus.pending => 'Pending',
      GuideRequestStatus.processing => 'Processing',
      GuideRequestStatus.confirmed => 'Confirmed',
      GuideRequestStatus.rejected => 'Rejected',
      GuideRequestStatus.completed => 'Completed',
    };
    final color = switch (status) {
      GuideRequestStatus.pending => AppColors.warning,
      GuideRequestStatus.processing => AppColors.primary,
      GuideRequestStatus.confirmed => AppColors.success,
      GuideRequestStatus.rejected => AppColors.error,
      GuideRequestStatus.completed => AppColors.success,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _GuidePreparingCard extends StatelessWidget {
  final GuideRequest request;

  const _GuidePreparingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guide profile is being prepared',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.status == GuideRequestStatus.confirmed
                          ? 'Confirmed. Admin will add guide details shortly.'
                          : 'We will show the guide profile, charges and booking button after admin confirmation.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _GuideSkeletonLine(widthFactor: 0.85),
          const SizedBox(height: 8),
          const _GuideSkeletonLine(widthFactor: 0.62),
          const SizedBox(height: 8),
          const _GuideSkeletonLine(widthFactor: 0.72),
        ],
      ),
    );
  }
}

class _GuideSkeletonLine extends StatelessWidget {
  final double widthFactor;

  const _GuideSkeletonLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 9,
        decoration: BoxDecoration(
          color: AppColors.grey300.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _AssignedGuideCard extends StatelessWidget {
  final GuideRequest request;
  final VoidCallback onBook;

  const _AssignedGuideCard({
    required this.request,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final booked = request.bookingStatus == 'booked';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.96),
            AppColors.primary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    backgroundImage: request.guidePhotoUrl?.isNotEmpty == true
                        ? NetworkImage(request.guidePhotoUrl!)
                        : null,
                    child: request.guidePhotoUrl?.isNotEmpty == true
                        ? null
                        : const Icon(Icons.badge_rounded,
                            color: Colors.white, size: 30),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'Verified UniSafeX Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      request.guideName ?? 'Assigned guide',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (request.guideLanguages?.isNotEmpty == true)
                          request.guideLanguages,
                        if (request.guideExperienceYears != null)
                          '${request.guideExperienceYears} yrs experience',
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.formattedGuideCharge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.guideBio?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              request.guideBio!,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ],
          if (request.guideMeetingPoint?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Meeting: ${request.guideMeetingPoint}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: booked ? null : onBook,
              icon: Icon(booked ? Icons.check_circle_rounded : Icons.event),
              label: Text(booked ? 'Guide booked' : 'Book this guide'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Loading Delhi guide places...')),
          ],
        ),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _UnavailableCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.warning, size: 34),
            const SizedBox(height: 10),
            const Text(
              'Delhi guide places could not be loaded right now.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 34, color: AppColors.grey400),
          SizedBox(height: 10),
          Text('No guide requests yet'),
          SizedBox(height: 4),
          Text(
            'Your Delhi guide request history will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

bool _shouldPopupForStatus(GuideRequestStatus status) {
  return status == GuideRequestStatus.confirmed ||
      status == GuideRequestStatus.rejected ||
      status == GuideRequestStatus.completed;
}

String _guidePopupTitle(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.confirmed => 'Guide confirmed',
    GuideRequestStatus.rejected => 'Guide request rejected',
    GuideRequestStatus.completed => 'Guide request completed',
    GuideRequestStatus.pending => 'Guide request pending',
    GuideRequestStatus.processing => 'Guide request processing',
  };
}

String _guideStatusMessage(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => 'Submitted and waiting for team review',
    GuideRequestStatus.processing => 'Team review in progress',
    GuideRequestStatus.confirmed => 'Guide confirmed by UniSafeX team',
    GuideRequestStatus.rejected => 'Rejected by admin team',
    GuideRequestStatus.completed => 'Guide service completed',
  };
}

double _guideStatusProgress(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => 0.18,
    GuideRequestStatus.processing => 0.45,
    GuideRequestStatus.confirmed => 0.78,
    GuideRequestStatus.rejected => 1.0,
    GuideRequestStatus.completed => 1.0,
  };
}

IconData _guideStatusIcon(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => Icons.hourglass_top_rounded,
    GuideRequestStatus.processing => Icons.manage_search_rounded,
    GuideRequestStatus.confirmed => Icons.verified_rounded,
    GuideRequestStatus.rejected => Icons.cancel_rounded,
    GuideRequestStatus.completed => Icons.task_alt_rounded,
  };
}

Color _guideStatusColor(GuideRequestStatus status) {
  return switch (status) {
    GuideRequestStatus.pending => AppColors.warning,
    GuideRequestStatus.processing => AppColors.primary,
    GuideRequestStatus.confirmed => AppColors.success,
    GuideRequestStatus.rejected => AppColors.error,
    GuideRequestStatus.completed => AppColors.success,
  };
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
