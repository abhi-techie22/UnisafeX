-- Tourism media bucket for admin-managed destination photos.
-- Apply this once in Supabase SQL editor before using "Upload from folder"
-- in the UniSafeX admin destination editor.

insert into storage.buckets (id, name, public)
values ('tourism-media', 'tourism-media', true)
on conflict (id) do update set public = true;

drop policy if exists tourism_media_public_read on storage.objects;
create policy tourism_media_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'tourism-media');

drop policy if exists tourism_media_admin_insert on storage.objects;
create policy tourism_media_admin_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  );

drop policy if exists tourism_media_admin_update on storage.objects;
create policy tourism_media_admin_update on storage.objects
  for update to authenticated
  using (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  )
  with check (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  );

drop policy if exists tourism_media_admin_delete on storage.objects;
create policy tourism_media_admin_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'tourism-media'
    and public.is_admin(auth.uid())
  );
