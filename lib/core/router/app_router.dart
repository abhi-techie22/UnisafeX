import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/features/auth/presentation/screens/auth_selection_screen.dart';
import 'package:unisafex/features/auth/presentation/screens/login_screen.dart';
import 'package:unisafex/features/auth/presentation/screens/register_screen.dart';
import 'package:unisafex/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:unisafex/features/home/presentation/screens/home_screen.dart';
import 'package:unisafex/features/map/presentation/screens/map_screen.dart';
import 'package:unisafex/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:unisafex/features/profile/presentation/screens/profile_completion_screen.dart';
import 'package:unisafex/features/profile/presentation/screens/profile_screen.dart';
import 'package:unisafex/features/search/presentation/screens/search_screen.dart';
import 'package:unisafex/features/settings/presentation/screens/settings_screen.dart';
import 'package:unisafex/features/splash/presentation/screens/splash_screen.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/presentation/screens/place_detail_screen.dart';
import 'package:unisafex/features/tourism/presentation/screens/places_list_screen.dart';
import 'package:unisafex/core/widgets/main_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool(AppConstants.cacheKeyOnboarding) ?? false;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isOnAuth = state.matchedLocation.startsWith('/auth');

      if (isOnSplash) return null;
      if (!onboardingDone && !isOnOnboarding) return AppRoutes.onboarding;
      if (onboardingDone && isOnOnboarding) return AppRoutes.authSelection;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.authSelection,
        builder: (context, state) => const AuthSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileCompletion,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.placeDetail,
        builder: (context, state) {
          final place = state.extra as TourismPlace;
          return PlaceDetailScreen(place: place);
        },
      ),
      GoRoute(
        path: AppRoutes.placesList,
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          final title = state.uri.queryParameters['title'] ?? 'Places';
          return PlacesListScreen(category: category, title: title);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authSelection = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profileCompletion = '/profile-completion';
  static const String home = '/home';
  static const String search = '/search';
  static const String map = '/map';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String placeDetail = '/place-detail';
  static const String placesList = '/places-list';
  static const String settings = '/settings';
}
