import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/shimmer_loader.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../providers/hotel_providers.dart';
import '../widgets/room_card.dart';

class RoomSelectionScreen extends ConsumerWidget {
  final Hotel hotel;

  const RoomSelectionScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(hotelRoomsProvider(hotel));
    final bookingState = ref.watch(bookingFlowProvider);
    final params = ref.watch(hotelSearchParamsProvider);
    final fmt = DateFormat('dd MMM');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: AppColors.darkTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hotel.name,
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.ivory),
                overflow: TextOverflow.ellipsis),
            Text(
              '${fmt.format(params.checkIn)} – ${fmt.format(params.checkOut)} · ${params.adults} guest${params.adults != 1 ? 's' : ''}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.darkTextMuted),
            ),
          ],
        ),
      ),
      body: roomsAsync.when(
        data: (rooms) {
          if (rooms.isEmpty) {
            return _NoRooms(hotelName: hotel.name);
          }
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      '${rooms.length} room type${rooms.length != 1 ? 's' : ''} available',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.darkTextMuted),
                    ),
                    const Spacer(),
                    Text(
                      '${params.nights} night${params.nights != 1 ? 's' : ''}',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.goldPrimary),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              // Rooms list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  physics: const BouncingScrollPhysics(),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => RoomCard(
                    room: rooms[i],
                    isSelected:
                        bookingState.selectedRoom?.id == rooms[i].id,
                    onTap: () => ref
                        .read(bookingFlowProvider.notifier)
                        .selectRoom(rooms[i]),
                  )
                      .animate()
                      .fadeIn(delay: (i * 80).ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                ),
              ),
            ],
          );
        },
        loading: () => _LoadingRooms(),
        error: (e, _) => Center(
          child: Text('Failed to load rooms: ${e.toString()}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.darkTextMuted)),
        ),
      ),
      bottomNavigationBar: bookingState.selectedRoom == null
          ? null
          : _BottomBookBar(
              room: bookingState.selectedRoom!,
              hotel: hotel,
              nights: params.nights,
              checkIn: params.checkIn,
              checkOut: params.checkOut,
              adults: params.adults,
            ),
    );
  }
}

class _BottomBookBar extends ConsumerWidget {
  final Room room;
  final Hotel hotel;
  final int nights;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;

  const _BottomBookBar({
    required this.room,
    required this.hotel,
    required this.nights,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = room.pricePerNight * nights;
    final isLoading = ref.watch(bookingFlowProvider).isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
            top: BorderSide(color: AppColors.darkDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Price summary
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.darkTextMuted)),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.goldPrimary),
              ),
              Text('$nights night${nights != 1 ? 's' : ''} · ${room.name}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.darkTextMuted, fontSize: 9)),
            ],
          ),
          const SizedBox(width: 16),
          // Book now
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => _confirmBooking(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: AppColors.navyDeep,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navyDeep))
                    : Text('Book Now',
                        style: AppTextStyles.buttonText
                            .copyWith(color: AppColors.navyDeep)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context, WidgetRef ref) async {
    context.push('/hotel/checkout', extra: {
      'hotel': hotel,
      'room': room,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'adults': adults,
      'nights': nights,
    });
  }
}

class _NoRooms extends StatelessWidget {
  final String hotelName;
  const _NoRooms({required this.hotelName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bed_outlined,
              color: AppColors.darkTextMuted, size: 64),
          const SizedBox(height: 16),
          Text('No rooms available',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 8),
          Text('Try different dates or contact $hotelName directly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.darkTextMuted)),
        ],
      ),
    );
  }
}

class _LoadingRooms extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => ShimmerLoader(
        child: Container(
          height: 220,
          decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
