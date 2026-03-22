-- Campus TaskHub — Supabase SQL Editor → New query → Run.
-- Safe for existing projects: adds missing columns BEFORE indexes/policies.

-- ---------------------------------------------------------------------------
-- 1) Ensure base tables exist (minimal columns if created from scratch)
-- ---------------------------------------------------------------------------
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  group_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  title text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 2) Add columns your app expects (no-op if already present)
-- ---------------------------------------------------------------------------
alter table public.groups
  add column if not exists user_id uuid references auth.users (id) on delete cascade;

alter table public.tasks
  add column if not exists subject text not null default 'GENERAL';

alter table public.tasks
  add column if not exists due_date date;

alter table public.tasks
  add column if not exists priority text not null default 'med';

alter table public.tasks
  add column if not exists user_id uuid references auth.users (id) on delete set null;

-- Optional: set owner on old groups so RLS can see them (use your auth user UUID from Authentication → Users)
-- update public.groups set user_id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' where user_id is null;

-- ---------------------------------------------------------------------------
-- 3) Indexes (only after columns exist)
-- ---------------------------------------------------------------------------
create index if not exists groups_user_id_idx on public.groups (user_id);
create index if not exists tasks_group_id_idx on public.tasks (group_id);

-- ---------------------------------------------------------------------------
-- 4) Row Level Security
-- ---------------------------------------------------------------------------
alter table public.groups enable row level security;
alter table public.tasks enable row level security;

drop policy if exists "groups_select_own" on public.groups;
create policy "groups_select_own" on public.groups
  for select using (auth.uid() = user_id);

drop policy if exists "groups_insert_own" on public.groups;
create policy "groups_insert_own" on public.groups
  for insert with check (auth.uid() = user_id);

drop policy if exists "groups_update_own" on public.groups;
create policy "groups_update_own" on public.groups
  for update using (auth.uid() = user_id);

drop policy if exists "groups_delete_own" on public.groups;
create policy "groups_delete_own" on public.groups
  for delete using (auth.uid() = user_id);

drop policy if exists "tasks_select_via_group" on public.tasks;
create policy "tasks_select_via_group" on public.tasks
  for select using (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
  );

drop policy if exists "tasks_insert_via_group" on public.tasks;
create policy "tasks_insert_via_group" on public.tasks
  for insert with check (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
  );

drop policy if exists "tasks_update_via_group" on public.tasks;
create policy "tasks_update_via_group" on public.tasks
  for update using (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
  );

drop policy if exists "tasks_delete_via_group" on public.tasks;
create policy "tasks_delete_via_group" on public.tasks
  for delete using (
    exists (
      select 1 from public.groups g
      where g.id = tasks.group_id and g.user_id = auth.uid()
    )
  );
