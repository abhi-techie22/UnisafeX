import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsApiKey = Bundle.main.object(
      forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
    ) as? String, !mapsApiKey.isEmpty, mapsApiKey != "$(GOOGLE_MAPS_API_KEY)" {
      GMSServices.provideAPIKey(mapsApiKey)
    } else {
      NSLog("GOOGLE_MAPS_API_KEY is not configured.")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
