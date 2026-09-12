alter table public.tourism_place_reviews
  add column if not exists reviewer_name text,
  add column if not exists reviewer_avatar_url text;

update public.tourism_place_reviews as review
set
  reviewer_name = coalesce(
    nullif(trim(profile.full_name), ''),
    nullif(split_part(auth_user.email, '@', 1), ''),
    'UniSafeX traveler'
  ),
  reviewer_avatar_url = nullif(trim(profile.profile_image_url), '')
from auth.users as auth_user
left join public.profiles as profile
  on profile.user_id = auth_user.id
where review.user_id = auth_user.id
  and (
    review.reviewer_name is null
    or trim(review.reviewer_name) = ''
    or review.reviewer_avatar_url is null
  );
