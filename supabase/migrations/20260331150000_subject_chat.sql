-- Subject room chat: enrolled students + assigned faculty (teacher admin).
-- Run after academic_registration.sql (needs catalog_subjects, student_enrollments, student_profiles.app_role).

-- ---------------------------------------------------------------------------
-- Faculty assigned to subjects (teacher = admin for moderation in app)
-- ---------------------------------------------------------------------------
create table if not exists public.subject_faculty (
  catalog_subject_id uuid not null references public.catalog_subjects (id) on delete cascade,
  faculty_user_id uuid not null references auth.users (id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (catalog_subject_id, faculty_user_id)
);

create index if not exists subject_faculty_user_idx on public.subject_faculty (faculty_user_id);

-- ---------------------------------------------------------------------------
-- Messages (one thread per subject)
-- ---------------------------------------------------------------------------
create table if not exists public.subject_chat_messages (
  id uuid primary key default gen_random_uuid(),
  catalog_subject_id uuid not null references public.catalog_subjects (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  body text not null check (char_length(trim(body)) > 0 and char_length(body) <= 4000),
  created_at timestamptz not null default now()
);

create index if not exists subject_chat_messages_subject_time_idx
  on public.subject_chat_messages (catalog_subject_id, created_at desc);

-- Realtime: In Supabase Dashboard → Database → Publications, add `subject_chat_messages`
-- to `supabase_realtime` so the app receives live inserts.

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.subject_faculty enable row level security;
alter table public.subject_chat_messages enable row level security;

-- Faculty can see their assignments; students can see who teaches (optional — keep simple: faculty-only read own rows)
drop policy if exists "subject_faculty_select" on public.subject_faculty;
create policy "subject_faculty_select" on public.subject_faculty
  for select using (
    faculty_user_id = auth.uid()
    or exists (
      select 1 from public.student_enrollments se
      where se.catalog_subject_id = subject_faculty.catalog_subject_id
        and se.user_id = auth.uid()
    )
  );

-- Inserts: service role / dashboard only — app seeds via SQL. Optional policy for college admin later.
drop policy if exists "subject_faculty_insert_placeholder" on public.subject_faculty;
-- No insert for anon/authenticated by default (assign teachers in SQL Editor).

drop policy if exists "subject_chat_select" on public.subject_chat_messages;
create policy "subject_chat_select" on public.subject_chat_messages
  for select using (
    exists (
      select 1 from public.student_enrollments se
      where se.catalog_subject_id = subject_chat_messages.catalog_subject_id
        and se.user_id = auth.uid()
    )
    or exists (
      select 1 from public.subject_faculty sf
      where sf.catalog_subject_id = subject_chat_messages.catalog_subject_id
        and sf.faculty_user_id = auth.uid()
    )
  );

drop policy if exists "subject_chat_insert" on public.subject_chat_messages;
create policy "subject_chat_insert" on public.subject_chat_messages
  for insert with check (
    auth.uid() = user_id
    and (
      exists (
        select 1 from public.student_enrollments se
        where se.catalog_subject_id = subject_chat_messages.catalog_subject_id
          and se.user_id = auth.uid()
      )
      or exists (
        select 1 from public.subject_faculty sf
        where sf.catalog_subject_id = subject_chat_messages.catalog_subject_id
          and sf.faculty_user_id = auth.uid()
      )
    )
  );

drop policy if exists "subject_chat_delete" on public.subject_chat_messages;
create policy "subject_chat_delete" on public.subject_chat_messages
  for delete using (
    user_id = auth.uid()
    or exists (
      select 1 from public.subject_faculty sf
      where sf.catalog_subject_id = subject_chat_messages.catalog_subject_id
        and sf.faculty_user_id = auth.uid()
    )
  );

comment on table public.subject_faculty is 'Maps faculty users to subjects they teach (chat admin + visibility).';
comment on table public.subject_chat_messages is 'Per-subject chat thread for enrolled students and assigned faculty.';
