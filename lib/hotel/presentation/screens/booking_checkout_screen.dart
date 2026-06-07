import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/common/loading_overlay.dart';
import '../../../widgets/common/premium_text_field.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../providers/hotel_providers.dart';

class BookingCheckoutScreen extends ConsumerStatefulWidget {
  final Hotel hotel;
  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int nights;

  const BookingCheckoutScreen({
    super.key,
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.nights,
  });

  @override
  ConsumerState<BookingCheckoutScreen> createState() =>
      _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState
    extends ConsumerState<BookingCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _acceptTerms = false;
  final _fmt = DateFormat('EEE, dd MMM yyyy');

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showSnack('Please accept the terms and conditions.');
      return;
    }

    final booking = await ref
        .read(bookingFlowProvider.notifier)
        .confirmBooking(
          hotel: widget.hotel,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          guests: widget.adults,
        );

    if (!mounted) return;

    if (booking != null) {
      context.pushReplacement('/hotel/confirmation', extra: booking);
    } else {
      final error = ref.read(bookingFlowProvider).error;
      _showSnack(error ?? 'Booking failed. Please try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingFlowProvider);
    final total = widget.room.pricePerNight * widget.nights;
    final taxes = total * 0.12;
    final grandTotal = total + taxes;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Complete Booking',
            style:
                AppTextStyles.headlineSmall.copyWith(color: AppColors.ivory)),
      ),
      body: LoadingOverlay(
        isLoading: bookingState.isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Booking summary ─────────────────────────────────
                _BookingSummaryCard(
                  hotel: widget.hotel,
                  room: widget.room,
                  checkIn: widget.checkIn,
                  checkOut: widget.checkOut,
                  nights: widget.nights,
                  adults: widget.adults,
                  fmt: _fmt,
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ── Guest details ────────────────────────────────────
                Text('Guest Details',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.ivory))
                    .animate()
                    .fadeIn(delay: 100.ms),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: PremiumTextField(
                        controller: _firstNameCtrl,
                        label: 'First Name',
                        hint: 'John',
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumTextField(
                        controller: _lastNameCtrl,
                        label: 'Last Name',
                        hint: 'Smith',
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 14),

                PremiumTextField(
                  controller: _emailCtrl,
                  label: 'Email Address',
                  hint: 'john@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ).animate().fadeIn(delay: 180.ms),

                const SizedBox(height: 14),

                PremiumTextField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: '+91 98765 43210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ).animate().fadeIn(delay: 210.ms),

                const SizedBox(height: 28),

                // ── Price breakdown ──────────────────────────────────
                Text('Price Breakdown',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.ivory))
                    .animate()
                    .fadeIn(delay: 240.ms),

                const SizedBox(height: 14),

                _PriceBreakdown(
                  room: widget.room,
                  nights: widget.nights,
                  subtotal: total,
                  taxes: taxes,
                  grandTotal: grandTotal,
                ).animate().fadeIn(delay: 270.ms),

                const SizedBox(height: 20),

                // ── Cancellation policy ──────────────────────────────
                if (widget.room.cancellationPolicy != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.room.refundable
                          ? AppColors.success.withValues(alpha: 0.07)
                          : AppColors.warning.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.room.refundable
                            ? AppColors.success.withValues(alpha: 0.25)
                            : AppColors.warning.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          widget.room.refundable
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: widget.room.refundable
                              ? AppColors.success
                              : AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.room.cancellationPolicy!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: widget.room.refundable
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                ],

                // ── Payment note ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.glassGold,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline,
                          color: AppColors.goldPrimary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Payment is processed securely. Your booking confirmation and receipt will be sent via email.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.goldMuted),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 330.ms),

                const SizedBox(height: 20),

                // ── Terms checkbox ───────────────────────────────────
                GestureDetector(
                  onTap: () =>
                      setState(() => _acceptTerms = !_acceptTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: 150.ms,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _acceptTerms
                              ? AppColors.goldPrimary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _acceptTerms
                                ? AppColors.goldPrimary
                                : AppColors.darkDivider,
                            width: 1.5,
                          ),
                        ),
                        child: _acceptTerms
                            ? const Icon(Icons.check,
                                color: AppColors.navyDeep, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I agree to the Terms & Conditions and Privacy Policy. I understand the cancellation policy for this booking.',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.darkTextSecondary,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 360.ms),

                const SizedBox(height: 28),

                // ── Book button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        bookingState.isLoading ? null : _placeBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: AppColors.navyDeep,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                    child: Text(
                      'Confirm & Pay ₹${grandTotal.toStringAsFixed(0)}',
                      style: AppTextStyles.buttonText
                          .copyWith(color: AppColors.navyDeep),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                // Also offer affiliate redirect
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(bookingFlowProvider.notifier).redirectToBookingCom(
                              hotel: widget.hotel,
                              checkIn: widget.checkIn,
                              checkOut: widget.checkOut,
                              adults: widget.adults,
                              rooms: 1,
                            ),
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: const Text('Book via Booking.com instead'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkTextSecondary,
                      side: const BorderSide(color: AppColors.darkDivider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ).animate().fadeIn(delay: 440.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  final Hotel hotel;
  final Room room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final DateFormat fmt;

  const _BookingSummaryCard({
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Hotel icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hotel,
                    color: AppColors.goldPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name,
                        style: AppTextStyles.titleLarge
                            .copyWith(color: AppColors.ivory),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(room.name,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.darkTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.darkDivider, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryItem(label: 'Check-in', value: fmt.format(checkIn)),
              const SizedBox(width: 20),
              _SummaryItem(label: 'Check-out', value: fmt.format(checkOut)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SummaryItem(
                  label: 'Duration',
                  value: '$nights night${nights != 1 ? 's' : ''}'),
              const SizedBox(width: 20),
              _SummaryItem(
                  label: 'Guests',
                  value: '$adults adult${adults != 1 ? 's' : ''}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.overline
                .copyWith(color: AppColors.darkTextMuted, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.ivory, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  final Room room;
  final int nights;
  final double subtotal;
  final double taxes;
  final double grandTotal;

  const _PriceBreakdown({
    required this.room,
    required this.nights,
    required this.subtotal,
    required this.taxes,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: Column(
        children: [
          _PriceRow(
            label: '${room.formattedPrice} × $nights night${nights != 1 ? 's' : ''}',
            value: '₹${subtotal.toStringAsFixed(0)}',
          ),
          if (room.breakfastIncluded)
            const _PriceRow(
              label: 'Breakfast included',
              value: 'Complimentary',
              valueColor: AppColors.success,
            ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.darkDivider, height: 1),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Taxes & fees (12%)',
            value: '₹${taxes.toStringAsFixed(0)}',
            labelColor: AppColors.darkTextMuted,
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.darkDivider, height: 1),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Total Amount',
            value: '₹${grandTotal.toStringAsFixed(0)}',
            isBold: true,
            valueColor: AppColors.goldPrimary,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? labelColor;
  final Color? valueColor;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: labelColor ?? AppColors.darkTextSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.ivory,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
