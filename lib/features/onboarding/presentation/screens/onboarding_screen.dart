import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Explore India\nSafely',
      subtitle:
          'Discover the most breathtaking destinations across India with verified safety information tailored for international travelers.',
      icon: Icons.explore_rounded,
      color: const Color(0xFF1A6B4A),
      accent: const Color(0xFF2D8A62),
    ),
    OnboardingData(
      title: 'Verified Tourism\nInformation',
      subtitle:
          'Every destination is curated and verified. Get accurate entry fees, timings, and essential visitor guidelines.',
      icon: Icons.verified_rounded,
      color: const Color(0xFF1E40AF),
      accent: const Color(0xFF3B82F6),
    ),
    OnboardingData(
      title: 'Smart Travel\nRecommendations',
      subtitle:
          'Personalized suggestions based on your interests, location, and travel preferences for the perfect Indian journey.',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF7C3AED),
      accent: const Color(0xFF8B5CF6),
    ),
    OnboardingData(
      title: 'In-App Maps\n& Navigation',
      subtitle:
          'Use live GPS distances to discover nearby places, then navigate with Google Maps.',
      icon: Icons.map_rounded,
      color: const Color(0xFFB45309),
      accent: const Color(0xFFF59E0B),
    ),
    OnboardingData(
      title: 'Personalized\nExperience',
      subtitle:
          'Create your traveler profile, save favorite places, and get recommendations that match your unique travel style.',
      icon: Icons.person_rounded,
      color: const Color(0xFF047857),
      accent: const Color(0xFF10B981),
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.cacheKeyOnboarding, true);
    if (mounted) context.go(AppRoutes.authSelection);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_currentPage];
    final size = MediaQuery.of(context).size;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: current.color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index], size: size);
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Indicator
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.white,
                        dotColor: AppColors.white.withOpacity(0.3),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _controller.nextPage(
                              duration: AppConstants.animNormal,
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: current.color,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Continue'
                              : 'Get Started',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final Size size;

  const _OnboardingPage({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              data.icon,
              color: AppColors.white,
              size: 52,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(),

          const SizedBox(height: 48),

          Text(
            data.title,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ).animate().slideY(
                begin: 0.2,
                duration: 500.ms,
                delay: 100.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 20),

          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withOpacity(0.85),
              height: 1.55,
            ),
          ).animate().slideY(
                begin: 0.2,
                duration: 500.ms,
                delay: 200.ms,
                curve: Curves.easeOutCubic,
              ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accent;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accent,
  });
}
