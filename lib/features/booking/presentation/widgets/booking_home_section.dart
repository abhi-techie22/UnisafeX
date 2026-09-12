import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class BookingHomeSection extends StatelessWidget {
  const BookingHomeSection({
    super.key,
    this.showHotels = true,
    this.showFlights = true,
  });

  final bool showHotels;
  final bool showFlights;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Book',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'in-app',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Hotels and flights, ready when you need them.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (showHotels)
                Expanded(
                  child: _BookingQuickButton(
                    label: 'Stay',
                    subtitle: 'Hotels',
                    icon: Icons.bed_rounded,
                    accentIcon: Icons.location_city_rounded,
                    colors: const [Color(0xFF173F35), AppColors.primary],
                    onTap: () => context.push(AppRoutes.hotelBooking),
                  ),
                ),
              if (showHotels && showFlights) const SizedBox(width: 12),
              if (showFlights)
                Expanded(
                  child: _BookingQuickButton(
                    label: 'Flights',
                    subtitle: 'Tickets',
                    icon: Icons.flight_takeoff_rounded,
                    accentIcon: Icons.public_rounded,
                    colors: const [Color(0xFF193A62), Color(0xFF2E6AA5)],
                    onTap: () => context.push(AppRoutes.flightBooking),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingQuickButton extends StatelessWidget {
  const _BookingQuickButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentIcon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final IconData accentIcon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _BookingIconMark(
              icon: icon,
              accentIcon: accentIcon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_outward_rounded,
              color: Colors.white,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingIconMark extends StatelessWidget {
  const _BookingIconMark({
    required this.icon,
    required this.accentIcon,
  });

  final IconData icon;
  final IconData accentIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(accentIcon, color: AppColors.primaryDark, size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
