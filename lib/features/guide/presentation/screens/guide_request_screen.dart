import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisafex/core/theme/app_theme.dart';
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
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(guideRequestsProvider);
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
          delhiPlaces.when(
            data: (places) => _RequestForm(
              places: _prioritizedDelhiPlaces(places),
              selectedPlace: _selectedPlace,
              travelers: _travelers,
              noteController: _noteController,
              submitting: _submitting,
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
            onRebook: _rebook,
            onDelete: (request) async {
              await ref.read(guideRequestsProvider.notifier).remove(request.id);
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
          'Our team will review and complete confirmation within 7 days.',
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
    await Future<void>.delayed(const Duration(milliseconds: 900));
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
      _submitting = false;
      _selectedPlace = null;
      _travelers = 1;
    });
    _showConfirmation(request);
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
              'Confirmation target: ${_formatDate(request.expectedBy)}.',
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: 0.28,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            const Text('Status: team review in progress'),
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

class _RequestForm extends StatelessWidget {
  final List<TourismPlace> places;
  final TourismPlace? selectedPlace;
  final int travelers;
  final TextEditingController noteController;
  final bool submitting;
  final ValueChanged<TourismPlace?> onPlaceChanged;
  final ValueChanged<int> onTravelersChanged;
  final VoidCallback onSubmit;

  const _RequestForm({
    required this.places,
    required this.selectedPlace,
    required this.travelers,
    required this.noteController,
    required this.submitting,
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
            DropdownButtonFormField<TourismPlace>(
              initialValue: selectedPlace,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Delhi place',
                prefixIcon: Icon(Icons.account_balance_rounded),
              ),
              items: places
                  .map(
                    (place) => DropdownMenuItem(
                      value: place,
                      child: Text(
                        '${place.name} · ${place.city}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: submitting ? null : onPlaceChanged,
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
                  onPressed: travelers <= 1 || submitting
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
                  onPressed: travelers >= 8 || submitting
                      ? null
                      : () => onTravelersChanged(travelers + 1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              enabled: !submitting,
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
                onPressed: submitting || places.isEmpty || selectedPlace == null
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

class _HistorySection extends StatelessWidget {
  final List<GuideRequest> requests;
  final ValueChanged<GuideRequest> onRebook;
  final ValueChanged<GuideRequest> onDelete;

  const _HistorySection({
    required this.requests,
    required this.onRebook,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Request history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (requests.isEmpty)
          const _EmptyHistory()
        else
          ...requests.map(
            (request) => _GuideRequestCard(
              request: request,
              onRebook: () => onRebook(request),
              onDelete: () => onDelete(request),
            ),
          ),
      ],
    );
  }
}

class _GuideRequestCard extends StatelessWidget {
  final GuideRequest request;
  final VoidCallback onRebook;
  final VoidCallback onDelete;

  const _GuideRequestCard({
    required this.request,
    required this.onRebook,
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
              child: const LinearProgressIndicator(value: 0.28),
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
    };
    final color = switch (status) {
      GuideRequestStatus.pending => AppColors.warning,
      GuideRequestStatus.processing => AppColors.primary,
      GuideRequestStatus.confirmed => AppColors.success,
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
