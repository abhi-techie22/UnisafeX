import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/profile/domain/entities/user_profile.dart';
import 'package:unisafex/features/profile/domain/profile_completion.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final supportAttention =
        ref.watch(supportNeedsAttentionProvider).valueOrNull ?? false;

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
        data: (profile) {
          final completionPercent = profileCompletionPercent(profile);
          final canGenerateVerifiedCard =
              profile != null && completionPercent == 100;
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(profileNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                _IdentityCard(
                  profile: profile,
                  onTap: () => context.push(AppRoutes.identityDetails),
                  onEditPhoto: () => _pickProfilePhoto(context, ref),
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
                    if (canGenerateVerifiedCard)
                      _ProfileAction(
                        icon: Icons.verified_user_outlined,
                        label: 'Verified UniSafeX card',
                        subtitle: 'Generate your traveler verification card',
                        onTap: () => _showVerifiedUserCard(context, profile),
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
                        subtitle: 'Manage UniSafeX admin tools',
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
                      subtitle: supportAttention
                          ? 'Support has an update for you'
                          : 'help_subtitle'.tr(),
                      highlight: supportAttention,
                      badgeLabel: supportAttention ? 'Update' : null,
                      onTap: () {
                        if (supportAttention) {
                          _markSupportSeen(ref);
                        }
                        context.push(AppRoutes.helpSupport);
                      },
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
          );
        },
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

  Future<void> _pickProfilePhoto(BuildContext context, WidgetRef ref) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!context.mounted) return;
      final croppedBytes = await _showProfilePhotoCropper(context, bytes);
      if (croppedBytes == null) return;
      await ref.read(profileNotifierProvider.notifier).uploadImageBytes(
            bytes: croppedBytes,
            extension: 'png',
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile photo. $error')),
      );
    }
  }

  Future<Uint8List?> _showProfilePhotoCropper(
    BuildContext context,
    Uint8List imageBytes,
  ) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ProfilePhotoCropDialog(
        imageBytes: imageBytes,
        onCancel: () => Navigator.pop(dialogContext),
        onSave: (croppedBytes) => Navigator.pop(dialogContext, croppedBytes),
      ),
    );
  }

  Future<void> _markSupportSeen(WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final tickets = await ref.read(mySupportTicketsProvider.future);
      await markSupportTicketsSeen(userId: user.id, tickets: tickets);
      ref.invalidate(supportNeedsAttentionProvider);
    } catch (_) {
      // The Help & Support screen also marks updates seen after loading.
    }
  }

  void _showVerifiedUserCard(BuildContext context, UserProfile profile) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _VerifiedUserCard(
          profile: profile,
          onClose: () => Navigator.pop(dialogContext),
        ),
      ),
    );
  }
}

class _ProfilePhotoCropDialog extends StatefulWidget {
  const _ProfilePhotoCropDialog({
    required this.imageBytes,
    required this.onCancel,
    required this.onSave,
  });

  final Uint8List imageBytes;
  final VoidCallback onCancel;
  final ValueChanged<Uint8List> onSave;

  @override
  State<_ProfilePhotoCropDialog> createState() =>
      _ProfilePhotoCropDialogState();
}

class _ProfilePhotoCropDialogState extends State<_ProfilePhotoCropDialog> {
  final _cropKey = GlobalKey();
  final _transformController = TransformationController();
  bool _saving = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _saveCrop() async {
    final boundary =
        _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _saving = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;
      widget.onSave(bytes);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cropSize = (size.width - 72).clamp(220.0, 320.0);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Adjust profile photo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _cropKey,
            child: ClipOval(
              child: ColoredBox(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: SizedBox.square(
                  dimension: cropSize,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(120),
                    clipBehavior: Clip.none,
                    child: Image.memory(
                      widget.imageBytes,
                      width: cropSize,
                      height: cropSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Drag or pinch to center your face.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _saveCrop,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: const Text('Use photo'),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.profile,
    required this.onTap,
    required this.onEditPhoto,
  });

  final UserProfile? profile;
  final VoidCallback onTap;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final percent = profileCompletionPercent(profile);
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
            Stack(
              clipBehavior: Clip.none,
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
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                    child: InkWell(
                      onTap: onEditPhoto,
                      borderRadius: BorderRadius.circular(99),
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(99),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
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

class _VerifiedUserCard extends StatelessWidget {
  const _VerifiedUserCard({
    required this.profile,
    required this.onClose,
  });

  final UserProfile profile;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verified UniSafeX user card',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            profile.profileImageUrl?.trim().isNotEmpty == true
                                ? NetworkImage(profile.profileImageUrl!.trim())
                                : null,
                        child:
                            profile.profileImageUrl?.trim().isNotEmpty == true
                                ? null
                                : Text(
                                    profile.initials,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              '100% profile complete',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VerifiedCardPill(
                        icon: Icons.flag_outlined,
                        label: profile.nationality ?? profile.country ?? '',
                      ),
                      _VerifiedCardPill(
                        icon: Icons.public_rounded,
                        label: profile.currentLocation ?? '',
                      ),
                      _VerifiedCardPill(
                        icon: Icons.credit_card_rounded,
                        label: profile.passportCountry ?? '',
                      ),
                      _VerifiedCardPill(
                        icon: Icons.assignment_turned_in_outlined,
                        label: profile.visaType ?? '',
                      ),
                    ].where((pill) => pill.label.trim().isNotEmpty).toList(),
                  ),
                  if (profile.visaExpiry != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Visa valid until ${DateFormat.yMMMd().format(profile.visaExpiry!)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Generated from verified profile details. Complete profile is required before this card is available.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedCardPill extends StatelessWidget {
  const _VerifiedCardPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              tileColor: action.highlight
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : null,
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
              trailing: action.badgeLabel == null
                  ? const Icon(Icons.arrow_forward_ios_rounded, size: 13)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        action.badgeLabel!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
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
    this.highlight = false,
    this.badgeLabel,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;
  final String? badgeLabel;
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
