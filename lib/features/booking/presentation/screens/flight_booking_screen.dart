import 'package:flutter/material.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
import 'package:unisafex/features/booking/presentation/widgets/booking_form_widgets.dart';

class FlightBookingScreen extends StatefulWidget {
  const FlightBookingScreen({super.key});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController(text: 'London');
  final _destinationController = TextEditingController(text: 'New Delhi');
  late DateTime _departure;
  late DateTime _returnDate;
  bool _roundTrip = true;
  int _travellers = 1;
  BookingPartner _selectedPartner = flightBookingPartners.first;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _departure = today.add(const Duration(days: 14));
    _returnDate = today.add(const Duration(days: 24));
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDeparture() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _departure,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null) return;
    setState(() {
      _departure = selected;
      if (!_returnDate.isAfter(_departure)) {
        _returnDate = _departure.add(const Duration(days: 7));
      }
    });
  }

  Future<void> _pickReturn() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: _departure.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => _returnDate = selected);
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    showPartnerPendingMessage(context, _selectedPartner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flight booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const BookingHero(
                icon: Icons.flight_takeoff_rounded,
                title: 'Search flights',
                subtitle: 'Compare routes to India and domestic connections.',
                colors: [Color(0xFF193A62), Color(0xFF2E6AA5)],
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Round trip')),
                  ButtonSegment(value: false, label: Text('One way')),
                ],
                selected: {_roundTrip},
                onSelectionChanged: (value) =>
                    setState(() => _roundTrip = value.first),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(
                  labelText: 'From',
                  hintText: 'City or airport',
                  prefixIcon: Icon(Icons.flight_takeoff_rounded),
                ),
                validator: _requiredLocation,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'City or airport',
                  prefixIcon: Icon(Icons.flight_land_rounded),
                ),
                validator: _requiredLocation,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'Departure',
                value: _departure,
                onTap: _pickDeparture,
              ),
              if (_roundTrip) ...[
                const SizedBox(height: 14),
                BookingDateField(
                  label: 'Return',
                  value: _returnDate,
                  onTap: _pickReturn,
                ),
              ],
              const SizedBox(height: 14),
              BookingCounter(
                label: 'Travellers',
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
              BookingPartnerSelector(
                partners: flightBookingPartners,
                selected: _selectedPartner,
                onSelected: (partner) =>
                    setState(() => _selectedPartner = partner),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text('Search with ${_selectedPartner.name}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredLocation(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter a city or airport' : null;
}
