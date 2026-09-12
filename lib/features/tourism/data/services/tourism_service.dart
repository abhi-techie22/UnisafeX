import 'package:supabase_flutter/supabase_flutter.dart';

class TourismService {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> getPlaces() async {
    try {
      final response = await supabase
          .from(
            'tourism_places',
          )
          .select()
          .eq('is_hidden', false);

      return response;
    } catch (e) {
      throw Exception(
        'Failed to fetch tourism places: $e',
      );
    }
  }
}
