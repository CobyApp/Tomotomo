-- Profile status message, character tagline, signup metadata, friend list fields, nickname search

alter table public.profiles
  add column if not exists status_message text;

alter table public.characters
  add column if not exists tagline text;

-- New users: display_name + status_message from auth user_metadata (signUp data)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, status_message)
  values (
    new.id,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), split_part(new.email, '@', 1)),
    nullif(trim(new.raw_user_meta_data->>'status_message'), '')
  );
  return new;
end;
$$;

-- Friend list: include avatar + status for UI
-- PG cannot change RETURNS TABLE columns via CREATE OR REPLACE; drop first if upgrading.
drop function if exists public.list_my_friends();

create function public.list_my_friends()
returns table (
  friend_id uuid,
  display_name text,
  email text,
  avatar_url text,
  status_message text
)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.display_name, p.email, p.avatar_url, p.status_message
  from public.friends f
  join public.profiles p on p.id = f.friend_id
  where f.user_id = auth.uid()
  order by f.created_at desc;
$$;

revoke all on function public.list_my_friends() from public;
grant execute on function public.list_my_friends() to authenticated;

-- Search by display name (nickname); no email returned. Min 2 chars.
create or replace function public.search_profiles_by_nickname(search_query text, result_limit int default 20)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  status_message text
)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.display_name, p.avatar_url, p.status_message
  from public.profiles p
  where auth.uid() is not null
    and p.id <> auth.uid()
    and length(trim(search_query)) >= 2
    and p.display_name is not null
    and p.display_name ilike ('%' || trim(search_query) || '%')
  order by p.display_name asc
  limit least(coalesce(nullif(result_limit, 0), 20), 50);
$$;

revoke all on function public.search_profiles_by_nickname(text, int) from public;
grant execute on function public.search_profiles_by_nickname(text, int) to authenticated;
