-- Harden UniSafeX admin ownership.
-- Main owner account cannot be demoted, disabled, deleted, or replaced.
-- Only an active owner can add/update/remove admin team members.

insert into public.admin_users(user_id, email, role, is_active)
select id, email, 'owner', true
from auth.users
where lower(email) = 'abhishek.work962511@gmail.com'
on conflict (user_id) do update
set email = excluded.email,
    role = 'owner',
    is_active = true,
    updated_at = now();

create or replace function public.is_owner(p_user_id uuid default auth.uid())
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
      and au.role = 'owner'
      and au.is_active = true
  )
  or lower(coalesce(auth.jwt() ->> 'email', '')) = 'abhishek.work962511@gmail.com';
$$;

revoke all on function public.is_owner(uuid) from public;
grant execute on function public.is_owner(uuid) to authenticated;

create or replace function public.prevent_primary_owner_admin_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_primary_owner_email constant text := 'abhishek.work962511@gmail.com';
begin
  if tg_op = 'DELETE' then
    if lower(old.email) = v_primary_owner_email then
      raise exception 'Primary UniSafeX owner cannot be removed';
    end if;
    return old;
  end if;

  if lower(new.email) = v_primary_owner_email then
    if new.role <> 'owner' or new.is_active is not true then
      raise exception 'Primary UniSafeX owner must stay active owner';
    end if;
  end if;

  if tg_op = 'UPDATE' and lower(old.email) = v_primary_owner_email then
    if new.user_id <> old.user_id
      or lower(new.email) <> v_primary_owner_email
      or new.role <> 'owner'
      or new.is_active is not true then
      raise exception 'Primary UniSafeX owner cannot be changed or replaced';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_primary_owner_admin_change on public.admin_users;
create trigger prevent_primary_owner_admin_change
  before insert or update or delete on public.admin_users
  for each row execute function public.prevent_primary_owner_admin_change();

drop policy if exists admin_users_admin_all on public.admin_users;
drop policy if exists admin_users_self_or_admin_read on public.admin_users;
drop policy if exists admin_users_owner_insert on public.admin_users;
drop policy if exists admin_users_owner_update on public.admin_users;
drop policy if exists admin_users_owner_delete on public.admin_users;

create policy admin_users_self_or_admin_read on public.admin_users
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

create policy admin_users_owner_insert on public.admin_users
  for insert to authenticated
  with check (public.is_owner(auth.uid()));

create policy admin_users_owner_update on public.admin_users
  for update to authenticated
  using (public.is_owner(auth.uid()))
  with check (public.is_owner(auth.uid()));

create policy admin_users_owner_delete on public.admin_users
  for delete to authenticated
  using (
    public.is_owner(auth.uid())
    and lower(email) <> 'abhishek.work962511@gmail.com'
  );

create or replace function public.add_admin_by_email(
  p_email text,
  p_role text default 'editor'
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
  v_email text := lower(trim(p_email));
  v_role text := lower(trim(coalesce(p_role, 'editor')));
begin
  if not public.is_owner(auth.uid()) then
    raise exception 'Only the UniSafeX owner can manage admin team members';
  end if;

  if v_role not in ('owner', 'admin', 'editor') then
    raise exception 'Invalid admin role';
  end if;

  select id into v_user_id
  from auth.users
  where lower(email) = v_email
  limit 1;

  if v_user_id is null then
    raise exception 'No registered user found for %', v_email;
  end if;

  insert into public.admin_users(user_id, email, role, is_active)
  values (v_user_id, v_email, v_role, true)
  on conflict (user_id) do update
  set email = excluded.email,
      role = excluded.role,
      is_active = true,
      updated_at = now();

  return v_user_id;
end;
$$;

grant execute on function public.add_admin_by_email(text, text) to authenticated;
