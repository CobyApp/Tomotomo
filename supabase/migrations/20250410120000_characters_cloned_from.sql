-- Track public-character forks: same user can only have one clone per source.
-- ON DELETE SET NULL on source row keeps the fork row usable when the author deletes the original.
alter table public.characters
  add column if not exists cloned_from_id uuid references public.characters (id) on delete set null;

create unique index if not exists characters_owner_cloned_from_unique
  on public.characters (owner_id, cloned_from_id)
  where cloned_from_id is not null;
