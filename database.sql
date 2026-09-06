
-- NPP A.A.K. DATABASE V3
-- Supabase/PostgreSQL schema
-- Run this entire file in Supabase -> SQL Editor.
--
-- IMPORTANT:
-- 1) Replace no secrets in this file.
-- 2) Do NOT put a Supabase service-role/secret key in HTML.
-- 3) Membership/political-affiliation information is sensitive. Keep access
--    limited to authorized administrators and publish a privacy notice/consent.
-- 4) For production, add CAPTCHA/rate limiting or submit public applications
--    through a server-side Edge Function.

create extension if not exists pgcrypto;

-- =========================
-- 1. CORE REFERENCE TABLES
-- =========================

create table if not exists public.electoral_areas (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  electoral_area_id uuid references public.electoral_areas(id) on delete set null,
  location text,
  phone text,
  email text,
  contact_person text,
  created_at timestamptz not null default now()
);

create table if not exists public.leaders (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  position_title text not null,
  electoral_area_id uuid references public.electoral_areas(id) on delete set null,
  phone text,
  email text,
  photo_url text,
  bio text,
  display_order integer not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================
-- 2. MEMBERSHIP APPLICATIONS
-- =========================
-- Keep this table private. Public visitors can submit an application,
-- but they cannot read other applications.

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  application_number text not null unique default ('AAK-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
  full_name text not null,
  email text,
  phone text not null,
  date_of_birth date,
  gender text,
  address text,
  electoral_area_id uuid references public.electoral_areas(id) on delete set null,
  branch_id uuid references public.branches(id) on delete set null,
  membership_type text not null default 'Member',
  consent_given boolean not null default false,
  status text not null default 'Pending'
    check (status in ('Pending','Approved','Rejected','Inactive')),
  notes text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null
);

-- =========================
-- 3. CONTENT
-- =========================

create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text,
  body text,
  image_url text,
  author_name text,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  venue text,
  event_date timestamptz not null,
  image_url text,
  published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.policies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  summary text,
  body text,
  document_url text,
  published boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.media (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  media_type text not null check (media_type in ('photo','video')),
  media_url text not null,
  thumbnail_url text,
  caption text,
  published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  message text not null,
  link_url text,
  published boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  message text not null,
  status text not null default 'New'
    check (status in ('New','Read','Resolved')),
  created_at timestamptz not null default now()
);

-- =========================
-- 4. ADMIN ROLES + AUDIT
-- =========================

create table if not exists public.admin_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin'
    check (role in ('admin','editor','viewer')),
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  table_name text,
  record_id uuid,
  metadata jsonb,
  created_at timestamptz not null default now()
);

-- =========================
-- 5. SECURITY HELPERS
-- =========================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_roles
    where user_id = (select auth.uid())
      and role in ('admin','editor','viewer')
  );
$$;

create or replace function public.is_editor()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_roles
    where user_id = (select auth.uid())
      and role in ('admin','editor')
  );
$$;

create or replace function public.is_owner_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_roles
    where user_id = (select auth.uid())
      and role = 'admin'
  );
$$;

-- =========================
-- 6. ENABLE RLS
-- =========================

alter table public.electoral_areas enable row level security;
alter table public.branches enable row level security;
alter table public.leaders enable row level security;
alter table public.members enable row level security;
alter table public.news enable row level security;
alter table public.events enable row level security;
alter table public.policies enable row level security;
alter table public.media enable row level security;
alter table public.notifications enable row level security;
alter table public.contact_messages enable row level security;
alter table public.admin_roles enable row level security;
alter table public.audit_logs enable row level security;

-- =========================
-- 7. PUBLIC READ POLICIES
-- =========================

drop policy if exists "public read electoral areas" on public.electoral_areas;
create policy "public read electoral areas"
on public.electoral_areas for select
to anon, authenticated
using (true);

drop policy if exists "public read branches" on public.branches;
create policy "public read branches"
on public.branches for select
to anon, authenticated
using (true);

drop policy if exists "public read published leaders" on public.leaders;
create policy "public read published leaders"
on public.leaders for select
to anon, authenticated
using (is_published = true or public.is_admin());

drop policy if exists "public read published news" on public.news;
create policy "public read published news"
on public.news for select
to anon, authenticated
using (published = true or public.is_admin());

drop policy if exists "public read published events" on public.events;
create policy "public read published events"
on public.events for select
to anon, authenticated
using (published = true or public.is_admin());

drop policy if exists "public read published policies" on public.policies;
create policy "public read published policies"
on public.policies for select
to anon, authenticated
using (published = true or public.is_admin());

drop policy if exists "public read published media" on public.media;
create policy "public read published media"
on public.media for select
to anon, authenticated
using (published = true or public.is_admin());

drop policy if exists "public read published notifications" on public.notifications;
create policy "public read published notifications"
on public.notifications for select
to anon, authenticated
using (published = true or public.is_admin());

-- =========================
-- 8. PUBLIC SUBMISSION POLICIES
-- =========================

drop policy if exists "public submit membership application" on public.members;
create policy "public submit membership application"
on public.members for insert
to anon, authenticated
with check (
  consent_given = true
  and status = 'Pending'
);

drop policy if exists "public submit contact message" on public.contact_messages;
create policy "public submit contact message"
on public.contact_messages for insert
to anon, authenticated
with check (true);

-- =========================
-- 9. ADMIN POLICIES
-- =========================

drop policy if exists "admins manage members" on public.members;
create policy "admins manage members"
on public.members for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "admins manage leaders" on public.leaders;
create policy "admins manage leaders"
on public.leaders for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage branches" on public.branches;
create policy "admins manage branches"
on public.branches for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage electoral areas" on public.electoral_areas;
create policy "admins manage electoral areas"
on public.electoral_areas for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage news" on public.news;
create policy "admins manage news"
on public.news for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage events" on public.events;
create policy "admins manage events"
on public.events for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage policies" on public.policies;
create policy "admins manage policies"
on public.policies for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage media" on public.media;
create policy "admins manage media"
on public.media for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage notifications" on public.notifications;
create policy "admins manage notifications"
on public.notifications for all
to authenticated
using (public.is_editor())
with check (public.is_editor());

drop policy if exists "admins manage contact messages" on public.contact_messages;
create policy "admins manage contact messages"
on public.contact_messages for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "admins read roles" on public.admin_roles;
create policy "admins read roles"
on public.admin_roles for select
to authenticated
using (public.is_admin());

drop policy if exists "owner admins manage roles" on public.admin_roles;
create policy "owner admins manage roles"
on public.admin_roles for all
to authenticated
using (public.is_owner_admin())
with check (public.is_owner_admin());

drop policy if exists "admins read audit logs" on public.audit_logs;
create policy "admins read audit logs"
on public.audit_logs for select
to authenticated
using (public.is_admin());

-- =========================
-- 10. GRANTS
-- =========================

revoke all on all tables in schema public from anon, authenticated;

grant select on public.electoral_areas, public.branches, public.leaders,
  public.news, public.events, public.policies, public.media, public.notifications
  to anon, authenticated;

grant insert on public.members, public.contact_messages to anon, authenticated;

grant select, insert, update, delete on public.members,
  public.electoral_areas, public.branches, public.leaders, public.news,
  public.events, public.policies, public.media, public.notifications,
  public.contact_messages, public.admin_roles, public.audit_logs
  to authenticated;

grant execute on function public.is_admin() to anon, authenticated;
grant execute on function public.is_editor() to anon, authenticated;
grant execute on function public.is_owner_admin() to authenticated;

-- Indexes
create index if not exists members_status_idx on public.members(status);
create index if not exists members_electoral_area_idx on public.members(electoral_area_id);
create index if not exists members_branch_idx on public.members(branch_id);
create index if not exists news_published_idx on public.news(published, published_at desc);
create index if not exists events_date_idx on public.events(event_date);
create index if not exists leaders_area_idx on public.leaders(electoral_area_id);
create index if not exists audit_actor_idx on public.audit_logs(actor_user_id);

-- Seed the constituency identity.
insert into public.electoral_areas (name, description)
values ('Abura–Asebu Kwamankese Constituency', 'Constituency-level administrative area')
on conflict (name) do nothing;

-- After you create your first Auth user in Supabase, run:
-- INSERT INTO public.admin_roles (user_id, role)
-- VALUES ('PASTE-AUTH-USER-UUID-HERE', 'admin');
