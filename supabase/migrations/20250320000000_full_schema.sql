-- Tomotomo consolidated schema (single migration)
-- Combines former migrations 20250320000000 through 20250321500000.
-- For existing projects that already applied the old chain, reset the remote DB or keep history; do not apply this twice.

-- ---------------------------------------------------------------------------
-- Profiles (extends auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  status_message text,
  app_language text not null default 'ko' check (app_language in ('ko', 'ja')),
  learning_language text not null default 'ja' check (learning_language in ('ko', 'ja')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ---------------------------------------------------------------------------
-- Characters (custom + shared)
-- ---------------------------------------------------------------------------
create table public.characters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  name_secondary text,
  avatar_url text,
  speech_style text,
  language text not null default 'ja' check (language in ('ko', 'ja')),
  is_public boolean not null default false,
  download_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index characters_owner_id_idx on public.characters(owner_id);
create index characters_is_public_idx on public.characters(is_public) where is_public = true;

alter table public.characters enable row level security;

create policy "Anyone can read public characters"
  on public.characters for select
  using (is_public = true or owner_id = auth.uid());

create policy "Users can insert own characters"
  on public.characters for insert
  with check (auth.uid() = owner_id);

create policy "Users can update own characters"
  on public.characters for update
  using (auth.uid() = owner_id);

create policy "Users can delete own characters"
  on public.characters for delete
  using (auth.uid() = owner_id);

-- ---------------------------------------------------------------------------
-- Friends
-- ---------------------------------------------------------------------------
create table public.friends (
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id),
  check (user_id != friend_id)
);

alter table public.friends enable row level security;

create policy "Users can read own friends"
  on public.friends for select
  using (auth.uid() = user_id);

create policy "Users can manage own friends"
  on public.friends for all
  using (auth.uid() = user_id);

create policy "Users can read friend profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.friends f
      where (f.user_id = auth.uid() and f.friend_id = profiles.id)
         or (f.user_id = profiles.id and f.friend_id = auth.uid())
    )
  );

-- ---------------------------------------------------------------------------
-- Chat rooms (character + DM)
-- ---------------------------------------------------------------------------
create table public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  character_id uuid references public.characters(id) on delete set null,
  external_character_key text,
  peer_user_id uuid references public.profiles(id) on delete cascade,
  room_type text not null default 'character',
  title text not null,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_rooms_room_type_check check (room_type in ('character', 'dm')),
  constraint chat_rooms_room_shape_check check (
    (room_type = 'character' and peer_user_id is null)
    or (
      room_type = 'dm'
      and peer_user_id is not null
      and character_id is null
      and external_character_key is null
    )
  )
);

create index chat_rooms_user_id_idx on public.chat_rooms(user_id);

create unique index chat_rooms_user_character_id_uniq
  on public.chat_rooms (user_id, character_id)
  where character_id is not null;

create unique index chat_rooms_user_external_key_uniq
  on public.chat_rooms (user_id, external_character_key)
  where external_character_key is not null;

create unique index chat_rooms_dm_pair_uniq
  on public.chat_rooms (user_id, peer_user_id)
  where room_type = 'dm';

alter table public.chat_rooms enable row level security;

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

-- ---------------------------------------------------------------------------
-- User blocks (required before chat_messages insert RLS references user_blocks)
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Chat messages
-- ---------------------------------------------------------------------------
create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  explanation text,
  vocabulary jsonb,
  sender_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint chat_messages_role_sender_check check (
    (sender_id is null and role in ('user', 'assistant'))
    or (sender_id is not null and role = 'user')
  )
);

create index chat_messages_room_id_idx on public.chat_messages(room_id);

alter table public.chat_messages enable row level security;

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

-- ---------------------------------------------------------------------------
-- Saved expressions
-- ---------------------------------------------------------------------------
create table public.saved_expressions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source text check (source in ('chat', 'call')),
  content text,
  explanation text,
  translation text,
  notebook_lang text not null default 'ko' check (notebook_lang in ('ko', 'ja')),
  room_id uuid references public.chat_rooms(id) on delete set null,
  created_at timestamptz not null default now()
);

create index saved_expressions_user_notebook_lang_idx
  on public.saved_expressions (user_id, notebook_lang, created_at desc);

comment on table public.saved_expressions is
  'Vocabulary rows: user saves individual words from chat explanation sheet via +.';

comment on column public.saved_expressions.content is
  'Headword (word or short phrase) in the studied language.';

comment on column public.saved_expressions.translation is
  'Reading and gloss line (e.g. hiragana — meaning).';

comment on column public.saved_expressions.explanation is
  'Deprecated for new saves (leave null). Legacy rows may contain old full-message explanation text.';

alter table public.saved_expressions enable row level security;

create policy "saved_expressions_select_own"
  on public.saved_expressions for select
  using (auth.uid() = user_id);

create policy "saved_expressions_insert_own"
  on public.saved_expressions for insert
  with check (auth.uid() = user_id);

create policy "saved_expressions_update_own"
  on public.saved_expressions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "saved_expressions_delete_own"
  on public.saved_expressions for delete
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- User theme overrides
-- ---------------------------------------------------------------------------
create table public.themes (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  chat_bubble_user text,
  chat_bubble_bot text,
  chat_bg text,
  accent text,
  updated_at timestamptz not null default now()
);

alter table public.themes enable row level security;

create policy "Users can manage own theme"
  on public.themes for all
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Triggers: profile on sign up
-- ---------------------------------------------------------------------------
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

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Trigger: update chat_rooms.last_message_at
-- ---------------------------------------------------------------------------
create or replace function public.update_chat_room_last_message()
returns trigger as $$
begin
  update public.chat_rooms
  set last_message_at = new.created_at, updated_at = now()
  where id = new.room_id;
  return new;
end;
$$ language plpgsql;

create trigger on_chat_message_inserted
  after insert on public.chat_messages
  for each row execute procedure public.update_chat_room_last_message();

-- ---------------------------------------------------------------------------
-- RPC: friends
-- ---------------------------------------------------------------------------
create or replace function public.list_my_friends()
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

-- ---------------------------------------------------------------------------
-- RPC: search profiles / characters
-- ---------------------------------------------------------------------------
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

create or replace function public.search_accessible_characters(search_query text, result_limit int default 20)
returns setof public.characters
language sql
security definer
set search_path = public
stable
as $$
  select c.*
  from public.characters c
  where auth.uid() is not null
    and length(trim(search_query)) >= 2
    and (c.owner_id = auth.uid() or c.is_public = true)
    and (
      c.name ilike ('%' || trim(search_query) || '%')
      or coalesce(c.name_secondary, '') ilike ('%' || trim(search_query) || '%')
    )
  order by (c.owner_id = auth.uid()) desc, c.name asc
  limit least(coalesce(nullif(result_limit, 0), 20), 50);
$$;

revoke all on function public.search_accessible_characters(text, int) from public;
grant execute on function public.search_accessible_characters(text, int) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: DM room
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- RPC: blocks
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Storage buckets
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('backgrounds', 'backgrounds', true),
  ('dm_voice', 'dm_voice', true)
on conflict (id) do update set public = excluded.public;

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

-- ---------------------------------------------------------------------------
-- Realtime publication
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_rooms'
  ) then
    alter publication supabase_realtime add table public.chat_rooms;
  end if;
end $$;
