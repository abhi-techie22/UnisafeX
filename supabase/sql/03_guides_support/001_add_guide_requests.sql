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

alter table public.guide_requests enable row level security;

drop policy if exists guide_requests_select_own_or_admin
  on public.guide_requests;
drop policy if exists guide_requests_insert_own
  on public.guide_requests;
drop policy if exists guide_requests_admin_update
  on public.guide_requests;
drop policy if exists guide_requests_admin_delete
  on public.guide_requests;

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

drop trigger if exists guide_requests_updated_at
  on public.guide_requests;
create trigger guide_requests_updated_at
  before update on public.guide_requests
  for each row execute function public.handle_updated_at();

grant select, insert, update, delete on public.guide_requests to authenticated;
