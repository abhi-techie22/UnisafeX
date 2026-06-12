import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';
import 'package:unisafex/features/heritage/data/heritage_repository.dart';
import 'package:unisafex/features/profile/presentation/providers/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isHandlingAuthCallback = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await ref.read(authNotifierProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      final isAdmin = await ref.read(heritageRepositoryProvider).isAdmin();
      if (isAdmin) {
        ref.invalidate(isAdminProvider);
        if (mounted) context.go(AppRoutes.admin);
        return;
      }

      final profile =
          await ref.read(profileRepositoryProvider).getProfile(user.id);
      ref.invalidate(profileNotifierProvider);

      if (mounted) {
        context.go(
          profile?.isProfileComplete == true
              ? AppRoutes.home
              : AppRoutes.profileCompletion,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final authState = next.value;
      if (authState?.event == AuthChangeEvent.signedIn &&
          authState?.session != null) {
        _handleConfirmedSession(authState!.session!);
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('sign_in'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Text(
                'welcome_back'.tr(),
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                'trusted_companion'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 40),

              // Email
              _buildLabel('email_address'.tr()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'required_field'.tr();
                  if (!v.contains('@')) return 'invalid_email'.tr();
                  return null;
                },
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 200.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 20),

              // Password
              _buildLabel('password'.tr()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'required_field'.tr();
                  }
                  if (v.length < 6) {
                    return 'min_password'.tr();
                  }
                  return null;
                },
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showResendConfirmation(context),
                      child: Text('resend_confirmation'.tr()),
                    ),
                    TextButton(
                      onPressed: () => _showForgotPassword(context),
                      child: Text('forgot_password'.tr()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Login button
              AppButton(
                label: 'sign_in'.tr(),
                onPressed: _login,
                isLoading: _isLoading,
                isFullWidth: true,
                height: 56,
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 24),

              // Register CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${'no_account'.tr()} ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'create_account'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: Theme.of(context).textTheme.labelLarge);
  }

  String _errorMessage(Object error) {
    if (error is AuthException) return error.message;
    return error.toString();
  }

  Future<void> _handleConfirmedSession(Session session) async {
    if (_isHandlingAuthCallback) return;
    _isHandlingAuthCallback = true;

    try {
      final isAdmin = await ref.read(heritageRepositoryProvider).isAdmin();
      if (isAdmin) {
        ref.invalidate(isAdminProvider);
        if (mounted) context.go(AppRoutes.admin);
        return;
      }

      final profile =
          await ref.read(profileRepositoryProvider).getProfile(session.user.id);
      ref.invalidate(profileNotifierProvider);

      if (mounted) {
        context.go(
          profile?.isProfileComplete == true
              ? AppRoutes.home
              : AppRoutes.profileCompletion,
        );
      }
    } finally {
      _isHandlingAuthCallback = false;
    }
  }

  void _showResendConfirmation(BuildContext context) {
    final controller =
        TextEditingController(text: _emailController.text.trim());
    _showEmailActionSheet(
      context: context,
      title: 'resend_confirmation_title'.tr(),
      description: 'confirmation_sent'.tr(),
      buttonLabel: 'resend_confirmation'.tr(),
      controller: controller,
      action: (email) =>
          ref.read(authNotifierProvider.notifier).resendConfirmation(email),
      successMessage: 'confirmation_sent'.tr(),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final controller = TextEditingController();
    _showEmailActionSheet(
      context: context,
      title: 'reset_password'.tr(),
      description: 'send_reset_link'.tr(),
      buttonLabel: 'send_reset_link'.tr(),
      controller: controller,
      action: (email) =>
          ref.read(authNotifierProvider.notifier).resetPassword(email),
      successMessage: 'send_reset_link'.tr(),
    );
  }

  void _showEmailActionSheet({
    required BuildContext context,
    required String title,
    required String description,
    required String buttonLabel,
    required TextEditingController controller,
    required Future<void> Function(String email) action,
    required String successMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: buttonLabel,
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    try {
                      await action(controller.text.trim());
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(successMessage),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (error) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_errorMessage(error)),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                isFullWidth: true,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
