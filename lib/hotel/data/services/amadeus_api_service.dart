import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import '../dto/amadeus_dto.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/hotel_search_params.dart';

/// Amadeus Hotel API service.
/// Docs: https://developers.amadeus.com/self-service/category/hotels
///
/// Set AMADEUS_CLIENT_ID and AMADEUS_CLIENT_SECRET in environment or
/// HotelApiConfig. When keys are absent, this throws [AmadeusNotConfigured]
/// and the repository falls back to MockHotelService.
class AmadeusApiService {
  static const String _baseUrl = 'https://api.amadeus.com';
  static const String _testBaseUrl = 'https://test.api.amadeus.com';

  final Dio _dio;
  final Logger _log = Logger();
  final String _clientId;
  final String _clientSecret;
  final bool _useSandbox;

  AmadeusTokenDto? _cachedToken;

  AmadeusApiService({
    required String clientId,
    required String clientSecret,
    bool useSandbox = true,
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _useSandbox = useSandbox,
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

  String get _base => _useSandbox ? _testBaseUrl : _baseUrl;

  // ── Auth ──────────────────────────────────────────────────────
  Future<String> _getAccessToken() async {
    if (_cachedToken != null && !_cachedToken!.isExpired) {
      return _cachedToken!.accessToken;
    }

    final response = await _dio.post(
      '$_base/v1/security/oauth2/token',
      data: {
        'grant_type': 'client_credentials',
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    _cachedToken = AmadeusTokenDto.fromJson(
        response.data as Map<String, dynamic>);
    return _cachedToken!.accessToken;
  }

  Future<Options> _authOptions() async {
    final token = await _getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Hotel Search by City ───────────────────────────────────────
  Future<List<Hotel>> searchByCity(HotelSearchParams params) async {
    final token = await _getAccessToken();
    final fmt = DateFormat('yyyy-MM-dd');

    // Step 1: Get hotel IDs for city
    final listResp = await _dio.get(
      '$_base/v1/reference-data/locations/hotels/by-city',
      queryParameters: {
        'cityCode': _cityToIATACode(params.city),
        'radius': (params.radiusKm ?? 10).toInt(),
        'radiusUnit': 'KM',
        'ratings': '3,4,5',
        'amenities': 'SWIMMING_POOL,SPA,RESTAURANT',
        'hotelSource': 'ALL',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final hotelIds = ((listResp.data['data'] as List?) ?? [])
        .take(20)
        .map((h) => h['hotelId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (hotelIds.isEmpty) return [];

    // Step 2: Get offers for those hotels
    final offersResp = await _dio.get(
      '$_base/v3/shopping/hotel-offers',
      queryParameters: {
        'hotelIds': hotelIds.join(','),
        'adults': params.adults,
        'checkInDate': fmt.format(params.checkIn),
        'checkOutDate': fmt.format(params.checkOut),
        'roomQuantity': params.rooms,
        'currency': 'INR',
        'bestRateOnly': true,
        'includeClosed': false,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = (offersResp.data['data'] as List?) ?? [];
    return data
        .map((json) =>
            AmadeusHotelDto.fromJson(json as Map<String, dynamic>)
                .toEntity(params.city))
        .toList();
  }

  // ── Hotel Search by Geo ────────────────────────────────────────
  Future<List<Hotel>> searchByGeo(HotelSearchParams params) async {
    if (params.latitude == null || params.longitude == null) {
      return searchByCity(params);
    }

    final token = await _getAccessToken();
    final fmt = DateFormat('yyyy-MM-dd');

    final listResp = await _dio.get(
      '$_base/v1/reference-data/locations/hotels/by-geocode',
      queryParameters: {
        'latitude': params.latitude,
        'longitude': params.longitude,
        'radius': (params.radiusKm ?? 10).toInt(),
        'radiusUnit': 'KM',
        'ratings': '3,4,5',
        'hotelSource': 'ALL',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final hotelIds = ((listResp.data['data'] as List?) ?? [])
        .take(20)
        .map((h) => h['hotelId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (hotelIds.isEmpty) return [];

    final offersResp = await _dio.get(
      '$_base/v3/shopping/hotel-offers',
      queryParameters: {
        'hotelIds': hotelIds.join(','),
        'adults': params.adults,
        'checkInDate': fmt.format(params.checkIn),
        'checkOutDate': fmt.format(params.checkOut),
        'roomQuantity': params.rooms,
        'currency': 'INR',
        'bestRateOnly': true,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = (offersResp.data['data'] as List?) ?? [];
    return data
        .map((json) =>
            AmadeusHotelDto.fromJson(json as Map<String, dynamic>)
                .toEntity(params.city))
        .toList();
  }

  // ── Hotel Offers (rooms) ───────────────────────────────────────
  Future<List<Room>> getHotelOffers({
    required String partnerHotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required String localHotelId,
  }) async {
    final token = await _getAccessToken();
    final fmt = DateFormat('yyyy-MM-dd');

    final resp = await _dio.get(
      '$_base/v3/shopping/hotel-offers',
      queryParameters: {
        'hotelIds': partnerHotelId,
        'adults': adults,
        'checkInDate': fmt.format(checkIn),
        'checkOutDate': fmt.format(checkOut),
        'bestRateOnly': false,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = (resp.data['data'] as List?) ?? [];
    if (data.isEmpty) return [];

    final hotel = AmadeusHotelDto.fromJson(data.first as Map<String, dynamic>);
    return hotel.offers.map((o) => o.toEntity(localHotelId)).toList();
  }

  // ── Create Booking ─────────────────────────────────────────────
  Future<Map<String, dynamic>> createBooking({
    required String offerId,
    required Map<String, String> traveler,
  }) async {
    final token = await _getAccessToken();

    final resp = await _dio.post(
      '$_base/v1/booking/hotel-orders',
      data: {
        'data': {
          'type': 'hotel-order',
          'guests': [
            {
              'tid': 1,
              'title': 'MR',
              'firstName': traveler['firstName'] ?? '',
              'lastName': traveler['lastName'] ?? '',
              'phone': traveler['phone'] ?? '',
              'email': traveler['email'] ?? '',
            }
          ],
          'travelAgent': {
            'contact': {'email': 'bookings@unisafex.app'}
          },
          'roomAssociations': [
            {
              'guestReferences': [
                {'tid': 1, 'hotelOfferId': offerId}
              ],
              'hotelOfferId': offerId,
            }
          ],
          'payment': {
            'method': 'CREDIT_CARD',
            'paymentCard': {
              'paymentCardInfo': {
                'vendorCode': 'VI',
                'cardNumber': traveler['cardNumber'] ?? '',
                'expiryDate': traveler['expiryDate'] ?? '',
                'holderName': traveler['holderName'] ?? '',
              }
            }
          },
        }
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return resp.data as Map<String, dynamic>;
  }

  // ── City Code Mapping ──────────────────────────────────────────
  static const Map<String, String> _cityIATACodes = {
    'Delhi': 'DEL',
    'Mumbai': 'BOM',
    'Bangalore': 'BLR',
    'Goa': 'GOI',
    'Chennai': 'MAA',
    'Kolkata': 'CCU',
    'Hyderabad': 'HYD',
    'Jaipur': 'JAI',
    'Kochi': 'COK',
    'Varanasi': 'VNS',
    'Agra': 'AGR',
    'Amritsar': 'ATQ',
    'Udaipur': 'UDR',
    'Jodhpur': 'JDH',
    'Rishikesh': 'DED',
    'Mysore': 'MYQ',
  };

  String _cityToIATACode(String city) =>
      _cityIATACodes[city] ?? city.substring(0, 3).toUpperCase();
}

/// Thrown when Amadeus credentials are not set.
class AmadeusNotConfigured implements Exception {
  final String message;
  const AmadeusNotConfigured(
      [this.message = 'Amadeus API keys not configured']);
  @override
  String toString() => message;
}
