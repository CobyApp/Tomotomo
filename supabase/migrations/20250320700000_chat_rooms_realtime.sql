-- Enable Postgres → Realtime for chat_rooms (recent list order / last_message_at)
-- RLS limits which row events each user receives.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_rooms'
  ) then
    alter publication supabase_realtime add table public.chat_rooms;
  end if;
end $$;
