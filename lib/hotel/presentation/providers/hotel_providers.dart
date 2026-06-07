import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/amadeus_api_service.dart';
import '../../data/services/mock_hotel_service.dart';
import '../../data/services/hotel_supabase_service.dart';
import '../../data/services/booking_affiliate_service.dart';
import '../../data/repositories/hotel_repository.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/hotel_search_params.dart';
import '../../application/usecases/hotel_usecases.dart';
import 'package:unisafex/data/providers/auth_provider.dart';

// ── Infrastructure providers ──────────────────────────────────

final _mockHotelServiceProvider = Provider<MockHotelService>(
  (_) => MockHotelService(),
);

final _hotelSupabaseServiceProvider = Provider<HotelSupabaseService>((ref) {
  final client = ref.watch(supabaseProvider);
  return HotelSupabaseService(client);
});

final _bookingAffiliateServiceProvider = Provider<BookingAffiliateService>(
  (_) => BookingAffiliateService(),
);

/// To enable Amadeus, set these env values or replace the strings.
/// Leave them as '' to use mock service.
final _amadeusServiceProvider = Provider<AmadeusApiService?>((_) {
  const clientId = '';     // 'your_amadeus_client_id'
  const clientSecret = ''; // 'your_amadeus_client_secret'
  if (clientId.isEmpty || clientSecret.isEmpty) return null;
  return AmadeusApiService(
    clientId: clientId,
    clientSecret: clientSecret,
    useSandbox: true,
  );
});

final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  return HotelRepository(
    mockService: ref.watch(_mockHotelServiceProvider),
    supabaseService: ref.watch(_hotelSupabaseServiceProvider),
    affiliateService: ref.watch(_bookingAffiliateServiceProvider),
    amadeusService: ref.watch(_amadeusServiceProvider),
  );
});

// ── Use case providers ────────────────────────────────────────

final searchHotelsUseCaseProvider = Provider<SearchHotelsUseCase>(
  (ref) => SearchHotelsUseCase(ref.watch(hotelRepositoryProvider)),
);

final getHotelDetailUseCaseProvider = Provider<GetHotelDetailUseCase>(
  (ref) => GetHotelDetailUseCase(ref.watch(hotelRepositoryProvider)),
);

final getHotelRoomsUseCaseProvider = Provider<GetHotelRoomsUseCase>(
  (ref) => GetHotelRoomsUseCase(ref.watch(hotelRepositoryProvider)),
);

final createBookingUseCaseProvider = Provider<CreateBookingUseCase>(
  (ref) => CreateBookingUseCase(ref.watch(hotelRepositoryProvider)),
);

final trackAffiliateUseCaseProvider = Provider<TrackAffiliateClickUseCase>(
  (ref) => TrackAffiliateClickUseCase(ref.watch(hotelRepositoryProvider)),
);

final getUserBookingsUseCaseProvider = Provider<GetUserBookingsUseCase>(
  (ref) => GetUserBookingsUseCase(ref.watch(hotelRepositoryProvider)),
);

// ── State providers ───────────────────────────────────────────

/// Current search params state — drives hotel search
final hotelSearchParamsProvider =
    StateNotifierProvider<HotelSearchParamsNotifier, HotelSearchParams>(
  (ref) => HotelSearchParamsNotifier(),
);

class HotelSearchParamsNotifier extends StateNotifier<HotelSearchParams> {
  HotelSearchParamsNotifier()
      : super(HotelSearchParams(
          city: 'Delhi',
          checkIn: DateTime.now().add(const Duration(days: 1)),
          checkOut: DateTime.now().add(const Duration(days: 3)),
          adults: 2,
          rooms: 1,
        ));

  void updateCity(String city) => state = state.copyWith(city: city);
  void updateDates(DateTime checkIn, DateTime checkOut) =>
      state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
  void updateGuests(int adults) => state = state.copyWith(adults: adults);
  void updateSort(HotelSortBy sort) => state = state.copyWith(sortBy: sort);
  void updateMinPrice(double? v) => state = state.copyWith(minPrice: v);
  void updateMaxPrice(double? v) => state = state.copyWith(maxPrice: v);
  void updateMinRating(double? v) => state = state.copyWith(minRating: v);
  void updateTiers(List<HotelTierFilter> tiers) =>
      state = state.copyWith(tiers: tiers);
  void updateGeoLocation(double lat, double lng) =>
      state = state.copyWith(latitude: lat, longitude: lng);
}

/// Hotel search results — auto-fetched when params change
final hotelSearchResultsProvider =
    FutureProvider.autoDispose<List<Hotel>>((ref) async {
  final params = ref.watch(hotelSearchParamsProvider);
  final useCase = ref.watch(searchHotelsUseCaseProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
  return useCase.execute(params: params, userId: userId);
});

/// Single hotel detail
final hotelDetailProvider =
    FutureProvider.family.autoDispose<Hotel?, String>((ref, hotelId) async {
  final useCase = ref.watch(getHotelDetailUseCaseProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
  return useCase.execute(hotelId: hotelId, userId: userId);
});

/// Rooms for a given hotel — keyed by hotel ID
final hotelRoomsProvider =
    FutureProvider.family.autoDispose<List<Room>, Hotel>((ref, hotel) async {
  final useCase = ref.watch(getHotelRoomsUseCaseProvider);
  final params = ref.watch(hotelSearchParamsProvider);
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
  return useCase.execute(
    hotel: hotel,
    checkIn: params.checkIn,
    checkOut: params.checkOut,
    adults: params.adults,
    userId: userId,
  );
});

/// User booking history
final userBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final userId = ref.watch(supabaseProvider).auth.currentUser?.id;
  if (userId == null) return [];
  final useCase = ref.watch(getUserBookingsUseCaseProvider);
  return useCase.execute(userId);
});

/// Active booking flow state
final bookingFlowProvider =
    StateNotifierProvider.autoDispose<BookingFlowNotifier, BookingFlowState>(
  (ref) => BookingFlowNotifier(ref),
);

class BookingFlowState {
  final Room? selectedRoom;
  final bool isLoading;
  final Booking? completedBooking;
  final String? error;

  const BookingFlowState({
    this.selectedRoom,
    this.isLoading = false,
    this.completedBooking,
    this.error,
  });

  BookingFlowState copyWith({
    Room? selectedRoom,
    bool? isLoading,
    Booking? completedBooking,
    String? error,
  }) =>
      BookingFlowState(
        selectedRoom: selectedRoom ?? this.selectedRoom,
        isLoading: isLoading ?? this.isLoading,
        completedBooking: completedBooking ?? this.completedBooking,
        error: error,
      );
}

class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  final Ref _ref;
  BookingFlowNotifier(this._ref) : super(const BookingFlowState());

  void selectRoom(Room room) =>
      state = state.copyWith(selectedRoom: room, error: null);

  Future<Booking?> confirmBooking({
    required Hotel hotel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    if (state.selectedRoom == null) return null;
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    if (userId == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final booking = await _ref.read(createBookingUseCaseProvider).execute(
            hotel: hotel,
            room: state.selectedRoom!,
            checkIn: checkIn,
            checkOut: checkOut,
            guests: guests,
            userId: userId,
          );
      state = state.copyWith(
          isLoading: false, completedBooking: booking, error: null);
      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> redirectToBookingCom({
    required Hotel hotel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int rooms,
  }) async {
    final userId = _ref.read(supabaseProvider).auth.currentUser?.id;
    await _ref.read(trackAffiliateUseCaseProvider).execute(
          hotel: hotel,
          checkIn: checkIn,
          checkOut: checkOut,
          adults: adults,
          rooms: rooms,
          userId: userId,
        );
  }

  void reset() => state = const BookingFlowState();
}

/// Saved hotels (client-side set)
final savedHotelsProvider =
    StateNotifierProvider<SavedHotelsNotifier, Set<String>>(
  (_) => SavedHotelsNotifier(),
);

class SavedHotelsNotifier extends StateNotifier<Set<String>> {
  SavedHotelsNotifier() : super({});

  bool isSaved(String id) => state.contains(id);

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }
}
