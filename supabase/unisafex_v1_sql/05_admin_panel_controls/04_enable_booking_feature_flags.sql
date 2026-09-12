-- Enable hotel booking from Admin-controlled remote config.
-- Admin can still hide it later from Admin Console > Flags.

insert into public.app_feature_flags(key, enabled, description)
values
  ('feature_hotels_enabled', true, 'Show hotel booking features'),
  ('feature_flights_enabled', true, 'Show flight booking features')
on conflict (key) do update
set enabled = true,
    description = excluded.description,
    updated_at = now();
