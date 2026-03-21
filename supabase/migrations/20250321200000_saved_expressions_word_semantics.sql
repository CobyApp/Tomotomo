-- Clarify semantics: rows are per-word saves from chat (+), not full popup dumps.
comment on table public.saved_expressions is
  'Vocabulary rows: user saves individual words from chat explanation sheet via +.';

comment on column public.saved_expressions.content is
  'Headword (word or short phrase) in the studied language.';

comment on column public.saved_expressions.translation is
  'Reading and gloss line (e.g. hiragana — meaning).';

comment on column public.saved_expressions.explanation is
  'Deprecated for new saves (leave null). Legacy rows may contain old full-message explanation text.';
