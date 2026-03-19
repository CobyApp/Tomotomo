-- Built-in characters use non-UUID ids; store them in external_character_key when character_id is null.

alter table public.chat_rooms add column if not exists external_character_key text;

-- One chat room per user per Supabase character
create unique index if not exists chat_rooms_user_character_id_uniq
  on public.chat_rooms (user_id, character_id)
  where character_id is not null;

-- One chat room per user per built-in character key
create unique index if not exists chat_rooms_user_external_key_uniq
  on public.chat_rooms (user_id, external_character_key)
  where external_character_key is not null;
