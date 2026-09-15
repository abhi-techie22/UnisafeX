import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/booking/data/booking_link_service.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
import 'package:unisafex/features/booking/domain/delhi_metro_network.dart';
import 'package:unisafex/features/booking/domain/travel_hub.dart';
import 'package:unisafex/features/booking/presentation/widgets/booking_form_widgets.dart';
import 'package:unisafex/features/home/presentation/providers/location_provider.dart';

class TravelBookingScreen extends ConsumerStatefulWidget {
  const TravelBookingScreen({super.key});

  @override
  ConsumerState<TravelBookingScreen> createState() =>
      _TravelBookingScreenState();
}

class _TravelBookingScreenState extends ConsumerState<TravelBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController(text: 'New Delhi');
  final _destinationController = TextEditingController(text: 'Agra');
  late DateTime _travelDate;
  int _travellers = 1;
  TravelTransportMode _selectedMode = TravelTransportMode.bus;
  String _selectedDelhiLineId = 'yellow';
  late BookingPartner _selectedPartner;
  bool _updatingRouteText = false;
  LocationData? _currentPickupLocation;
  bool _locatingPickup = false;

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

  bool get _usesTravelHubPicker =>
      _selectedMode == TravelTransportMode.train ||
      _selectedMode == TravelTransportMode.flight;

  bool get _usesRidePickup =>
      _selectedMode == TravelTransportMode.cab ||
      _selectedMode == TravelTransportMode.auto;

  bool get _hasCurrentRidePickup =>
      _usesRidePickup &&
      _currentPickupLocation != null &&
      _originController.text.startsWith('Current location');

  void _handleRouteChanged() {
    if (_updatingRouteText) return;
    setState(() {
      if (_currentPickupLocation != null &&
          !_originController.text.startsWith('Current location')) {
        _currentPickupLocation = null;
      }
      _syncSelectedPartner();
    });
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

  bool get _usesDelhiMetroPlanner => _selectedMode == TravelTransportMode.metro;

  void _setRouteText({
    required String origin,
    required String destination,
  }) {
    _updatingRouteText = true;
    try {
      if (_originController.text != origin) _originController.text = origin;
      if (_destinationController.text != destination) {
        _destinationController.text = destination;
      }
    } finally {
      _updatingRouteText = false;
    }
    _syncSelectedPartner();
  }

  void _applyDelhiMetroDefaultsIfNeeded({bool force = false}) {
    final route = buildDelhiMetroRoutePlan(
      origin: _originController.text,
      destination: _destinationController.text,
    );
    if (!force && route != null) return;
    _setRouteText(
      origin: 'Rajiv Chowk',
      destination: 'Kashmere Gate',
    );
    _selectedDelhiLineId = 'yellow';
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
    final pickupLocation =
        _hasCurrentRidePickup ? _currentPickupLocation : null;
    final uri = BookingLinkService.buildTravelSearch(
      mode: _selectedMode,
      origin: _originController.text,
      destination: _destinationController.text,
      departure: _travelDate,
      travellers: _travellers,
      partner: partner,
      originLatitude: pickupLocation?.latitude,
      originLongitude: pickupLocation?.longitude,
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

  Future<void> _openDelhiMetroQrTicket() async {
    final route = buildDelhiMetroRoutePlan(
      origin: _originController.text,
      destination: _destinationController.text,
    );
    if (route == null || route.totalStations == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose two different Delhi Metro stations first.'),
        ),
      );
      return;
    }

    final proceed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          22 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(Icons.qr_code_2_rounded),
            ),
            const SizedBox(height: 14),
            Text(
              'Delhi Metro QR ticket',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${route.fromStation} to ${route.toStation}\n'
              '${route.totalStations} station${route.totalStations == 1 ? '' : 's'}'
              '${route.isDirect ? '' : ' · change at ${route.interchanges.join(', ')}'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Valid QR tickets are issued only by official DMRC or approved ticketing partners. UniSafeX will open the official DMRC ticketing information page so you can complete the purchase safely.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open DMRC'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (proceed != true) return;

    final uri = BookingLinkService.buildDelhiMetroQrTicketInfo(
      origin: route.fromStation,
      destination: route.toStation,
    );
    final opened = await BookingLinkService.open(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the DMRC ticketing page right now.'),
        ),
      );
    }
  }

  Future<void> _useCurrentLocationAsPickup() async {
    if (!_usesRidePickup) return;

    setState(() => _locatingPickup = true);
    try {
      await ref.read(locationProvider.notifier).refresh();
      final locationState = ref.read(locationProvider);
      final location = locationState.asData?.value;
      if (!mounted) return;

      if (location == null) {
        final message = locationState.whenOrNull(
              error: (error, _) => error is LocationException
                  ? error.message
                  : 'Current location is unavailable. Please try again.',
            ) ??
            'Current location is unavailable. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      setState(() {
        _currentPickupLocation = location;
        _setRouteText(
          origin: _currentPickupLabel(location),
          destination: _destinationController.text,
        );
      });
    } finally {
      if (mounted) setState(() => _locatingPickup = false);
    }
  }

  void _clearCurrentPickup() {
    setState(() {
      _currentPickupLocation = null;
      if (_originController.text.startsWith('Current location')) {
        _originController.clear();
      }
      _syncSelectedPartner();
    });
  }

  void _selectMode(TravelTransportMode mode) {
    setState(() {
      _selectedMode = mode;
      if (mode != TravelTransportMode.cab && mode != TravelTransportMode.auto) {
        _currentPickupLocation = null;
      }
      if (mode == TravelTransportMode.metro) {
        _applyDelhiMetroDefaultsIfNeeded();
        _selectedPartner = metroBookingPartners.firstWhere(
          (partner) => partner.name == 'Delhi Metro',
        );
        return;
      }
      _applyModeDefaultsIfNeeded(mode);
      final partners = _availablePartners;
      _selectedPartner = partners.first;
    });
  }

  void _selectPartner(BookingPartner partner) {
    setState(() {
      _selectedPartner = partner;
      if (partner.name == 'Delhi Metro') {
        _applyDelhiMetroDefaultsIfNeeded();
      }
    });
  }

  void _applyModeDefaultsIfNeeded(TravelTransportMode mode) {
    switch (mode) {
      case TravelTransportMode.flight:
        if (!_currentRouteUsesTravelHubs(airportTravelHubs) ||
            _currentRouteHasSameText) {
          _setRouteText(
            origin: airportTravelHubs[0].routeValue,
            destination: airportTravelHubs[1].routeValue,
          );
        }
        return;
      case TravelTransportMode.train:
        if (!_currentRouteUsesTravelHubs(railwayStationTravelHubs) ||
            _currentRouteUsesDelhiMetroStations ||
            _currentRouteHasSameText) {
          _setRouteText(
            origin: railwayStationTravelHubs[0].routeValue,
            destination: railwayStationTravelHubs[3].routeValue,
          );
        }
        return;
      case TravelTransportMode.bus:
        if (_currentRouteUsesDelhiMetroStations || _currentRouteUsesAnyHub) {
          _setRouteText(origin: 'New Delhi', destination: 'Agra');
        }
        return;
      case TravelTransportMode.cab || TravelTransportMode.auto:
        if (_currentRouteUsesDelhiMetroStations ||
            _currentRouteUsesAnyHub ||
            _currentRouteLooksIntercity) {
          _setRouteText(
            origin: 'Connaught Place, Delhi',
            destination: 'India Gate, Delhi',
          );
        }
        return;
      case TravelTransportMode.metro:
        return;
    }
  }

  bool get _currentRouteUsesDelhiMetroStations {
    return delhiMetroStationNames.contains(_originController.text.trim()) ||
        delhiMetroStationNames.contains(_destinationController.text.trim());
  }

  bool get _currentRouteHasSameText {
    final origin = _originController.text.trim().toLowerCase();
    final destination = _destinationController.text.trim().toLowerCase();
    return origin.isNotEmpty && origin == destination;
  }

  bool get _currentRouteLooksIntercity {
    final route = '${_originController.text} ${_destinationController.text}'
        .toLowerCase();
    return route.contains('agra') ||
        route.contains('jaipur') ||
        route.contains('mumbai') ||
        route.contains('varanasi') ||
        route.contains('kerala');
  }

  bool get _currentRouteUsesAnyHub =>
      travelHubForRouteValue(
            railwayStationTravelHubs,
            _originController.text,
          ) !=
          null ||
      travelHubForRouteValue(
            railwayStationTravelHubs,
            _destinationController.text,
          ) !=
          null ||
      travelHubForRouteValue(
            airportTravelHubs,
            _originController.text,
          ) !=
          null ||
      travelHubForRouteValue(
            airportTravelHubs,
            _destinationController.text,
          ) !=
          null;

  bool _currentRouteUsesTravelHubs(List<TravelHub> hubs) {
    return travelHubForRouteValue(hubs, _originController.text) != null &&
        travelHubForRouteValue(hubs, _destinationController.text) != null;
  }

  String _currentPickupLabel(LocationData location) {
    final city = location.city?.trim();
    final state = location.state?.trim();
    final name = location.name.trim();
    final parts = [
      if (city?.isNotEmpty == true) city!,
      if (state?.isNotEmpty == true && state != city) state!,
    ];
    final area = parts.isEmpty ? name : parts.join(', ');
    return area.isEmpty ? 'Current location' : 'Current location - $area';
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
    final usesDelhiMetroPlanner = _usesDelhiMetroPlanner;
    final bookingButtonLabel = canOpenPartner
        ? _selectedMode == TravelTransportMode.metro &&
                _selectedPartner.name == 'Delhi Metro'
            ? 'Open DMRC planner'
            : 'Open ${_selectedPartner.name}'
        : 'No partner for this route';
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
              if (usesDelhiMetroPlanner)
                _DelhiMetroPlannerPanel(
                  selectedLineId: _selectedDelhiLineId,
                  originStation: _originController.text,
                  destinationStation: _destinationController.text,
                  onLineChanged: (lineId) =>
                      setState(() => _selectedDelhiLineId = lineId),
                  onOriginChanged: (station) => setState(
                    () {
                      _setRouteText(
                        origin: station,
                        destination: _destinationController.text,
                      );
                      _syncSelectedDelhiLine(station);
                    },
                  ),
                  onDestinationChanged: (station) => setState(
                    () {
                      _setRouteText(
                        origin: _originController.text,
                        destination: station,
                      );
                      _syncSelectedDelhiLine(station);
                    },
                  ),
                  onSwap: () => setState(
                    () => _setRouteText(
                      origin: _destinationController.text,
                      destination: _originController.text,
                    ),
                  ),
                  onQrTicket: _openDelhiMetroQrTicket,
                )
              else if (_usesTravelHubPicker)
                _TravelHubRoutePanel(
                  mode: _selectedMode,
                  originValue: _originController.text,
                  destinationValue: _destinationController.text,
                  travelDate: _travelDate,
                  travellers: _travellers,
                  onOriginChanged: (hub) => setState(
                    () => _setRouteText(
                      origin: hub.routeValue,
                      destination: _destinationController.text,
                    ),
                  ),
                  onDestinationChanged: (hub) => setState(
                    () => _setRouteText(
                      origin: _originController.text,
                      destination: hub.routeValue,
                    ),
                  ),
                  onSwap: () => setState(
                    () => _setRouteText(
                      origin: _destinationController.text,
                      destination: _originController.text,
                    ),
                  ),
                  onPickDate: _pickDate,
                  onDecreaseTravellers: () => setState(
                    () => _travellers = (_travellers - 1).clamp(1, 9),
                  ),
                  onIncreaseTravellers: () => setState(
                    () => _travellers = (_travellers + 1).clamp(1, 9),
                  ),
                )
              else if (_usesRidePickup)
                _RideRoutePanel(
                  mode: _selectedMode,
                  originController: _originController,
                  destinationController: _destinationController,
                  travelDate: _travelDate,
                  travellers: _travellers,
                  pickupLocation:
                      _hasCurrentRidePickup ? _currentPickupLocation : null,
                  locatingPickup: _locatingPickup,
                  onUseCurrentPickup: _useCurrentLocationAsPickup,
                  onClearCurrentPickup: _clearCurrentPickup,
                  onPickDate: _pickDate,
                  onDecreaseTravellers: () => setState(
                    () => _travellers = (_travellers - 1).clamp(1, 9),
                  ),
                  onIncreaseTravellers: () => setState(
                    () => _travellers = (_travellers + 1).clamp(1, 9),
                  ),
                  validator: _requiredLocation,
                )
              else ...[
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
              ],
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
                  onSelected: _selectPartner,
                )
              else
                _NoPartnerCard(message: _noPartnerMessage(_selectedMode)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: canOpenPartner ? _search : null,
                icon: Icon(_modeIcon(_selectedMode)),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(bookingButtonLabel),
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

  void _syncSelectedDelhiLine(String station) {
    final lines = delhiMetroLinesForStation(station);
    if (lines.isNotEmpty) _selectedDelhiLineId = lines.first.id;
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
        'City-specific metro partners are shown only when both locations are inside the same metro area. Delhi Metro and Amazon Pay Metro appear only for Delhi NCR routes.',
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

class _TravelHubRoutePanel extends StatelessWidget {
  const _TravelHubRoutePanel({
    required this.mode,
    required this.originValue,
    required this.destinationValue,
    required this.travelDate,
    required this.travellers,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onSwap,
    required this.onPickDate,
    required this.onDecreaseTravellers,
    required this.onIncreaseTravellers,
  });

  final TravelTransportMode mode;
  final String originValue;
  final String destinationValue;
  final DateTime travelDate;
  final int travellers;
  final ValueChanged<TravelHub> onOriginChanged;
  final ValueChanged<TravelHub> onDestinationChanged;
  final VoidCallback onSwap;
  final VoidCallback onPickDate;
  final VoidCallback onDecreaseTravellers;
  final VoidCallback onIncreaseTravellers;

  @override
  Widget build(BuildContext context) {
    final hubs = travelHubsForMode(mode);
    final originHub = travelHubForRouteValue(hubs, originValue);
    final destinationHub = travelHubForRouteValue(hubs, destinationValue);
    final hubLabel = _hubKindLabel(mode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${mode.label} route',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_vert_rounded),
              label: const Text('Swap'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TravelHubField(
          mode: mode,
          label: 'From $hubLabel',
          value: originHub,
          onChanged: onOriginChanged,
        ),
        const SizedBox(height: 12),
        _TravelHubField(
          mode: mode,
          label: 'To $hubLabel',
          value: destinationHub,
          onChanged: onDestinationChanged,
        ),
        const SizedBox(height: 14),
        BookingDateField(
          label: mode == TravelTransportMode.flight
              ? 'Departure date'
              : 'Travel date',
          value: travelDate,
          onTap: onPickDate,
        ),
        const SizedBox(height: 14),
        BookingCounter(
          label:
              mode == TravelTransportMode.flight ? 'Passengers' : 'Travelers',
          value: travellers,
          icon: Icons.people_outline_rounded,
          onDecrease: onDecreaseTravellers,
          onIncrease: onIncreaseTravellers,
        ),
        const SizedBox(height: 14),
        _SelectedHubSummary(
          mode: mode,
          originHub: originHub,
          destinationHub: destinationHub,
        ),
      ],
    );
  }
}

class _TravelHubField extends StatelessWidget {
  const _TravelHubField({
    required this.mode,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final TravelTransportMode mode;
  final String label;
  final TravelHub? value;
  final ValueChanged<TravelHub> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<TravelHub>(
      key: ValueKey('$label-${value?.routeValue ?? 'empty'}'),
      initialValue: value,
      validator: (value) => value == null
          ? 'Choose a ${_hubKindLabel(mode).toLowerCase()}'
          : null,
      builder: (field) {
        final selected = field.value;
        return InkWell(
          onTap: () async {
            final hub = await showModalBottomSheet<TravelHub>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              routeSettings: RouteSettings(name: '$label picker'),
              builder: (context) => _TravelHubPickerSheet(
                mode: mode,
                title: label,
                selectedHub: selected,
              ),
            );
            if (hub == null) return;
            field.didChange(hub);
            onChanged(hub);
          },
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            isEmpty: selected == null,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(_modeIcon(mode)),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              errorText: field.errorText,
            ),
            child: selected == null
                ? Text(
                    'Choose ${_hubKindLabel(mode).toLowerCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  )
                : _HubText(hub: selected),
          ),
        );
      },
    );
  }
}

class _TravelHubPickerSheet extends StatefulWidget {
  const _TravelHubPickerSheet({
    required this.mode,
    required this.title,
    required this.selectedHub,
  });

  final TravelTransportMode mode;
  final String title;
  final TravelHub? selectedHub;

  @override
  State<_TravelHubPickerSheet> createState() => _TravelHubPickerSheetState();
}

class _TravelHubPickerSheetState extends State<_TravelHubPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TravelHub> get _hubs {
    final hubs = travelHubsForMode(widget.mode);
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return hubs;
    return hubs.where((hub) => hub.searchText.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final hubs = _hubs;
    final kind = _hubKindLabel(widget.mode).toLowerCase();

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: 'Search $kind',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: hubs.isEmpty
                  ? Center(child: Text('No $kind found.'))
                  : ListView.separated(
                      itemCount: hubs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final hub = hubs[index];
                        final selected =
                            hub.routeValue == widget.selectedHub?.routeValue;
                        return ListTile(
                          selected: selected,
                          contentPadding: EdgeInsets.zero,
                          leading: _HubCodeBadge(hub: hub),
                          title: Text(hub.name),
                          subtitle: Text('${hub.city}, ${hub.state}'),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, hub),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedHubSummary extends StatelessWidget {
  const _SelectedHubSummary({
    required this.mode,
    required this.originHub,
    required this.destinationHub,
  });

  final TravelTransportMode mode;
  final TravelHub? originHub;
  final TravelHub? destinationHub;

  @override
  Widget build(BuildContext context) {
    final color = mode == TravelTransportMode.flight
        ? const Color(0xFF1463FF)
        : AppColors.primary;
    final title = originHub == null || destinationHub == null
        ? 'Select both ${_hubKindLabel(mode).toLowerCase()}s'
        : '${originHub!.code} to ${destinationHub!.code}';
    final subtitle = originHub == null || destinationHub == null
        ? 'Route details will update after selection.'
        : '${originHub!.city} to ${destinationHub!.city}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(
              mode == TravelTransportMode.flight
                  ? Icons.flight_takeoff_rounded
                  : Icons.train_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

class _RideRoutePanel extends StatelessWidget {
  const _RideRoutePanel({
    required this.mode,
    required this.originController,
    required this.destinationController,
    required this.travelDate,
    required this.travellers,
    required this.pickupLocation,
    required this.locatingPickup,
    required this.onUseCurrentPickup,
    required this.onClearCurrentPickup,
    required this.onPickDate,
    required this.onDecreaseTravellers,
    required this.onIncreaseTravellers,
    required this.validator,
  });

  final TravelTransportMode mode;
  final TextEditingController originController;
  final TextEditingController destinationController;
  final DateTime travelDate;
  final int travellers;
  final LocationData? pickupLocation;
  final bool locatingPickup;
  final VoidCallback onUseCurrentPickup;
  final VoidCallback onClearCurrentPickup;
  final VoidCallback onPickDate;
  final VoidCallback onDecreaseTravellers;
  final VoidCallback onIncreaseTravellers;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: originController,
          decoration: InputDecoration(
            labelText: 'Pickup',
            hintText: 'Current location, hotel, station or address',
            prefixIcon: const Icon(Icons.my_location_rounded),
            suffixIcon: pickupLocation == null
                ? null
                : IconButton(
                    tooltip: 'Clear current pickup',
                    onPressed: onClearCurrentPickup,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: locatingPickup ? null : onUseCurrentPickup,
            icon: locatingPickup
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.near_me_rounded),
            label: Text(
              locatingPickup ? 'Finding pickup' : 'Use current location',
            ),
          ),
        ),
        if (pickupLocation != null) ...[
          const SizedBox(height: 10),
          _CurrentPickupBadge(location: pickupLocation!),
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: destinationController,
          decoration: InputDecoration(
            labelText: 'Drop',
            hintText: mode == TravelTransportMode.auto
                ? 'Nearby market, metro stop or place'
                : 'Hotel, airport, station or place',
            prefixIcon: const Icon(Icons.place_outlined),
          ),
          validator: validator,
        ),
        const SizedBox(height: 14),
        BookingDateField(
          label: 'Ride date',
          value: travelDate,
          onTap: onPickDate,
        ),
        const SizedBox(height: 14),
        BookingCounter(
          label: 'Passengers',
          value: travellers,
          icon: Icons.people_outline_rounded,
          onDecrease: onDecreaseTravellers,
          onIncrease: onIncreaseTravellers,
        ),
      ],
    );
  }
}

class _CurrentPickupBadge extends StatelessWidget {
  const _CurrentPickupBadge({required this.location});

  final LocationData location;

  @override
  Widget build(BuildContext context) {
    final area = [
      if (location.city?.trim().isNotEmpty == true) location.city!.trim(),
      if (location.state?.trim().isNotEmpty == true) location.state!.trim(),
    ].join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_fixed_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              area.isEmpty
                  ? 'Pickup set from GPS'
                  : 'Pickup set from GPS - $area',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCodeBadge extends StatelessWidget {
  const _HubCodeBadge({required this.hub});

  final TravelHub hub;

  @override
  Widget build(BuildContext context) {
    final color = hub.type == TravelHubType.airport
        ? const Color(0xFF1463FF)
        : AppColors.primary;
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Text(
        hub.code.length <= 3 ? hub.code : hub.code.substring(0, 3),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HubText extends StatelessWidget {
  const _HubText({required this.hub});

  final TravelHub hub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${hub.name} (${hub.code})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${hub.city}, ${hub.state}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DelhiMetroPlannerPanel extends StatelessWidget {
  const _DelhiMetroPlannerPanel({
    required this.selectedLineId,
    required this.originStation,
    required this.destinationStation,
    required this.onLineChanged,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onSwap,
    required this.onQrTicket,
  });

  final String selectedLineId;
  final String originStation;
  final String destinationStation;
  final ValueChanged<String> onLineChanged;
  final ValueChanged<String> onOriginChanged;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onSwap;
  final VoidCallback onQrTicket;

  @override
  Widget build(BuildContext context) {
    final selectedLine = delhiMetroLineById(selectedLineId);
    final route = buildDelhiMetroRoutePlan(
      origin: originStation,
      destination: destinationStation,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Delhi Metro planner',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_vert_rounded),
              label: const Text('Swap'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DelhiMetroStationField(
          label: 'From station',
          value: _stationValue(originStation),
          onChanged: onOriginChanged,
        ),
        const SizedBox(height: 12),
        _DelhiMetroStationField(
          label: 'To station',
          value: _stationValue(destinationStation),
          onChanged: onDestinationChanged,
        ),
        const SizedBox(height: 16),
        Text(
          'Lines',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        _DelhiMetroLineSelector(
          selectedLineId: selectedLineId,
          onLineChanged: onLineChanged,
        ),
        const SizedBox(height: 12),
        _DelhiMetroStopsStrip(line: selectedLine),
        const SizedBox(height: 14),
        _DelhiMetroRouteSummary(route: route),
        if (route != null && route.totalStations > 0) ...[
          const SizedBox(height: 12),
          _DelhiMetroTicketAction(onQrTicket: onQrTicket),
        ],
      ],
    );
  }

  String? _stationValue(String value) {
    return delhiMetroStationNames.contains(value) ? value : null;
  }
}

class _DelhiMetroStationField extends StatelessWidget {
  const _DelhiMetroStationField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('$label-${value ?? 'empty'}'),
      initialValue: value,
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Choose a metro station'
          : null,
      builder: (field) {
        final selected = field.value;
        return InkWell(
          onTap: () async {
            final station = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              routeSettings: RouteSettings(name: '$label picker'),
              builder: (context) => _DelhiMetroStationPickerSheet(
                title: label,
                selectedStation: selected,
              ),
            );
            if (station == null) return;
            field.didChange(station);
            onChanged(station);
          },
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            isEmpty: selected == null || selected.isEmpty,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.subway_outlined),
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
              errorText: field.errorText,
            ),
            child: Text(
              selected ?? 'Choose Delhi Metro station',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: selected == null
                  ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      )
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}

class _DelhiMetroStationPickerSheet extends StatefulWidget {
  const _DelhiMetroStationPickerSheet({
    required this.title,
    required this.selectedStation,
  });

  final String title;
  final String? selectedStation;

  @override
  State<_DelhiMetroStationPickerSheet> createState() =>
      _DelhiMetroStationPickerSheetState();
}

class _DelhiMetroStationPickerSheetState
    extends State<_DelhiMetroStationPickerSheet> {
  final _searchController = TextEditingController();
  String? _lineId;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _stations {
    final baseStations = _lineId == null
        ? delhiMetroStationNames
        : delhiMetroLineById(_lineId!).stations;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return baseStations;
    return baseStations
        .where((station) => station.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final stations = _stations;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: 'Search inside station list',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: delhiMetroLines.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ChoiceChip(
                      selected: _lineId == null,
                      label: const Text('All lines'),
                      onSelected: (_) => setState(() => _lineId = null),
                    );
                  }
                  final line = delhiMetroLines[index - 1];
                  final selected = _lineId == line.id;
                  return ChoiceChip(
                    selected: selected,
                    avatar: CircleAvatar(backgroundColor: line.color),
                    label: Text(line.name.replaceAll(' Line', '')),
                    selectedColor: line.color.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: selected
                          ? line.color
                          : Theme.of(context).dividerColor,
                    ),
                    onSelected: (_) => setState(() => _lineId = line.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: stations.isEmpty
                  ? const Center(child: Text('No station found.'))
                  : ListView.separated(
                      itemCount: stations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final station = stations[index];
                        final lines = delhiMetroLinesForStation(station);
                        final selected = station == widget.selectedStation;
                        return ListTile(
                          selected: selected,
                          contentPadding: EdgeInsets.zero,
                          leading: _MetroStationLineDots(lines: lines),
                          title: Text(station),
                          subtitle: Text(
                            lines.map((line) => line.name).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, station),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetroStationLineDots extends StatelessWidget {
  const _MetroStationLineDots({required this.lines});

  final List<DelhiMetroLine> lines;

  @override
  Widget build(BuildContext context) {
    final visibleLines = lines.take(3).toList();
    return SizedBox(
      width: 34,
      child: Stack(
        children: [
          for (var index = 0; index < visibleLines.length; index += 1)
            Positioned(
              left: index * 9,
              top: 10,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: visibleLines[index].color,
              ),
            ),
        ],
      ),
    );
  }
}

class _DelhiMetroTicketAction extends StatelessWidget {
  const _DelhiMetroTicketAction({required this.onQrTicket});

  final VoidCallback onQrTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accent.withValues(alpha: 0.14),
            foregroundColor: AppColors.accent,
            child: const Icon(Icons.qr_code_2_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metro QR ticket',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Open the official DMRC ticketing flow for this route.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: onQrTicket,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Get QR'),
          ),
        ],
      ),
    );
  }
}

class _DelhiMetroLineSelector extends StatelessWidget {
  const _DelhiMetroLineSelector({
    required this.selectedLineId,
    required this.onLineChanged,
  });

  final String selectedLineId;
  final ValueChanged<String> onLineChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: delhiMetroLines.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final line = delhiMetroLines[index];
          final selected = selectedLineId == line.id;
          return ChoiceChip(
            selected: selected,
            avatar: CircleAvatar(backgroundColor: line.color),
            label: Text(line.name.replaceAll(' Line', '')),
            selectedColor: line.color.withValues(alpha: 0.18),
            side: BorderSide(
              color: selected ? line.color : Theme.of(context).dividerColor,
            ),
            onSelected: (_) => onLineChanged(line.id),
          );
        },
      ),
    );
  }
}

class _DelhiMetroStopsStrip extends StatelessWidget {
  const _DelhiMetroStopsStrip({required this.line});

  final DelhiMetroLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: line.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 6, backgroundColor: line.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${line.name} stops',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '${line.stations.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: line.stations.length,
              separatorBuilder: (_, __) => const Icon(
                Icons.chevron_right_rounded,
                size: 16,
              ),
              itemBuilder: (context, index) => Chip(
                label: Text(line.stations[index]),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DelhiMetroRouteSummary extends StatelessWidget {
  const _DelhiMetroRouteSummary({required this.route});

  final DelhiMetroRoutePlan? route;

  @override
  Widget build(BuildContext context) {
    final plan = route;
    if (plan == null) {
      return const _NoPartnerCard(
        message:
            'Choose two Delhi Metro stations to see line changes and route guidance.',
      );
    }

    if (plan.totalStations == 0) {
      return const _NoPartnerCard(
        message: 'Start and destination are the same station.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(Icons.alt_route_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.isDirect
                          ? 'Direct metro route'
                          : 'Change at ${plan.interchanges.join(', ')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.totalStations} station${plan.totalStations == 1 ? '' : 's'} from ${plan.fromStation} to ${plan.toStation}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final leg in plan.legs) ...[
            _DelhiMetroLegTile(leg: leg),
            if (leg != plan.legs.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DelhiMetroLegTile extends StatelessWidget {
  const _DelhiMetroLegTile({required this.leg});

  final DelhiMetroRouteLeg leg;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 42,
          decoration: BoxDecoration(
            color: leg.line.color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${leg.fromStation} to ${leg.toStation}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '${leg.line.name} · ${leg.stationCount} stop${leg.stationCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
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

String _hubKindLabel(TravelTransportMode mode) {
  return switch (mode) {
    TravelTransportMode.flight => 'Airport',
    TravelTransportMode.train => 'Station',
    _ => 'Stop',
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
