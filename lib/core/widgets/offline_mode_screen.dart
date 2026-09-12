import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class OfflineModeScreen extends StatelessWidget {
  const OfflineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 42),
                SizedBox(height: 16),
                Text(
                  'You are offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'UniSafeX will reconnect automatically. Until then, use '
                  'offline-safe tools and saved travel information.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Available offline',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _OfflineFeatureCard(
            icon: Icons.bookmark_rounded,
            title: 'Saved places',
            subtitle: 'Open places saved locally on this device.',
            onTap: () => context.go(AppRoutes.favorites),
          ),
          _OfflineFeatureCard(
            icon: Icons.currency_exchange_rounded,
            title: 'Currency helper',
            subtitle: 'Use fallback travel rates while offline.',
            onTap: () => context.push(AppRoutes.currencyHelper),
          ),
          _OfflineFeatureCard(
            icon: Icons.translate_rounded,
            title: 'Phrase book',
            subtitle: 'Basic Hindi phrases for emergencies and travel.',
            onTap: () => context.push(AppRoutes.phraseBook),
          ),
          _OfflineFeatureCard(
            icon: Icons.emergency_rounded,
            title: 'Emergency numbers',
            subtitle: 'Police 112 · Tourist helpline 1363 · Ambulance 108',
            onTap: () => _showEmergencyNumbers(context),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Maps, live place search, admin changes, guide requests and '
                'profile saving need internet access.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyNumbers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.local_police_outlined),
              title: Text('Emergency / Police'),
              trailing: Text('112'),
            ),
            ListTile(
              leading: Icon(Icons.support_agent_rounded),
              title: Text('Tourist helpline'),
              trailing: Text('1363'),
            ),
            ListTile(
              leading: Icon(Icons.local_hospital_outlined),
              title: Text('Ambulance'),
              trailing: Text('108'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineFeatureCard extends StatelessWidget {
  const _OfflineFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
