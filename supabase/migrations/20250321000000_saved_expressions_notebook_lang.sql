-- Split saved expressions into Korean vs Japanese notebooks per user.
alter table public.saved_expressions
  add column if not exists notebook_lang text not null default 'ko';

alter table public.saved_expressions
  drop constraint if exists saved_expressions_notebook_lang_check;

alter table public.saved_expressions
  add constraint saved_expressions_notebook_lang_check
  check (notebook_lang in ('ko', 'ja'));

create index if not exists saved_expressions_user_notebook_lang_idx
  on public.saved_expressions (user_id, notebook_lang, created_at desc);
