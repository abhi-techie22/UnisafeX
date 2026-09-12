-- Threaded user replies on approved place reviews.

create table if not exists public.tourism_place_review_replies (
  id uuid primary key default uuid_generate_v4(),
  review_id uuid not null references public.tourism_place_reviews(id)
    on delete cascade,
  place_id uuid not null references public.tourism_places(place_id)
    on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  replier_name text,
  replier_avatar_url text,
  body text not null check (length(trim(body)) between 1 and 800),
  status text not null default 'approved'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists tourism_place_review_replies_place_status_idx
  on public.tourism_place_review_replies(place_id, status, created_at);
create index if not exists tourism_place_review_replies_review_idx
  on public.tourism_place_review_replies(review_id, created_at);
create index if not exists tourism_place_review_replies_user_idx
  on public.tourism_place_review_replies(user_id, created_at desc);

drop trigger if exists tourism_place_review_replies_updated_at
  on public.tourism_place_review_replies;
create trigger tourism_place_review_replies_updated_at
  before update on public.tourism_place_review_replies
  for each row execute function public.handle_updated_at();

alter table public.tourism_place_review_replies enable row level security;

grant select on public.tourism_place_review_replies to anon, authenticated;
grant insert, update, delete on public.tourism_place_review_replies
  to authenticated;

drop policy if exists tourism_place_review_replies_public_read
  on public.tourism_place_review_replies;
create policy tourism_place_review_replies_public_read
  on public.tourism_place_review_replies
  for select to anon
  using (
    status = 'approved'
    and exists (
      select 1
      from public.tourism_place_reviews r
      where r.id = review_id
        and r.place_id = place_id
        and r.status = 'approved'
    )
  );

drop policy if exists tourism_place_review_replies_auth_read
  on public.tourism_place_review_replies;
create policy tourism_place_review_replies_auth_read
  on public.tourism_place_review_replies
  for select to authenticated
  using (
    status = 'approved'
    or (select auth.uid()) = user_id
    or (select public.is_admin(auth.uid()))
  );

drop policy if exists tourism_place_review_replies_auth_insert
  on public.tourism_place_review_replies;
create policy tourism_place_review_replies_auth_insert
  on public.tourism_place_review_replies
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'approved'
    and exists (
      select 1
      from public.tourism_place_reviews r
      where r.id = review_id
        and r.place_id = place_id
        and r.status = 'approved'
    )
  );

drop policy if exists tourism_place_review_replies_auth_update
  on public.tourism_place_review_replies;
create policy tourism_place_review_replies_auth_update
  on public.tourism_place_review_replies
  for update to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin(auth.uid())))
  with check (
    ((select auth.uid()) = user_id and status = 'approved')
    or (select public.is_admin(auth.uid()))
  );

drop policy if exists tourism_place_review_replies_auth_delete
  on public.tourism_place_review_replies;
create policy tourism_place_review_replies_auth_delete
  on public.tourism_place_review_replies
  for delete to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin(auth.uid())));
