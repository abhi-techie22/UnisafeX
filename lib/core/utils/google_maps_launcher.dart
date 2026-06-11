import 'package:url_launcher/url_launcher.dart';

class GoogleMapsLauncher {
  GoogleMapsLauncher._();

  static Future<bool> openDirections({
    double? originLatitude,
    double? originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    final parameters = <String, String>{
      'api': '1',
      if (originLatitude != null && originLongitude != null)
        'origin': '$originLatitude,$originLongitude',
      'destination': '$destinationLatitude,$destinationLongitude',
      'travelmode': 'driving',
    };
    return launchUrl(
      Uri.https('www.google.com', '/maps/dir/', parameters),
      mode: LaunchMode.externalApplication,
    );
  }
}
