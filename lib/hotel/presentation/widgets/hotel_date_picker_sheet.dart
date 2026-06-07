import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/hotel_providers.dart';

/// Shows a date-range + guest picker sheet.
/// Calls [onConfirm] with the chosen values.
class HotelDatePickerSheet extends ConsumerStatefulWidget {
  final void Function(DateTime checkIn, DateTime checkOut, int adults, int rooms)
      onConfirm;

  const HotelDatePickerSheet({super.key, required this.onConfirm});

  @override
  ConsumerState<HotelDatePickerSheet> createState() =>
      _HotelDatePickerSheetState();
}

class _HotelDatePickerSheetState
    extends ConsumerState<HotelDatePickerSheet> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _rooms;

  @override
  void initState() {
    super.initState();
    final p = ref.read(hotelSearchParamsProvider);
    _checkIn = p.checkIn;
    _checkOut = p.checkOut;
    _adults = p.adults;
    _rooms = p.rooms;
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.goldPrimary,
            onPrimary: AppColors.navyDeep,
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final nights = _checkOut.difference(_checkIn).inDays;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.darkDivider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Text('When are you going?',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.ivory)),

          const SizedBox(height: 20),

          // Date row
          GestureDetector(
            onTap: _pickDates,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.darkDivider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CHECK-IN',
                            style: AppTextStyles.overline
                                .copyWith(color: AppColors.darkTextMuted)),
                        const SizedBox(height: 4),
                        Text(fmt.format(_checkIn),
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.ivory)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('CHECK-OUT',
                            style: AppTextStyles.overline
                                .copyWith(color: AppColors.darkTextMuted)),
                        const SizedBox(height: 4),
                        Text(fmt.format(_checkOut),
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.ivory)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Adults
          _CounterRow(
            label: 'Adults',
            subtitle: 'Per room',
            value: _adults,
            min: 1,
            max: 6,
            onChanged: (v) => setState(() => _adults = v),
          ),

          const SizedBox(height: 12),

          // Rooms
          _CounterRow(
            label: 'Rooms',
            subtitle: 'Number of rooms',
            value: _rooms,
            min: 1,
            max: 5,
            onChanged: (v) => setState(() => _rooms = v),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(
                  _checkIn, _checkOut, _adults, _rooms),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: AppColors.navyDeep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
              child: Text('Search Hotels',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.navyDeep)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.ivory)),
              Text(subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.darkTextMuted)),
            ],
          ),
        ),
        _CountBtn(
          icon: Icons.remove,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$value',
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.ivory),
          ),
        ),
        _CountBtn(
          icon: Icons.add,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.darkCard : AppColors.darkBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap != null
                ? AppColors.goldPrimary
                : AppColors.darkDivider,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? AppColors.goldPrimary
              : AppColors.darkTextMuted,
        ),
      ),
    );
  }
}
