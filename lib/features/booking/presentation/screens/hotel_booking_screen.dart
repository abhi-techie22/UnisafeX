import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/booking/data/booking_link_service.dart';
import 'package:unisafex/features/booking/domain/booking_partner_config.dart';
import 'package:unisafex/features/booking/presentation/widgets/booking_form_widgets.dart';

class HotelBookingScreen extends StatefulWidget {
  const HotelBookingScreen({super.key});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController(text: 'New Delhi');
  late DateTime _checkIn;
  late DateTime _checkOut;
  int _guests = 2;
  int _rooms = 1;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _checkIn = today.add(const Duration(days: 7));
    _checkOut = today.add(const Duration(days: 10));
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckIn() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null) return;
    setState(() {
      _checkIn = selected;
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _pickCheckOut() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _checkOut,
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected != null) setState(() => _checkOut = selected);
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _opening = true);
    final opened = await BookingLinkService.open(
      BookingLinkService.buildHotelSearch(
        destination: _destinationController.text,
        checkIn: _checkIn,
        checkOut: _checkOut,
        adults: _guests,
        rooms: _rooms,
      ),
    );
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the booking partner.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotel booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const BookingHero(
                icon: Icons.hotel_rounded,
                title: 'Find your stay in India',
                subtitle:
                    'Search hotels with your dates and guest preferences.',
                colors: [Color(0xFF173F35), AppColors.primary],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _destinationController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'City or destination',
                  hintText: 'For example: Jaipur',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a destination'
                    : null,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'Check-in',
                value: _checkIn,
                onTap: _pickCheckIn,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'Check-out',
                value: _checkOut,
                onTap: _pickCheckOut,
              ),
              const SizedBox(height: 14),
              BookingCounter(
                label: 'Guests',
                value: _guests,
                icon: Icons.people_outline_rounded,
                onDecrease: () =>
                    setState(() => _guests = (_guests - 1).clamp(1, 20)),
                onIncrease: () =>
                    setState(() => _guests = (_guests + 1).clamp(1, 20)),
              ),
              const SizedBox(height: 12),
              BookingCounter(
                label: 'Rooms',
                value: _rooms,
                icon: Icons.bed_outlined,
                onDecrease: () =>
                    setState(() => _rooms = (_rooms - 1).clamp(1, 10)),
                onIncrease: () =>
                    setState(() => _rooms = (_rooms + 1).clamp(1, 10)),
              ),
              const SizedBox(height: 18),
              AffiliateDisclosure(
                isConfigured: BookingPartnerConfig.hasHotelAffiliate,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _opening ? null : _search,
                icon: _opening
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Search hotel partner'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
