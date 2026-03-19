-- Friend list with profile fields without widening profiles RLS.
-- Run in SQL Editor if needed.

create or replace function public.list_my_friends()
returns table (friend_id uuid, display_name text, email text)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.display_name, p.email
  from public.friends f
  join public.profiles p on p.id = f.friend_id
  where f.user_id = auth.uid()
  order by f.created_at desc;
$$;

revoke all on function public.list_my_friends() from public;
grant execute on function public.list_my_friends() to authenticated;

create or replace function public.add_friend(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_id is null then
    raise exception 'invalid id';
  end if;
  if target_id = auth.uid() then
    raise exception 'cannot add yourself';
  end if;
  if not exists (select 1 from public.profiles where id = target_id) then
    raise exception 'user not found';
  end if;
  insert into public.friends (user_id, friend_id)
  values (auth.uid(), target_id)
  on conflict (user_id, friend_id) do nothing;
end;
$$;

revoke all on function public.add_friend(uuid) from public;
grant execute on function public.add_friend(uuid) to authenticated;

create or replace function public.remove_friend(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.friends
  where user_id = auth.uid() and friend_id = target_id;
end;
$$;

revoke all on function public.remove_friend(uuid) from public;
grant execute on function public.remove_friend(uuid) to authenticated;
