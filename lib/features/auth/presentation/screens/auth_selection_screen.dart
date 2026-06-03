import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/core/widgets/app_button.dart';
import 'package:unisafex/features/home/presentation/screens/home_screen.dart';

class AuthSelectionScreen extends StatelessWidget {
  const AuthSelectionScreen({super.key});

  Future<void> _continueAsGuest(BuildContext context) async {
    await Supabase.instance.client.auth.signInAnonymously();
    if (context.mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: size.height * 0.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F4A33),
                  Color(0xFF1A6B4A),
                  Color(0xFF2D8A62),
                ],
              ),
            ),
          ),

          // India map silhouette hint
          Positioned(
            top: 60,
            right: -30,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.public_rounded,
                size: 300,
                color: AppColors.white,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'UniSafeX',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 48),

                      const Text(
                        'Welcome to\nIncredible India',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      )
                          .animate()
                          .slideY(
                            begin: 0.2,
                            duration: 500.ms,
                            delay: 100.ms,
                            curve: Curves.easeOutCubic,
                          )
                          .fadeIn(duration: 400.ms, delay: 100.ms),

                      const SizedBox(height: 14),

                      Text(
                        'Your safe and trusted companion for exploring the wonders of India.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      )
                          .animate()
                          .slideY(
                            begin: 0.2,
                            duration: 500.ms,
                            delay: 200.ms,
                            curve: Curves.easeOutCubic,
                          )
                          .fadeIn(duration: 400.ms, delay: 200.ms),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom sheet card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Started',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to unlock the full experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                            ),
                      ),

                      const SizedBox(height: 32),

                      // Email Login
                      AppButton(
                        label: 'Continue with Email',
                        onPressed: () => context.push(AppRoutes.login),
                        icon: Icons.email_outlined,
                        isFullWidth: true,
                      ),

                      const SizedBox(height: 12),

                      // Register
                      AppOutlinedButton(
                        label: 'Create Account',
                        onPressed: () => context.push(AppRoutes.register),
                        icon: Icons.person_add_alt_1_outlined,
                        isFullWidth: true,
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.grey600
                                    : AppColors.grey400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Guest button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed: () => context.go(AppRoutes.home),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.explore_outlined,
                                size: 20,
                                color: isDark
                                    ? AppColors.grey400
                                    : AppColors.grey600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explore as Guest',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.grey400
                                      : AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Terms
                      Center(
                        child: Text(
                          'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.grey600
                                : AppColors.grey400,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.3,
                      duration: 500.ms,
                      delay: 300.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 400.ms, delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
