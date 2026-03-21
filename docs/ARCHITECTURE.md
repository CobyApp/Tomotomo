# Tomotomo v2 — Architecture & Feature Plan

## Overview
Line/KakaoTalk-style language learning app with Supabase backend: auth, custom characters, chat, voice chat, expression notebook, themes, and sharing.

### Implemented slice (current repo)
Auth, profiles, custom characters + discover, Supabase-backed AI chat & DM, friends (UUID), expression notebook, themes, Storage avatars/backgrounds, Realtime for `chat_messages` / `chat_rooms`, app-resume silent refresh (main tabs + open chat screen). **Not in this slice:** push notifications, voice chat, email/username friend discovery, read receipts.

## App lifecycle
- Main tabs (**Friends**, **Chats**, **Characters**) use `OnAppResumedMixin` (`lib/core/widgets/on_app_resumed_mixin.dart`): on `AppLifecycleState.resumed`, run a **silent** list reload to catch changes missed while backgrounded (complements Realtime).
- **Chat screen** (`ChatScreen`): `didChangeAppLifecycleState` calls `ChatViewModel.onAppResumedSync()` (debounced reload; defers while Gemini is generating, same as Realtime).

## Bottom navigation (4 tabs)
1. **Friends** — Friend list (Supabase `friends` + RPC); add by UUID; tap → DM (`ensure_dm_room` + shared `chat_rooms` row)
2. **Chats** — Chat room list (recent chats)
3. **Characters** — Custom characters (mine + discover online)
4. **Settings** — Account, theme, app language, logout

## Supabase schema (core)

### auth.users
- Supabase Auth (email/password). No extra tables for auth.

### public.profiles
- `id` uuid PK (auth.users.id)
- `email` text
- `display_name` text
- `avatar_url` text (Storage)
- `app_language` text ('ko' | 'ja') — UI language
- `learning_language` text ('ko' | 'ja') — which language to learn
- `created_at`, `updated_at` timestamptz

### public.characters
- `id` uuid PK
- `owner_id` uuid FK profiles(id)
- `name` text, `name_secondary` text (e.g. Japanese name)
- `avatar_url` text (Storage)
- `speech_style` text (persona / tone hints for the model)
- `language` text ('ko' | 'ja') — **AI chat persona** for *Japanese study*: `ja` = Japanese-speaking character (bubble in Japanese, study notes in Korean); `ko` = Korean friend (bubble in Korean, study notes in Japanese). See `lib/data/repositories/gemini_prompts/`.
- `is_public` boolean, `download_count` int
- `created_at`, `updated_at` timestamptz

### public.friends
- `user_id` uuid, `friend_id` uuid, unique(user_id, friend_id)
- `created_at` timestamptz

### public.chat_rooms
- **Realtime**: optional publication for list refresh (`20250320700000_chat_rooms_realtime.sql`).
- `id` uuid PK
- `user_id` uuid (character room: owner; DM: smaller participant UUID)
- `peer_user_id` uuid (DM only; larger participant UUID; canonical pair)
- `room_type` text (`character` | `dm`)
- `character_id` uuid (nullable; DM must be null)
- `external_character_key` text (built-in characters)
- `title` text (character name or DM display label from app)
- `last_message_at` timestamptz
- `created_at`, `updated_at` timestamptz

### public.chat_messages
- `id` uuid PK
- `sender_id` uuid (DM human messages; null for AI character chat)
- `room_id` uuid FK
- **Realtime**: add table to `supabase_realtime` publication; see `20250320600000_chat_messages_realtime.sql`. Subscriptions listen for **all** row events (insert/update/delete) and refetch messages; character (AI) chats defer reload while Gemini is generating. Channel **timedOut/channelError** triggers backoff resubscribe (chat screen + chats tab list).
- `role` text (AI: `user` | `assistant` with `sender_id` null; DM: `user` with `sender_id` = author)
- `content` text, `explanation` text
- `vocabulary` jsonb
- `created_at` timestamptz

### public.saved_expressions (word book)
- Per **vocabulary row** saved from chat via `+` on each word in the explanation sheet — not the full popup.
- `id` uuid PK, `user_id` uuid, `source` text ('chat' | 'call')
- `notebook_lang` text (`ko` | `ja`) — Korean vs Japanese word-book segment
- `content` text — headword; `translation` text — reading + gloss line
- `explanation` text — legacy only (new saves leave null); see `20250321200000_saved_expressions_word_semantics.sql`
- `room_id` uuid nullable, `created_at` timestamptz

### public.themes (user theme override)
- `user_id` uuid PK
- `chat_bubble_user` text (color hex)
- `chat_bubble_bot` text
- `chat_bg` text
- `accent` text
- `updated_at` timestamptz

### Storage buckets
- `avatars` — profile and character avatars
- `backgrounds` — optional legacy bucket (character backgrounds removed from app schema)
- RLS: upload by owner path prefix

## Features (implementation order)

### Phase 1 — Foundation
- [x] Supabase init, env (SUPABASE_URL, SUPABASE_ANON_KEY)
- [ ] Email/password sign up & login
- [ ] Auth gate: show login/signup if not signed in
- [ ] Bottom nav shell: Friends / Chats / Characters / Settings
- [ ] Profiles table + RLS; create profile on first sign up

### Phase 2 — Characters & Chats
- [x] Custom character CRUD (create with avatar, background, speech_style, language)
- [x] Chat rooms and messages in Supabase (`SupabaseChatRepository`, Chats tab)
- [x] Character list: my characters + public discover

### Phase 3 — Voice & UX
- [x] Device STT + TTS (`speech_to_text`, `flutter_tts`): **Voice chat screen** from AI character chat (hold mic → same Supabase messages as text chat; assistant line read aloud in Japanese)
- [ ] Rich call UI (waveform, expression sheet during call)
- [ ] Call summary and save expressions

### Phase 4 — Polish
- [x] Expression/vocabulary notebook (Supabase list, delete, save from chat sheet)
- [x] Theme customization (chat bubble, accent) stored in Supabase; presets in Settings
- [x] Character sharing: publish, download, delete (owner only)
- [x] App locale: Korean / Japanese UI via `profiles.app_language` + `AppStrings` / `LocaleNotifier`

## App locale
- `app_language`: 'ko' | 'ja' — entire UI in this language
- `learning_language`: 'ko' | 'ja' — learning target (character language)
- Characters have `language`; show only characters matching learning_language in main flows.
