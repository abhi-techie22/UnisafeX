import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';

class IdentityDetailsScreen extends ConsumerWidget {
  const IdentityDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final email = ref.watch(currentUserProvider)?.email ?? '';

    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text('my_identity'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'identity_private'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'identity_sign_in'.tr(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.authSelection),
                  child: Text('sign_in'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('my_identity'.tr())),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
        data: (profile) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _PrivateIdentityHeader(profile: profile, email: email),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _IdentityRow(
                    icon: Icons.person_outline_rounded,
                    label: 'full_name'.tr(),
                    value: profile?.fullName,
                  ),
                  _IdentityRow(
                    icon: Icons.email_outlined,
                    label: 'email'.tr(),
                    value: email,
                  ),
                  _IdentityRow(
                    icon: Icons.wc_outlined,
                    label: 'gender'.tr(),
                    value: profile?.gender,
                  ),
                  _IdentityRow(
                    icon: Icons.public_rounded,
                    label: 'nationality'.tr(),
                    value: profile?.nationality ?? profile?.country,
                  ),
                  _IdentityRow(
                    icon: Icons.location_on_outlined,
                    label: 'current_location'.tr(),
                    value: profile?.currentLocation,
                  ),
                  _IdentityRow(
                    icon: Icons.badge_outlined,
                    label: 'passport_country'.tr(),
                    value: profile?.passportCountry,
                  ),
                  _IdentityRow(
                    icon: Icons.document_scanner_outlined,
                    label: 'visa_type'.tr(),
                    value: profile?.visaType,
                  ),
                  _IdentityRow(
                    icon: Icons.event_outlined,
                    label: 'visa_expiry'.tr(),
                    value: profile?.visaExpiry == null
                        ? null
                        : DateFormat('dd MMM yyyy')
                            .format(profile!.visaExpiry!),
                  ),
                  _IdentityRow(
                    icon: Icons.luggage_outlined,
                    label: 'travel_purpose'.tr(),
                    value: profile?.travelPurpose,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 20, color: AppColors.info),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text('private_identity_notice'.tr()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.profileCompletion),
              icon: const Icon(Icons.edit_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text('edit_identity'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateIdentityHeader extends StatelessWidget {
  const _PrivateIdentityHeader({
    required this.profile,
    required this.email,
  });

  final UserProfile? profile;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            backgroundImage: profile?.profileImageUrl?.isNotEmpty == true
                ? NetworkImage(profile!.profileImageUrl!)
                : null,
            child: profile?.profileImageUrl?.isNotEmpty == true
                ? null
                : Text(
                    profile?.initials ?? 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'private_identity'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  profile?.displayName ?? 'traveler'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 3),
                    Text(
                      value?.trim().isNotEmpty == true
                          ? value!
                          : 'not_added'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
