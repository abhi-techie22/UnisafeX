import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../domain/entities/booking.dart';
import '../providers/hotel_providers.dart';

class BookingConfirmationScreen extends ConsumerWidget {
  final Booking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('EEE, dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    AppColors.success.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Success animation ──────────────────────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.12),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 52),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  Text(
                    'Booking Confirmed!',
                    style: AppTextStyles.displaySmall
                        .copyWith(color: AppColors.ivory),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Your reservation is confirmed. Check your email for details.',
                    style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.darkTextSecondary, height: 1.6),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                  const SizedBox(height: 32),

                  // ── Confirmation card ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.08),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Confirmation code
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.navyMid,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text('CONFIRMATION CODE',
                                  style: AppTextStyles.overline.copyWith(
                                      color: AppColors.darkTextMuted,
                                      letterSpacing: 2)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  if (booking.confirmationCode != null) {
                                    Clipboard.setData(ClipboardData(
                                        text: booking.confirmationCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Copied to clipboard'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      booking.confirmationCode ?? '—',
                                      style: AppTextStyles.headlineLarge
                                          .copyWith(
                                        color: AppColors.goldPrimary,
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.copy_outlined,
                                        color: AppColors.darkTextMuted,
                                        size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(color: AppColors.darkDivider),
                        const SizedBox(height: 16),

                        // Details
                        _DetailRow(
                            icon: Icons.hotel,
                            label: 'Hotel',
                            value: booking.hotelName),
                        _DetailRow(
                            icon: Icons.bed_outlined,
                            label: 'Room',
                            value: booking.roomType),
                        _DetailRow(
                            icon: Icons.login,
                            label: 'Check-in',
                            value: fmt.format(booking.checkIn)),
                        _DetailRow(
                            icon: Icons.logout,
                            label: 'Check-out',
                            value: fmt.format(booking.checkOut)),
                        _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Guests',
                            value:
                                '${booking.guests} adult${booking.guests != 1 ? 's' : ''}'),
                        _DetailRow(
                            icon: Icons.nights_stay_outlined,
                            label: 'Duration',
                            value:
                                '${booking.nights} night${booking.nights != 1 ? 's' : ''}'),

                        const SizedBox(height: 12),
                        const Divider(color: AppColors.darkDivider),
                        const SizedBox(height: 12),

                        // Total
                        Row(
                          children: [
                            Text('Total Paid',
                                style: AppTextStyles.titleMedium
                                    .copyWith(color: AppColors.darkTextSecondary)),
                            const Spacer(),
                            Text(
                              booking.formattedTotal,
                              style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.goldPrimary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 28),

                  // Partner badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkDivider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_outlined,
                            color: AppColors.info, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Booked via ${booking.partnerSource.toUpperCase()}',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 750.ms),

                  const SizedBox(height: 32),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/hotel/history'),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('View My Bookings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary,
                        foregroundColor: AppColors.navyDeep,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(bookingFlowProvider.notifier).reset();
                        context.go(AppRoutes.home);
                      },
                      icon: const Icon(Icons.explore_outlined, size: 16),
                      label: const Text('Explore More Places'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkTextSecondary,
                        side: const BorderSide(color: AppColors.darkDivider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 850.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldPrimary, size: 15),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.darkTextMuted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.ivory, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
