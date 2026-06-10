import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class BookingHomeSection extends StatelessWidget {
  const BookingHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book your journey',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Compare trusted travel partners before you book',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          _BookingCard(
            eyebrow: 'PRIORITY',
            title: 'Hotels in India',
            description: 'Find stays for your dates, budget and destination.',
            icon: Icons.hotel_rounded,
            colors: const [Color(0xFF173F35), AppColors.primary],
            onTap: () => context.push(AppRoutes.hotelBooking),
          ),
          const SizedBox(height: 12),
          _BookingCard(
            eyebrow: 'FLIGHTS',
            title: 'Flights to & around India',
            description: 'Search international and domestic flight partners.',
            icon: Icons.flight_takeoff_rounded,
            colors: const [Color(0xFF193A62), Color(0xFF2E6AA5)],
            onTap: () => context.push(AppRoutes.flightBooking),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
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
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
