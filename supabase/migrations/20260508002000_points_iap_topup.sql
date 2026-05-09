-- IAP point top-up ledger + idempotent credit RPC.

create table if not exists public.point_topup_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  store text not null check (store in ('app_store', 'play_store')),
  transaction_id text not null,
  product_id text not null,
  purchase_token text,
  points int not null check (points > 0),
  usd_cents int not null check (usd_cents >= 0),
  raw_receipt text,
  created_at timestamptz not null default now()
);

create unique index if not exists point_topup_receipts_store_txn_unique
  on public.point_topup_receipts (store, transaction_id);

create unique index if not exists point_topup_receipts_store_token_unique
  on public.point_topup_receipts (store, purchase_token)
  where purchase_token is not null and length(trim(purchase_token)) > 0;

create index if not exists point_topup_receipts_user_created_idx
  on public.point_topup_receipts (user_id, created_at desc);

alter table public.point_topup_receipts enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'point_topup_receipts'
      and policyname = 'point_topup_receipts_select_own'
  ) then
    create policy "point_topup_receipts_select_own"
      on public.point_topup_receipts for select
      using (auth.uid() = user_id);
  end if;
end $$;

create or replace function public.credit_iap_points(
  p_store text,
  p_transaction_id text,
  p_product_id text,
  p_purchase_token text,
  p_points int,
  p_usd_cents int,
  p_raw_receipt text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  ins_count int := 0;
  new_bal int := 0;
begin
  if uid is null then
    return jsonb_build_object(
      'ok', false,
      'credited', false,
      'error', 'not_authenticated',
      'balance', null
    );
  end if;
  if p_store not in ('app_store', 'play_store') then
    return jsonb_build_object('ok', false, 'credited', false, 'error', 'invalid_store', 'balance', null);
  end if;
  if p_transaction_id is null or length(trim(p_transaction_id)) = 0 then
    return jsonb_build_object('ok', false, 'credited', false, 'error', 'invalid_transaction_id', 'balance', null);
  end if;
  if p_product_id is null or length(trim(p_product_id)) = 0 then
    return jsonb_build_object('ok', false, 'credited', false, 'error', 'invalid_product_id', 'balance', null);
  end if;
  if p_points is null or p_points <= 0 then
    return jsonb_build_object('ok', false, 'credited', false, 'error', 'invalid_points', 'balance', null);
  end if;
  if p_usd_cents is null or p_usd_cents < 0 then
    return jsonb_build_object('ok', false, 'credited', false, 'error', 'invalid_price', 'balance', null);
  end if;

  insert into public.point_topup_receipts (
    user_id,
    store,
    transaction_id,
    product_id,
    purchase_token,
    points,
    usd_cents,
    raw_receipt
  )
  values (
    uid,
    p_store,
    trim(p_transaction_id),
    trim(p_product_id),
    nullif(trim(coalesce(p_purchase_token, '')), ''),
    p_points,
    p_usd_cents,
    p_raw_receipt
  )
  on conflict do nothing;
  get diagnostics ins_count = row_count;

  if ins_count > 0 then
    update public.profiles
    set
      point_balance = coalesce(point_balance, 0) + p_points,
      updated_at = now()
    where id = uid
    returning point_balance into new_bal;

    return jsonb_build_object(
      'ok', true,
      'credited', true,
      'error', null,
      'balance', coalesce(new_bal, 0)
    );
  end if;

  select coalesce(point_balance, 0) into new_bal
  from public.profiles
  where id = uid;

  return jsonb_build_object(
    'ok', true,
    'credited', false,
    'error', 'duplicate_receipt',
    'balance', coalesce(new_bal, 0)
  );
end;
$$;

revoke all on function public.credit_iap_points(text, text, text, text, int, int, text) from public;
grant execute on function public.credit_iap_points(text, text, text, text, int, int, text) to authenticated;
