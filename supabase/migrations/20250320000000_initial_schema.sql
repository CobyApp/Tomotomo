-- Tomotomo v2 initial schema
-- Run in Supabase SQL Editor or via supabase db push

-- Profiles (extends auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
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

-- Characters (custom + shared)
create table public.characters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  name_secondary text,
  avatar_url text,
  background_url text,
  speech_style text,
  voice_provider text,
  voice_id text,
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

-- Friends
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

-- Chat rooms
create table public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  character_id uuid references public.characters(id) on delete set null,
  title text not null,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index chat_rooms_user_id_idx on public.chat_rooms(user_id);

alter table public.chat_rooms enable row level security;

create policy "Users can manage own chat rooms"
  on public.chat_rooms for all
  using (auth.uid() = user_id);

-- Chat messages
create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  explanation text,
  vocabulary jsonb,
  created_at timestamptz not null default now()
);

create index chat_messages_room_id_idx on public.chat_messages(room_id);

alter table public.chat_messages enable row level security;

create policy "Users can read messages in own rooms"
  on public.chat_messages for select
  using (
    exists (
      select 1 from public.chat_rooms r
      where r.id = room_id and r.user_id = auth.uid()
    )
  );

create policy "Users can insert messages in own rooms"
  on public.chat_messages for insert
  with check (
    exists (
      select 1 from public.chat_rooms r
      where r.id = room_id and r.user_id = auth.uid()
    )
  );

-- Saved expressions
create table public.saved_expressions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source text check (source in ('chat', 'call')),
  content text,
  explanation text,
  translation text,
  room_id uuid references public.chat_rooms(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.saved_expressions enable row level security;

create policy "Users can manage own saved expressions"
  on public.saved_expressions for all
  using (auth.uid() = user_id);

-- User theme overrides
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

-- Trigger: create profile on sign up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger: update chat_rooms.last_message_at
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
