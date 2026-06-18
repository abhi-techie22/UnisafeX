# UniSafeX Security And Quality Audit

Date: 2026-06-18  
Branch: `security-quality-audit-2026-06-18`

## Executive Summary

This audit focused on Flutter compile quality, Riverpod state safety, GoRouter access control, Supabase authentication, RLS, storage policies, guest access, hardcoded credentials, and hotel/booking database readiness.

The app is now compile-clean for errors. Remaining analyzer output is non-blocking quality debt: deprecated `withOpacity`, `print` usage in tourism repositories, and const/style suggestions.

## Fixed In This Audit

- Added sign-out action directly inside the admin panel.
- Removed hardcoded Supabase URL and anon/publishable key from Dart source.
- Added runtime config validation for `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- Switched Supabase initialization from deprecated `anonKey` to `publishableKey`.
- Added GoRouter route guards for private pages and admin route access.
- Added hotel module compatibility design constants/widgets so hotel code compiles.
- Moved Amadeus hotel API credentials to `--dart-define`.
- Added hotel booking, analytics, affiliate click, and hotel cache SQL tables with RLS.
- Added stricter storage object policies for profile media owner paths.
- Added `tourism_places_admin_write` policy to the full schema.
- Fixed favorites provider to use the shared Supabase Riverpod provider.
- Replaced obsolete widget test with a current metadata smoke test.

## Vulnerability Findings

### Critical

None found in committed application code after fixes.

### High

1. Hardcoded Supabase publishable key in `AppConstants`.
   - Status: Fixed.
   - Fix: `String.fromEnvironment` runtime config.
   - Production action: inject keys via CI/CD or `--dart-define`.

2. Storage upload policy allowed authenticated users to upload without ownership path validation.
   - Status: Fixed in schema and migration.
   - Fix: insert/update/delete policies require path `profiles/<auth.uid>/...`.
   - Production action: run the new Supabase migration.

3. Hotel booking tables were used by app code but missing from full schema.
   - Status: Fixed in schema and migration.
   - Impact before fix: booking/history writes could fail or be deployed without reviewed RLS.

### Medium

1. Admin route relied mostly on screen-level checks.
   - Status: Improved.
   - Fix: GoRouter now redirects non-admin users away from `/admin`.
   - Note: Server-side RLS remains the real security control.

2. `tourism_places` full schema had public read but no admin write policy.
   - Status: Fixed.
   - Fix: added `tourism_places_admin_write`.

3. `user-media` bucket is public.
   - Status: Accepted with caution.
   - Risk: profile images are public URLs.
   - Recommendation: keep only non-sensitive profile images here; use a private bucket for passport/visa documents.

4. Admin identity is email-based.
   - Status: Existing risk.
   - Recommendation: before production, move admin authorization to a dedicated `admin_users` table or custom claim.

### Low

1. Analyzer style debt remains.
   - Deprecated `withOpacity`.
   - Production `print` calls in tourism repositories/providers.
   - Const/style hints.

2. Hotel affiliate ID is a placeholder.
   - Not a secret, but should be configured server-side before real monetization.

## RLS Review

Reviewed:

- `profiles`: users can only CRUD own profile.
- `favorites`: users can only access own rows.
- `tourism_place_likes`: users can only insert/delete own likes.
- `guide_requests`: users see own requests; admin manages all.
- `guide_profiles`: admin-only.
- `app_settings`: public read, admin write.
- `tourism_places`: public read, admin write.
- `hotel_bookings`: users see/insert/update own bookings; admin can manage.
- `hotel_analytics_events`: client insert; admin read.
- `hotel_affiliate_clicks`: client insert; owner/admin read/update.
- `hotels_cache`: public read; admin write.
- `storage.objects/user-media`: public read; user-owned insert/update/delete by profile path.

## Guest Access Review

Allowed:

- Tourism browsing.
- Public destinations.
- Public app map settings.
- Hotel search mock/affiliate discovery.
- Analytics/affiliate insert with nullable `user_id`.

Blocked or redirected:

- Profile.
- Identity details.
- Favorites.
- Guide requests.
- Admin panel.
- Profile completion.
- Hotel booking confirmation requires authenticated `userId` in provider flow.

## Riverpod Review

- Auth state flows through `authStateProvider`, `currentSessionProvider`, and `currentUserProvider`.
- Favorites now use `supabaseClientProvider` instead of directly reading `Supabase.instance`.
- Profile repository verifies the requested profile user matches the current authenticated session before read/write/upload.
- Remaining improvement: several tourism providers still use `print`; replace with a logger.

## GoRouter Review

Fixed:

- Private route access now redirects unsigned users to login.
- `/admin` now performs an async admin RPC check before rendering.
- Logged-in users are redirected away from auth entry pages to home.

Remaining:

- Profile completion is not globally enforced after login if users manually navigate to home after an incomplete profile. Splash handles this, but a stricter redirect could enforce it on every route.

## Secret Scan

Pattern scan found no real committed API keys/tokens after fixes.

Only placeholder documentation remains:

- `README.md` contains `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY`.

Runtime config now required:

```bash
--dart-define=SUPABASE_URL=...
--dart-define=SUPABASE_ANON_KEY=...
--dart-define=AMADEUS_CLIENT_ID=...
--dart-define=AMADEUS_CLIENT_SECRET=...
```

Amadeus defines are optional; when omitted, hotels use mock fallback.

## Testing Report

Commands run:

```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_ANON_KEY=dummy
```

Results:

- `flutter analyze --no-fatal-infos --no-fatal-warnings`: Passed with no compile errors.
- `flutter test`: Passed.
- `flutter build web`: Passed.

Strict `flutter analyze` still reports non-blocking lint/style items. These are not compile failures but should be cleaned before production polish.

## Flow Verification Status

Static/compile verified:

- Registration and login code paths compile.
- Profile completion repository has session/user ownership guard.
- Tourism screens/providers compile.
- Hotel module compiles after compatibility fixes.
- Booking module has schema/RLS support.
- Admin panel compiles and has sign-out.

Needs live Supabase/browser verification after SQL migration:

- Email registration and confirmation.
- Login with real Supabase project.
- Profile completion save.
- Profile image upload to `user-media`.
- Guide request create/admin update.
- Hotel booking save/history.
- Admin map settings save.

## Production Launch Remaining Risks

- Apply all Supabase migrations before testing live flows.
- Configure `SUPABASE_URL` and `SUPABASE_ANON_KEY` in CI/CD and local run commands.
- Restrict Supabase Auth redirect URLs to production domains and app schemes.
- Move admin authorization from email comparison to an admin table or custom claim.
- Confirm Supabase password policy and email confirmation settings in dashboard.
- Confirm storage bucket does not store passport/visa/private documents publicly.
- Replace tourism `print` calls with structured logging.
- Complete strict analyzer cleanup if you want zero lint output.
