-- Likes for tourism destinations.
-- Safe to run multiple times from Supabase SQL editor.

alter table public.tourism_places
  add column if not exists likes_count integer not null default 1000
  check (likes_count >= 0);

update public.tourism_places
set likes_count = greatest(coalesce(likes_count, 0), 1000)
where likes_count < 1000;

create index if not exists idx_tourism_places_likes
  on public.tourism_places(likes_count desc);

create table if not exists public.tourism_place_likes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id uuid not null references public.tourism_places(place_id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, place_id)
);

create index if not exists idx_tourism_place_likes_user_id
  on public.tourism_place_likes(user_id);

create index if not exists idx_tourism_place_likes_place_id
  on public.tourism_place_likes(place_id);

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
