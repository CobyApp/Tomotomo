-- Storage buckets for character avatars and backgrounds.
-- Run in Supabase SQL Editor if your CLI cannot modify storage (e.g. "must be owner of table objects").

-- Create public buckets (readable by anyone; upload restricted by RLS)
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('backgrounds', 'backgrounds', true)
on conflict (id) do update set public = excluded.public;

-- RLS: users can upload/update/delete only in their own folder (path = {user_id}/...)
-- First path segment must equal auth.uid()::text
create policy "Users can upload own avatars"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = (auth.uid())::text
  );

create policy "Users can update own avatars"
  on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (auth.uid())::text);

create policy "Users can delete own avatars"
  on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (auth.uid())::text);

create policy "Avatar files are publicly readable"
  on storage.objects for select to public
  using (bucket_id = 'avatars');

create policy "Users can upload own backgrounds"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'backgrounds' and (storage.foldername(name))[1] = (auth.uid())::text
  );

create policy "Users can update own backgrounds"
  on storage.objects for update to authenticated
  using (bucket_id = 'backgrounds' and (storage.foldername(name))[1] = (auth.uid())::text);

create policy "Users can delete own backgrounds"
  on storage.objects for delete to authenticated
  using (bucket_id = 'backgrounds' and (storage.foldername(name))[1] = (auth.uid())::text);

create policy "Background files are publicly readable"
  on storage.objects for select to public
  using (bucket_id = 'backgrounds');
