# UniSafeX — Premium Tourism App for India

A production-grade Flutter app built for international tourists visiting India. Designed with premium UI/UX inspired by Airbnb, Zomato, and Apple.

---

## 🚀 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (latest stable) |
| State Management | Riverpod |
| Navigation | go_router |
| Backend | Supabase |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth |
| Maps | Google Maps Flutter |
| Localization | easy_localization |

---

## ⚙️ Setup

### 1. Prerequisites
- Flutter SDK ≥ 3.3.0
- Dart SDK ≥ 3.3.0
- A Supabase project (free tier works)

### 2. Clone & Install

```bash
git clone <repo-url>
cd unisafex
flutter pub get
```

### 3. Configure Supabase

Open `lib/core/constants/app_constants.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

With your actual Supabase project URL and anon key (found in Settings > API).

In Supabase Dashboard, open **Authentication > URL Configuration** and add
this exact value to **Redirect URLs**:

```text
unisafex://login-callback/
```

Without this allowlist entry, confirmation emails fall back to the configured
Site URL, which is often `http://localhost:3000` in a new Supabase project.

### 4. Set Up Database

In the Supabase SQL Editor, run the complete schema:
```
supabase/schema.sql
```

This will:
- Create all tables (profiles, tourism_places, favorites)
- Set up Row Level Security policies
- Create triggers and functions
- Seed 18 popular Indian tourist destinations

### 5. Set Up Storage

The schema.sql automatically creates the `user-media` storage bucket. Verify it exists in Supabase Storage dashboard.

### 6. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# With flavor
flutter run --flavor development
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/       # App-wide constants
│   ├── router/          # go_router setup
│   ├── theme/           # Light & dark theme
│   ├── extensions/      # BuildContext, String extensions
│   ├── errors/          # Error widgets
│   ├── utils/           # Distance calculator, connectivity
│   └── widgets/         # Shared widgets (buttons, shimmer, etc.)
├── features/
│   ├── splash/          # Splash screen
│   ├── onboarding/      # 5-screen premium onboarding
│   ├── auth/            # Email login, register, guest mode
│   ├── profile/         # Profile completion + profile screen
│   ├── home/            # Main home screen with sections
│   ├── tourism/         # Place cards, detail screen, list
│   ├── map/             # Nearby discovery and location flow
│   ├── maps/            # Google Maps destination screen
│   ├── search/          # Global search with categories
│   ├── favorites/       # Saved places (authenticated)
│   └── settings/        # Theme, language, notifications
assets/
├── translations/        # 10 language JSON files
supabase/
└── schema.sql           # Complete DB schema + seed data
```

---

## 🗄️ Database Schema

### `profiles`
Stores user travel information (full name, nationality, visa details, etc.)

### `tourism_places`
All tourist destinations with full metadata:
- Location (lat/lng, city, state)
- Category (Historical, Nature, Spiritual, Adventure, Photography, Food, Shopping, Wildlife)
- Entry fees (separate for Indian nationals and foreigners)
- Safety guidelines and tourist tips
- Images, timings, best season
- Tier system (1=UNESCO/iconic, 2=popular, 3=regional)

### `favorites`
Many-to-many relationship between users and places.

---

## 🛡️ Security

- Row Level Security enabled on all tables
- Users can only read/write their own profile and favorites
- Tourism places are publicly readable
- Storage bucket policies enforce ownership

---

## 🌍 Localization

Supports 10 languages:
- English (en) — Complete
- Hindi (hi), French (fr), German (de), Spanish (es)
- Chinese (zh), Japanese (ja), Korean (ko), Arabic (ar), Russian (ru)

Add translations in `assets/translations/<lang>.json`

---

## 📱 Screens

1. **Splash** — Animated premium logo screen
2. **Onboarding** — 5 screens with smooth animations
3. **Auth Selection** — Email / Guest mode
4. **Login** — Email + password with forgot password
5. **Register** — Account creation
6. **Profile Completion** — 2-step travel profile form
7. **Home** — Featured, Must Visit, Trending, Popular sections
8. **Search** — Real-time search with category filters
9. **Map** — In-app Google Maps destination view with markers and live distance
10. **Favorites** — Saved places (auth required)
11. **Profile** — Travel info, account management
12. **Place Detail** — Full-detail screen with hero images
13. **Places List** — Filterable list with advanced filters
14. **Settings** — Theme, language, notifications

---

## 🗺️ Maps

Uses `google_maps_flutter`. Enable billing, Maps SDK for Android, Maps SDK for
iOS, and Maps JavaScript API, then replace the `YOUR_API_KEY` placeholders in
the Android manifest, iOS app delegate, and web index. Use separate
platform-restricted keys for production.

For a premium map style, sign up at [MapTiler](https://www.maptiler.com/) (free tier available) and replace the style URL in `map_screen.dart`.

---

## 🔮 Future Roadmap

- [ ] Hotel booking system
- [ ] Payment integration (Razorpay/Stripe)
- [ ] In-app chat support
- [ ] Offline maps caching
- [ ] AI travel recommendations
- [ ] Emergency SOS button
- [ ] Push notifications
- [ ] Social sharing

---

## 📄 License

MIT License — Free for commercial and personal use.
