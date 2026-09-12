-- Correct image URLs for iconic destinations.
-- This keeps image data in Supabase, not hardcoded in Flutter.

update public.tourism_places
set images = array[
  'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=1200',
  'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=1200'
]
where lower(place_name) = 'taj mahal'
  and lower(city) = 'agra';

update public.tourism_places
set images = array[
  'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=1200',
  'https://images.unsplash.com/photo-1598623029920-8c9d2d6d642c?w=1200'
]
where lower(place_name) = 'india gate'
  and lower(city) in ('new delhi', 'delhi');

update public.tourism_places
set images = array[
  'https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?w=1200',
  'https://images.unsplash.com/photo-1605640840605-50a4d3a0f25?w=1200'
]
where lower(place_name) = 'ajanta caves';

update public.tourism_places
set images = array[
  'https://images.unsplash.com/photo-1623670598543-1f9b04f5a5e2?w=1200',
  'https://images.unsplash.com/photo-1591018343989-2a3e0a9bfae8?w=1200'
]
where lower(place_name) = 'ellora caves';

update public.tourism_places
set images = array[
  'https://images.unsplash.com/photo-1599661046289-e31897846e41?w=1200',
  'https://images.unsplash.com/photo-1477587458883-47145ed31459?w=1200'
]
where lower(place_name) in ('amer fort', 'amber fort')
  and lower(city) = 'jaipur';

update public.tourism_places
set likes_count = greatest(coalesce(likes_count, 1000), 1000)
where likes_count is null or likes_count < 1000;
