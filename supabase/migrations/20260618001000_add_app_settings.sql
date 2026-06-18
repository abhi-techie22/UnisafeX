create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.app_settings(key, value)
values (
  'maps_config',
  '{"in_app_maps_enabled": true, "route_overlay_enabled": true}'::jsonb
)
on conflict (key) do nothing;

alter table public.app_settings enable row level security;

grant select on public.app_settings to anon, authenticated;
grant insert, update, delete on public.app_settings to authenticated;

drop policy if exists app_settings_public_read on public.app_settings;
drop policy if exists app_settings_admin_write on public.app_settings;

create policy app_settings_public_read
  on public.app_settings
  for select
  to anon, authenticated
  using (true);

create policy app_settings_admin_write
  on public.app_settings
  for all
  to authenticated
  using (public.is_unisafex_admin())
  with check (public.is_unisafex_admin());

drop trigger if exists app_settings_updated_at on public.app_settings;
create trigger app_settings_updated_at
  before update on public.app_settings
  for each row execute function public.handle_updated_at();
