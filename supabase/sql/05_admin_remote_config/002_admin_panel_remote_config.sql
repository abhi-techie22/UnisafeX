-- UniSafeX MVP Admin Panel + Remote Config
-- Apply in Supabase SQL Editor or via Supabase CLI.

create extension if not exists "uuid-ossp";

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role text not null default 'admin' check (role in ('owner', 'admin', 'editor')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_feature_flags (
  key text primary key,
  enabled boolean not null default false,
  description text,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.home_banners (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  subtitle text,
  image_url text,
  action_label text,
  action_route text,
  banner_type text not null default 'featured_city'
    check (banner_type in ('festival', 'hotel_promo', 'flight_promo', 'featured_city', 'emergency')),
  city text,
  state text,
  priority integer not null default 100,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.travel_alerts (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  message text not null,
  severity text not null default 'info'
    check (severity in ('info', 'warning', 'emergency')),
  city text,
  state text,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_notifications (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  message text not null,
  notification_type text not null default 'general',
  target_city text,
  target_state text,
  is_active boolean not null default true,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.tourism_content_audit_log (
  id uuid primary key default uuid_generate_v4(),
  actor_user_id uuid references auth.users(id) on delete set null,
  entity_type text not null,
  entity_id text,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index if not exists home_banners_active_idx
  on public.home_banners(is_active, priority, starts_at, ends_at);
create index if not exists travel_alerts_active_idx
  on public.travel_alerts(is_active, severity, starts_at, ends_at);
create index if not exists app_notifications_active_idx
  on public.app_notifications(is_active, starts_at, ends_at);
create index if not exists profiles_created_at_idx on public.profiles(created_at desc);

insert into public.app_feature_flags(key, enabled, description)
values
  ('feature_hotels_enabled', true, 'Show hotel booking features'),
  ('feature_flights_enabled', true, 'Show flight booking features'),
  ('feature_ai_assistant_enabled', true, 'Show AI travel assistant'),
  ('feature_sos_enabled', true, 'Show emergency/SOS affordances'),
  ('feature_festival_campaign_enabled', true, 'Show festival campaign banners'),
  ('feature_audio_guide_enabled', true, 'Enable audio phrase/guide features'),
  ('feature_trip_planner_enabled', true, 'Show smart trip planner')
on conflict (key) do nothing;

insert into public.admin_users(user_id, email, role, is_active)
select id, email, 'owner', true
from auth.users
where lower(email) = 'abhishek.work962511@gmail.com'
on conflict (user_id) do update
set email = excluded.email,
    role = 'owner',
    is_active = true,
    updated_at = now();

create or replace function public.is_admin(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = p_user_id
      and au.is_active = true
  )
  or lower(coalesce(auth.jwt() ->> 'email', '')) = 'abhishek.work962511@gmail.com';
$$;

create or replace function public.is_unisafex_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_admin(auth.uid());
$$;

revoke all on function public.is_admin(uuid) from public;
revoke all on function public.is_unisafex_admin() from public;
grant execute on function public.is_admin(uuid) to authenticated;
grant execute on function public.is_unisafex_admin() to authenticated;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists admin_users_updated_at on public.admin_users;
create trigger admin_users_updated_at
  before update on public.admin_users
  for each row execute function public.touch_updated_at();

drop trigger if exists app_feature_flags_updated_at on public.app_feature_flags;
create trigger app_feature_flags_updated_at
  before update on public.app_feature_flags
  for each row execute function public.touch_updated_at();

drop trigger if exists home_banners_updated_at on public.home_banners;
create trigger home_banners_updated_at
  before update on public.home_banners
  for each row execute function public.touch_updated_at();

drop trigger if exists travel_alerts_updated_at on public.travel_alerts;
create trigger travel_alerts_updated_at
  before update on public.travel_alerts
  for each row execute function public.touch_updated_at();

alter table public.admin_users enable row level security;
alter table public.app_feature_flags enable row level security;
alter table public.home_banners enable row level security;
alter table public.travel_alerts enable row level security;
alter table public.app_notifications enable row level security;
alter table public.tourism_content_audit_log enable row level security;

grant select on public.app_feature_flags to anon, authenticated;
grant select on public.home_banners to anon, authenticated;
grant select on public.travel_alerts to anon, authenticated;
grant select on public.app_notifications to authenticated;
grant select on public.profiles to authenticated;

grant select, insert, update, delete on public.admin_users to authenticated;
grant insert, update, delete on public.app_feature_flags to authenticated;
grant insert, update, delete on public.home_banners to authenticated;
grant insert, update, delete on public.travel_alerts to authenticated;
grant insert, update, delete on public.app_notifications to authenticated;
grant select, insert on public.tourism_content_audit_log to authenticated;

drop policy if exists admin_users_admin_all on public.admin_users;
create policy admin_users_admin_all on public.admin_users
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists app_feature_flags_public_read on public.app_feature_flags;
create policy app_feature_flags_public_read on public.app_feature_flags
  for select to anon, authenticated
  using (true);

drop policy if exists app_feature_flags_admin_write on public.app_feature_flags;
create policy app_feature_flags_admin_write on public.app_feature_flags
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists home_banners_public_active_read on public.home_banners;
create policy home_banners_public_active_read on public.home_banners
  for select to anon, authenticated
  using (
    is_active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

drop policy if exists home_banners_admin_all on public.home_banners;
create policy home_banners_admin_all on public.home_banners
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists travel_alerts_public_active_read on public.travel_alerts;
create policy travel_alerts_public_active_read on public.travel_alerts
  for select to anon, authenticated
  using (
    is_active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

drop policy if exists travel_alerts_admin_all on public.travel_alerts;
create policy travel_alerts_admin_all on public.travel_alerts
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists app_notifications_active_read on public.app_notifications;
create policy app_notifications_active_read on public.app_notifications
  for select to authenticated
  using (
    is_active = true
    and (starts_at is null or starts_at <= now())
    and (ends_at is null or ends_at >= now())
  );

drop policy if exists app_notifications_admin_all on public.app_notifications;
create policy app_notifications_admin_all on public.app_notifications
  for all to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

drop policy if exists tourism_content_audit_admin_read on public.tourism_content_audit_log;
create policy tourism_content_audit_admin_read on public.tourism_content_audit_log
  for select to authenticated
  using (public.is_admin(auth.uid()));

drop policy if exists tourism_content_audit_admin_insert on public.tourism_content_audit_log;
create policy tourism_content_audit_admin_insert on public.tourism_content_audit_log
  for insert to authenticated
  with check (public.is_admin(auth.uid()));

drop policy if exists profiles_admin_read on public.profiles;
create policy profiles_admin_read on public.profiles
  for select to authenticated
  using (public.is_admin(auth.uid()));
