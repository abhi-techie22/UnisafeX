import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    if (isGuest) return const _GuestProfile();

    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'settings'.tr(),
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ProfileError(
          error: error,
          onRetry: () => ref.read(profileNotifierProvider.notifier).refresh(),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () => ref.read(profileNotifierProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _IdentityCard(
                profile: profile,
                onTap: () => context.push(AppRoutes.identityDetails),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'your_account'.tr(),
                actions: [
                  _ProfileAction(
                    icon: Icons.badge_outlined,
                    label: 'my_identity'.tr(),
                    subtitle: 'view_private_details'.tr(),
                    onTap: () => context.push(AppRoutes.identityDetails),
                  ),
                  _ProfileAction(
                    icon: Icons.bookmark_outline_rounded,
                    label: 'saved_places'.tr(),
                    subtitle: 'view_travel_shortlist'.tr(),
                    onTap: () => context.go(AppRoutes.favorites),
                  ),
                  _ProfileAction(
                    icon: Icons.settings_outlined,
                    label: 'settings'.tr(),
                    subtitle: 'settings_subtitle'.tr(),
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  if (isAdmin)
                    _ProfileAction(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'admin_console'.tr(),
                      subtitle: 'admin_live_updates'.tr(),
                      onTap: () => context.push(AppRoutes.admin),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _ActionCard(
                title: 'information_support'.tr(),
                actions: [
                  _ProfileAction(
                    icon: Icons.help_outline_rounded,
                    label: 'help_support'.tr(),
                    subtitle: 'help_subtitle'.tr(),
                    onTap: () => context.push(AppRoutes.helpSupport),
                  ),
                  _ProfileAction(
                    icon: Icons.privacy_tip_outlined,
                    label: 'privacy_policy'.tr(),
                    subtitle: 'privacy_subtitle'.tr(),
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  _ProfileAction(
                    icon: Icons.description_outlined,
                    label: 'terms_of_service'.tr(),
                    subtitle: 'terms_subtitle'.tr(),
                    onTap: () => context.push(AppRoutes.termsOfService),
                  ),
                  _ProfileAction(
                    icon: Icons.info_outline_rounded,
                    label: 'about_unisafex'.tr(),
                    subtitle: 'about_subtitle'.tr(),
                    onTap: () => context.push(AppRoutes.about),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text('sign_out'.tr()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('sign_out_question'.tr()),
        content: Text('sign_out_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.authSelection);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('sign_out'.tr()),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.onTap,
  });

  final UserProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: profile?.profileImageUrl?.isNotEmpty == true
                  ? Image.network(
                      profile!.profileImageUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(),
                    )
                  : _initials(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayName ?? 'traveler'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (profile?.isProfileComplete == true
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile?.isProfileComplete == true
                          ? 'identity_ready'.tr()
                          : 'identity_needs_details'.tr(),
                      style: TextStyle(
                        color: profile?.isProfileComplete == true
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 5),
                Text(
                  'view'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials() => Text(
        profile?.initials ?? 'T',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
      );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.actions});

  final String title;
  final List<_ProfileAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          ...actions.map(
            (action) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(action.icon, size: 20, color: AppColors.primary),
              ),
              title: Text(action.label),
              subtitle: Text(action.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
              onTap: action.onTap,
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 18),
              Text(
                'travel_profile'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'travel_profile_guest'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () => context.go(AppRoutes.authSelection),
                child: Text('sign_in_or_create'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 52, color: AppColors.error),
            const SizedBox(height: 14),
            Text('profile_load_error'.tr()),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
