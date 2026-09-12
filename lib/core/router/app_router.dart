import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/widgets/main_scaffold.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';

import 'package:unisafex/features/auth/presentation/screens/auth_selection_screen.dart';
import 'package:unisafex/features/auth/presentation/screens/login_screen.dart';
import 'package:unisafex/features/auth/presentation/screens/register_screen.dart';
import 'package:unisafex/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:unisafex/features/booking/presentation/screens/booking_hub_screen.dart';
import 'package:unisafex/features/booking/presentation/screens/flight_booking_screen.dart';

import 'package:unisafex/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:unisafex/features/guide/presentation/screens/guide_request_screen.dart';
import 'package:unisafex/features/home/presentation/screens/home_screen.dart';
import 'package:unisafex/features/map/presentation/screens/map_screen.dart';
import 'package:unisafex/features/maps/presentation/screens/in_app_map_screen.dart';

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
import 'package:unisafex/hotel/hotel_router.dart';
import 'package:unisafex/hotel/presentation/screens/hotel_search_screen.dart';

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

      final location = state.matchedLocation;
      final user = Supabase.instance.client.auth.currentUser;
      final isAuthRoute = location == AppRoutes.authSelection ||
          location == AppRoutes.login ||
          location == AppRoutes.register;

      if (user != null && isAuthRoute) {
        return AppRoutes.home;
      }

      if (_requiresSignedInUser(location) && user == null) {
        return AppRoutes.login;
      }

      if (location == AppRoutes.admin) {
        if (user == null) return AppRoutes.login;
        final isAdmin = await _isAdminUser();
        if (!isAdmin) return AppRoutes.profile;
      }

      return null;
    },
    routes: [
      ...hotelRoutes,

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
            builder: (context, state) => _FeatureFlagRouteGuard(
              enabled: (flags) => flags.hotels,
              child: const HotelSearchScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.flightBooking,
            builder: (context, state) => _FeatureFlagRouteGuard(
              enabled: (flags) => flags.flights,
              child: const FlightBookingScreen(),
            ),
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

          /// Guide Request
          GoRoute(
            path: AppRoutes.guideRequest,
            builder: (
              context,
              state,
            ) {
              return const GuideRequestScreen();
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

      /// In-app destination map
      GoRoute(
        path: AppRoutes.destinationMap,
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final latitude = double.tryParse(query['latitude'] ?? '');
          final longitude = double.tryParse(query['longitude'] ?? '');

          if (latitude == null || longitude == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid map coordinates')),
            );
          }

          return InAppMapScreen(
            placeName: query['placeName'] ?? 'Destination',
            latitude: latitude,
            longitude: longitude,
            address: query['address'],
            imageUrl: query['imageUrl'],
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
        redirect: (context, state) =>
            '${AppRoutes.placesList}?title=All Destinations',
      ),
      GoRoute(
        path: AppRoutes.heritageDetail,
        redirect: (context, state) => AppRoutes.home,
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

class _FeatureFlagRouteGuard extends ConsumerWidget {
  const _FeatureFlagRouteGuard({
    required this.enabled,
    required this.child,
  });

  final bool Function(FeatureFlags flags) enabled;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(publicFeatureFlagsProvider);
    const fallbackFlags = FeatureFlags({});
    final isEnabled = flags.maybeWhen(
      data: enabled,
      orElse: () => enabled(fallbackFlags),
    );
    if (isEnabled) return child;
    return Scaffold(
      appBar: AppBar(title: const Text('Feature unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 42),
              const SizedBox(height: 12),
              const Text(
                'This booking feature is currently hidden by admin.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _requiresSignedInUser(String location) {
  return location == AppRoutes.profileCompletion ||
      location == AppRoutes.profile ||
      location == AppRoutes.identityDetails ||
      location == AppRoutes.favorites ||
      location == AppRoutes.guideRequest ||
      location == AppRoutes.admin;
}

Future<bool> _isAdminUser() async {
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    final row = await client
        .from('admin_users')
        .select('user_id')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .maybeSingle();
    return row != null;
  } catch (_) {
    return false;
  }
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
  static const String destinationMap = '/maps';

  static const String favorites = '/favorites';

  static const String guideRequest = '/guide-request';

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
  static const String heritageDetail = '/heritage-detail';
  static const String admin = '/admin';
  static const String hotelBooking = '/booking/hotels';
  static const String flightBooking = '/booking/flights';

  static String destinationMapLocation({
    required String placeName,
    required double latitude,
    required double longitude,
    String? address,
    String? imageUrl,
  }) {
    return Uri(
      path: destinationMap,
      queryParameters: {
        'placeName': placeName,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (address?.trim().isNotEmpty == true) 'address': address!.trim(),
        if (imageUrl?.trim().isNotEmpty == true) 'imageUrl': imageUrl!.trim(),
      },
    ).toString();
  }
}
