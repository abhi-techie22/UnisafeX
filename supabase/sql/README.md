# UniSafeX Structured SQL Library

This folder is a human-friendly SQL library copied from `supabase/migrations/`.
It does not replace Supabase CLI migrations. Keep `supabase/migrations/` as the
source used by `supabase db push`.

Use this folder when you want to review or manually paste SQL into the Supabase
Dashboard SQL Editor feature-by-feature.

## Folders

- `00_full_schema/` - complete schema snapshot.
- `01_profiles_auth/` - profiles, auth profile sync, auth app settings.
- `02_tourism_places/` - destinations, heritage data, likes, images.
- `03_guides_support/` - guide requests, guide profiles, support tickets.
- `04_hotels_booking/` - hotel booking and affiliate/analytics tables.
- `05_admin_remote_config/` - admin panel, feature flags, banners, alerts,
  app settings, currency rates.
- `06_storage/` - public tourism media bucket.
- `07_security_hardening/` - owner protection and production launch hardening.
- `99_apply_order/` - recommended execution order and notes.

## Important

For a new database, prefer `00_full_schema/000_complete_schema.sql`.

For an existing database, run the files from `99_apply_order/apply_order.md` in
order. Most files use `if not exists`, `drop policy if exists`, or
`on conflict`, but you should still review before running in production.

Never paste private API keys, service-role keys, or partner secrets into these
SQL files.
