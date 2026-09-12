# UniSafeX v1 Existing Supabase Project Apply Order

Use this order when your Supabase project already exists.

Open each SQL file, paste it into Supabase Dashboard SQL Editor, run it, then
continue to the next file. Most files are written with `if not exists`,
`drop policy if exists`, or `on conflict`, but still read before running.

## 1. Users, Auth, Profiles

1. `../01_users_auth_profiles/01_profiles_table_registration_rls.sql`
2. `../01_users_auth_profiles/02_profile_email_sync.sql`
3. `../01_users_auth_profiles/03_auth_confirmation_guest_settings.sql`

## 2. Tourism Places And Destination Content

4. `../02_tourism_places_content/01_seed_core_destination_details.sql`
5. `../02_tourism_places_content/02_create_heritage_catalog_admin_access.sql`
6. `../02_tourism_places_content/03_import_india_monuments_dataset.sql`
7. `../02_tourism_places_content/04_destination_likes_system.sql`
8. `../02_tourism_places_content/05_destination_image_updates.sql`

## 3. Guides, Support, Admin Team

9. `../03_guides_support/01_guide_requests.sql`
10. `../03_guides_support/02_guide_assignment_and_booking.sql`
11. `../03_guides_support/03_guide_profiles.sql`
12. `../03_guides_support/04_support_tickets_and_admin_team.sql`

## 4. Booking

13. `../04_booking_hotels_flights/01_hotel_booking_tables_security.sql`

## 5. Admin Panel Controls

14. `../05_admin_panel_controls/01_app_settings_table.sql`
15. `../05_admin_panel_controls/02_admin_dashboard_flags_banners_alerts.sql`
16. `../05_admin_panel_controls/03_live_currency_rates_admin.sql`
17. `../05_admin_panel_controls/04_enable_booking_feature_flags.sql`

## 6. Storage

18. `../06_storage_media/01_tourism_media_bucket.sql`

## 7. Security Before Launch

19. `../07_security_launch/01_protect_owner_and_admin_roles.sql`
20. `../07_security_launch/02_production_security_hardening.sql`

## Dashboard Checks After SQL

- Confirm your owner admin email exists: `abhishek.work962511@gmail.com`.
- Supabase Auth email confirmation setting matches Admin > Auth setting.
- Google login redirect URLs are correct.
- Storage bucket policies are correct.
- Security Advisor and Database Linter have no critical warnings.
- Hotel and flight feature flags are visible in Admin > Flags.
