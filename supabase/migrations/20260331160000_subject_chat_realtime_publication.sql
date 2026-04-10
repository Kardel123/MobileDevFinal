-- Add subject_chat_messages to the Realtime publication so clients receive live INSERT/UPDATE/DELETE.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'subject_chat_messages'
  ) then
    alter publication supabase_realtime add table public.subject_chat_messages;
  end if;
end $$;
