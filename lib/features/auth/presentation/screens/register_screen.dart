import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(authNotifierProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;

      if (result.requiresEmailConfirmation) {
        final config = ref.read(authAccessConfigProvider).valueOrNull ??
            const AuthAccessConfig();
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              config.emailConfirmationRequired
                  ? 'confirm_email'.tr()
                  : 'Supabase confirmation is still ON',
            ),
            content: Text(
              config.emailConfirmationRequired
                  ? 'confirm_email_message'
                      .tr(args: [_emailController.text.trim()])
                  : 'Admin app setting is OFF, but Supabase Auth still '
                      'requires email confirmation. Turn off Confirm email '
                      'in Supabase Dashboard > Authentication > Providers > '
                      'Email to allow instant login.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('continue_sign_in'.tr()),
              ),
            ],
          ),
        );
        if (mounted) context.go(AppRoutes.login);
      } else {
        context.go(AppRoutes.profileCompletion);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authConfig = ref.watch(authAccessConfigProvider).valueOrNull ??
        const AuthAccessConfig();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.authSelection);
            }
          },
        ),
        title: Text('create_account'.tr()),
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
                'join_unisafex'.tr(),
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'unlock_experience'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                    ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: 40),
              _buildLabel('email_address'.tr()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'required_field'.tr();
                  if (!_isValidEmail(v)) return 'invalid_email'.tr();
                  return null;
                },
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 200.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 20),
              _buildLabel('password'.tr()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'min_password'.tr(),
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
                  if (v == null || v.isEmpty) return 'required_field'.tr();
                  final passwordError = _passwordValidationMessage(v);
                  if (passwordError != null) {
                    return passwordError;
                  }
                  return null;
                },
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 300.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 10),
              _PasswordSecurityNote(
                password: _passwordController.text,
                emailConfirmationRequired: authConfig.emailConfirmationRequired,
              ),
              const SizedBox(height: 20),
              _buildLabel('confirm_password'.tr()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _register(),
                decoration: InputDecoration(
                  hintText: 'repeat_password'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'required_field'.tr();
                  }
                  if (v != _passwordController.text) {
                    return 'passwords_mismatch'.tr();
                  }
                  return null;
                },
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 40),
              AppButton(
                label: 'create_account'.tr(),
                onPressed: _register,
                isLoading: _isLoading,
                isFullWidth: true,
                height: 56,
              ).animate().slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    delay: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${'already_account'.tr()} ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'sign_in'.tr(),
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

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
  }

  String? _passwordValidationMessage(String value) {
    if (value.length < 10) {
      return 'Use at least 10 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Add at least one lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Add at least one number.';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(value)) {
      return 'Add at least one special character.';
    }
    return null;
  }
}

class _PasswordSecurityNote extends StatelessWidget {
  final String password;
  final bool emailConfirmationRequired;

  const _PasswordSecurityNote({
    required this.password,
    required this.emailConfirmationRequired,
  });

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('10+ characters', password.length >= 10),
      ('Uppercase', RegExp(r'[A-Z]').hasMatch(password)),
      ('Lowercase', RegExp(r'[a-z]').hasMatch(password)),
      ('Number', RegExp(r'\d').hasMatch(password)),
      (
        'Special',
        RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(password)
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security required: strong password.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            emailConfirmationRequired
                ? 'Email confirmation is ON.'
                : 'Email confirmation is OFF in app settings. Supabase Auth must also be OFF.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rules
                .map(
                  (rule) => _PasswordRuleChip(
                    label: rule.$1,
                    passed: rule.$2,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _PasswordRuleChip extends StatelessWidget {
  final String label;
  final bool passed;

  const _PasswordRuleChip({
    required this.label,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.grey500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
