# UniSafeX v1 Supabase SQL

This is the easy-to-use SQL package for the UniSafeX v1 project.

Use this folder when you want to apply or review database setup from the
Supabase Dashboard SQL Editor. The older `supabase/migrations/` and
`supabase/sql/` folders are kept as development history. This v1 folder uses
clear names so you can quickly understand each file.

## Best Option For Your Current Project

Your Supabase project already has many tables and data, so use:

`00_start_here/01_apply_order_existing_project.md`

Run the files in that order.

## Fresh Project Option

Only for a brand-new empty Supabase project:

`99_full_schema_backup/00_complete_fresh_project_schema.sql`

After that, run newer files that are listed in the apply order and not already
included in the full schema backup.

## Folder Meaning

- `01_users_auth_profiles/` - user profiles, registration save fix, email sync,
  auth confirmation and guest-login settings.
- `02_tourism_places_content/` - places, destination details, 3000+ monuments
  dataset, likes, image patches.
- `03_guides_support/` - guide requests, guide assignment, guide profiles,
  support tickets, admin team helpers.
- `04_booking_hotels_flights/` - hotel booking tables, cache, affiliate clicks,
  analytics, booking security. Flight UI is app-side for now.
- `05_admin_panel_controls/` - admin panel tables, feature flags, banners,
  alerts, currency values, hotel/flight hide-show flags.
- `06_storage_media/` - tourism media bucket for admin-uploaded destination
  images.
- `07_security_launch/` - owner protection and production security hardening.
- `99_full_schema_backup/` - one large schema file for a fresh rebuild only.

## Important

Never paste service-role keys, Google Maps keys, API keys, or partner secrets
into SQL files. Keep those in Supabase secrets, Google Cloud restrictions, or
runtime configuration.
