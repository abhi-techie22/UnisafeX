# UniSafeX iOS Release Checklist

Android users install an APK or Play Store build. iPhone users need an iOS
build, usually through TestFlight or the App Store.

## Required Local Files

Create `ios/Flutter/GoogleMapsSecrets.xcconfig` from the example file:

```xcconfig
GOOGLE_MAPS_API_KEY=YOUR_RESTRICTED_IOS_GOOGLE_MAPS_KEY
```

Pass Supabase config at build or run time:

```sh
--dart-define=SUPABASE_URL=YOUR_SUPABASE_URL
--dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Build Commands

Simulator smoke test:

```sh
flutter build ios --simulator \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

App Store/TestFlight archive:

```sh
flutter build ipa \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Xcode Setup

Open `ios/Runner.xcworkspace`, select the `Runner` target, then set:

- Apple developer team
- Signing certificate/profile
- Bundle identifier: `com.unisafex.app`

## iOS Features Covered

- Location and nearby places
- Google Maps and in-app map views
- Camera/profile image picking
- Photo library upload
- Supabase auth deep link: `unisafex://login-callback/`
- External booking/navigation partner links
