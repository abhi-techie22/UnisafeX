-- UniSafeX v1 quick admin checks.
-- Safe read-only checks. Run after applying SQL.

select key, enabled, description
from public.app_feature_flags
order by key;

select email, role, is_active, created_at
from public.admin_users
order by role, email;

select key, value
from public.app_settings
where key in ('auth_config', 'currency_rates')
order by key;

select count(*) as tourism_places_count
from public.tourism_places;
