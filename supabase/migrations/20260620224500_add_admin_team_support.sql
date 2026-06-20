-- Admin team, activity progress, and in-app support tickets.

create table if not exists public.support_tickets (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references auth.users(id) on delete set null,
  user_email text,
  title text not null,
  message text not null,
  category text not null default 'general'
    check (category in ('general', 'profile', 'places', 'guide', 'map', 'payment', 'bug')),
  priority text not null default 'normal'
    check (priority in ('low', 'normal', 'high', 'urgent')),
  status text not null default 'open'
    check (status in ('open', 'in_progress', 'waiting_user', 'resolved', 'closed')),
  admin_response text,
  assigned_to uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists support_tickets_user_idx
  on public.support_tickets(user_id, created_at desc);
create index if not exists support_tickets_admin_idx
  on public.support_tickets(status, priority, updated_at desc);

create or replace function public.add_admin_by_email(p_email text, p_role text default 'editor')
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
  if not public.is_admin(auth.uid()) then
    raise exception 'Only admins can add team members';
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

drop trigger if exists support_tickets_updated_at on public.support_tickets;
create trigger support_tickets_updated_at
  before update on public.support_tickets
  for each row execute function public.touch_updated_at();

alter table public.support_tickets enable row level security;

grant execute on function public.add_admin_by_email(text, text) to authenticated;
grant select, insert, update on public.support_tickets to authenticated;

drop policy if exists support_tickets_user_read on public.support_tickets;
create policy support_tickets_user_read on public.support_tickets
  for select to authenticated
  using (user_id = auth.uid() or public.is_admin(auth.uid()));

drop policy if exists support_tickets_user_insert on public.support_tickets;
create policy support_tickets_user_insert on public.support_tickets
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists support_tickets_admin_update on public.support_tickets;
create policy support_tickets_admin_update on public.support_tickets
  for update to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));
