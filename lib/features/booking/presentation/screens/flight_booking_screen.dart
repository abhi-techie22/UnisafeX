import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(title: Text('flight_booking'.tr())),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              BookingHero(
                icon: Icons.flight_takeoff_rounded,
                title: 'search_flights'.tr(),
                subtitle: 'flight_search_subtitle'.tr(),
                colors: const [Color(0xFF193A62), Color(0xFF2E6AA5)],
              ),
              const SizedBox(height: 18),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text('round_trip'.tr()),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('one_way'.tr()),
                  ),
                ],
                selected: {_roundTrip},
                onSelectionChanged: (value) =>
                    setState(() => _roundTrip = value.first),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _originController,
                decoration: InputDecoration(
                  labelText: 'from'.tr(),
                  hintText: 'city_airport'.tr(),
                  prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                ),
                validator: _requiredLocation,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  labelText: 'to'.tr(),
                  hintText: 'city_airport'.tr(),
                  prefixIcon: const Icon(Icons.flight_land_rounded),
                ),
                validator: _requiredLocation,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'departure'.tr(),
                value: _departure,
                onTap: _pickDeparture,
              ),
              if (_roundTrip) ...[
                const SizedBox(height: 14),
                BookingDateField(
                  label: 'return_date'.tr(),
                  value: _returnDate,
                  onTap: _pickReturn,
                ),
              ],
              const SizedBox(height: 14),
              BookingCounter(
                label: 'travellers'.tr(),
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
                  child: Text(
                    'search_with'.tr(args: [_selectedPartner.name]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredLocation(String? value) =>
      value == null || value.trim().isEmpty ? 'enter_city_airport'.tr() : null;
}
