-- Reviews, bucket-list metadata, and stricter admin checks.

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
  select p_user_id is not null
    and exists (
      select 1
      from public.admin_users au
      where au.user_id = p_user_id
        and au.is_active = true
    );
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

create or replace function public.is_owner(p_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null
    and exists (
      select 1
      from public.admin_users au
      where au.user_id = p_user_id
        and au.role = 'owner'
        and au.is_active = true
    );
$$;

revoke all on function public.is_admin(uuid) from public;
revoke all on function public.is_admin(uuid) from anon;
revoke all on function public.is_unisafex_admin() from public;
revoke all on function public.is_unisafex_admin() from anon;
revoke all on function public.is_owner(uuid) from public;
revoke all on function public.is_owner(uuid) from anon;
grant execute on function public.is_admin(uuid) to authenticated;
grant execute on function public.is_unisafex_admin() to authenticated;
grant execute on function public.is_owner(uuid) to authenticated;

create or replace function public.handle_updated_at()
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

alter table public.favorites
  add column if not exists status text not null default 'saved'
    check (status in ('saved', 'planned', 'completed')),
  add column if not exists notes text,
  add column if not exists planned_visit_date date,
  add column if not exists completed_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_favorites_status
  on public.favorites(user_id, status, updated_at desc);

drop trigger if exists favorites_updated_at on public.favorites;
create trigger favorites_updated_at
  before update on public.favorites
  for each row execute function public.handle_updated_at();

drop policy if exists "favorites_update_own" on public.favorites;
create policy "favorites_update_own" on public.favorites
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create table if not exists public.tourism_place_reviews (
  id uuid primary key default uuid_generate_v4(),
  place_id uuid not null references public.tourism_places(place_id)
    on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  title text,
  body text,
  image_urls text[] not null default '{}',
  visit_date date,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  admin_note text,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, place_id)
);

alter table public.tourism_place_reviews
  add column if not exists image_urls text[] not null default '{}';

insert into public.app_settings(key, value)
values (
  'review_moderation',
  '{"reviews_require_approval": true, "images_require_approval": true}'::jsonb
)
on conflict (key) do update
set value = excluded.value || public.app_settings.value,
    updated_at = now();

drop policy if exists app_settings_public_read on public.app_settings;
create policy app_settings_public_read
  on public.app_settings
  for select
  to anon, authenticated
  using (
    key in (
      'maps_config',
      'auth_config',
      'currency_rates',
      'review_moderation'
    )
  );

create index if not exists tourism_place_reviews_place_status_idx
  on public.tourism_place_reviews(place_id, status, created_at desc);
create index if not exists tourism_place_reviews_user_idx
  on public.tourism_place_reviews(user_id, created_at desc);
create index if not exists tourism_place_reviews_reviewed_by_idx
  on public.tourism_place_reviews(reviewed_by);

drop trigger if exists tourism_place_reviews_updated_at
  on public.tourism_place_reviews;
create trigger tourism_place_reviews_updated_at
  before update on public.tourism_place_reviews
  for each row execute function public.handle_updated_at();

alter table public.tourism_place_reviews enable row level security;

grant select, insert, update, delete
  on public.tourism_place_reviews to authenticated;
grant select on public.tourism_place_reviews to anon;

drop policy if exists tourism_place_reviews_public_approved_read
  on public.tourism_place_reviews;
create policy tourism_place_reviews_public_approved_read
  on public.tourism_place_reviews
  for select to anon
  using (status = 'approved');

drop policy if exists tourism_place_reviews_user_own_read
  on public.tourism_place_reviews;
drop policy if exists tourism_place_reviews_auth_read
  on public.tourism_place_reviews;
create policy tourism_place_reviews_auth_read
  on public.tourism_place_reviews
  for select to authenticated
  using (
    status = 'approved'
    or (select auth.uid()) = user_id
    or (select public.is_admin(auth.uid()))
  );

drop policy if exists tourism_place_reviews_user_insert
  on public.tourism_place_reviews;
drop policy if exists tourism_place_reviews_auth_insert
  on public.tourism_place_reviews;
create policy tourism_place_reviews_auth_insert
  on public.tourism_place_reviews
  for insert to authenticated
  with check (
    ((select auth.uid()) = user_id and status = 'pending')
    or (select public.is_admin(auth.uid()))
  );

drop policy if exists tourism_place_reviews_user_update_pending
  on public.tourism_place_reviews;
drop policy if exists tourism_place_reviews_auth_update
  on public.tourism_place_reviews;
create policy tourism_place_reviews_auth_update
  on public.tourism_place_reviews
  for update to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin(auth.uid())))
  with check (
    ((select auth.uid()) = user_id and status = 'pending')
    or (select public.is_admin(auth.uid()))
  );

drop policy if exists tourism_place_reviews_admin_all
  on public.tourism_place_reviews;

create or replace function public.update_tourism_place_review_summary()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.tourism_places tp
  set rating = coalesce((
        select round(avg(r.rating)::numeric, 1)
        from public.tourism_place_reviews r
        where r.place_id = tp.place_id
          and r.status = 'approved'
      ), tp.rating)
  where tp.place_id = coalesce(new.place_id, old.place_id);

  return coalesce(new, old);
end;
$$;

drop trigger if exists tourism_place_reviews_refresh_place_rating
  on public.tourism_place_reviews;
create trigger tourism_place_reviews_refresh_place_rating
  after insert or update or delete on public.tourism_place_reviews
  for each row execute function public.update_tourism_place_review_summary();

revoke all on function public.handle_updated_at() from public;
revoke all on function public.handle_updated_at() from anon;
revoke all on function public.handle_updated_at() from authenticated;
revoke all on function public.update_tourism_place_review_summary()
  from public;
revoke all on function public.update_tourism_place_review_summary()
  from anon;
revoke all on function public.update_tourism_place_review_summary()
  from authenticated;
