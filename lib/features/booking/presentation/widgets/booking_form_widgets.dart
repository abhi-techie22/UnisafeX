import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class BookingHero extends StatelessWidget {
  const BookingHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(height: 22),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class BookingDateField extends StatelessWidget {
  const BookingDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_rounded),
        ),
        child: Text(
          DateFormat('EEE, d MMM yyyy').format(value),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class BookingCounter extends StatelessWidget {
  const BookingCounter({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int value;
  final IconData icon;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class AffiliateDisclosure extends StatelessWidget {
  const AffiliateDisclosure({super.key, required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConfigured
                  ? 'UniSafeX may earn a commission from partner bookings at no extra cost to you.'
                  : 'Preview mode: partner search works, but commission tracking is not configured yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
