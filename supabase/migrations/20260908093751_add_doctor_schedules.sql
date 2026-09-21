-- Phase 4: versioned weekly availability and explicit availability exceptions.
-- Schedule writes remain server-controlled. A version is effective from a
-- clinic-local calendar date, which lets future changes preserve prior rules.
create extension if not exists btree_gist with schema extensions;

create table public.doctor_schedule_versions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  dentist_member_id uuid not null references public.clinic_members(id) on delete restrict,
  effective_from date not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint doctor_schedule_versions_one_effective_date
    unique (dentist_member_id, effective_from)
);

create table public.doctor_working_hours (
  id uuid primary key default gen_random_uuid(),
  schedule_version_id uuid not null
    references public.doctor_schedule_versions(id) on delete restrict,
  weekday smallint not null,
  starts_at time not null,
  ends_at time not null,
  created_at timestamptz not null default now(),
  constraint doctor_working_hours_weekday check (weekday between 1 and 7),
  constraint doctor_working_hours_non_empty check (starts_at < ends_at),
  constraint doctor_working_hours_daytime_only
    check (starts_at >= time '00:00' and ends_at <= time '23:59:59.999999')
);

alter table public.doctor_working_hours
  add constraint doctor_working_hours_no_overlap
  exclude using gist (
    schedule_version_id with =,
    weekday with =,
    int4range(
      (extract(epoch from starts_at) / 60)::integer,
      (extract(epoch from ends_at) / 60)::integer,
      '[)'
    ) with &&
  );

create table public.doctor_schedule_breaks (
  id uuid primary key default gen_random_uuid(),
  working_hours_id uuid not null
    references public.doctor_working_hours(id) on delete restrict,
  starts_at time not null,
  ends_at time not null,
  created_at timestamptz not null default now(),
  constraint doctor_schedule_breaks_non_empty check (starts_at < ends_at)
);

alter table public.doctor_schedule_breaks
  add constraint doctor_schedule_breaks_no_overlap
  exclude using gist (
    working_hours_id with =,
    int4range(
      (extract(epoch from starts_at) / 60)::integer,
      (extract(epoch from ends_at) / 60)::integer,
      '[)'
    ) with &&
  );

create table public.doctor_schedule_exceptions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  dentist_member_id uuid not null references public.clinic_members(id) on delete restrict,
  kind text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  reason text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint doctor_schedule_exceptions_kind
    check (kind in ('leave', 'unavailable')),
  constraint doctor_schedule_exceptions_non_empty check (starts_at < ends_at),
  constraint doctor_schedule_exceptions_reason
    check (reason is null or (reason = btrim(reason) and char_length(reason) between 1 and 1000))
);

create index doctor_schedule_versions_clinic_dentist_effective_idx
  on public.doctor_schedule_versions (clinic_id, dentist_member_id, effective_from desc);
create index doctor_working_hours_version_weekday_start_idx
  on public.doctor_working_hours (schedule_version_id, weekday, starts_at);
create index doctor_schedule_exceptions_clinic_dentist_start_idx
  on public.doctor_schedule_exceptions (clinic_id, dentist_member_id, starts_at);

create function private.assert_schedule_version_dentist()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.clinic_members member
    join public.clinic_member_roles member_role
      on member_role.clinic_member_id = member.id
    where member.id = new.dentist_member_id
      and member.clinic_id = new.clinic_id
      and member.is_active
      and member_role.role = 'dentist'::public.clinic_role
  ) then
    raise exception using errcode = 'P0001', message = 'active_dentist_required';
  end if;
  return new;
end;
$$;

create function private.assert_schedule_break_within_working_hours()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  working_period public.doctor_working_hours%rowtype;
begin
  select * into working_period
  from public.doctor_working_hours
  where id = new.working_hours_id;

  if not found
    or new.starts_at < working_period.starts_at
    or new.ends_at > working_period.ends_at then
    raise exception using errcode = 'P0001', message = 'break_outside_working_hours';
  end if;
  return new;
end;
$$;

create function private.assert_schedule_exception_dentist()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.clinic_members member
    join public.clinic_member_roles member_role
      on member_role.clinic_member_id = member.id
    where member.id = new.dentist_member_id
      and member.clinic_id = new.clinic_id
      and member.is_active
      and member_role.role = 'dentist'::public.clinic_role
  ) then
    raise exception using errcode = 'P0001', message = 'active_dentist_required';
  end if;
  return new;
end;
$$;

revoke all on function private.assert_schedule_version_dentist() from public;
revoke all on function private.assert_schedule_break_within_working_hours() from public;
revoke all on function private.assert_schedule_exception_dentist() from public;

create trigger doctor_schedule_versions_require_active_dentist
before insert or update of clinic_id, dentist_member_id
on public.doctor_schedule_versions
for each row execute function private.assert_schedule_version_dentist();

create trigger doctor_schedule_breaks_require_containment
before insert or update of working_hours_id, starts_at, ends_at
on public.doctor_schedule_breaks
for each row execute function private.assert_schedule_break_within_working_hours();

create trigger doctor_schedule_exceptions_require_active_dentist
before insert or update of clinic_id, dentist_member_id
on public.doctor_schedule_exceptions
for each row execute function private.assert_schedule_exception_dentist();

create trigger doctor_schedule_exceptions_set_updated_at
before update on public.doctor_schedule_exceptions
for each row execute function private.set_updated_at();

alter table public.doctor_schedule_versions enable row level security;
alter table public.doctor_working_hours enable row level security;
alter table public.doctor_schedule_breaks enable row level security;
alter table public.doctor_schedule_exceptions enable row level security;

revoke all on table public.doctor_schedule_versions from anon, authenticated;
revoke all on table public.doctor_working_hours from anon, authenticated;
revoke all on table public.doctor_schedule_breaks from anon, authenticated;
revoke all on table public.doctor_schedule_exceptions from anon, authenticated;
grant select on table public.doctor_schedule_versions to authenticated;
grant select on table public.doctor_working_hours to authenticated;
grant select on table public.doctor_schedule_breaks to authenticated;
grant select on table public.doctor_schedule_exceptions to authenticated;

create policy "active members read clinic schedule versions"
on public.doctor_schedule_versions for select
to authenticated
using (private.is_active_clinic_member(clinic_id, (select auth.uid())));

create policy "active members read clinic working hours"
on public.doctor_working_hours for select
to authenticated
using (
  exists (
    select 1
    from public.doctor_schedule_versions version
    where version.id = doctor_working_hours.schedule_version_id
      and private.is_active_clinic_member(version.clinic_id, (select auth.uid()))
  )
);

create policy "active members read clinic schedule breaks"
on public.doctor_schedule_breaks for select
to authenticated
using (
  exists (
    select 1
    from public.doctor_working_hours hours
    join public.doctor_schedule_versions version
      on version.id = hours.schedule_version_id
    where hours.id = doctor_schedule_breaks.working_hours_id
      and private.is_active_clinic_member(version.clinic_id, (select auth.uid()))
  )
);

create policy "active members read clinic schedule exceptions"
on public.doctor_schedule_exceptions for select
to authenticated
using (private.is_active_clinic_member(clinic_id, (select auth.uid())));
