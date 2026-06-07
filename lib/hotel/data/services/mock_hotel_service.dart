import 'package:uuid/uuid.dart';
import '../dto/mock_hotel_data.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/hotel_search_params.dart';

/// Mock hotel service that returns realistic static data.
/// Architecture is identical to AmadeusApiService —
/// swap by changing one line in HotelRepositoryImpl.
class MockHotelService {
  final _uuid = const Uuid();

  Future<List<Hotel>> searchHotels(HotelSearchParams params) async {
    // Simulate network delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 800));

    var hotels = MockHotelData.hotelsForCity(params.city);

    // Apply price filter
    if (params.minPrice != null) {
      hotels = hotels
          .where((h) => h.pricePerNight >= params.minPrice!)
          .toList();
    }
    if (params.maxPrice != null) {
      hotels = hotels
          .where((h) => h.pricePerNight <= params.maxPrice!)
          .toList();
    }

    // Apply rating filter
    if (params.minRating != null) {
      hotels =
          hotels.where((h) => h.rating >= params.minRating!).toList();
    }

    // Apply tier filter
    if (params.tiers.isNotEmpty) {
      hotels = hotels.where((h) {
        return params.tiers.any((t) {
          switch (t) {
            case HotelTierFilter.budget:
              return h.tier == HotelTier.budget;
            case HotelTierFilter.midRange:
              return h.tier == HotelTier.midRange;
            case HotelTierFilter.luxury:
              return h.tier == HotelTier.luxury;
            case HotelTierFilter.ultraLuxury:
              return h.tier == HotelTier.ultraLuxury;
          }
        });
      }).toList();
    }

    // Apply sort
    switch (params.sortBy) {
      case HotelSortBy.priceLow:
        hotels.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;
      case HotelSortBy.priceHigh:
        hotels.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;
      case HotelSortBy.rating:
        hotels.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case HotelSortBy.distance:
        hotels.sort((a, b) =>
            (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
        break;
      case HotelSortBy.recommended:
        // Composite: rating × 0.6 + price_inv × 0.4
        hotels.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return hotels;
  }

  Future<Hotel?> getHotelById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = MockHotelData.hotelsForCity('');
    try {
      return all.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Room>> getRoomsForHotel(String hotelId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockHotelData.roomsForHotel(hotelId);
  }

  Future<Map<String, dynamic>> createMockBooking({
    required String hotelId,
    required Room room,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final confirmationCode =
        'USX${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    return {
      'success': true,
      'confirmation_code': confirmationCode,
      'partner_booking_id': 'MOCK_${_uuid.v4().substring(0, 8).toUpperCase()}',
      'status': 'confirmed',
    };
  }
}
