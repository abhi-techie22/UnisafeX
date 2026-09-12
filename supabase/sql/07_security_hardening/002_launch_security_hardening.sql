-- UniSafeX production security hardening.
-- Apply after existing admin/profile/storage migrations.
-- Non-destructive: no user data is deleted.

-- Keep app_settings publicly readable only for known non-secret keys.
drop policy if exists app_settings_public_read on public.app_settings;
create policy app_settings_public_read
  on public.app_settings
  for select
  to anon, authenticated
  using (
    key in (
      'maps_config',
      'auth_config',
      'currency_rates',
      'review_moderation'
    )
  );

-- App feature flags are intentionally public booleans, but only active rows
-- should be used by the client. Admin write remains database-enforced.
drop policy if exists app_feature_flags_public_read on public.app_feature_flags;
create policy app_feature_flags_public_read on public.app_feature_flags
  for select to anon, authenticated
  using (true);

-- Prevent normal users from changing payment/price/partner/admin-controlled
-- hotel booking fields. Users may only cancel their own booking.
create or replace function public.prevent_hotel_booking_user_tamper()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.is_admin(auth.uid()) then
    return new;
  end if;

  if auth.uid() is null or old.user_id is distinct from auth.uid() then
    raise exception 'Not allowed to update this booking'
      using errcode = '42501';
  end if;

  if new.id is distinct from old.id
    or new.user_id is distinct from old.user_id
    or new.hotel_id is distinct from old.hotel_id
    or new.hotel_name is distinct from old.hotel_name
    or new.hotel_image_url is distinct from old.hotel_image_url
    or new.room_type is distinct from old.room_type
    or new.check_in is distinct from old.check_in
    or new.check_out is distinct from old.check_out
    or new.guests is distinct from old.guests
    or new.total_price is distinct from old.total_price
    or new.currency is distinct from old.currency
    or new.affiliate_id is distinct from old.affiliate_id
    or new.partner_source is distinct from old.partner_source
    or new.partner_booking_id is distinct from old.partner_booking_id
    or new.confirmation_code is distinct from old.confirmation_code
    or new.metadata is distinct from old.metadata
    or new.created_at is distinct from old.created_at then
    raise exception 'Booking fields are protected'
      using errcode = '42501';
  end if;

  if new.status is distinct from old.status and new.status <> 'cancelled' then
    raise exception 'Users can only cancel bookings'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_hotel_booking_user_tamper on public.hotel_bookings;
create trigger prevent_hotel_booking_user_tamper
  before update on public.hotel_bookings
  for each row execute function public.prevent_hotel_booking_user_tamper();

-- Affiliate click outcomes are operational/payment-adjacent. Clients can
-- create clicks, but only admins should update outcomes/commission fields.
drop policy if exists hotel_affiliate_update_own_or_admin on public.hotel_affiliate_clicks;
create policy hotel_affiliate_update_admin
  on public.hotel_affiliate_clicks
  for update
  to authenticated
  using (public.is_admin(auth.uid()))
  with check (public.is_admin(auth.uid()));

-- Profile photos remain public for display, but upload/update/delete must be
-- owned, image-only, and size-limited. Never store passport/visa documents in
-- user-media.
update storage.buckets
set public = true,
    file_size_limit = 5242880,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'user-media';

drop policy if exists "user_media_public_read" on storage.objects;
drop policy if exists "user_media_auth_upload" on storage.objects;
drop policy if exists "user_media_own_delete" on storage.objects;
drop policy if exists "user_media_own_update" on storage.objects;

create policy "user_media_public_read" on storage.objects
  for select to anon, authenticated
  using (
    bucket_id = 'user-media'
    and (storage.foldername(name))[1] = 'profiles'
  );

create policy "user_media_auth_upload" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'user-media'
    and (storage.foldername(name))[1] = 'profiles'
    and auth.uid()::text = (storage.foldername(name))[2]
    and lower(coalesce(storage.extension(name), '')) in ('jpg', 'jpeg', 'png', 'webp')
  );

create policy "user_media_own_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'user-media'
    and (storage.foldername(name))[1] = 'profiles'
    and auth.uid()::text = (storage.foldername(name))[2]
  );

create policy "user_media_own_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'user-media'
    and (storage.foldername(name))[1] = 'profiles'
    and auth.uid()::text = (storage.foldername(name))[2]
  )
  with check (
    bucket_id = 'user-media'
    and (storage.foldername(name))[1] = 'profiles'
    and auth.uid()::text = (storage.foldername(name))[2]
    and lower(coalesce(storage.extension(name), '')) in ('jpg', 'jpeg', 'png', 'webp')
  );

-- Private bucket reserved for future passport/visa/hotel documents.
-- Use signed URLs or authenticated downloads only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'user-documents',
  'user-documents',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'application/pdf']
)
on conflict (id) do update
set public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'application/pdf'];

drop policy if exists user_documents_owner_read on storage.objects;
drop policy if exists user_documents_owner_insert on storage.objects;
drop policy if exists user_documents_owner_update on storage.objects;
drop policy if exists user_documents_owner_delete on storage.objects;
drop policy if exists user_documents_admin_read on storage.objects;

create policy user_documents_owner_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'user-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy user_documents_owner_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'user-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
    and lower(coalesce(storage.extension(name), '')) in ('jpg', 'jpeg', 'png', 'pdf')
  );

create policy user_documents_owner_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'user-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  )
  with check (
    bucket_id = 'user-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
    and lower(coalesce(storage.extension(name), '')) in ('jpg', 'jpeg', 'png', 'pdf')
  );

create policy user_documents_owner_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'user-documents'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy user_documents_admin_read on storage.objects
  for select to authenticated
  using (
    bucket_id = 'user-documents'
    and public.is_admin(auth.uid())
  );
