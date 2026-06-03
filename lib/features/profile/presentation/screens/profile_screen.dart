import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGuest = ref.watch(isGuestProvider);
    final profile = ref.watch(profileNotifierProvider);
    final user = ref.watch(currentUserProvider);

    if (isGuest) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text('Your Profile',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to manage your travel profile, saved places, and personalized recommendations.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.authSelection),
                      child: const Text('Sign In or Create Account'),
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: profile.when(
        data: (p) => CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 220,
              pinned: true,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.white.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: p?.profileImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: Image.network(
                                              p!.profileImageUrl!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              p?.initials ?? 'T',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (p?.countryCode != null)
                                    Positioned(
                                      right: -4,
                                      bottom: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _codeToFlag(p!.countryCode!),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p?.displayName ?? 'Traveler',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (p?.nationality != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        p!.nationality!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      user?.email ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Travel Info Card
                    if (p != null && p.isProfileComplete) ...[
                      _SectionCard(
                        title: 'Travel Information',
                        children: [
                          if (p.travelPurpose != null)
                            _InfoRow(
                              icon: Icons.luggage_outlined,
                              label: 'Purpose',
                              value: p.travelPurpose!,
                            ),
                          if (p.visaType != null)
                            _InfoRow(
                              icon: Icons.document_scanner_outlined,
                              label: 'Visa Type',
                              value: p.visaType!,
                            ),
                          if (p.visaExpiry != null)
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Visa Expiry',
                              value: DateFormat('dd MMM yyyy').format(p.visaExpiry!),
                            ),
                          if (p.currentLocation != null)
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: p.currentLocation!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Quick actions
                    _SectionCard(
                      title: 'Account',
                      children: [
                        _ActionRow(
                          icon: Icons.bookmark_outline,
                          label: 'Saved Places',
                          onTap: () => context.go(AppRoutes.favorites),
                        ),
                        _ActionRow(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          onTap: () => context.push(AppRoutes.profileCompletion),
                        ),
                        _ActionRow(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          onTap: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _SectionCard(
                      title: 'Support',
                      children: [
                        _ActionRow(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          onTap: () {},
                        ),
                        _ActionRow(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _ActionRow(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          onTap: () {},
                        ),
                        _ActionRow(
                          icon: Icons.info_outline_rounded,
                          label: 'About UniSafeX',
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmSignOut(context, ref),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 18),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.error.withOpacity(0.4)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _codeToFlag(String code) {
    return code.toUpperCase().runes.map((r) => String.fromCharCode(r + 127397)).join('');
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.authSelection);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark ? AppColors.grey400 : AppColors.grey500,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: isDark ? AppColors.grey400 : AppColors.grey500),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.grey400 : AppColors.grey500)),
          const Spacer(),
          Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            Icon(icon, size: 18,
                color: isDark ? AppColors.grey400 : AppColors.grey600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 13,
                color: isDark ? AppColors.grey600 : AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
