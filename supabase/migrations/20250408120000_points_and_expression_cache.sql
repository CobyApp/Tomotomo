-- Point wallet on profiles + RPCs for spending, DM expression unlock (1 pt once per message), and line-analysis cache.

-- ---------------------------------------------------------------------------
-- Column: default 500 for new rows; existing profiles get 500 on migration add.
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column if not exists point_balance int not null default 500;

update public.profiles
set point_balance = 500
where point_balance is null;

-- ---------------------------------------------------------------------------
-- New signups: explicit 500 (same as default)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, status_message, point_balance)
  values (
    new.id,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), split_part(new.email, '@', 1)),
    nullif(trim(new.raw_user_meta_data->>'status_message'), ''),
    500
  );
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- DM: first time user opens learning sheet for a message → 1 point (idempotent per message)
-- ---------------------------------------------------------------------------
create table public.dm_expression_unlocks (
  user_id uuid not null references public.profiles(id) on delete cascade,
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, message_id)
);

create index dm_expression_unlocks_message_id_idx on public.dm_expression_unlocks(message_id);

alter table public.dm_expression_unlocks enable row level security;

create policy "dm_expression_unlocks_select_own"
  on public.dm_expression_unlocks for select
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Cached Gemini line analysis (per viewer × message × app UI language)
-- ---------------------------------------------------------------------------
create table public.chat_message_line_analysis_cache (
  user_id uuid not null references public.profiles(id) on delete cascade,
  message_id uuid not null references public.chat_messages(id) on delete cascade,
  app_lang text not null check (app_lang in ('ko', 'ja')),
  explanation text,
  line_translation text,
  vocabulary jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, message_id, app_lang)
);

create index chat_message_line_analysis_cache_message_idx on public.chat_message_line_analysis_cache(message_id);

alter table public.chat_message_line_analysis_cache enable row level security;

create policy "line_analysis_cache_select_own"
  on public.chat_message_line_analysis_cache for select
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- spend_points: returns { ok, balance, error }
-- ---------------------------------------------------------------------------
create or replace function public.spend_points(p_amount int, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  new_bal int;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated', 'balance', null);
  end if;
  if p_amount is null or p_amount <= 0 then
    return jsonb_build_object('ok', false, 'error', 'invalid_amount', 'balance', null);
  end if;

  update public.profiles
  set
    point_balance = point_balance - p_amount,
    updated_at = now()
  where id = uid and point_balance >= p_amount
  returning point_balance into new_bal;

  if new_bal is null then
    select p.point_balance into new_bal from public.profiles p where p.id = uid;
    return jsonb_build_object(
      'ok', false,
      'error', 'insufficient_points',
      'balance', coalesce(new_bal, 0)
    );
  end if;

  return jsonb_build_object('ok', true, 'error', null, 'balance', new_bal);
end;
$$;

revoke all on function public.spend_points(int, text) from public;
grant execute on function public.spend_points(int, text) to authenticated;

-- ---------------------------------------------------------------------------
-- DM learning popup: charge once per (user, message); idempotent
-- ---------------------------------------------------------------------------
create or replace function public.try_unlock_dm_expression(p_message_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  new_bal int;
  ins_count int;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated', 'balance', null, 'charged', false);
  end if;

  if not exists (
    select 1
    from public.chat_messages m
    join public.chat_rooms r on r.id = m.room_id
    where m.id = p_message_id
      and r.room_type = 'dm'
      and (r.user_id = uid or r.peer_user_id = uid)
  ) then
    return jsonb_build_object('ok', false, 'error', 'forbidden', 'balance', null, 'charged', false);
  end if;

  insert into public.dm_expression_unlocks (user_id, message_id)
  values (uid, p_message_id)
  on conflict (user_id, message_id) do nothing;
  get diagnostics ins_count = row_count;

  if ins_count > 0 then
    update public.profiles
    set point_balance = point_balance - 1, updated_at = now()
    where id = uid and point_balance >= 1
    returning point_balance into new_bal;

    if new_bal is null then
      delete from public.dm_expression_unlocks where user_id = uid and message_id = p_message_id;
      select p.point_balance into new_bal from public.profiles p where p.id = uid;
      return jsonb_build_object(
        'ok', false,
        'error', 'insufficient_points',
        'balance', coalesce(new_bal, 0),
        'charged', false
      );
    end if;

    return jsonb_build_object('ok', true, 'error', null, 'balance', new_bal, 'charged', true);
  end if;

  select p.point_balance into new_bal from public.profiles p where p.id = uid;
  return jsonb_build_object(
    'ok', true,
    'error', null,
    'balance', coalesce(new_bal, 0),
    'charged', false
  );
end;
$$;

revoke all on function public.try_unlock_dm_expression(uuid) from public;
grant execute on function public.try_unlock_dm_expression(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Line analysis cache (character + DM); no charge here — unlock handled separately for DM
-- ---------------------------------------------------------------------------
create or replace function public.get_line_analysis_cache(p_message_id uuid, p_app_lang text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  rec public.chat_message_line_analysis_cache%rowtype;
begin
  if uid is null then
    return null;
  end if;
  if p_app_lang is null or p_app_lang not in ('ko', 'ja') then
    return null;
  end if;

  if not exists (
    select 1
    from public.chat_messages m
    join public.chat_rooms r on r.id = m.room_id
    where m.id = p_message_id
      and (
        (r.room_type = 'character' and r.user_id = uid)
        or (r.room_type = 'dm' and (r.user_id = uid or r.peer_user_id = uid))
      )
  ) then
    return null;
  end if;

  select c.*
  into rec
  from public.chat_message_line_analysis_cache c
  where c.user_id = uid
    and c.message_id = p_message_id
    and c.app_lang = p_app_lang;

  if rec.message_id is null then
    return null;
  end if;

  return jsonb_build_object(
    'explanation', rec.explanation,
    'line_translation', rec.line_translation,
    'vocabulary', coalesce(rec.vocabulary, '[]'::jsonb)
  );
end;
$$;

revoke all on function public.get_line_analysis_cache(uuid, text) from public;
grant execute on function public.get_line_analysis_cache(uuid, text) to authenticated;

create or replace function public.save_line_analysis_cache(
  p_message_id uuid,
  p_app_lang text,
  p_explanation text,
  p_line_translation text,
  p_vocabulary jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not_authenticated';
  end if;
  if p_app_lang is null or p_app_lang not in ('ko', 'ja') then
    raise exception 'invalid_app_lang';
  end if;

  if not exists (
    select 1
    from public.chat_messages m
    join public.chat_rooms r on r.id = m.room_id
    where m.id = p_message_id
      and (
        (r.room_type = 'character' and r.user_id = uid)
        or (r.room_type = 'dm' and (r.user_id = uid or r.peer_user_id = uid))
      )
  ) then
    raise exception 'forbidden';
  end if;

  insert into public.chat_message_line_analysis_cache (
    user_id, message_id, app_lang, explanation, line_translation, vocabulary, updated_at
  )
  values (
    uid, p_message_id, p_app_lang, p_explanation, p_line_translation, coalesce(p_vocabulary, '[]'::jsonb), now()
  )
  on conflict (user_id, message_id, app_lang) do update set
    explanation = excluded.explanation,
    line_translation = excluded.line_translation,
    vocabulary = excluded.vocabulary,
    updated_at = now();
end;
$$;

revoke all on function public.save_line_analysis_cache(uuid, text, text, text, jsonb) from public;
grant execute on function public.save_line_analysis_cache(uuid, text, text, text, jsonb) to authenticated;
