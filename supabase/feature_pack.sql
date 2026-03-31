-- Feature pack: pinned tasks, progress %, join codes, group members, app roles, task RLS for members.
-- Run in Supabase SQL Editor after schema.sql and academic_registration.sql.

-- ---------------------------------------------------------------------------
-- Tasks: pin + progress
-- ---------------------------------------------------------------------------
alter table public.tasks
  add column if not exists is_pinned boolean not null default false;

alter table public.tasks
  add column if not exists progress_percent smallint not null default 0;

alter table public.tasks
  add constraint tasks_progress_percent_range
  check (progress_percent >= 0 and progress_percent <= 100);

-- ---------------------------------------------------------------------------
-- Groups: optional join code (short code for invite flow)
-- ---------------------------------------------------------------------------
alter table public.groups
  add column if not exists join_code text;

create unique index if not exists groups_join_code_unique
  on public.groups (join_code)
  where join_code is not null;

-- ---------------------------------------------------------------------------
-- Group members (for shared task access after join)
-- ---------------------------------------------------------------------------
create table if not exists public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index if not exists group_members_user_idx on public.group_members (user_id);

-- ---------------------------------------------------------------------------
-- Student profile: app role (display + future permission gates)
-- ---------------------------------------------------------------------------
alter table public.student_profiles
  add column if not exists app_role text not null default 'student';

alter table public.student_profiles
  add constraint student_profiles_app_role_check
  check (app_role in ('student', 'faculty', 'admin'));

-- ---------------------------------------------------------------------------
-- Join by code (RPC) — avoids exposing all groups to RLS guessing
-- ---------------------------------------------------------------------------
create or replace function public.join_group_by_code(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  gid uuid;
begin
  if p_code is null or length(trim(p_code)) < 4 then
    raise exception 'invalid code';
  end if;
  select id into gid
  from public.groups
  where join_code = trim(p_code)
  limit 1;
  if gid is null then
    raise exception 'invalid code';
  end if;
  insert into public.group_members (group_id, user_id, role)
  values (gid, auth.uid(), 'member')
  on conflict (group_id, user_id) do nothing;
  return gid;
end;
$$;

grant execute on function public.join_group_by_code(text) to authenticated;

-- Breaks infinite recursion: groups policy → group_members policy → groups policy.
-- Ownership is checked with SECURITY DEFINER so it does not re-enter groups RLS.
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

-- Members can read group rows (name, join code) for groups they belong to
drop policy if exists "groups_select_via_membership" on public.groups;
create policy "groups_select_via_membership" on public.groups
  for select using (
    exists (
      select 1 from public.group_members m
      where m.group_id = groups.id and m.user_id = auth.uid()
    )
  );

-- Owner is also a logical member for queries (optional backfill skipped — owner uses group.user_id)

-- ---------------------------------------------------------------------------
-- RLS: group_members
-- ---------------------------------------------------------------------------
alter table public.group_members enable row level security;

drop policy if exists "group_members_select" on public.group_members;
create policy "group_members_select" on public.group_members
  for select using (
    user_id = auth.uid()
    or public.current_user_owns_group(group_id)
  );

-- Members join via join_group_by_code (security definer). Owners can add rows directly:
drop policy if exists "group_members_owner_insert" on public.group_members;
create policy "group_members_owner_insert" on public.group_members
  for insert with check (
    public.current_user_owns_group(group_id)
  );

-- ---------------------------------------------------------------------------
-- Tasks: allow members of shared groups (not only owner)
-- ---------------------------------------------------------------------------
drop policy if exists "tasks_select_via_group" on public.tasks;
create policy "tasks_select_via_group" on public.tasks
  for select using (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
    or exists (
      select 1 from public.group_members m
      where m.group_id = tasks.group_id and m.user_id = auth.uid()
    )
  );

drop policy if exists "tasks_insert_via_group" on public.tasks;
create policy "tasks_insert_via_group" on public.tasks
  for insert with check (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
    or exists (
      select 1 from public.group_members m
      where m.group_id = tasks.group_id and m.user_id = auth.uid()
    )
  );

drop policy if exists "tasks_update_via_group" on public.tasks;
create policy "tasks_update_via_group" on public.tasks
  for update using (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
    or exists (
      select 1 from public.group_members m
      where m.group_id = tasks.group_id and m.user_id = auth.uid()
    )
  );

drop policy if exists "tasks_delete_via_group" on public.tasks;
create policy "tasks_delete_via_group" on public.tasks
  for delete using (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
    or exists (
      select 1 from public.group_members m
      where m.group_id = tasks.group_id and m.user_id = auth.uid()
    )
  );
