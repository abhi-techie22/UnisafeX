import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/common/shimmer_loader.dart';
import '../../domain/entities/booking.dart';
import '../providers/hotel_providers.dart';
import 'package:unisafex/data/providers/auth_provider.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('My Bookings',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.ivory)),
      ),
      body: isGuest
          ? _GuestView()
          : bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) return _EmptyView();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _BookingHistoryCard(
                    booking: bookings[i],
                    index: i,
                  ),
                );
              },
              loading: () => _LoadingList(),
              error: (e, _) => _ErrorView(message: e.toString()),
            ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  final Booking booking;
  final int index;

  const _BookingHistoryCard(
      {required this.booking, required this.index});

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.completed:
        return AppColors.info;
      case BookingStatus.redirected:
        return AppColors.darkTextMuted;
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.redirected:
        return Icons.open_in_browser;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top section ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.navyMid,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hotel,
                      color: AppColors.goldPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.hotelName,
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.ivory),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(booking.roomType,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.darkTextSecondary)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, color: _statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(booking.statusLabel,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: _statusColor, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.darkDivider, height: 1),

          // ── Dates row ──────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _DateChip(
                    label: 'CHECK-IN',
                    value: fmt.format(booking.checkIn)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 1,
                        color: AppColors.darkDivider,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${booking.nights}n',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.darkTextMuted,
                                fontSize: 9),
                      ),
                    ],
                  ),
                ),
                _DateChip(
                    label: 'CHECK-OUT',
                    value: fmt.format(booking.checkOut)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('TOTAL',
                        style: AppTextStyles.overline
                            .copyWith(
                                color: AppColors.darkTextMuted,
                                fontSize: 8,
                                letterSpacing: 1)),
                    Text(
                      booking.formattedTotal,
                      style: AppTextStyles.headlineSmall
                          .copyWith(
                              color: AppColors.goldPrimary,
                              fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Confirmation code ──────────────────────────────────
          if (booking.confirmationCode != null) ...[
            const Divider(color: AppColors.darkDivider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                      color: AppColors.darkTextMuted, size: 14),
                  const SizedBox(width: 6),
                  Text('Confirmation: ',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.darkTextMuted)),
                  Text(
                    booking.confirmationCode!,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.goldPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'via ${booking.partnerSource.toUpperCase()}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.darkTextMuted, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 400.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  const _DateChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.overline.copyWith(
                color: AppColors.darkTextMuted, fontSize: 8, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.ivory, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GuestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkDivider),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.darkTextMuted, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Sign in to View Bookings',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.ivory),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Create an account to track and manage your hotel bookings.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.darkTextSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.register),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: AppColors.navyDeep,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                ),
                child: Text('Create Account',
                    style: AppTextStyles.buttonText
                        .copyWith(color: AppColors.navyDeep)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel_outlined,
              color: AppColors.darkTextMuted, size: 64),
          const SizedBox(height: 16),
          Text('No Bookings Yet',
              style: AppTextStyles.headlineSmall
                  .copyWith(color: AppColors.darkTextSecondary)),
          const SizedBox(height: 8),
          Text('Your hotel bookings will appear here.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.darkTextMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/hotel/search'),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Find Hotels'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: AppColors.navyDeep,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => ShimmerLoader(
        child: Container(
          height: 150,
          decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Error: $message',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.darkTextMuted)),
    );
  }
}
