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

alter table public.guide_requests
  add column if not exists guide_profile_id uuid
    references public.guide_profiles(id) on delete set null;

create index if not exists guide_profiles_active_idx
  on public.guide_profiles(is_active);
create index if not exists guide_profiles_name_idx
  on public.guide_profiles(name);
create index if not exists guide_requests_guide_profile_id_idx
  on public.guide_requests(guide_profile_id);

alter table public.guide_profiles enable row level security;

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

drop trigger if exists guide_profiles_updated_at
  on public.guide_profiles;
create trigger guide_profiles_updated_at
  before update on public.guide_profiles
  for each row execute function public.handle_updated_at();

grant select, insert, update, delete on public.guide_profiles to authenticated;
