import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/widgets/main_scaffold.dart';

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
import 'package:unisafex/features/tourism/presentation/screens/ai_travel_assistant_screen.dart';
import 'package:unisafex/features/tourism/presentation/screens/currency_helper_screen.dart';
import 'package:unisafex/features/tourism/presentation/screens/phrase_book_screen.dart';
import 'package:unisafex/features/tourism/presentation/screens/travel_toolkit_screen.dart';
import 'package:unisafex/features/tourism/presentation/screens/trip_planner_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(
  AppRouterRef ref,
) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;

      final prefs = await SharedPreferences.getInstance();

      final onboardingDone = prefs.getBool(
            AppConstants.cacheKeyOnboarding,
          ) ??
          false;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;

      final isOnAuth = state.matchedLocation.startsWith('/auth');

      if (isOnSplash) {
        return null;
      }

      if (!onboardingDone && !isOnOnboarding) {
        return AppRoutes.onboarding;
      }

      if (onboardingDone && isOnOnboarding) {
        return AppRoutes.authSelection;
      }

      return null;
    },
    routes: [
      /// Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      /// Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      /// Auth Selection
      GoRoute(
        path: AppRoutes.authSelection,
        builder: (context, state) => const AuthSelectionScreen(),
      ),

      /// Login
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      /// Register
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      /// Profile Completion
      GoRoute(
        path: AppRoutes.profileCompletion,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),

      /// Bottom Nav Pages
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (
          context,
          state,
          child,
        ) {
          return MainScaffold(
            child: child,
          );
        },
        routes: [
          /// Home
          GoRoute(
            path: AppRoutes.home,
            builder: (
              context,
              state,
            ) {
              return const HomeScreen();
            },
          ),

          /// Search
          GoRoute(
            path: AppRoutes.search,
            builder: (
              context,
              state,
            ) {
              return const SearchScreen();
            },
          ),

          /// MAP (UPDATED)
          GoRoute(
            path: AppRoutes.map,
            builder: (
              context,
              state,
            ) {
              final place = state.extra as TourismPlace?;

              return MapScreen(
                selectedPlace: place,
              );
            },
          ),

          /// Favorites
          GoRoute(
            path: AppRoutes.favorites,
            builder: (
              context,
              state,
            ) {
              return const FavoritesScreen();
            },
          ),

          /// Profile
          GoRoute(
            path: AppRoutes.profile,
            builder: (
              context,
              state,
            ) {
              return const ProfileScreen();
            },
          ),
        ],
      ),

      /// Place Detail
      GoRoute(
        path: AppRoutes.placeDetail,
        builder: (
          context,
          state,
        ) {
          final place = state.extra as TourismPlace;

          return PlaceDetailScreen(
            place: place,
          );
        },
      ),

      /// Places List
      GoRoute(
        path: AppRoutes.placesList,
        builder: (
          context,
          state,
        ) {
          final category = state.uri.queryParameters['category'];

          final title = state.uri.queryParameters['title'] ?? 'Places';

          return PlacesListScreen(
            category: category,
            title: title,
          );
        },
      ),

      /// Settings
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.travelToolkit,
        builder: (context, state) => const TravelToolkitScreen(),
      ),
      GoRoute(
        path: AppRoutes.tripPlanner,
        builder: (context, state) => const TripPlannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.currencyHelper,
        builder: (context, state) => const CurrencyHelperScreen(),
      ),
      GoRoute(
        path: AppRoutes.phraseBook,
        builder: (context, state) => const PhraseBookScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) => const AiTravelAssistantScreen(),
      ),
    ],
    errorBuilder: (
      context,
      state,
    ) {
      return Scaffold(
        body: Center(
          child: Text(
            'Page not found: ${state.error}',
          ),
        ),
      );
    },
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

  static const String travelToolkit = '/travel-toolkit';
  static const String tripPlanner = '/travel-toolkit/trip-planner';
  static const String currencyHelper = '/travel-toolkit/currency';
  static const String phraseBook = '/travel-toolkit/phrase-book';
  static const String aiAssistant = '/travel-toolkit/ai-assistant';
}
