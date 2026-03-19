-- Search characters the current user may use in chat (own + public) by name.

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
