import '../../data/repositories/hotel_repository.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/affiliate_click.dart';
import '../../domain/entities/hotel_search_params.dart';

// ── Search Hotels ─────────────────────────────────────────────
class SearchHotelsUseCase {
  final HotelRepository _repo;
  const SearchHotelsUseCase(this._repo);

  Future<List<Hotel>> execute({
    required HotelSearchParams params,
    String? userId,
  }) => _repo.searchHotels(params: params, userId: userId);
}

// ── Get Hotel Detail ──────────────────────────────────────────
class GetHotelDetailUseCase {
  final HotelRepository _repo;
  const GetHotelDetailUseCase(this._repo);

  Future<Hotel?> execute({required String hotelId, String? userId}) =>
      _repo.getHotelDetail(hotelId: hotelId, userId: userId);
}

// ── Get Hotel Rooms ───────────────────────────────────────────
class GetHotelRoomsUseCase {
  final HotelRepository _repo;
  const GetHotelRoomsUseCase(this._repo);

  Future<List<Room>> execute({
    required Hotel hotel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    String? userId,
  }) => _repo.getHotelRooms(
        hotel: hotel,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        userId: userId,
      );
}

// ── Create Booking ────────────────────────────────────────────
class CreateBookingUseCase {
  final HotelRepository _repo;
  const CreateBookingUseCase(this._repo);

  Future<Booking> execute({
    required Hotel hotel,
    required Room room,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String userId,
    Map<String, String> travelerInfo = const {},
  }) => _repo.createBooking(
        hotel: hotel,
        room: room,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        userId: userId,
        travelerInfo: travelerInfo,
      );
}

// ── Track Affiliate Click (redirect) ─────────────────────────
class TrackAffiliateClickUseCase {
  final HotelRepository _repo;
  const TrackAffiliateClickUseCase(this._repo);

  Future<AffiliateClick> execute({
    required Hotel hotel,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int rooms,
    String? userId,
  }) => _repo.redirectToAffiliate(
        hotel: hotel,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        rooms: rooms,
        userId: userId,
      );
}

// ── Get User Bookings ─────────────────────────────────────────
class GetUserBookingsUseCase {
  final HotelRepository _repo;
  const GetUserBookingsUseCase(this._repo);

  Future<List<Booking>> execute(String userId) =>
      _repo.getUserBookings(userId);
}
