-- Public bucket for DM voice notes (path: {sender_user_id}/{room_id}/{timestamp}.m4a)
insert into storage.buckets (id, name, public)
values ('dm_voice', 'dm_voice', true)
on conflict (id) do update set public = excluded.public;

create policy "dm_voice_insert_own_folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'dm_voice'
    and (storage.foldername(name))[1] = (auth.uid())::text
  );

create policy "dm_voice_update_own_folder"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'dm_voice'
    and (storage.foldername(name))[1] = (auth.uid())::text
  );

create policy "dm_voice_delete_own_folder"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'dm_voice'
    and (storage.foldername(name))[1] = (auth.uid())::text
  );

create policy "dm_voice_public_read"
  on storage.objects for select to public
  using (bucket_id = 'dm_voice');
