-- Student registration: colleges, catalog subjects, class schedules, profiles & enrollments.
-- Run in Supabase SQL Editor after schema.sql (or merge into one migration).

-- ---------------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------------
create table if not exists public.colleges (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  primary_hex text not null,
  accent_hex text not null,
  sort_order int not null default 0
);

create table if not exists public.catalog_subjects (
  id uuid primary key default gen_random_uuid(),
  college_id uuid not null references public.colleges (id) on delete cascade,
  name text not null,
  code text not null,
  unique (college_id, code)
);

create table if not exists public.course_schedules (
  id uuid primary key default gen_random_uuid(),
  catalog_subject_id uuid not null references public.catalog_subjects (id) on delete cascade,
  day_of_week smallint not null check (day_of_week >= 1 and day_of_week <= 7),
  start_time time not null,
  end_time time not null,
  room text,
  session_label text not null default 'Class'
);

create table if not exists public.student_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  college_id uuid not null references public.colleges (id),
  full_name text,
  updated_at timestamptz not null default now()
);

create table if not exists public.student_enrollments (
  user_id uuid not null references auth.users (id) on delete cascade,
  catalog_subject_id uuid not null references public.catalog_subjects (id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  primary key (user_id, catalog_subject_id)
);

create index if not exists catalog_subjects_college_idx on public.catalog_subjects (college_id);
create index if not exists course_schedules_subject_idx on public.course_schedules (catalog_subject_id);
create index if not exists student_enrollments_user_idx on public.student_enrollments (user_id);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.colleges enable row level security;
alter table public.catalog_subjects enable row level security;
alter table public.course_schedules enable row level security;
alter table public.student_profiles enable row level security;
alter table public.student_enrollments enable row level security;

drop policy if exists "colleges_select_authenticated" on public.colleges;
create policy "colleges_select_authenticated" on public.colleges
  for select to authenticated using (true);

drop policy if exists "catalog_subjects_select_authenticated" on public.catalog_subjects;
create policy "catalog_subjects_select_authenticated" on public.catalog_subjects
  for select to authenticated using (true);

drop policy if exists "course_schedules_select_authenticated" on public.course_schedules;
create policy "course_schedules_select_authenticated" on public.course_schedules
  for select to authenticated using (true);

drop policy if exists "student_profiles_select_own" on public.student_profiles;
create policy "student_profiles_select_own" on public.student_profiles
  for select using (auth.uid() = user_id);

drop policy if exists "student_profiles_insert_own" on public.student_profiles;
create policy "student_profiles_insert_own" on public.student_profiles
  for insert with check (auth.uid() = user_id);

drop policy if exists "student_profiles_update_own" on public.student_profiles;
create policy "student_profiles_update_own" on public.student_profiles
  for update using (auth.uid() = user_id);

drop policy if exists "student_enrollments_select_own" on public.student_enrollments;
create policy "student_enrollments_select_own" on public.student_enrollments
  for select using (auth.uid() = user_id);

drop policy if exists "student_enrollments_insert_own" on public.student_enrollments;
create policy "student_enrollments_insert_own" on public.student_enrollments
  for insert with check (auth.uid() = user_id);

drop policy if exists "student_enrollments_delete_own" on public.student_enrollments;
create policy "student_enrollments_delete_own" on public.student_enrollments
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Seed colleges (7) — brand colors: primary + light accent
-- ---------------------------------------------------------------------------
insert into public.colleges (slug, name, primary_hex, accent_hex, sort_order) values
  ('arts_science', 'College of Arts and Science', '#1565C0', '#E3F2FD', 1),
  ('engineering', 'College of Engineering', '#E65100', '#FFE0B2', 2),
  ('nursing', 'College of Nursing', '#C62828', '#FFCDD2', 3),
  ('tourism', 'College of Tourism & Hospitality', '#00695C', '#B2DFDB', 4),
  ('business', 'College of Business & Accountancy', '#2E7D32', '#C8E6C9', 5),
  ('computing', 'College of Computing Studies', '#6A1B9A', '#E1BEE7', 6),
  ('education', 'College of Education', '#F57F17', '#FFECB3', 7)
on conflict (slug) do update set
  name = excluded.name,
  primary_hex = excluded.primary_hex,
  accent_hex = excluded.accent_hex,
  sort_order = excluded.sort_order;

-- ---------------------------------------------------------------------------
-- Seed subjects (per college)
-- ---------------------------------------------------------------------------
insert into public.catalog_subjects (college_id, name, code)
select c.id, x.name, x.code
from public.colleges c
inner join (
  values
    ('arts_science', 'General Psychology', 'PSY 101'),
    ('arts_science', 'English Communication', 'ENG 101'),
    ('arts_science', 'Filipino', 'FIL 101'),
    ('engineering', 'Statics', 'CE 201'),
    ('engineering', 'Thermodynamics', 'ME 202'),
    ('engineering', 'Engineering Mathematics', 'MATH 210'),
    ('nursing', 'Fundamentals of Nursing', 'NUR 101'),
    ('nursing', 'Anatomy and Physiology', 'NUR 102'),
    ('nursing', 'Community Health Nursing', 'NUR 203'),
    ('tourism', 'Tourism Planning & Development', 'THM 101'),
    ('tourism', 'Hospitality Operations', 'THM 110'),
    ('tourism', 'Events Management', 'THM 120'),
    ('business', 'Financial Accounting', 'ACC 101'),
    ('business', 'Principles of Management', 'MGT 101'),
    ('business', 'Business Law', 'LAW 105'),
    ('computing', 'Programming Fundamentals', 'CS 101'),
    ('computing', 'Data Structures', 'CS 201'),
    ('computing', 'Database Systems', 'CS 220'),
    ('education', 'Principles of Teaching', 'ED 101'),
    ('education', 'Child & Adolescent Development', 'ED 110'),
    ('education', 'Assessment of Learning', 'ED 201')
) as x(slug, name, code) on c.slug = x.slug
on conflict (college_id, code) do nothing;

-- ---------------------------------------------------------------------------
-- Seed sample weekly schedules (Mon–Fri patterns; day_of_week 1=Mon … 7=Sun)
-- ---------------------------------------------------------------------------
insert into public.course_schedules (catalog_subject_id, day_of_week, start_time, end_time, room, session_label)
select s.id, v.dow, v.st::time, v.en::time, v.room, v.lbl
from public.catalog_subjects s
join public.colleges c on c.id = s.college_id
inner join (
  values
    ('arts_science', 'PSY 101', 1, '09:00', '11:00', 'Rm 301', 'Lecture'),
    ('arts_science', 'PSY 101', 3, '13:00', '15:00', 'Lab A', 'Laboratory'),
    ('arts_science', 'ENG 101', 2, '10:00', '12:00', 'Rm 105', 'Lecture'),
    ('arts_science', 'FIL 101', 4, '08:00', '10:00', 'Rm 112', 'Lecture'),
    ('engineering', 'CE 201', 1, '08:30', '10:30', 'Eng Bldg 201', 'Lecture'),
    ('engineering', 'ME 202', 2, '13:00', '15:30', 'Eng Bldg 105', 'Lecture'),
    ('engineering', 'MATH 210', 5, '09:00', '11:00', 'Math Hall 3', 'Lecture'),
    ('nursing', 'NUR 101', 1, '07:00', '11:00', 'Skills Lab 1', 'Clinical Lab'),
    ('nursing', 'NUR 102', 3, '08:00', '11:00', 'Anatomy Lab', 'Lecture'),
    ('nursing', 'NUR 203', 5, '13:00', '17:00', 'Community Site', 'Field'),
    ('tourism', 'THM 101', 2, '09:00', '12:00', 'THM 101', 'Lecture'),
    ('tourism', 'THM 110', 4, '10:00', '13:00', 'Kitchen Lab', 'Lab'),
    ('tourism', 'THM 120', 1, '14:00', '17:00', 'Events Hall', 'Workshop'),
    ('business', 'ACC 101', 1, '10:00', '12:00', 'BA 201', 'Lecture'),
    ('business', 'MGT 101', 3, '15:00', '17:00', 'BA 305', 'Lecture'),
    ('business', 'LAW 105', 5, '08:00', '10:00', 'BA 110', 'Lecture'),
    ('computing', 'CS 101', 1, '13:00', '16:00', 'Comp Lab 1', 'Lab'),
    ('computing', 'CS 201', 2, '09:00', '11:00', 'Comp Lab 2', 'Lab'),
    ('computing', 'CS 220', 4, '13:00', '15:00', 'Rm 402', 'Lecture'),
    ('education', 'ED 101', 2, '08:00', '11:00', 'Ed Bldg 101', 'Lecture'),
    ('education', 'ED 110', 4, '09:00', '12:00', 'Ed Bldg 115', 'Lecture'),
    ('education', 'ED 201', 6, '08:00', '11:00', 'Ed Bldg 202', 'Seminar')
) as v(slug, code, dow, st, en, room, lbl)
  on c.slug = v.slug and s.code = v.code
where not exists (
  select 1 from public.course_schedules cs where cs.catalog_subject_id = s.id and cs.day_of_week = v.dow and cs.start_time = v.st::time
);

-- Year level (shown with college on dashboard / profile). Safe to re-run.
alter table public.student_profiles
  add column if not exists year_level text;
