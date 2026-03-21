-- Remove unused character columns (UI uses avatar + speech_style + names only).

alter table public.characters
  drop column if exists background_url,
  drop column if exists tagline,
  drop column if exists voice_provider,
  drop column if exists voice_id;
