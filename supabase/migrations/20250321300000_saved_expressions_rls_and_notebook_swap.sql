-- 1) Split RLS so DELETE (and other ops) match PostgREST expectations.
drop policy if exists "Users can manage own saved expressions" on public.saved_expressions;

create policy "saved_expressions_select_own"
  on public.saved_expressions for select
  using (auth.uid() = user_id);

create policy "saved_expressions_insert_own"
  on public.saved_expressions for insert
  with check (auth.uid() = user_id);

create policy "saved_expressions_update_own"
  on public.saved_expressions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "saved_expressions_delete_own"
  on public.saved_expressions for delete
  using (auth.uid() = user_id);

-- Do not bulk-swap notebook_lang here: users who already updated the app would get correct rows flipped.
-- Wrong-tab legacy rows: delete and re-save from chat, or run a one-off SQL if you know your data.
