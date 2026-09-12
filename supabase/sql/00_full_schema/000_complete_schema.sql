-- ============================================================
-- UniSafeX — Complete Supabase SQL Schema
-- Run this in Supabase SQL Editor (Settings > SQL Editor)
-- ============================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";  -- for geo queries (optional)

-- ============================================================
-- TABLE: profiles
-- ============================================================
create table if not exists public.profiles (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null unique references auth.users(id) on delete cascade,
  email         text,
  full_name     text,
  gender        text,
  nationality   text,
  country       text,
  country_code  text,
  current_location text,
  passport_country text,
  visa_type     text,
  visa_expiry   date,
  travel_purpose text,
  profile_image_url text,
  is_profile_complete boolean default false,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index if not exists profiles_email_idx
  on public.profiles (lower(email));

-- ============================================================
-- TABLE: tourism_places
-- ============================================================
create table if not exists public.tourism_places (
  place_id      uuid primary key default uuid_generate_v4(),
  place_name    text not null,
  description   text,
  state         text not null,
  district      text,
  city          text not null,
  category      text not null default 'Historical',
  subcategory   text,
  latitude      double precision not null,
  longitude     double precision not null,
  images        text[] default '{}',
  entry_fee_indian     numeric(10,2) default 0,
  entry_fee_foreigner  numeric(10,2) default 0,
  timings       text,
  best_season   text,
  best_months   text[] default '{}',
  safety_guidelines    text[] default '{}',
  tourist_tips  text[] default '{}',
  tier          integer default 2 check (tier in (1,2,3)),
  featured      boolean default false,
  rating        numeric(3,1) default 0.0 check (rating >= 0 and rating <= 5),
  is_popular    boolean default false,
  is_hidden     boolean not null default false,
  likes_count   integer not null default 1000 check (likes_count >= 0),
  visit_duration_minutes integer,
  address       text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_tourism_places_category on public.tourism_places(category);
create index if not exists idx_tourism_places_city on public.tourism_places(city);
create index if not exists idx_tourism_places_state on public.tourism_places(state);
create index if not exists idx_tourism_places_featured on public.tourism_places(featured);
create index if not exists idx_tourism_places_popular on public.tourism_places(is_popular);
create index if not exists idx_tourism_places_hidden on public.tourism_places(is_hidden);
create index if not exists idx_tourism_places_tier on public.tourism_places(tier);
create index if not exists idx_tourism_places_rating on public.tourism_places(rating desc);
create index if not exists idx_tourism_places_likes on public.tourism_places(likes_count desc);
create index if not exists idx_tourism_places_location on public.tourism_places(latitude, longitude);

-- Full text search index
create index if not exists idx_tourism_places_fts on public.tourism_places
  using gin(to_tsvector('english', coalesce(place_name,'') || ' ' || coalesce(city,'') || ' ' || coalesce(state,'') || ' ' || coalesce(category,'')));

-- ============================================================
-- TABLE: favorites
-- ============================================================
create table if not exists public.favorites (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  place_id   uuid not null references public.tourism_places(place_id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, place_id)
);

create index if not exists idx_favorites_user_id on public.favorites(user_id);
create index if not exists idx_favorites_place_id on public.favorites(place_id);

-- ============================================================
-- TABLE: tourism_place_likes
-- ============================================================
create table if not exists public.tourism_place_likes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id uuid not null references public.tourism_places(place_id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, place_id)
);

create index if not exists idx_tourism_place_likes_user_id on public.tourism_place_likes(user_id);
create index if not exists idx_tourism_place_likes_place_id on public.tourism_place_likes(place_id);

-- ============================================================
-- TABLE: app_settings
-- ============================================================
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

-- ============================================================
-- TABLE: guide_profiles
-- ============================================================
create table if not exists public.guide_profiles (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  photo_url text,
  phone text,
  languages text,
  experience_years integer
    check (experience_years is null or experience_years >= 0),
  bio text,
  charge_amount numeric(10,2)
    check (charge_amount is null or charge_amount >= 0),
  charge_currency text not null default 'INR',
  meeting_point text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists guide_profiles_active_idx
  on public.guide_profiles(is_active);
create index if not exists guide_profiles_name_idx
  on public.guide_profiles(name);

-- ============================================================
-- TABLE: guide_requests
-- ============================================================
create table if not exists public.guide_requests (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete set null,
  user_email text,
  place_id uuid references public.tourism_places(place_id) on delete set null,
  place_name text not null,
  city text not null default 'Delhi',
  travelers integer not null default 1 check (travelers between 1 and 20),
  contact_note text,
  status text not null default 'processing'
    check (status in ('pending', 'processing', 'confirmed', 'rejected', 'completed')),
  requested_at timestamptz not null default now(),
  expected_by timestamptz not null default (now() + interval '7 days'),
  admin_note text,
  admin_whatsapp text not null default '9625119731',
  admin_email text not null default 'abhishek.work962511@gmail.com',
  guide_profile_id uuid references public.guide_profiles(id) on delete set null,
  guide_name text,
  guide_photo_url text,
  guide_phone text,
  guide_languages text,
  guide_experience_years integer
    check (guide_experience_years is null or guide_experience_years >= 0),
  guide_bio text,
  guide_charge_amount numeric(10,2)
    check (guide_charge_amount is null or guide_charge_amount >= 0),
  guide_charge_currency text not null default 'INR',
  guide_meeting_point text,
  booking_status text not null default 'not_booked'
    check (booking_status in ('not_booked', 'booked', 'cancelled')),
  booked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists guide_requests_user_id_idx
  on public.guide_requests(user_id);
create index if not exists guide_requests_status_idx
  on public.guide_requests(status);
create index if not exists guide_requests_city_idx
  on public.guide_requests(city);
create index if not exists guide_requests_requested_at_idx
  on public.guide_requests(requested_at desc);
create index if not exists guide_requests_booking_status_idx
  on public.guide_requests(booking_status);
create index if not exists guide_requests_guide_profile_id_idx
  on public.guide_requests(guide_profile_id);

-- ============================================================
-- TABLES: hotel booking module
-- ============================================================
create table if not exists public.hotel_bookings (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  hotel_id text not null,
  hotel_name text not null,
  hotel_image_url text,
  room_type text not null,
  check_in date not null,
  check_out date not null,
  guests integer not null default 1 check (guests between 1 and 20),
  total_price numeric(12,2) not null check (total_price >= 0),
  currency text not null default 'INR',
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'cancelled', 'completed', 'redirected')),
  affiliate_id text,
  partner_source text,
  partner_booking_id text,
  confirmation_code text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hotel_analytics_events (
  id uuid primary key,
  user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  hotel_id text,
  session_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.hotel_affiliate_clicks (
  id uuid primary key,
  click_id uuid not null unique,
  user_id uuid references auth.users(id) on delete set null,
  hotel_id text not null,
  partner_source text not null,
  affiliate_id text not null,
  session_id text,
  outcome text not null default 'clicked'
    check (outcome in ('clicked', 'viewed', 'bookingStarted', 'bookingCompleted', 'bookingFailed')),
  commission_amount numeric(12,2),
  booking_id uuid references public.hotel_bookings(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hotels_cache (
  id text primary key,
  name text not null,
  city text,
  price numeric(12,2),
  rating numeric(3,1),
  image text,
  source text,
  partner_hotel_id text,
  cached_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists hotel_bookings_user_id_idx
  on public.hotel_bookings(user_id, created_at desc);
create index if not exists hotel_analytics_events_created_at_idx
  on public.hotel_analytics_events(created_at desc);
create index if not exists hotel_affiliate_clicks_user_id_idx
  on public.hotel_affiliate_clicks(user_id, created_at desc);
create index if not exists hotels_cache_city_idx
  on public.hotels_cache(city);

-- ============================================================
-- ADMIN HELPERS
-- ============================================================
create or replace function public.is_unisafex_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) =
    'abhishek.work962511@gmail.com';
$$;

revoke all on function public.is_unisafex_admin() from public;
grant execute on function public.is_unisafex_admin() to authenticated;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- profiles: users can only read/write their own profile
alter table public.profiles enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "profiles_delete_own" on public.profiles
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- tourism_places: public read, admin write
alter table public.tourism_places enable row level security;

drop policy if exists "tourism_places_public_read" on public.tourism_places;

create policy "tourism_places_public_read" on public.tourism_places
  for select
  to anon, authenticated
  using (is_hidden = false);

drop policy if exists tourism_places_admin_write on public.tourism_places;

create policy tourism_places_admin_write
  on public.tourism_places
  for all
  to authenticated
  using (public.is_unisafex_admin())
  with check (public.is_unisafex_admin());

-- tourism_place_likes: users can like each destination once
alter table public.tourism_place_likes enable row level security;

grant select, insert, delete on public.tourism_place_likes to authenticated;

drop policy if exists "tourism_place_likes_select_own" on public.tourism_place_likes;
drop policy if exists "tourism_place_likes_insert_own" on public.tourism_place_likes;
drop policy if exists "tourism_place_likes_delete_own" on public.tourism_place_likes;

create policy "tourism_place_likes_select_own" on public.tourism_place_likes
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "tourism_place_likes_insert_own" on public.tourism_place_likes
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "tourism_place_likes_delete_own" on public.tourism_place_likes
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- app_settings: public read, admin write
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

-- guide_requests: users see their own requests, admin manages all requests
alter table public.guide_requests enable row level security;

grant select, insert, update, delete on public.guide_requests to authenticated;

drop policy if exists guide_requests_select_own_or_admin on public.guide_requests;
drop policy if exists guide_requests_insert_own on public.guide_requests;
drop policy if exists guide_requests_admin_update on public.guide_requests;
drop policy if exists guide_requests_admin_delete on public.guide_requests;

create policy guide_requests_select_own_or_admin
  on public.guide_requests
  for select
  to authenticated
  using ((select auth.uid()) = user_id or public.is_unisafex_admin());

create policy guide_requests_insert_own
  on public.guide_requests
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy guide_requests_admin_update
  on public.guide_requests
  for update
  to authenticated
  using (public.is_unisafex_admin())
  with check (public.is_unisafex_admin());

create policy guide_requests_admin_delete
  on public.guide_requests
  for delete
  to authenticated
  using (public.is_unisafex_admin());

-- guide_profiles: admin-only saved guide catalog
alter table public.guide_profiles enable row level security;

grant select, insert, update, delete on public.guide_profiles to authenticated;

drop policy if exists guide_profiles_admin_read on public.guide_profiles;
drop policy if exists guide_profiles_admin_write on public.guide_profiles;

create policy guide_profiles_admin_read
  on public.guide_profiles
  for select
  to authenticated
  using (public.is_unisafex_admin());

create policy guide_profiles_admin_write
  on public.guide_profiles
  for all
  to authenticated
  using (public.is_unisafex_admin())
  with check (public.is_unisafex_admin());

-- hotel booking module: users own bookings, admin sees operational data
alter table public.hotel_bookings enable row level security;
alter table public.hotel_analytics_events enable row level security;
alter table public.hotel_affiliate_clicks enable row level security;
alter table public.hotels_cache enable row level security;

grant select, insert, update on public.hotel_bookings to authenticated;
grant insert on public.hotel_analytics_events to anon, authenticated;
grant select on public.hotel_analytics_events to authenticated;
grant insert, update on public.hotel_affiliate_clicks to anon, authenticated;
grant select on public.hotel_affiliate_clicks to authenticated;
grant select, insert, update, delete on public.hotels_cache to authenticated;

drop policy if exists hotel_bookings_select_own_or_admin on public.hotel_bookings;
drop policy if exists hotel_bookings_insert_own on public.hotel_bookings;
drop policy if exists hotel_bookings_update_own_or_admin on public.hotel_bookings;
drop policy if exists hotel_analytics_insert_client on public.hotel_analytics_events;
drop policy if exists hotel_analytics_select_admin on public.hotel_analytics_events;
drop policy if exists hotel_affiliate_insert_client on public.hotel_affiliate_clicks;
drop policy if exists hotel_affiliate_select_own_or_admin on public.hotel_affiliate_clicks;
drop policy if exists hotel_affiliate_update_own_or_admin on public.hotel_affiliate_clicks;
drop policy if exists hotels_cache_admin_write on public.hotels_cache;
drop policy if exists hotels_cache_public_read on public.hotels_cache;

create policy hotel_bookings_select_own_or_admin
  on public.hotel_bookings
  for select
  to authenticated
  using ((select auth.uid()) = user_id or public.is_unisafex_admin());

create policy hotel_bookings_insert_own
  on public.hotel_bookings
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy hotel_bookings_update_own_or_admin
  on public.hotel_bookings
  for update
  to authenticated
  using ((select auth.uid()) = user_id or public.is_unisafex_admin())
  with check ((select auth.uid()) = user_id or public.is_unisafex_admin());

create policy hotel_analytics_insert_client
  on public.hotel_analytics_events
  for insert
  to anon, authenticated
  with check (user_id is null or (select auth.uid()) = user_id);

create policy hotel_analytics_select_admin
  on public.hotel_analytics_events
  for select
  to authenticated
  using (public.is_unisafex_admin());

create policy hotel_affiliate_insert_client
  on public.hotel_affiliate_clicks
  for insert
  to anon, authenticated
  with check (user_id is null or (select auth.uid()) = user_id);

create policy hotel_affiliate_select_own_or_admin
  on public.hotel_affiliate_clicks
  for select
  to authenticated
  using ((select auth.uid()) = user_id or public.is_unisafex_admin());

create policy hotel_affiliate_update_own_or_admin
  on public.hotel_affiliate_clicks
  for update
  to authenticated
  using ((select auth.uid()) = user_id or public.is_unisafex_admin())
  with check ((select auth.uid()) = user_id or public.is_unisafex_admin());

create policy hotels_cache_public_read
  on public.hotels_cache
  for select
  to anon, authenticated
  using (true);

create policy hotels_cache_admin_write
  on public.hotels_cache
  for all
  to authenticated
  using (public.is_unisafex_admin())
  with check (public.is_unisafex_admin());

-- favorites: users can only access their own favorites
alter table public.favorites enable row level security;

drop policy if exists "favorites_select_own" on public.favorites;
drop policy if exists "favorites_insert_own" on public.favorites;
drop policy if exists "favorites_delete_own" on public.favorites;

create policy "favorites_select_own" on public.favorites
  for select using (auth.uid() = user_id);

create policy "favorites_insert_own" on public.favorites
  for insert with check (auth.uid() = user_id);

create policy "favorites_delete_own" on public.favorites
  for delete using (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_updated_at on public.profiles;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

drop trigger if exists tourism_places_updated_at on public.tourism_places;

create trigger tourism_places_updated_at
  before update on public.tourism_places
  for each row execute function public.handle_updated_at();

drop trigger if exists guide_requests_updated_at on public.guide_requests;

create trigger guide_requests_updated_at
  before update on public.guide_requests
  for each row execute function public.handle_updated_at();

drop trigger if exists guide_profiles_updated_at on public.guide_profiles;

create trigger guide_profiles_updated_at
  before update on public.guide_profiles
  for each row execute function public.handle_updated_at();

drop trigger if exists app_settings_updated_at on public.app_settings;

create trigger app_settings_updated_at
  before update on public.app_settings
  for each row execute function public.handle_updated_at();

drop trigger if exists hotel_bookings_updated_at on public.hotel_bookings;

create trigger hotel_bookings_updated_at
  before update on public.hotel_bookings
  for each row execute function public.handle_updated_at();

drop trigger if exists hotel_affiliate_clicks_updated_at on public.hotel_affiliate_clicks;

create trigger hotel_affiliate_clicks_updated_at
  before update on public.hotel_affiliate_clicks
  for each row execute function public.handle_updated_at();

drop trigger if exists hotels_cache_updated_at on public.hotels_cache;

create trigger hotels_cache_updated_at
  before update on public.hotels_cache
  for each row execute function public.handle_updated_at();

create or replace function public.book_guide_request(p_request_id uuid)
returns public.guide_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request public.guide_requests;
begin
  update public.guide_requests
  set booking_status = 'booked',
      booked_at = coalesce(booked_at, now()),
      updated_at = now()
  where id = p_request_id
    and user_id = auth.uid()
    and status = 'confirmed'
    and guide_name is not null
    and guide_charge_amount is not null
    and booking_status <> 'booked'
  returning * into v_request;

  if v_request.id is null then
    raise exception 'Guide request is not ready for booking'
      using errcode = 'P0001';
  end if;

  return v_request;
end;
$$;

revoke all on function public.book_guide_request(uuid) from public;
grant execute on function public.book_guide_request(uuid) to authenticated;

create or replace function public.like_tourism_place(p_place_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_inserted integer := 0;
  v_likes integer := 1000;
begin
  if v_user_id is null then
    raise exception 'Login required to like a place'
      using errcode = '28000';
  end if;

  insert into public.tourism_place_likes (user_id, place_id)
  values (v_user_id, p_place_id)
  on conflict (user_id, place_id) do nothing;

  get diagnostics v_inserted = row_count;

  if v_inserted = 1 then
    update public.tourism_places
    set likes_count = greatest(coalesce(likes_count, 1000), 1000) + 1
    where place_id = p_place_id
    returning likes_count into v_likes;
  else
    select greatest(coalesce(likes_count, 1000), 1000)
    into v_likes
    from public.tourism_places
    where place_id = p_place_id;
  end if;

  return coalesce(v_likes, 1000);
end;
$$;

grant execute on function public.like_tourism_place(uuid) to authenticated;

create or replace function public.toggle_tourism_place_like(p_place_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_changed integer := 0;
  v_likes integer := 1000;
  v_liked boolean := false;
begin
  if v_user_id is null then
    raise exception 'Login required to update a place like'
      using errcode = '28000';
  end if;

  delete from public.tourism_place_likes
  where user_id = v_user_id
    and place_id = p_place_id;

  get diagnostics v_changed = row_count;

  if v_changed = 1 then
    update public.tourism_places
    set likes_count = greatest(coalesce(likes_count, 1000) - 1, 1000)
    where place_id = p_place_id
    returning likes_count into v_likes;
    v_liked := false;
  else
    insert into public.tourism_place_likes (user_id, place_id)
    values (v_user_id, p_place_id)
    on conflict (user_id, place_id) do nothing;

    get diagnostics v_changed = row_count;

    if v_changed = 1 then
      update public.tourism_places
      set likes_count = greatest(coalesce(likes_count, 1000), 1000) + 1
      where place_id = p_place_id
      returning likes_count into v_likes;
    else
      select greatest(coalesce(likes_count, 1000), 1000)
      into v_likes
      from public.tourism_places
      where place_id = p_place_id;
    end if;
    v_liked := true;
  end if;

  if v_likes is null then
    raise exception 'Place not found'
      using errcode = 'P0002';
  end if;

  return jsonb_build_object(
    'likes_count', v_likes,
    'liked', v_liked
  );
end;
$$;

revoke all on function public.toggle_tourism_place_like(uuid) from public;
revoke all on function public.toggle_tourism_place_like(uuid) from anon;
grant execute on function public.toggle_tourism_place_like(uuid) to authenticated;

-- Auto-create profile on user signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, email)
  values (new.id, new.email)
  on conflict (user_id) do update
    set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists on_auth_user_email_updated on auth.users;

create trigger on_auth_user_email_updated
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_new_user();

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

insert into storage.buckets (id, name, public)
values ('user-media', 'user-media', true)
on conflict (id) do nothing;

drop policy if exists "user_media_public_read" on storage.objects;
drop policy if exists "user_media_auth_upload" on storage.objects;
drop policy if exists "user_media_own_delete" on storage.objects;
drop policy if exists "user_media_own_update" on storage.objects;

create policy "user_media_public_read" on storage.objects
  for select using (bucket_id = 'user-media');

create policy "user_media_auth_upload" on storage.objects
  for insert with check (
    bucket_id = 'user-media'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "user_media_own_delete" on storage.objects
  for delete using (
    bucket_id = 'user-media'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "user_media_own_update" on storage.objects
  for update using (
    bucket_id = 'user-media'
    and auth.uid()::text = (storage.foldername(name))[2]
  )
  with check (
    bucket_id = 'user-media'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

insert into storage.buckets (id, name, public)
values ('tourism-media', 'tourism-media', true)
on conflict (id) do update set public = true;

drop policy if exists "tourism_media_public_read" on storage.objects;
drop policy if exists "tourism_media_admin_insert" on storage.objects;
drop policy if exists "tourism_media_admin_update" on storage.objects;
drop policy if exists "tourism_media_admin_delete" on storage.objects;

create policy "tourism_media_public_read" on storage.objects
  for select using (bucket_id = 'tourism-media');

create policy "tourism_media_admin_insert" on storage.objects
  for insert with check (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  );

create policy "tourism_media_admin_update" on storage.objects
  for update using (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  );

create policy "tourism_media_admin_delete" on storage.objects
  for delete using (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  );

-- ============================================================
-- SEED DATA — Popular Indian Tourist Places
-- ============================================================

insert into public.tourism_places (
  place_name, description, state, district, city, category,
  latitude, longitude, images, entry_fee_indian, entry_fee_foreigner,
  timings, best_season, best_months, safety_guidelines, tourist_tips,
  tier, featured, rating, is_popular, visit_duration_minutes
) values

-- TIER 1: UNESCO & Iconic
(
  'Taj Mahal',
  'The Taj Mahal is an ivory-white marble mausoleum on the right bank of the Yamuna river in Agra. Commissioned in 1632 by the Mughal emperor Shah Jahan to house the tomb of his beloved wife Mumtaz Mahal, it is one of the Seven Wonders of the World and a UNESCO World Heritage Site.',
  'Uttar Pradesh', 'Agra', 'Agra', 'Historical',
  27.1751, 78.0421,
  ARRAY['https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800','https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800'],
  50, 1100,
  'Sunrise to Sunset (Closed on Fridays)',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Keep your belongings secure in crowded areas','Hire only government-approved guides','Avoid touts outside the main entrance','Store valuables in hotel safes'],
  ARRAY['Visit at sunrise for the best light and fewer crowds','The Taj changes color throughout the day — magical at dusk','Buy tickets online to avoid long queues','Remove shoes before entering the mausoleum'],
  1, true, 4.8, true, 180
),

(
  'Qutub Minar',
  'Qutub Minar is a UNESCO World Heritage Site located in Delhi. At 72.5 meters, it is the tallest brick minaret in the world, built in the early 13th century by Qutub-ud-Din Aibak. The complex contains several historically significant structures from the Slave Dynasty era.',
  'Delhi', 'South Delhi', 'New Delhi', 'Historical',
  28.5245, 77.1855,
  ARRAY['https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800'],
  30, 500,
  '7:00 AM to 5:00 PM',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Be cautious of pickpockets in crowded areas','Stay on designated paths','Wear comfortable walking shoes'],
  ARRAY['Combine with a visit to Humayun Tomb nearby','Early morning visits are less crowded','Audio guides available at the entrance'],
  1, true, 4.5, true, 120
),

(
  'Jaipur City Palace',
  'The City Palace of Jaipur is a palace complex in Jaipur, the capital of Rajasthan state. It was the seat of the Maharaja of Jaipur. Built between 1729 and 1732, the complex includes the Chandra Mahal and Mubarak Mahal palaces, several buildings, courtyards and temples.',
  'Rajasthan', 'Jaipur', 'Jaipur', 'Historical',
  26.9258, 75.8237,
  ARRAY['https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800','https://images.unsplash.com/photo-1477587458883-47145ed31459?w=800'],
  200, 700,
  '9:30 AM to 5:00 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Dress modestly when visiting royal residences','Respect photography restrictions inside museums','Bargain at local shops but be respectful'],
  ARRAY['Buy a combined ticket for multiple palaces','The royal family still resides in a portion of the palace','Guided tours give fascinating historical context'],
  1, true, 4.6, true, 150
),

(
  'Hawa Mahal',
  'Hawa Mahal, the Palace of Winds, is a palace in Jaipur built of red and pink sandstone. It was built in 1799 by Maharaja Sawai Pratap Singh. The five-story exterior is akin to a honeycomb with 953 small windows called Jharokhas decorated with intricate latticework.',
  'Rajasthan', 'Jaipur', 'Jaipur', 'Historical',
  26.9239, 75.8267,
  ARRAY['https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=800'],
  50, 200,
  '9:00 AM to 4:30 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Be cautious of overpriced autorickshaws','Watch out for touts near entrance'],
  ARRAY['View from the street is free and spectacular','Best photographed in morning light from across the road','Small but intricate interior worth exploring'],
  1, true, 4.4, true, 90
),

(
  'Kerala Backwaters',
  'The Kerala Backwaters are a network of interconnected canals, rivers, lakes, and inlets formed by more than 900 km of waterways. A houseboat cruise through the backwaters offers a tranquil experience of local life, fishing villages, and lush coconut palms.',
  'Kerala', 'Alappuzha', 'Alleppey', 'Nature',
  9.4981, 76.3388,
  ARRAY['https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800','https://images.unsplash.com/photo-1593693411515-c20261bcad6e?w=800'],
  0, 0,
  'All day',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Book certified houseboats only','Carry mosquito repellent','Stay hydrated in humid weather','Keep documents safe on water'],
  ARRAY['Book houseboats at least a week in advance','Sunrise and sunset on the backwaters are stunning','Try the traditional Kerala meal served on banana leaf'],
  1, true, 4.7, true, 480
),

(
  'Varanasi Ghats',
  'Varanasi is one of the oldest living cities in the world. The ghats along the Ganges River are the spiritual heart of the city. Over 80 ghats line the riverfront, built mainly in the 18th century by Maratha rulers. The Ganga Aarti ceremony at Dashashwamedh Ghat is a mesmerizing spectacle.',
  'Uttar Pradesh', 'Varanasi', 'Varanasi', 'Spiritual',
  25.3176, 83.0062,
  ARRAY['https://images.unsplash.com/photo-1561361058-c24e01f57a5c?w=800'],
  0, 0,
  'All day (Aarti at sunrise and sunset)',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Be respectful at cremation ghats','Do not photograph cremation ceremonies without permission','Hire only licensed boat operators for river rides','Be cautious of aggressive touts'],
  ARRAY['Witness the Ganga Aarti at Dashashwamedh Ghat','Take a boat ride at dawn for a spiritual experience','Explore the narrow alleys of the old city'],
  1, true, 4.6, true, 240
),

(
  'Hampi Ruins',
  'Hampi is a UNESCO World Heritage Site in Karnataka. The ruins of Vijayanagara, the former capital of the Vijayanagara Empire, spread across 4,100 hectares. The landscape of giant boulders and ancient temples is both surreal and historically profound.',
  'Karnataka', 'Vijayanagara', 'Hampi', 'Historical',
  15.3350, 76.4600,
  ARRAY['https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800'],
  40, 600,
  'Sunrise to Sunset',
  'October to February',
  ARRAY['October','November','December','January','February'],
  ARRAY['Carry plenty of water — limited facilities','Wear sun protection','Stick to known trails','Register at archaeological survey checkpoints'],
  ARRAY['Rent a bicycle to explore the spread-out ruins','The Virupaksha Temple is the spiritual center','Matanga Hill offers a stunning panoramic view'],
  1, true, 4.7, true, 360
),

(
  'Goa Beaches',
  'Goa, India''s smallest state, is famous for its beaches, Portuguese heritage, and vibrant nightlife. From the popular Baga and Calangute in North Goa to the serene Palolem and Agonda in South Goa, there is a beach for every type of traveler.',
  'Goa', 'North Goa', 'Panaji', 'Nature',
  15.2993, 74.1240,
  ARRAY['https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800','https://images.unsplash.com/photo-1571406252241-db0280bd36cd?w=800'],
  0, 0,
  'All day',
  'November to February',
  ARRAY['November','December','January','February'],
  ARRAY['Beware of strong currents and rip tides','Swim only in designated areas with lifeguards','Keep valuables locked in hotel','Be cautious on isolated beaches at night'],
  ARRAY['South Goa beaches are quieter and cleaner','Rent a scooter to explore at your own pace','Try fresh seafood at shacks on the beach','Anjuna flea market on Wednesdays is a must-visit'],
  1, true, 4.5, true, 300
),

(
  'Ranthambore National Park',
  'Ranthambore National Park in Rajasthan is one of the best places in India to see wild Bengal tigers. The park covers 392 sq km and is home to leopards, sloth bears, crocodiles, and diverse bird species, all set against the dramatic backdrop of ancient ruins.',
  'Rajasthan', 'Sawai Madhopur', 'Sawai Madhopur', 'Wildlife',
  26.0173, 76.5026,
  ARRAY['https://images.unsplash.com/photo-1602555553795-3e9ce56ea70d?w=800'],
  200, 1200,
  'Safari: 6:30 AM - 10:00 AM, 2:30 PM - 6:00 PM',
  'October to June',
  ARRAY['October','November','December','January','February','March','April','May'],
  ARRAY['Never get out of the safari vehicle','Keep noise to minimum','Do not feed animals','Book safaris in advance — limited daily entry'],
  ARRAY['Book gypsies (open jeeps) for better viewing than canters','Morning safaris have higher tiger sighting probability','Zone 3, 4, and 5 have the highest tiger density','Bring binoculars and a telephoto lens'],
  1, true, 4.6, true, 210
),

(
  'Amer Fort',
  'Amer Fort, also known as Amber Fort, is a fort located in Amer, Rajasthan. The fort was built by Raja Man Singh I in 1592. This magnificent fort is a blend of Rajput and Mughal architecture, with beautiful Sheesh Mahal (Hall of Mirrors) and artistic gateways.',
  'Rajasthan', 'Jaipur', 'Jaipur', 'Historical',
  26.9855, 75.8513,
  ARRAY['https://images.unsplash.com/photo-1477587458883-47145ed31459?w=800'],
  100, 500,
  '8:00 AM to 5:30 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Avoid elephant rides — they are controversial','Stay hydrated — lots of walking involved','Official guides are recommended for historical context'],
  ARRAY['Visit early morning to beat the heat and crowds','The light show in the evening is spectacular','Combine with Jaigarh Fort via the walking tunnel'],
  1, true, 4.7, true, 180
),

-- TIER 2: Popular destinations
(
  'Gateway of India',
  'The Gateway of India is an arch monument built during the 20th century in Mumbai. Overlooking the Arabian Sea, it was erected to commemorate the landing of King George V and Queen Mary at Apollo Bunder in Mumbai. It is the most iconic landmark of the financial capital of India.',
  'Maharashtra', 'Mumbai', 'Mumbai', 'Historical',
  18.9220, 72.8347,
  ARRAY['https://images.unsplash.com/photo-1529253355930-ddbe423a2ac7?w=800'],
  0, 0,
  'Open 24 hours',
  'November to February',
  ARRAY['November','December','January','February'],
  ARRAY['Watch out for pickpockets in crowded areas','Be careful near the waterfront','Avoid unlicensed boat operators for Elephanta Island'],
  ARRAY['Best visited early morning or at sunset','Take the ferry to Elephanta Caves from here','The Taj Mahal Palace Hotel opposite is iconic'],
  2, true, 4.3, true, 60
),

(
  'India Gate',
  'India Gate is a war memorial located astride the Rajpath, on the eastern edge of the ceremonial axis of New Delhi. India Gate is a tribute to 70,000 soldiers of the British Indian Army who died in various wars between 1914 and 1919.',
  'Delhi', 'New Delhi', 'New Delhi', 'Historical',
  28.6129, 77.2295,
  ARRAY['https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800'],
  0, 0,
  'Open 24 hours',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Beware of touts and hawkers','Keep bags zipped in crowds'],
  ARRAY['Illuminated beautifully at night','The lawns are perfect for an evening picnic','Combine with Rashtrapati Bhavan visit nearby'],
  2, true, 4.4, true, 90
),

(
  'Mysore Palace',
  'Mysore Palace, also known as Amba Vilas Palace, is a historical palace and a royal residence located in Mysore, Karnataka. It is one of the largest palaces in India. The palace is the seat of the Wadiyar dynasty and was the official residence of the Maharaja of Mysore.',
  'Karnataka', 'Mysuru', 'Mysore', 'Historical',
  12.3051, 76.6551,
  ARRAY['https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?w=800'],
  70, 200,
  '10:00 AM to 5:30 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Dress modestly — shoulders and knees covered','Shoes must be removed before entering','Cameras not allowed inside'],
  ARRAY['The palace is lit up with 97,000 bulbs on Sundays and holidays','Visit during Dasara festival for a spectacular display','Audio guides available in multiple languages'],
  2, true, 4.6, true, 120
),

(
  'Lotus Temple',
  'The Lotus Temple, located in New Delhi, is a Bahai House of Worship. Notable for its lotus-shaped architecture, it has won numerous architectural awards and been featured extensively in newspaper and magazine articles. All are welcome to visit regardless of religion.',
  'Delhi', 'New Delhi', 'New Delhi', 'Spiritual',
  28.5535, 77.2588,
  ARRAY['https://images.unsplash.com/photo-1597598490771-41d6c5b28a71?w=800'],
  0, 0,
  '9:00 AM to 5:30 PM (closed Mondays)',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Silence must be maintained inside','All religions welcome','Long queues on weekends — arrive early'],
  ARRAY['Free entry for everyone','Meditation is practiced inside','The gardens around the temple are beautiful'],
  2, true, 4.5, true, 75
),

(
  'Jim Corbett National Park',
  'Jim Corbett National Park is the oldest national park in India, established in 1936. Located in Uttarakhand, it protects the Bengal tiger and hosts a rich variety of wildlife including elephants, leopards, deer, and over 600 species of birds.',
  'Uttarakhand', 'Nainital', 'Ramnagar', 'Wildlife',
  29.5300, 78.7747,
  ARRAY['https://images.unsplash.com/photo-1602555553795-3e9ce56ea70d?w=800'],
  150, 900,
  'Safari: Dawn and Dusk zones',
  'November to June',
  ARRAY['November','December','January','February','March','April','May','June'],
  ARRAY['Book safaris well in advance','Never leave the vehicle during safari','Dhikala zone requires overnight stay permits','Follow park rules strictly'],
  ARRAY['Dhikala zone offers the best wildlife experience','Elephant safaris offer a unique vantage point','Bird watching is excellent near the river'],
  2, true, 4.5, true, 240
),

(
  'Ajanta Caves',
  'The Ajanta Caves are approximately 30 rock-cut Buddhist cave monuments dating from the 2nd century BC to about 480 CE in Aurangabad district of Maharashtra. The cave paintings are the finest surviving examples of Indian art from antiquity.',
  'Maharashtra', 'Aurangabad', 'Aurangabad', 'Historical',
  20.5519, 75.7033,
  ARRAY['https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800'],
  40, 600,
  '9:00 AM to 5:30 PM (Closed Mondays)',
  'November to March',
  ARRAY['November','December','January','February','March'],
  ARRAY['Photography with flash strictly prohibited inside caves','Wear comfortable shoes for uneven terrain','Carry water — limited facilities'],
  ARRAY['Hire a licensed guide to understand the cave paintings','Visit Ellora Caves on the same trip (65 km away)','Cave 1 and 2 have the most spectacular paintings'],
  1, true, 4.6, true, 240
),

(
  'Ellora Caves',
  'The Ellora Caves are a UNESCO World Heritage Site in Maharashtra. Representing Buddhist, Hindu and Jain rock-cut temples and monasteries, the 34 caves were built between the 6th and 11th centuries CE. The Kailasa Temple (Cave 16) is the world''s largest rock-cut structure.',
  'Maharashtra', 'Aurangabad', 'Aurangabad', 'Spiritual',
  20.0258, 75.1780,
  ARRAY['https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800'],
  40, 600,
  '6:00 AM to 6:00 PM (Closed Tuesdays)',
  'November to March',
  ARRAY['November','December','January','February','March'],
  ARRAY['Wear modest clothing','Respect the religious significance of caves','Photography allowed but no flash'],
  ARRAY['Start with Cave 16 (Kailasa Temple) — the most impressive','Combine with Ajanta Caves visit (100 km away)','Early morning visit recommended for fewer crowds'],
  1, true, 4.7, true, 300
),

(
  'Munnar Tea Gardens',
  'Munnar is a hill station and tea county in the Western Ghats mountain range in Kerala. The tea gardens of Munnar stretch over 60,000 hectares covering the hills of Munnar, Devikulam and Peerumade. The lush green landscape is spectacular year-round.',
  'Kerala', 'Idukki', 'Munnar', 'Nature',
  10.0889, 77.0595,
  ARRAY['https://images.unsplash.com/photo-1571803241078-c7b5b0571e85?w=800','https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800'],
  0, 0,
  'All day',
  'September to May',
  ARRAY['September','October','November','December','January','February','March','April'],
  ARRAY['Roads can be foggy and dangerous — drive carefully','Beware of leeches during monsoon season','Stay on designated hiking trails'],
  ARRAY['Visit a tea factory for a fascinating tour','The Eravikulam National Park has Nilgiri Tahr sightings','Top Station viewpoint offers incredible views into Kerala'],
  2, true, 4.6, true, 360
);

update public.tourism_places
set address = concat_ws(', ', nullif(city, ''), nullif(state, ''))
where address is null or btrim(address) = '';

-- Verify seed data
select count(*) as total_places from public.tourism_places;
select category, count(*) as count from public.tourism_places group by category order by count desc;
