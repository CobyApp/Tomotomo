-- Short one-line intro for list UI (name on top, tagline below). Filled by X import / editor.
alter table public.characters
  add column if not exists tagline text;

comment on column public.characters.tagline is 'Public-facing one-line self-intro (~20 chars) for list subtitles; separate from speech_style (AI instructions).';
