-- Add year level to student profiles (run after academic_registration.sql).
alter table public.student_profiles
  add column if not exists year_level text;
