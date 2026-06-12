import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/widgets/main_scaffold.dart';

import 'package:unisafex/features/auth/presentation/screens/auth_selection_screen.dart';
import 'package:unisafex/features/auth/presentation/screens/login_screen.dart';
import 'package:unisafex/features/auth/presentation/screens/register_screen.dart';
import 'package:unisafex/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:unisafex/features/booking/presentation/screens/flight_booking_screen.dart';
import 'package:unisafex/features/booking/presentation/screens/hotel_booking_screen.dart';
import 'package:unisafex/features/booking/presentation/screens/booking_hub_screen.dart';

import 'package:unisafex/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:unisafex/features/home/presentation/screens/home_screen.dart';
import 'package:unisafex/features/heritage/presentation/heritage_catalog_screen.dart';

import 'package:unisafex/features/map/presentation/screens/map_screen.dart';

import 'package:unisafex/features/onboarding/presentation/screens/onboarding_screen.dart';

import 'package:unisafex/features/profile/presentation/screens/profile_completion_screen.dart';
import 'package:unisafex/features/profile/presentation/screens/profile_screen.dart';
import 'package:unisafex/features/profile/presentation/screens/identity_details_screen.dart';

import 'package:unisafex/features/search/presentation/screens/search_screen.dart';

import 'package:unisafex/features/settings/presentation/screens/settings_screen.dart';
import 'package:unisafex/features/settings/presentation/screens/about_screen.dart';
import 'package:unisafex/features/settings/presentation/screens/help_support_screen.dart';
import 'package:unisafex/features/settings/presentation/screens/legal_document_screen.dart';

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
      final prefs = await SharedPreferences.getInstance();

      final onboardingDone = prefs.getBool(
            AppConstants.cacheKeyOnboarding,
          ) ??
          false;

      final isOnSplash = state.matchedLocation == AppRoutes.splash;

      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;

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

          GoRoute(
            path: AppRoutes.booking,
            builder: (context, state) => const BookingHubScreen(),
          ),
          GoRoute(
            path: AppRoutes.hotelBooking,
            builder: (context, state) => const HotelBookingScreen(),
          ),
          GoRoute(
            path: AppRoutes.flightBooking,
            builder: (context, state) => const FlightBookingScreen(),
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

      /// Private identity details
      GoRoute(
        path: AppRoutes.identityDetails,
        builder: (context, state) => const IdentityDetailsScreen(),
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
        path: AppRoutes.helpSupport,
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const LegalDocumentScreen.privacy(),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        builder: (context, state) => const LegalDocumentScreen.terms(),
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
      GoRoute(
        path: AppRoutes.heritageCatalog,
        builder: (context, state) => const HeritageCatalogScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
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
  static const String booking = '/booking';

  static const String map = '/map';

  static const String favorites = '/favorites';

  static const String profile = '/profile';
  static const String identityDetails = '/profile/identity';

  static const String placeDetail = '/place-detail';

  static const String placesList = '/places-list';

  static const String settings = '/settings';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  static const String travelToolkit = '/travel-toolkit';
  static const String tripPlanner = '/travel-toolkit/trip-planner';
  static const String currencyHelper = '/travel-toolkit/currency';
  static const String phraseBook = '/travel-toolkit/phrase-book';
  static const String aiAssistant = '/travel-toolkit/ai-assistant';
  static const String heritageCatalog = '/heritage-catalog';
  static const String admin = '/admin';
  static const String hotelBooking = '/booking/hotels';
  static const String flightBooking = '/booking/flights';
}
