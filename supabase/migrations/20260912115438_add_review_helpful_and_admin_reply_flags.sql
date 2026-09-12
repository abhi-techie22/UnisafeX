-- Review helpful votes and secure admin reply highlighting.

alter table public.tourism_place_review_replies
  add column if not exists is_admin_reply boolean not null default false;

create or replace function public.set_tourism_review_reply_author_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.is_admin_reply := public.is_admin(new.user_id);
  return new;
end;
$$;

drop trigger if exists tourism_review_reply_author_role
  on public.tourism_place_review_replies;
create trigger tourism_review_reply_author_role
  before insert or update of user_id
  on public.tourism_place_review_replies
  for each row execute function public.set_tourism_review_reply_author_role();

update public.tourism_place_review_replies
set is_admin_reply = public.is_admin(user_id)
where is_admin_reply is distinct from public.is_admin(user_id);

alter table public.tourism_place_reviews
  add column if not exists helpful_count integer not null default 0
  check (helpful_count >= 0);

create table if not exists public.tourism_place_review_likes (
  id uuid primary key default uuid_generate_v4(),
  review_id uuid not null references public.tourism_place_reviews(id)
    on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(user_id, review_id)
);

create index if not exists tourism_place_review_likes_review_idx
  on public.tourism_place_review_likes(review_id);
create index if not exists tourism_place_review_likes_user_idx
  on public.tourism_place_review_likes(user_id, created_at desc);

alter table public.tourism_place_review_likes enable row level security;

grant select, insert, delete on public.tourism_place_review_likes
  to authenticated;

drop policy if exists tourism_place_review_likes_auth_read_own
  on public.tourism_place_review_likes;
create policy tourism_place_review_likes_auth_read_own
  on public.tourism_place_review_likes
  for select to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin(auth.uid())));

drop policy if exists tourism_place_review_likes_auth_insert_own
  on public.tourism_place_review_likes;
create policy tourism_place_review_likes_auth_insert_own
  on public.tourism_place_review_likes
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.tourism_place_reviews r
      where r.id = review_id
        and r.status = 'approved'
    )
  );

drop policy if exists tourism_place_review_likes_auth_delete_own
  on public.tourism_place_review_likes;
create policy tourism_place_review_likes_auth_delete_own
  on public.tourism_place_review_likes
  for delete to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin(auth.uid())));

create or replace function public.toggle_tourism_place_review_like(
  p_review_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_deleted integer := 0;
  v_helpful_count integer := 0;
  v_liked boolean := false;
begin
  if v_user_id is null then
    raise exception 'Login required to mark a review helpful'
      using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.tourism_place_reviews r
    where r.id = p_review_id
      and r.status = 'approved'
  ) then
    raise exception 'Review is not available'
      using errcode = '22023';
  end if;

  delete from public.tourism_place_review_likes
  where review_id = p_review_id
    and user_id = v_user_id;
  get diagnostics v_deleted = row_count;

  if v_deleted > 0 then
    update public.tourism_place_reviews
    set helpful_count = greatest(coalesce(helpful_count, 0) - 1, 0)
    where id = p_review_id
    returning helpful_count into v_helpful_count;
    v_liked := false;
  else
    insert into public.tourism_place_review_likes(review_id, user_id)
    values (p_review_id, v_user_id)
    on conflict (user_id, review_id) do nothing;

    if found then
      update public.tourism_place_reviews
      set helpful_count = coalesce(helpful_count, 0) + 1
      where id = p_review_id
      returning helpful_count into v_helpful_count;
    else
      select coalesce(helpful_count, 0)
      into v_helpful_count
      from public.tourism_place_reviews
      where id = p_review_id;
    end if;
    v_liked := true;
  end if;

  return jsonb_build_object(
    'helpful_count', coalesce(v_helpful_count, 0),
    'liked', v_liked
  );
end;
$$;

revoke all on function public.set_tourism_review_reply_author_role()
  from public, anon, authenticated;
revoke all on function public.toggle_tourism_place_review_like(uuid)
  from public, anon;
grant execute on function public.toggle_tourism_place_review_like(uuid)
  to authenticated;
