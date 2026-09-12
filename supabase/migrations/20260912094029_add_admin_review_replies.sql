-- Public admin replies for traveler reviews.

alter table public.tourism_place_reviews
  add column if not exists admin_reply text,
  add column if not exists admin_reply_by uuid references auth.users(id)
    on delete set null,
  add column if not exists admin_reply_at timestamptz;

create index if not exists tourism_place_reviews_admin_reply_by_idx
  on public.tourism_place_reviews(admin_reply_by)
  where admin_reply_by is not null;
