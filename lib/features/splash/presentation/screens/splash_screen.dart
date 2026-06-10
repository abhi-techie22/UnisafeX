import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rippleController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final onboardingDone =
        prefs.getBool(AppConstants.cacheKeyOnboarding) ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (session != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('is_profile_complete')
          .eq('user_id', session.user.id)
          .maybeSingle();
      if (!mounted) return;

      final isComplete = profile?['is_profile_complete'] as bool? ?? false;
      context.go(
        isComplete ? AppRoutes.home : AppRoutes.profileCompletion,
      );
    } else {
      context.go(AppRoutes.authSelection);
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Ripple background
          Center(
            child: AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRipple(
                        _rippleAnimation.value, 300, AppColors.white, 0.04),
                    _buildRipple(
                        _rippleAnimation.value, 220, AppColors.white, 0.07),
                    _buildRipple(
                        _rippleAnimation.value, 150, AppColors.white, 0.1),
                  ],
                );
              },
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // App name
                const Text(
                  'UniSafeX',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.3,
                      duration: 600.ms,
                      delay: 200.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 500.ms, delay: 200.ms),

                const SizedBox(height: 8),

                const Text(
                  'Explore India Safely',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.3,
                      duration: 600.ms,
                      delay: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 500.ms, delay: 400.ms),
              ],
            ),
          ),

          // Bottom tagline
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: const Text(
              'Trusted · Safe · Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.white,
                letterSpacing: 2.0,
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildRipple(
      double animValue, double maxRadius, Color color, double opacity) {
    return Container(
      width: maxRadius * 2 * animValue,
      height: maxRadius * 2 * animValue,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity * (1 - animValue)),
      ),
    );
  }
}
