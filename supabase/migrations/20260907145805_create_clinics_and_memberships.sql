-- Phase 2: the first tenant boundary. No patient, staff, or clinical table is
-- introduced here. New public tables remain inaccessible until grants + RLS.
create schema if not exists private;

create function private.is_valid_time_zone(candidate text)
returns boolean
language sql
stable
set search_path = pg_catalog
as $$
  select exists (
    select 1 from pg_timezone_names where name = candidate
  );
$$;

create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  currency_code text not null default 'RUB',
  time_zone text not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clinics_name_trimmed check (name = btrim(name)),
  constraint clinics_name_length check (char_length(name) between 2 and 120),
  constraint clinics_currency_code check (currency_code ~ '^[A-Z]{3}$'),
  constraint clinics_time_zone check (private.is_valid_time_zone(time_zone))
);

create table public.clinic_members (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete restrict,
  -- Phase 3 replaces this bootstrap ownership marker with reusable roles.
  ownership text not null default 'owner',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clinic_members_unique_member unique (clinic_id, user_id),
  constraint clinic_members_only_owner check (ownership = 'owner')
);

create index clinic_members_active_user_clinic_idx
  on public.clinic_members (user_id, clinic_id)
  where is_active;

create function private.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger clinics_set_updated_at
before update on public.clinics
for each row execute function private.set_updated_at();

create trigger clinic_members_set_updated_at
before update on public.clinic_members
for each row execute function private.set_updated_at();

-- A user can create only a clinic they own. This trigger makes the first owner
-- membership part of the same transaction, so an ownerless clinic cannot exist.
create function private.create_creator_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.clinic_members (clinic_id, user_id, ownership, is_active)
  values (new.id, new.created_by, 'owner', true);
  return new;
end;
$$;

revoke all on function private.create_creator_owner_membership() from public;

create trigger clinics_create_creator_owner_membership
after insert on public.clinics
for each row execute function private.create_creator_owner_membership();

alter table public.clinics enable row level security;
alter table public.clinic_members enable row level security;

revoke all on table public.clinics from anon, authenticated;
revoke all on table public.clinic_members from anon, authenticated;
grant select, insert on table public.clinics to authenticated;
grant select on table public.clinic_members to authenticated;

create policy "active members read their clinics"
on public.clinics for select
to authenticated
using (
  exists (
    select 1
    from public.clinic_members member
    where member.clinic_id = clinics.id
      and member.user_id = (select auth.uid())
      and member.is_active
  )
);

create policy "users create clinics they own"
on public.clinics for insert
to authenticated
with check (created_by = (select auth.uid()));

create policy "users read their own memberships"
on public.clinic_members for select
to authenticated
using (user_id = (select auth.uid()));
