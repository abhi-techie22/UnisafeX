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
create index if not exists hotels_cache_city_idx on public.hotels_cache(city);

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

drop policy if exists tourism_places_admin_write on public.tourism_places;
create policy tourism_places_admin_write
  on public.tourism_places
  for all
  to authenticated
  using (public.is_unisafex_admin())
  with check (public.is_unisafex_admin());

drop policy if exists "user_media_own_update" on storage.objects;
drop policy if exists "user_media_auth_upload" on storage.objects;

create policy "user_media_auth_upload" on storage.objects
  for insert with check (
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
