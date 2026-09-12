# UniSafeX SQL Apply Order

Use this order for an existing Supabase project when applying manually in the
Dashboard SQL Editor.

## Existing Database Patch Order

1. `01_profiles_auth/001_fix_profile_registration_rls.sql`
2. `01_profiles_auth/002_add_profile_email_sync.sql`
3. `01_profiles_auth/003_add_auth_config_app_setting.sql`
4. `02_tourism_places/001_fill_place_details.sql`
5. `02_tourism_places/002_add_heritage_catalog_and_admin.sql`
6. `02_tourism_places/003_import_india_tourism_data.sql`
7. `02_tourism_places/004_add_tourism_place_likes.sql`
8. `02_tourism_places/005_patch_tourism_place_images.sql`
9. `03_guides_support/001_add_guide_requests.sql`
10. `03_guides_support/002_add_guide_assignment_booking.sql`
11. `03_guides_support/003_add_guide_profiles.sql`
12. `03_guides_support/004_add_admin_team_support_and_tickets.sql`
13. `04_hotels_booking/001_add_hotel_booking_security.sql`
14. `05_admin_remote_config/001_add_app_settings.sql`
15. `05_admin_remote_config/002_admin_panel_remote_config.sql`
16. `05_admin_remote_config/003_add_currency_rates_app_setting.sql`
17. `06_storage/001_add_tourism_media_bucket.sql`
18. `07_security_hardening/001_harden_admin_owner_access.sql`
19. `07_security_hardening/002_launch_security_hardening.sql`

## Fresh Database Option

For a clean project, run:

1. `00_full_schema/000_complete_schema.sql`
2. Then any newer files in `07_security_hardening/` that are not already folded
   into the schema snapshot.

## Required Dashboard Checks After Applying

- Supabase Auth email confirmation setting.
- Password policy and rate limits.
- Redirect URLs for mobile deep link and web.
- Storage bucket privacy and object policies.
- Security Advisor warnings.
- Database Linter warnings.
- Realtime disabled on sensitive tables unless explicitly needed.
- Edge Function secrets configured for `compute-route`.
