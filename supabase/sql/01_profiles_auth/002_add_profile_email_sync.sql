alter table public.profiles
  add column if not exists email text;

create index if not exists profiles_email_idx
  on public.profiles (lower(email));

update public.profiles as profile
set email = auth_user.email
from auth.users as auth_user
where profile.user_id = auth_user.id
  and profile.email is distinct from auth_user.email;

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

drop trigger if exists on_auth_user_email_updated on auth.users;
create trigger on_auth_user_email_updated
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_new_user();
