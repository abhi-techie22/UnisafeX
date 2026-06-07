import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './presentation/screens/hotel_search_screen.dart';
import './presentation/screens/hotel_list_screen.dart';
import './presentation/screens/hotel_detail_screen.dart';
import './presentation/screens/room_selection_screen.dart';
import './presentation/screens/booking_checkout_screen.dart';
import './presentation/screens/booking_confirmation_screen.dart';
import './presentation/screens/booking_history_screen.dart';
import './domain/entities/hotel.dart';
import './domain/entities/room.dart';
import './domain/entities/booking.dart';

/// All hotel module routes.
/// Add these to the top-level [GoRouter] routes list in app_router.dart.
///
/// Usage in app_router.dart:
///   routes: [
///     ...hotelRoutes,   // ← add this line
///     GoRoute(path: '/', ...),
///     ...
///   ]
List<RouteBase> get hotelRoutes => [
      GoRoute(
        path: '/hotel/search',
        pageBuilder: (_, state) => _fade(state, const HotelSearchScreen()),
      ),
      GoRoute(
        path: '/hotel/list',
        pageBuilder: (_, state) => _slide(state, const HotelListScreen()),
      ),
      GoRoute(
        path: '/hotel/detail/:hotelId',
        pageBuilder: (_, state) {
          final hotelId = state.pathParameters['hotelId']!;
          final hotel = state.extra as Hotel?;
          return _fade(
            state,
            HotelDetailScreen(hotelId: hotelId, cachedHotel: hotel),
          );
        },
      ),
      GoRoute(
        path: '/hotel/rooms/:hotelId',
        pageBuilder: (_, state) {
          final hotel = state.extra as Hotel;
          return _slide(state, RoomSelectionScreen(hotel: hotel));
        },
      ),
      GoRoute(
        path: '/hotel/checkout',
        pageBuilder: (_, state) {
          final data = state.extra as Map<String, dynamic>;
          return _slide(
            state,
            BookingCheckoutScreen(
              hotel: data['hotel'] as Hotel,
              room: data['room'] as Room,
              checkIn: data['checkIn'] as DateTime,
              checkOut: data['checkOut'] as DateTime,
              adults: data['adults'] as int,
              nights: data['nights'] as int,
            ),
          );
        },
      ),
      GoRoute(
        path: '/hotel/confirmation',
        pageBuilder: (_, state) {
          final booking = state.extra as Booking;
          return _fade(state, BookingConfirmationScreen(booking: booking));
        },
      ),
      GoRoute(
        path: '/hotel/history',
        pageBuilder: (_, state) =>
            _slide(state, const BookingHistoryScreen()),
      ),
    ];

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity:
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 340),
      transitionsBuilder: (_, animation, __, child) {
        final tween =
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
