import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/booking/domain/booking_partner.dart';
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
  BookingPartner _selectedPartner = hotelBookingPartners.first;

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
    showPartnerPendingMessage(context, _selectedPartner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('hotel_booking'.tr())),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              BookingHero(
                icon: Icons.hotel_rounded,
                title: 'find_stay'.tr(),
                subtitle: 'hotel_search_subtitle'.tr(),
                colors: const [Color(0xFF173F35), AppColors.primary],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _destinationController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'city_destination'.tr(),
                  hintText: 'destination_example'.tr(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'enter_destination'.tr()
                    : null,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'check_in'.tr(),
                value: _checkIn,
                onTap: _pickCheckIn,
              ),
              const SizedBox(height: 14),
              BookingDateField(
                label: 'check_out'.tr(),
                value: _checkOut,
                onTap: _pickCheckOut,
              ),
              const SizedBox(height: 14),
              BookingCounter(
                label: 'guests'.tr(),
                value: _guests,
                icon: Icons.people_outline_rounded,
                onDecrease: () =>
                    setState(() => _guests = (_guests - 1).clamp(1, 20)),
                onIncrease: () =>
                    setState(() => _guests = (_guests + 1).clamp(1, 20)),
              ),
              const SizedBox(height: 12),
              BookingCounter(
                label: 'rooms'.tr(),
                value: _rooms,
                icon: Icons.bed_outlined,
                onDecrease: () =>
                    setState(() => _rooms = (_rooms - 1).clamp(1, 10)),
                onIncrease: () =>
                    setState(() => _rooms = (_rooms + 1).clamp(1, 10)),
              ),
              const SizedBox(height: 18),
              BookingPartnerSelector(
                partners: hotelBookingPartners,
                selected: _selectedPartner,
                onSelected: (partner) =>
                    setState(() => _selectedPartner = partner),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search_rounded),
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
}
