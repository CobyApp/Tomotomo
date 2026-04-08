-- Persist full-line learner translation from tutor JSON (full_translation) alongside explanation.
alter table public.chat_messages
  add column if not exists line_translation text;

comment on column public.chat_messages.line_translation is 'Learner-facing full-line translation from assistant JSON (e.g. Japanese line → Korean).';
