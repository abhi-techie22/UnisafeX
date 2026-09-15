import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/booking/data/booking_link_service.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
import 'package:unisafex/features/booking/presentation/widgets/booking_form_widgets.dart';

class TravelBookingScreen extends StatefulWidget {
  const TravelBookingScreen({super.key});

  @override
  State<TravelBookingScreen> createState() => _TravelBookingScreenState();
}

class _TravelBookingScreenState extends State<TravelBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController(text: 'New Delhi');
  final _destinationController = TextEditingController(text: 'Agra');
  late DateTime _travelDate;
  int _travellers = 1;
  TravelTransportMode _selectedMode = TravelTransportMode.bus;
  late BookingPartner _selectedPartner;

  @override
  void initState() {
    super.initState();
    _travelDate = DateUtils.dateOnly(DateTime.now()).add(
      const Duration(days: 7),
    );
    _selectedPartner = _availablePartners.first;
    _originController.addListener(_handleRouteChanged);
    _destinationController.addListener(_handleRouteChanged);
  }

  @override
  void dispose() {
    _originController.removeListener(_handleRouteChanged);
    _destinationController.removeListener(_handleRouteChanged);
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  List<BookingPartner> get _availablePartners =>
      availableTravelPartnersForRoute(
        mode: _selectedMode,
        origin: _originController.text,
        destination: _destinationController.text,
      );

  void _handleRouteChanged() {
    setState(_syncSelectedPartner);
  }

  void _syncSelectedPartner() {
    final partners = _availablePartners;
    if (partners.isEmpty) return;
    final selectedStillAvailable = partners.any(
      (partner) => partner.name == _selectedPartner.name,
    );
    if (!selectedStillAvailable) {
      _selectedPartner = partners.first;
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _travelDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => _travelDate = selected);
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    final partners = _availablePartners;
    if (partners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_noPartnerMessage(_selectedMode))),
      );
      return;
    }
    final partner = partners.any(
      (available) => available.name == _selectedPartner.name,
    )
        ? _selectedPartner
        : partners.first;
    final uri = BookingLinkService.buildTravelSearch(
      mode: _selectedMode,
      origin: _originController.text,
      destination: _destinationController.text,
      departure: _travelDate,
      travellers: _travellers,
      partner: partner,
    );
    final opened = await BookingLinkService.open(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open ${partner.name}. Please try again.',
          ),
        ),
      );
    }
  }

  void _selectMode(TravelTransportMode mode) {
    setState(() {
      _selectedMode = mode;
      final partners = _availablePartners;
      _selectedPartner =
          partners.isEmpty ? travelPartnersForMode(mode).first : partners.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final partners = _availablePartners;
    final hiddenCount = hiddenTravelPartnerCountForRoute(
      mode: _selectedMode,
      origin: _originController.text,
      destination: _destinationController.text,
    );
    final canOpenPartner = partners.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Travel booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const BookingHero(
                icon: Icons.travel_explore_rounded,
                title: 'Travel & transport',
                subtitle:
                    'Book or compare bus, metro, train, cab, auto and flight options for your route.',
                colors: [Color(0xFF173F35), AppColors.primary],
              ),
              const SizedBox(height: 18),
              Text(
                'Choose transport',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              _TravelModeSelector(
                selectedMode: _selectedMode,
                onSelected: _selectMode,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(
                  labelText: 'From',
                  hintText: 'City, station, hotel or current area',
                  prefixIcon: Icon(Icons.trip_origin_rounded),
                ),
                validator: _requiredLocation,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'City, metro stop, place or airport',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                validator: _requiredLocation,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'Travel date',
                value: _travelDate,
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),
              BookingCounter(
                label: 'Travelers',
                value: _travellers,
                icon: Icons.people_outline_rounded,
                onDecrease: () => setState(
                  () => _travellers = (_travellers - 1).clamp(1, 9),
                ),
                onIncrease: () => setState(
                  () => _travellers = (_travellers + 1).clamp(1, 9),
                ),
              ),
              const SizedBox(height: 18),
              _ModeInfoCard(mode: _selectedMode),
              if (hiddenCount > 0) ...[
                const SizedBox(height: 12),
                _RouteAvailabilityNotice(
                  mode: _selectedMode,
                  hiddenCount: hiddenCount,
                ),
              ],
              const SizedBox(height: 18),
              if (canOpenPartner)
                BookingPartnerSelector(
                  partners: partners,
                  selected: _selectedPartner,
                  onSelected: (partner) =>
                      setState(() => _selectedPartner = partner),
                )
              else
                _NoPartnerCard(message: _noPartnerMessage(_selectedMode)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: canOpenPartner ? _search : null,
                icon: Icon(_modeIcon(_selectedMode)),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    canOpenPartner
                        ? 'Open ${_selectedPartner.name}'
                        : 'No partner for this route',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredLocation(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Enter a valid city, station or place'
        : null;
  }
}

class _RouteAvailabilityNotice extends StatelessWidget {
  const _RouteAvailabilityNotice({
    required this.mode,
    required this.hiddenCount,
  });

  final TravelTransportMode mode;
  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    final message = switch (mode) {
      TravelTransportMode.metro =>
        'City-specific metro partners are shown only when both locations are inside the same metro area. Delhi Metro appears only for Delhi NCR routes.',
      TravelTransportMode.cab ||
      TravelTransportMode.auto =>
        'Local ride partners are hidden for clear intercity routes. Use bus, train, flight, or Google Maps for longer travel.',
      TravelTransportMode.bus =>
        'Intercity bus partners are hidden when the route looks like a local city route.',
      TravelTransportMode.flight =>
        'Flight partners are hidden when both points look like the same city.',
      TravelTransportMode.train =>
        'Some rail partners may be hidden when the selected route is not suitable.',
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$hiddenCount unavailable partner${hiddenCount == 1 ? '' : 's'} hidden. $message',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPartnerCard extends StatelessWidget {
  const _NoPartnerCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelModeSelector extends StatelessWidget {
  const _TravelModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  final TravelTransportMode selectedMode;
  final ValueChanged<TravelTransportMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: TravelTransportMode.values.map((mode) {
        final selected = mode == selectedMode;
        return ChoiceChip(
          selected: selected,
          avatar: Icon(
            _modeIcon(mode),
            size: 18,
            color: selected ? Colors.white : AppColors.primary,
          ),
          label: Text(mode.label),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => onSelected(mode),
        );
      }).toList(),
    );
  }
}

class _ModeInfoCard extends StatelessWidget {
  const _ModeInfoCard({required this.mode});

  final TravelTransportMode mode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            child: Icon(_modeIcon(mode)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  mode.description,
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

IconData _modeIcon(TravelTransportMode mode) {
  return switch (mode) {
    TravelTransportMode.bus => Icons.directions_bus_filled_rounded,
    TravelTransportMode.metro => Icons.directions_subway_filled_rounded,
    TravelTransportMode.train => Icons.train_rounded,
    TravelTransportMode.cab => Icons.local_taxi_rounded,
    TravelTransportMode.auto => Icons.electric_rickshaw_rounded,
    TravelTransportMode.flight => Icons.flight_takeoff_rounded,
  };
}

String _noPartnerMessage(TravelTransportMode mode) {
  return switch (mode) {
    TravelTransportMode.metro =>
      'No metro partner matches both locations. Try a route inside the same metro city or use Google Maps Transit.',
    TravelTransportMode.bus =>
      'No bus partner matches this route. Try a different city or use local transit.',
    TravelTransportMode.train =>
      'No train partner matches this route. Try a city, station, or nearby rail hub.',
    TravelTransportMode.cab =>
      'No cab partner matches this route. Try a local route or use Google Maps Driving.',
    TravelTransportMode.auto =>
      'No auto partner matches this route. Try a local city route.',
    TravelTransportMode.flight =>
      'No flight partner matches this route. Choose different cities or airports.',
  };
}
