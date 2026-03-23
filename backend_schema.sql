-- Supabase schema for Campus TaskHub (mirrors screen 1-4 immutable backends)

-- tasks table (for Upcoming Deadlines + Tasks screen)
create table if not exists tasks (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references groups(id) on delete cascade,
  title text not null,
  description text,
  subject text,
  priority text check (priority in ('Low', 'Medium', 'High')) default 'Medium',
  due_date timestamptz,
  status text check (status in ('Pending','To Do','In Progress','Done')) default 'Pending',
  created_at timestamptz default now()
);

-- projects table (for Project Hub screen)
create table if not exists projects (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references groups(id) on delete cascade,
  title text not null,
  category text,
  status text check (status in ('Active','Completed','Request')) default 'Active',
  completion int check (completion >= 0 and completion <= 100) default 0,
  next_step text,
  members text[] default array[]::text[],
  created_at timestamptz default now()
);

-- schedule_events table (for Schedule / Calendar screen)
create table if not exists schedule_events (
  id uuid default uuid_generate_v4() primary key,
  group_id uuid references groups(id) on delete cascade,
  title text not null,
  course text,
  location text,
  event_type text check (event_type in ('Lecture','Lab','Session','Study','Other')) default 'Lecture',
  start_time timestamptz not null,
  end_time timestamptz not null,
  created_at timestamptz default now()
);

-- groups table (existing group association)
create table if not exists groups (
  id uuid default uuid_generate_v4() primary key,
  group_name text not null,
  created_at timestamptz default now()
);
