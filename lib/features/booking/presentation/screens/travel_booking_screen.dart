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
    _selectedPartner = travelPartnersForMode(_selectedMode).first;
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
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
    final uri = BookingLinkService.buildTravelSearch(
      mode: _selectedMode,
      origin: _originController.text,
      destination: _destinationController.text,
      departure: _travelDate,
      travellers: _travellers,
      partner: _selectedPartner,
    );
    final opened = await BookingLinkService.open(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open ${_selectedPartner.name}. Please try again.',
          ),
        ),
      );
    }
  }

  void _selectMode(TravelTransportMode mode) {
    setState(() {
      _selectedMode = mode;
      _selectedPartner = travelPartnersForMode(mode).first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final partners = travelPartnersForMode(_selectedMode);
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
              const SizedBox(height: 18),
              BookingPartnerSelector(
                partners: partners,
                selected: _selectedPartner,
                onSelected: (partner) =>
                    setState(() => _selectedPartner = partner),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _search,
                icon: Icon(_modeIcon(_selectedMode)),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text('Open ${_selectedPartner.name}'),
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
