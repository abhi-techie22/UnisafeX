-- ============================================================
-- UniSafeX — Complete Supabase SQL Schema
-- Run this in Supabase SQL Editor (Settings > SQL Editor)
-- ============================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";  -- for geo queries (optional)

-- ============================================================
-- TABLE: profiles
-- ============================================================
create table if not exists public.profiles (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null unique references auth.users(id) on delete cascade,
  email         text,
  full_name     text,
  gender        text,
  nationality   text,
  country       text,
  country_code  text,
  current_location text,
  passport_country text,
  visa_type     text,
  visa_expiry   date,
  travel_purpose text,
  profile_image_url text,
  is_profile_complete boolean default false,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

create index if not exists profiles_email_idx
  on public.profiles (lower(email));

-- ============================================================
-- TABLE: tourism_places
-- ============================================================
create table if not exists public.tourism_places (
  place_id      uuid primary key default uuid_generate_v4(),
  place_name    text not null,
  description   text,
  state         text not null,
  district      text,
  city          text not null,
  category      text not null default 'Historical',
  subcategory   text,
  latitude      double precision not null,
  longitude     double precision not null,
  images        text[] default '{}',
  entry_fee_indian     numeric(10,2) default 0,
  entry_fee_foreigner  numeric(10,2) default 0,
  timings       text,
  best_season   text,
  best_months   text[] default '{}',
  safety_guidelines    text[] default '{}',
  tourist_tips  text[] default '{}',
  tier          integer default 2 check (tier in (1,2,3)),
  featured      boolean default false,
  rating        numeric(3,1) default 0.0 check (rating >= 0 and rating <= 5),
  is_popular    boolean default false,
  visit_duration_minutes integer,
  address       text,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- Indexes for performance
create index if not exists idx_tourism_places_category on public.tourism_places(category);
create index if not exists idx_tourism_places_city on public.tourism_places(city);
create index if not exists idx_tourism_places_state on public.tourism_places(state);
create index if not exists idx_tourism_places_featured on public.tourism_places(featured);
create index if not exists idx_tourism_places_popular on public.tourism_places(is_popular);
create index if not exists idx_tourism_places_tier on public.tourism_places(tier);
create index if not exists idx_tourism_places_rating on public.tourism_places(rating desc);
create index if not exists idx_tourism_places_location on public.tourism_places(latitude, longitude);

-- Full text search index
create index if not exists idx_tourism_places_fts on public.tourism_places
  using gin(to_tsvector('english', coalesce(place_name,'') || ' ' || coalesce(city,'') || ' ' || coalesce(state,'') || ' ' || coalesce(category,'')));

-- ============================================================
-- TABLE: favorites
-- ============================================================
create table if not exists public.favorites (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  place_id   uuid not null references public.tourism_places(place_id) on delete cascade,
  created_at timestamptz default now(),
  unique(user_id, place_id)
);

create index if not exists idx_favorites_user_id on public.favorites(user_id);
create index if not exists idx_favorites_place_id on public.favorites(place_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- profiles: users can only read/write their own profile
alter table public.profiles enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "profiles_delete_own" on public.profiles
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- tourism_places: public read, admin write
alter table public.tourism_places enable row level security;

drop policy if exists "tourism_places_public_read" on public.tourism_places;

create policy "tourism_places_public_read" on public.tourism_places
  for select using (true);

-- favorites: users can only access their own favorites
alter table public.favorites enable row level security;

drop policy if exists "favorites_select_own" on public.favorites;
drop policy if exists "favorites_insert_own" on public.favorites;
drop policy if exists "favorites_delete_own" on public.favorites;

create policy "favorites_select_own" on public.favorites
  for select using (auth.uid() = user_id);

create policy "favorites_insert_own" on public.favorites
  for insert with check (auth.uid() = user_id);

create policy "favorites_delete_own" on public.favorites
  for delete using (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at timestamp
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists profiles_updated_at on public.profiles;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

drop trigger if exists tourism_places_updated_at on public.tourism_places;

create trigger tourism_places_updated_at
  before update on public.tourism_places
  for each row execute function public.handle_updated_at();

-- Auto-create profile on user signup
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

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists on_auth_user_email_updated on auth.users;

create trigger on_auth_user_email_updated
  after update of email on auth.users
  for each row
  when (old.email is distinct from new.email)
  execute function public.handle_new_user();

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

insert into storage.buckets (id, name, public)
values ('user-media', 'user-media', true)
on conflict (id) do nothing;

drop policy if exists "user_media_public_read" on storage.objects;
drop policy if exists "user_media_auth_upload" on storage.objects;
drop policy if exists "user_media_own_delete" on storage.objects;

create policy "user_media_public_read" on storage.objects
  for select using (bucket_id = 'user-media');

create policy "user_media_auth_upload" on storage.objects
  for insert with check (
    bucket_id = 'user-media'
    and auth.uid() is not null
  );

create policy "user_media_own_delete" on storage.objects
  for delete using (
    bucket_id = 'user-media'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

-- ============================================================
-- SEED DATA — Popular Indian Tourist Places
-- ============================================================

insert into public.tourism_places (
  place_name, description, state, district, city, category,
  latitude, longitude, images, entry_fee_indian, entry_fee_foreigner,
  timings, best_season, best_months, safety_guidelines, tourist_tips,
  tier, featured, rating, is_popular, visit_duration_minutes
) values

-- TIER 1: UNESCO & Iconic
(
  'Taj Mahal',
  'The Taj Mahal is an ivory-white marble mausoleum on the right bank of the Yamuna river in Agra. Commissioned in 1632 by the Mughal emperor Shah Jahan to house the tomb of his beloved wife Mumtaz Mahal, it is one of the Seven Wonders of the World and a UNESCO World Heritage Site.',
  'Uttar Pradesh', 'Agra', 'Agra', 'Historical',
  27.1751, 78.0421,
  ARRAY['https://images.unsplash.com/photo-1564507592333-c60657eea523?w=800','https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=800'],
  50, 1100,
  'Sunrise to Sunset (Closed on Fridays)',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Keep your belongings secure in crowded areas','Hire only government-approved guides','Avoid touts outside the main entrance','Store valuables in hotel safes'],
  ARRAY['Visit at sunrise for the best light and fewer crowds','The Taj changes color throughout the day — magical at dusk','Buy tickets online to avoid long queues','Remove shoes before entering the mausoleum'],
  1, true, 4.8, true, 180
),

(
  'Qutub Minar',
  'Qutub Minar is a UNESCO World Heritage Site located in Delhi. At 72.5 meters, it is the tallest brick minaret in the world, built in the early 13th century by Qutub-ud-Din Aibak. The complex contains several historically significant structures from the Slave Dynasty era.',
  'Delhi', 'South Delhi', 'New Delhi', 'Historical',
  28.5245, 77.1855,
  ARRAY['https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800'],
  30, 500,
  '7:00 AM to 5:00 PM',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Be cautious of pickpockets in crowded areas','Stay on designated paths','Wear comfortable walking shoes'],
  ARRAY['Combine with a visit to Humayun Tomb nearby','Early morning visits are less crowded','Audio guides available at the entrance'],
  1, true, 4.5, true, 120
),

(
  'Jaipur City Palace',
  'The City Palace of Jaipur is a palace complex in Jaipur, the capital of Rajasthan state. It was the seat of the Maharaja of Jaipur. Built between 1729 and 1732, the complex includes the Chandra Mahal and Mubarak Mahal palaces, several buildings, courtyards and temples.',
  'Rajasthan', 'Jaipur', 'Jaipur', 'Historical',
  26.9258, 75.8237,
  ARRAY['https://images.unsplash.com/photo-1599661046289-e31897846e41?w=800','https://images.unsplash.com/photo-1477587458883-47145ed31459?w=800'],
  200, 700,
  '9:30 AM to 5:00 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Dress modestly when visiting royal residences','Respect photography restrictions inside museums','Bargain at local shops but be respectful'],
  ARRAY['Buy a combined ticket for multiple palaces','The royal family still resides in a portion of the palace','Guided tours give fascinating historical context'],
  1, true, 4.6, true, 150
),

(
  'Hawa Mahal',
  'Hawa Mahal, the Palace of Winds, is a palace in Jaipur built of red and pink sandstone. It was built in 1799 by Maharaja Sawai Pratap Singh. The five-story exterior is akin to a honeycomb with 953 small windows called Jharokhas decorated with intricate latticework.',
  'Rajasthan', 'Jaipur', 'Jaipur', 'Historical',
  26.9239, 75.8267,
  ARRAY['https://images.unsplash.com/photo-1570168007204-dfb528c6958f?w=800'],
  50, 200,
  '9:00 AM to 4:30 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Be cautious of overpriced autorickshaws','Watch out for touts near entrance'],
  ARRAY['View from the street is free and spectacular','Best photographed in morning light from across the road','Small but intricate interior worth exploring'],
  1, true, 4.4, true, 90
),

(
  'Kerala Backwaters',
  'The Kerala Backwaters are a network of interconnected canals, rivers, lakes, and inlets formed by more than 900 km of waterways. A houseboat cruise through the backwaters offers a tranquil experience of local life, fishing villages, and lush coconut palms.',
  'Kerala', 'Alappuzha', 'Alleppey', 'Nature',
  9.4981, 76.3388,
  ARRAY['https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800','https://images.unsplash.com/photo-1593693411515-c20261bcad6e?w=800'],
  0, 0,
  'All day',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Book certified houseboats only','Carry mosquito repellent','Stay hydrated in humid weather','Keep documents safe on water'],
  ARRAY['Book houseboats at least a week in advance','Sunrise and sunset on the backwaters are stunning','Try the traditional Kerala meal served on banana leaf'],
  1, true, 4.7, true, 480
),

(
  'Varanasi Ghats',
  'Varanasi is one of the oldest living cities in the world. The ghats along the Ganges River are the spiritual heart of the city. Over 80 ghats line the riverfront, built mainly in the 18th century by Maratha rulers. The Ganga Aarti ceremony at Dashashwamedh Ghat is a mesmerizing spectacle.',
  'Uttar Pradesh', 'Varanasi', 'Varanasi', 'Spiritual',
  25.3176, 83.0062,
  ARRAY['https://images.unsplash.com/photo-1561361058-c24e01f57a5c?w=800'],
  0, 0,
  'All day (Aarti at sunrise and sunset)',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Be respectful at cremation ghats','Do not photograph cremation ceremonies without permission','Hire only licensed boat operators for river rides','Be cautious of aggressive touts'],
  ARRAY['Witness the Ganga Aarti at Dashashwamedh Ghat','Take a boat ride at dawn for a spiritual experience','Explore the narrow alleys of the old city'],
  1, true, 4.6, true, 240
),

(
  'Hampi Ruins',
  'Hampi is a UNESCO World Heritage Site in Karnataka. The ruins of Vijayanagara, the former capital of the Vijayanagara Empire, spread across 4,100 hectares. The landscape of giant boulders and ancient temples is both surreal and historically profound.',
  'Karnataka', 'Vijayanagara', 'Hampi', 'Historical',
  15.3350, 76.4600,
  ARRAY['https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=800'],
  40, 600,
  'Sunrise to Sunset',
  'October to February',
  ARRAY['October','November','December','January','February'],
  ARRAY['Carry plenty of water — limited facilities','Wear sun protection','Stick to known trails','Register at archaeological survey checkpoints'],
  ARRAY['Rent a bicycle to explore the spread-out ruins','The Virupaksha Temple is the spiritual center','Matanga Hill offers a stunning panoramic view'],
  1, true, 4.7, true, 360
),

(
  'Goa Beaches',
  'Goa, India''s smallest state, is famous for its beaches, Portuguese heritage, and vibrant nightlife. From the popular Baga and Calangute in North Goa to the serene Palolem and Agonda in South Goa, there is a beach for every type of traveler.',
  'Goa', 'North Goa', 'Panaji', 'Nature',
  15.2993, 74.1240,
  ARRAY['https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=800','https://images.unsplash.com/photo-1571406252241-db0280bd36cd?w=800'],
  0, 0,
  'All day',
  'November to February',
  ARRAY['November','December','January','February'],
  ARRAY['Beware of strong currents and rip tides','Swim only in designated areas with lifeguards','Keep valuables locked in hotel','Be cautious on isolated beaches at night'],
  ARRAY['South Goa beaches are quieter and cleaner','Rent a scooter to explore at your own pace','Try fresh seafood at shacks on the beach','Anjuna flea market on Wednesdays is a must-visit'],
  1, true, 4.5, true, 300
),

(
  'Ranthambore National Park',
  'Ranthambore National Park in Rajasthan is one of the best places in India to see wild Bengal tigers. The park covers 392 sq km and is home to leopards, sloth bears, crocodiles, and diverse bird species, all set against the dramatic backdrop of ancient ruins.',
  'Rajasthan', 'Sawai Madhopur', 'Sawai Madhopur', 'Wildlife',
  26.0173, 76.5026,
  ARRAY['https://images.unsplash.com/photo-1602555553795-3e9ce56ea70d?w=800'],
  200, 1200,
  'Safari: 6:30 AM - 10:00 AM, 2:30 PM - 6:00 PM',
  'October to June',
  ARRAY['October','November','December','January','February','March','April','May'],
  ARRAY['Never get out of the safari vehicle','Keep noise to minimum','Do not feed animals','Book safaris in advance — limited daily entry'],
  ARRAY['Book gypsies (open jeeps) for better viewing than canters','Morning safaris have higher tiger sighting probability','Zone 3, 4, and 5 have the highest tiger density','Bring binoculars and a telephoto lens'],
  1, true, 4.6, true, 210
),

(
  'Amer Fort',
  'Amer Fort, also known as Amber Fort, is a fort located in Amer, Rajasthan. The fort was built by Raja Man Singh I in 1592. This magnificent fort is a blend of Rajput and Mughal architecture, with beautiful Sheesh Mahal (Hall of Mirrors) and artistic gateways.',
  'Rajasthan', 'Jaipur', 'Jaipur', 'Historical',
  26.9855, 75.8513,
  ARRAY['https://images.unsplash.com/photo-1477587458883-47145ed31459?w=800'],
  100, 500,
  '8:00 AM to 5:30 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Avoid elephant rides — they are controversial','Stay hydrated — lots of walking involved','Official guides are recommended for historical context'],
  ARRAY['Visit early morning to beat the heat and crowds','The light show in the evening is spectacular','Combine with Jaigarh Fort via the walking tunnel'],
  1, true, 4.7, true, 180
),

-- TIER 2: Popular destinations
(
  'Gateway of India',
  'The Gateway of India is an arch monument built during the 20th century in Mumbai. Overlooking the Arabian Sea, it was erected to commemorate the landing of King George V and Queen Mary at Apollo Bunder in Mumbai. It is the most iconic landmark of the financial capital of India.',
  'Maharashtra', 'Mumbai', 'Mumbai', 'Historical',
  18.9220, 72.8347,
  ARRAY['https://images.unsplash.com/photo-1529253355930-ddbe423a2ac7?w=800'],
  0, 0,
  'Open 24 hours',
  'November to February',
  ARRAY['November','December','January','February'],
  ARRAY['Watch out for pickpockets in crowded areas','Be careful near the waterfront','Avoid unlicensed boat operators for Elephanta Island'],
  ARRAY['Best visited early morning or at sunset','Take the ferry to Elephanta Caves from here','The Taj Mahal Palace Hotel opposite is iconic'],
  2, true, 4.3, true, 60
),

(
  'India Gate',
  'India Gate is a war memorial located astride the Rajpath, on the eastern edge of the ceremonial axis of New Delhi. India Gate is a tribute to 70,000 soldiers of the British Indian Army who died in various wars between 1914 and 1919.',
  'Delhi', 'New Delhi', 'New Delhi', 'Historical',
  28.6129, 77.2295,
  ARRAY['https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800'],
  0, 0,
  'Open 24 hours',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Beware of touts and hawkers','Keep bags zipped in crowds'],
  ARRAY['Illuminated beautifully at night','The lawns are perfect for an evening picnic','Combine with Rashtrapati Bhavan visit nearby'],
  2, true, 4.4, true, 90
),

(
  'Mysore Palace',
  'Mysore Palace, also known as Amba Vilas Palace, is a historical palace and a royal residence located in Mysore, Karnataka. It is one of the largest palaces in India. The palace is the seat of the Wadiyar dynasty and was the official residence of the Maharaja of Mysore.',
  'Karnataka', 'Mysuru', 'Mysore', 'Historical',
  12.3051, 76.6551,
  ARRAY['https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?w=800'],
  70, 200,
  '10:00 AM to 5:30 PM',
  'October to March',
  ARRAY['October','November','December','January','February'],
  ARRAY['Dress modestly — shoulders and knees covered','Shoes must be removed before entering','Cameras not allowed inside'],
  ARRAY['The palace is lit up with 97,000 bulbs on Sundays and holidays','Visit during Dasara festival for a spectacular display','Audio guides available in multiple languages'],
  2, true, 4.6, true, 120
),

(
  'Lotus Temple',
  'The Lotus Temple, located in New Delhi, is a Bahai House of Worship. Notable for its lotus-shaped architecture, it has won numerous architectural awards and been featured extensively in newspaper and magazine articles. All are welcome to visit regardless of religion.',
  'Delhi', 'New Delhi', 'New Delhi', 'Spiritual',
  28.5535, 77.2588,
  ARRAY['https://images.unsplash.com/photo-1597598490771-41d6c5b28a71?w=800'],
  0, 0,
  '9:00 AM to 5:30 PM (closed Mondays)',
  'October to March',
  ARRAY['October','November','December','January','February','March'],
  ARRAY['Silence must be maintained inside','All religions welcome','Long queues on weekends — arrive early'],
  ARRAY['Free entry for everyone','Meditation is practiced inside','The gardens around the temple are beautiful'],
  2, true, 4.5, true, 75
),

(
  'Jim Corbett National Park',
  'Jim Corbett National Park is the oldest national park in India, established in 1936. Located in Uttarakhand, it protects the Bengal tiger and hosts a rich variety of wildlife including elephants, leopards, deer, and over 600 species of birds.',
  'Uttarakhand', 'Nainital', 'Ramnagar', 'Wildlife',
  29.5300, 78.7747,
  ARRAY['https://images.unsplash.com/photo-1602555553795-3e9ce56ea70d?w=800'],
  150, 900,
  'Safari: Dawn and Dusk zones',
  'November to June',
  ARRAY['November','December','January','February','March','April','May','June'],
  ARRAY['Book safaris well in advance','Never leave the vehicle during safari','Dhikala zone requires overnight stay permits','Follow park rules strictly'],
  ARRAY['Dhikala zone offers the best wildlife experience','Elephant safaris offer a unique vantage point','Bird watching is excellent near the river'],
  2, true, 4.5, true, 240
),

(
  'Ajanta Caves',
  'The Ajanta Caves are approximately 30 rock-cut Buddhist cave monuments dating from the 2nd century BC to about 480 CE in Aurangabad district of Maharashtra. The cave paintings are the finest surviving examples of Indian art from antiquity.',
  'Maharashtra', 'Aurangabad', 'Aurangabad', 'Historical',
  20.5519, 75.7033,
  ARRAY['https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800'],
  40, 600,
  '9:00 AM to 5:30 PM (Closed Mondays)',
  'November to March',
  ARRAY['November','December','January','February','March'],
  ARRAY['Photography with flash strictly prohibited inside caves','Wear comfortable shoes for uneven terrain','Carry water — limited facilities'],
  ARRAY['Hire a licensed guide to understand the cave paintings','Visit Ellora Caves on the same trip (65 km away)','Cave 1 and 2 have the most spectacular paintings'],
  1, true, 4.6, true, 240
),

(
  'Ellora Caves',
  'The Ellora Caves are a UNESCO World Heritage Site in Maharashtra. Representing Buddhist, Hindu and Jain rock-cut temples and monasteries, the 34 caves were built between the 6th and 11th centuries CE. The Kailasa Temple (Cave 16) is the world''s largest rock-cut structure.',
  'Maharashtra', 'Aurangabad', 'Aurangabad', 'Spiritual',
  20.0258, 75.1780,
  ARRAY['https://images.unsplash.com/photo-1567157577867-05ccb1388e66?w=800'],
  40, 600,
  '6:00 AM to 6:00 PM (Closed Tuesdays)',
  'November to March',
  ARRAY['November','December','January','February','March'],
  ARRAY['Wear modest clothing','Respect the religious significance of caves','Photography allowed but no flash'],
  ARRAY['Start with Cave 16 (Kailasa Temple) — the most impressive','Combine with Ajanta Caves visit (100 km away)','Early morning visit recommended for fewer crowds'],
  1, true, 4.7, true, 300
),

(
  'Munnar Tea Gardens',
  'Munnar is a hill station and tea county in the Western Ghats mountain range in Kerala. The tea gardens of Munnar stretch over 60,000 hectares covering the hills of Munnar, Devikulam and Peerumade. The lush green landscape is spectacular year-round.',
  'Kerala', 'Idukki', 'Munnar', 'Nature',
  10.0889, 77.0595,
  ARRAY['https://images.unsplash.com/photo-1571803241078-c7b5b0571e85?w=800','https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?w=800'],
  0, 0,
  'All day',
  'September to May',
  ARRAY['September','October','November','December','January','February','March','April'],
  ARRAY['Roads can be foggy and dangerous — drive carefully','Beware of leeches during monsoon season','Stay on designated hiking trails'],
  ARRAY['Visit a tea factory for a fascinating tour','The Eravikulam National Park has Nilgiri Tahr sightings','Top Station viewpoint offers incredible views into Kerala'],
  2, true, 4.6, true, 360
);

update public.tourism_places
set address = concat_ws(', ', nullif(city, ''), nullif(state, ''))
where address is null or btrim(address) = '';

-- Verify seed data
select count(*) as total_places from public.tourism_places;
select category, count(*) as count from public.tourism_places group by category order by count desc;
