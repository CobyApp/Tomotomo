-- Direct messages between friends: room_type dm, sender_id on messages, RLS, ensure_dm_room RPC

-- chat_rooms: DM metadata
alter table public.chat_rooms
  add column if not exists room_type text not null default 'character',
  add column if not exists peer_user_id uuid references public.profiles(id) on delete cascade;

alter table public.chat_rooms drop constraint if exists chat_rooms_room_type_check;
alter table public.chat_rooms
  add constraint chat_rooms_room_type_check check (room_type in ('character', 'dm'));

alter table public.chat_rooms drop constraint if exists chat_rooms_room_shape_check;
alter table public.chat_rooms
  add constraint chat_rooms_room_shape_check check (
    (room_type = 'character' and peer_user_id is null)
    or (
      room_type = 'dm'
      and peer_user_id is not null
      and character_id is null
      and external_character_key is null
    )
  );

create unique index if not exists chat_rooms_dm_pair_uniq
  on public.chat_rooms (user_id, peer_user_id)
  where room_type = 'dm';

-- Replace chat_rooms RLS (was single "manage own" policy)
drop policy if exists "Users can manage own chat rooms" on public.chat_rooms;

create policy "chat_rooms_select"
  on public.chat_rooms for select
  using (
    (room_type = 'character' and user_id = auth.uid())
    or (room_type = 'dm' and (user_id = auth.uid() or peer_user_id = auth.uid()))
  );

create policy "chat_rooms_insert_character"
  on public.chat_rooms for insert
  with check (
    room_type = 'character'
    and user_id = auth.uid()
    and peer_user_id is null
  );

create policy "chat_rooms_update"
  on public.chat_rooms for update
  using (
    (room_type = 'character' and user_id = auth.uid())
    or (room_type = 'dm' and (user_id = auth.uid() or peer_user_id = auth.uid()))
  )
  with check (
    (room_type = 'character' and user_id = auth.uid())
    or (room_type = 'dm' and (user_id = auth.uid() or peer_user_id = auth.uid()))
  );

create policy "chat_rooms_delete"
  on public.chat_rooms for delete
  using (
    (room_type = 'character' and user_id = auth.uid())
    or (room_type = 'dm' and (user_id = auth.uid() or peer_user_id = auth.uid()))
  );

-- chat_messages: sender for DM (character chats keep sender_id null)
alter table public.chat_messages
  add column if not exists sender_id uuid references public.profiles(id) on delete set null;

alter table public.chat_messages drop constraint if exists chat_messages_role_check;
alter table public.chat_messages
  add constraint chat_messages_role_sender_check check (
    (sender_id is null and role in ('user', 'assistant'))
    or (sender_id is not null and role = 'user')
  );

drop policy if exists "Users can read messages in own rooms" on public.chat_messages;
drop policy if exists "Users can insert messages in own rooms" on public.chat_messages;

create policy "chat_messages_select"
  on public.chat_messages for select
  using (
    exists (
      select 1 from public.chat_rooms r
      where r.id = room_id
      and (
        (r.room_type = 'character' and r.user_id = auth.uid())
        or (r.room_type = 'dm' and (r.user_id = auth.uid() or r.peer_user_id = auth.uid()))
      )
    )
  );

create policy "chat_messages_insert"
  on public.chat_messages for insert
  with check (
    exists (
      select 1 from public.chat_rooms r
      where r.id = room_id
      and (
        (r.room_type = 'character' and r.user_id = auth.uid())
        or (r.room_type = 'dm' and (r.user_id = auth.uid() or r.peer_user_id = auth.uid()))
      )
    )
    and (
      (
        exists (
          select 1 from public.chat_rooms r2
          where r2.id = room_id
          and r2.room_type = 'character'
          and r2.user_id = auth.uid()
        )
        and sender_id is null
      )
      or (
        exists (
          select 1 from public.chat_rooms r3
          where r3.id = room_id
          and r3.room_type = 'dm'
          and (r3.user_id = auth.uid() or r3.peer_user_id = auth.uid())
        )
        and sender_id = auth.uid()
      )
    )
  );

-- Allow reading a friend's public profile fields when friendship exists (either direction)
create policy "Users can read friend profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.friends f
      where (f.user_id = auth.uid() and f.friend_id = profiles.id)
         or (f.user_id = profiles.id and f.friend_id = auth.uid())
    )
  );

-- Create or return canonical DM room (user_id = lexicographically smaller UUID)
create or replace function public.ensure_dm_room(other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  low uuid;
  high uuid;
  rid uuid;
begin
  if me is null then
    raise exception 'not authenticated';
  end if;
  if other_user_id = me then
    raise exception 'cannot dm self';
  end if;
  if not exists (select 1 from public.profiles p where p.id = other_user_id) then
    raise exception 'user not found';
  end if;
  if not exists (
    select 1 from public.friends f
    where (f.user_id = me and f.friend_id = other_user_id)
       or (f.user_id = other_user_id and f.friend_id = me)
  ) then
    raise exception 'not friends';
  end if;

  if me::text < other_user_id::text then
    low := me;
    high := other_user_id;
  else
    low := other_user_id;
    high := me;
  end if;

  select c.id into rid
  from public.chat_rooms c
  where c.room_type = 'dm'
    and c.user_id = low
    and c.peer_user_id = high
  limit 1;

  if rid is not null then
    return rid;
  end if;

  insert into public.chat_rooms (user_id, peer_user_id, room_type, title)
  values (low, high, 'dm', '')
  returning id into rid;

  return rid;
end;
$$;

revoke all on function public.ensure_dm_room(uuid) from public;
grant execute on function public.ensure_dm_room(uuid) to authenticated;
