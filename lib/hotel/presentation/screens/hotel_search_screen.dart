import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../domain/entities/hotel_search_params.dart';
import '../providers/hotel_providers.dart';
import '../widgets/hotel_date_picker_sheet.dart';

class HotelSearchScreen extends ConsumerStatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  ConsumerState<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends ConsumerState<HotelSearchScreen> {
  bool _locating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      ref.read(hotelSearchParamsProvider.notifier)
          .updateGeoLocation(pos.latitude, pos.longitude);
      _showSnack('Using your current location');
    } catch (e) {
      _showSnack('Could not get location: ${e.toString()}');
    } finally {
      setState(() => _locating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HotelDatePickerSheet(
        onConfirm: (checkIn, checkOut, adults, rooms) {
          final n = ref.read(hotelSearchParamsProvider.notifier);
          n.updateDates(checkIn, checkOut);
          n.updateGuests(adults);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _search(String city) {
    ref.read(hotelSearchParamsProvider.notifier).updateCity(city);
    context.push('/hotel/list');
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(hotelSearchParamsProvider);
    final fmt = DateFormat('dd MMM');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.3,
                colors: [Color(0xFF0F2044), AppColors.darkBg],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.darkDivider),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.darkTextSecondary, size: 17),
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Find Hotels',
                              style: AppTextStyles.headlineMedium
                                  .copyWith(color: AppColors.ivory)),
                          Text('Book your perfect stay',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.darkTextMuted)),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // Hero card
                  _HeroSearchCard(
                    params: params,
                    dateLabel:
                        '${fmt.format(params.checkIn)} → ${fmt.format(params.checkOut)}',
                    onDateTap: _showDatePicker,
                    nights: params.nights,
                    adults: params.adults,
                  ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                  const SizedBox(height: 24),

                  // Nearby search button
                  GestureDetector(
                    onTap: _locating ? null : _useCurrentLocation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.goldPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.glassGold,
                              shape: BoxShape.circle,
                            ),
                            child: _locating
                                ? const CircularProgressIndicator(
                                    color: AppColors.goldPrimary,
                                    strokeWidth: 2)
                                : const Icon(Icons.my_location,
                                    color: AppColors.goldPrimary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hotels Near Me',
                                    style: AppTextStyles.titleMedium
                                        .copyWith(color: AppColors.ivory)),
                                Text('Use GPS to find nearby hotels',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.darkTextMuted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.darkTextMuted),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 28),

                  // Popular destinations
                  Text('Popular Destinations',
                          style: AppTextStyles.headlineSmall
                              .copyWith(color: AppColors.ivory))
                      .animate()
                      .fadeIn(delay: 300.ms),

                  const SizedBox(height: 6),

                  Text('Tap to search hotels in that city',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.darkTextMuted))
                      .animate()
                      .fadeIn(delay: 350.ms),

                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children:
                        _popularDestinations.asMap().entries.map((e) {
                      return _DestinationTile(
                        data: e.value,
                        index: e.key,
                        onTap: () => _search(e.value['city']!),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<Map<String, String>> _popularDestinations = [
    {'city': 'Delhi', 'emoji': '🏛️', 'sub': 'Capital City'},
    {'city': 'Mumbai', 'emoji': '🌊', 'sub': 'City of Dreams'},
    {'city': 'Jaipur', 'emoji': '🏰', 'sub': 'Pink City'},
    {'city': 'Goa', 'emoji': '🏖️', 'sub': 'Beach Paradise'},
    {'city': 'Agra', 'emoji': '🕌', 'sub': 'Taj Mahal'},
    {'city': 'Varanasi', 'emoji': '🪔', 'sub': 'Spiritual India'},
  ];
}

class _HeroSearchCard extends StatelessWidget {
  final HotelSearchParams params;
  final String dateLabel;
  final VoidCallback onDateTap;
  final int nights;
  final int adults;

  const _HeroSearchCard({
    required this.params,
    required this.dateLabel,
    required this.onDateTap,
    required this.nights,
    required this.adults,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyMid, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.goldPrimary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR SEARCH',
              style: AppTextStyles.overline
                  .copyWith(color: AppColors.goldPrimary, letterSpacing: 2)),
          const SizedBox(height: 14),

          // Date row
          GestureDetector(
            onTap: onDateTap,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.goldPrimary, size: 18),
                const SizedBox(width: 10),
                Text(dateLabel,
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.ivory)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.glassGold,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$nights night${nights != 1 ? 's' : ''}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.goldPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(color: AppColors.darkDivider),
          const SizedBox(height: 10),

          // Guests row
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.goldPrimary, size: 18),
              const SizedBox(width: 10),
              Text('$adults adult${adults != 1 ? 's' : ''}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.ivory)),
              const SizedBox(width: 20),
              const Icon(Icons.bed_outlined,
                  color: AppColors.goldPrimary, size: 18),
              const SizedBox(width: 10),
              Text('${params.rooms} room${params.rooms != 1 ? 's' : ''}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.ivory)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final Map<String, String> data;
  final int index;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.data,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkDivider),
        ),
        child: Row(
          children: [
            Text(data['emoji'] ?? '🏨',
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['city'] ?? '',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.ivory),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['sub'] ?? '',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.darkTextMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (index * 60 + 400).ms, duration: 350.ms)
          .slideX(begin: 0.05, end: 0),
    );
  }
}
