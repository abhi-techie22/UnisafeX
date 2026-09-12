-- Add admin-controlled place visibility.
-- Hidden places stay visible to admins, but are removed from public traveler reads.

alter table public.tourism_places
  add column if not exists is_hidden boolean not null default false;

create index if not exists idx_tourism_places_hidden
  on public.tourism_places(is_hidden);

drop policy if exists "tourism_places_public_read" on public.tourism_places;
create policy "tourism_places_public_read"
  on public.tourism_places
  for select
  to anon, authenticated
  using (is_hidden = false);
