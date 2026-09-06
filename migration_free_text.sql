-- V5 migration: allow membership applicants to type electoral area and branch.
-- Run this once in Supabase SQL Editor after the original database.sql.
alter table public.members
  add column if not exists electoral_area_name text,
  add column if not exists branch_name text;

-- No existing data is deleted. The original UUID columns remain available
-- for future structured matching to electoral_areas and branches.
