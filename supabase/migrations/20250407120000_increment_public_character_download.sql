-- Allow any authenticated user to bump download_count on *other users'* public characters
-- (RLS blocks direct UPDATE on rows you do not own.)
create or replace function public.increment_public_character_download_count(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.characters
  set
    download_count = coalesce(download_count, 0) + 1,
    updated_at = now()
  where
    id = target_id
    and is_public = true
    and owner_id is distinct from auth.uid();
end;
$$;

revoke all on function public.increment_public_character_download_count(uuid) from public;
grant execute on function public.increment_public_character_download_count(uuid) to authenticated;
