-- Run once in Supabase SQL Editor if you see:
-- PostgresException: infinite recursion detected in policy for relation "groups"
--
-- Cause: groups_select_via_membership reads group_members; group_members_select
-- read groups again → cycle. Fix: check ownership via SECURITY DEFINER (no RLS re-entry).

create or replace function public.current_user_owns_group(p_group_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.groups g
    where g.id = p_group_id and g.user_id = auth.uid()
  );
$$;

revoke all on function public.current_user_owns_group(uuid) from public;
grant execute on function public.current_user_owns_group(uuid) to authenticated;

drop policy if exists "group_members_select" on public.group_members;
create policy "group_members_select" on public.group_members
  for select using (
    user_id = auth.uid()
    or public.current_user_owns_group(group_id)
  );

drop policy if exists "group_members_owner_insert" on public.group_members;
create policy "group_members_owner_insert" on public.group_members
  for insert with check (
    public.current_user_owns_group(group_id)
  );
