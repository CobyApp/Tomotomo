-- One-way blocks + DM message policy (no sends when either party blocked the other).

create table public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id != blocked_id)
);

alter table public.user_blocks enable row level security;

create policy "user_blocks_select_involved"
  on public.user_blocks for select
  using (blocker_id = auth.uid() or blocked_id = auth.uid());

create policy "user_blocks_insert_as_blocker"
  on public.user_blocks for insert
  with check (blocker_id = auth.uid());

create policy "user_blocks_delete_as_blocker"
  on public.user_blocks for delete
  using (blocker_id = auth.uid());

create or replace function public.block_user(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_id is null or target_id = auth.uid() then
    raise exception 'invalid target';
  end if;
  if not exists (select 1 from public.profiles where id = target_id) then
    raise exception 'user not found';
  end if;
  insert into public.user_blocks (blocker_id, blocked_id)
  values (auth.uid(), target_id)
  on conflict (blocker_id, blocked_id) do nothing;
end;
$$;

create or replace function public.unblock_user(target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.user_blocks
  where blocker_id = auth.uid() and blocked_id = target_id;
end;
$$;

create or replace function public.list_blocked_users()
returns table (blocked_id uuid, display_name text, avatar_url text)
language sql
security definer
set search_path = public
stable
as $$
  select p.id, p.display_name, p.avatar_url
  from public.user_blocks b
  join public.profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;

revoke all on function public.block_user(uuid) from public;
grant execute on function public.block_user(uuid) to authenticated;

revoke all on function public.unblock_user(uuid) from public;
grant execute on function public.unblock_user(uuid) to authenticated;

revoke all on function public.list_blocked_users() from public;
grant execute on function public.list_blocked_users() to authenticated;

-- DM inserts: disallow when a block exists in either direction between participants.
drop policy if exists "chat_messages_insert" on public.chat_messages;

create policy "chat_messages_insert"
  on public.chat_messages for insert
  with check (
    exists (
      select 1 from public.chat_rooms r
      where r.id = room_id
      and (
        (r.room_type = 'character' and r.user_id = auth.uid())
        or (
          r.room_type = 'dm'
          and (r.user_id = auth.uid() or r.peer_user_id = auth.uid())
          and not exists (
            select 1 from public.user_blocks ub
            where
              (
                ub.blocker_id = auth.uid()
                and ub.blocked_id = (
                  case when r.user_id = auth.uid() then r.peer_user_id else r.user_id end
                )
              )
              or (
                ub.blocker_id = (
                  case when r.user_id = auth.uid() then r.peer_user_id else r.user_id end
                )
                and ub.blocked_id = auth.uid()
              )
          )
        )
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
