-- Phase 6: clinic appointments use UTC instants; all appointment writes are
-- protected server commands added by the following migration.
create type public.appointment_status as enum (
  'scheduled',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'no_show'
);

create type public.appointment_conflict_kind as enum (
  'working_hours',
  'leave',
  'unavailable'
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  dentist_member_id uuid not null references public.clinic_members(id) on delete restrict,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status public.appointment_status not null default 'scheduled',
  purpose text,
  cancellation_reason text,
  override_reason text,
  overridden_by uuid references auth.users(id) on delete restrict,
  overridden_at timestamptz,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  status_changed_by uuid references auth.users(id) on delete restrict,
  status_changed_at timestamptz,
  constraint appointments_non_empty check (starts_at < ends_at),
  constraint appointments_purpose check (
    purpose is null or (purpose = btrim(purpose) and char_length(purpose) between 1 and 240)
  ),
  constraint appointments_cancellation_reason check (
    (status <> 'cancelled' and cancellation_reason is null)
    or (status = 'cancelled' and cancellation_reason = btrim(cancellation_reason)
      and char_length(cancellation_reason) between 1 and 1000)
  ),
  constraint appointments_override_metadata check (
    (override_reason is null and overridden_by is null and overridden_at is null)
    or (override_reason = btrim(override_reason) and char_length(override_reason) between 1 and 1000
      and overridden_by is not null and overridden_at is not null)
  )
);

-- A patient must never be physically double-booked. The predicate intentionally
-- excludes completed history and terminal outcomes; protected commands prevent
-- changing a future appointment to a terminal status as a conflict bypass.
alter table public.appointments
  add constraint appointments_no_patient_overlap
  exclude using gist (
    clinic_id with =,
    patient_id with =,
    tstzrange(starts_at, ends_at, '[)') with &&
  ) where (status in ('scheduled', 'confirmed', 'in_progress'));

create table public.appointment_conflict_flags (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete restrict,
  kind public.appointment_conflict_kind not null,
  detected_at timestamptz not null default now(),
  detected_by uuid references auth.users(id) on delete restrict,
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete restrict,
  resolution_note text,
  constraint appointment_conflict_flags_resolution check (
    (resolved_at is null and resolved_by is null and resolution_note is null)
    or (resolved_at is not null and resolved_by is not null
      and resolution_note = btrim(resolution_note)
      and char_length(resolution_note) between 1 and 1000)
  )
);

create table public.appointment_preparation_notes (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null unique references public.appointments(id) on delete restrict,
  note text not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint appointment_preparation_notes_note check (
    note = btrim(note) and char_length(note) between 1 and 2000
  )
);

-- This is a deliberately narrow, reusable foundation for security-sensitive
-- actions. It contains no clinical content and will be expanded in Phase 13.
create table public.audit_events (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  event_type text not null,
  subject_type text not null,
  subject_id uuid not null,
  reason text,
  safe_metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  constraint audit_events_event_type check (
    event_type = btrim(event_type) and char_length(event_type) between 1 and 100
  ),
  constraint audit_events_subject_type check (
    subject_type = btrim(subject_type) and char_length(subject_type) between 1 and 100
  ),
  constraint audit_events_reason check (
    reason is null or (reason = btrim(reason) and char_length(reason) between 1 and 1000)
  ),
  constraint audit_events_safe_metadata check (jsonb_typeof(safe_metadata) = 'object')
);

create index appointments_clinic_starts_at_idx
  on public.appointments (clinic_id, starts_at);
create index appointments_clinic_dentist_starts_at_idx
  on public.appointments (clinic_id, dentist_member_id, starts_at);
create index appointments_clinic_patient_starts_at_idx
  on public.appointments (clinic_id, patient_id, starts_at);
create index appointment_conflict_flags_unresolved_idx
  on public.appointment_conflict_flags (appointment_id, detected_at)
  where resolved_at is null;
create index audit_events_clinic_occurred_at_idx
  on public.audit_events (clinic_id, occurred_at desc);

create trigger appointments_set_updated_at
before update on public.appointments
for each row execute function private.set_updated_at();

create trigger appointment_preparation_notes_set_updated_at
before update on public.appointment_preparation_notes
for each row execute function private.set_updated_at();

alter table public.appointments enable row level security;
alter table public.appointment_conflict_flags enable row level security;
alter table public.appointment_preparation_notes enable row level security;
alter table public.audit_events enable row level security;

revoke all on table public.appointments from anon, authenticated;
revoke all on table public.appointment_conflict_flags from anon, authenticated;
revoke all on table public.appointment_preparation_notes from anon, authenticated;
revoke all on table public.audit_events from anon, authenticated;

grant select on table public.appointments to authenticated;
grant select on table public.appointment_conflict_flags to authenticated;
grant select on table public.appointment_preparation_notes to authenticated;
grant select on table public.audit_events to authenticated;

create policy "active members read clinic appointments"
on public.appointments for select
to authenticated
using (private.is_active_clinic_member(clinic_id, (select auth.uid())));

create policy "active members read appointment conflict flags"
on public.appointment_conflict_flags for select
to authenticated
using (
  exists (
    select 1 from public.appointments appointment
    where appointment.id = appointment_conflict_flags.appointment_id
      and private.is_active_clinic_member(appointment.clinic_id, (select auth.uid()))
  )
);

create policy "active members read appointment preparation notes"
on public.appointment_preparation_notes for select
to authenticated
using (
  exists (
    select 1 from public.appointments appointment
    where appointment.id = appointment_preparation_notes.appointment_id
      and private.is_active_clinic_member(appointment.clinic_id, (select auth.uid()))
  )
);

create policy "owners read clinic audit events"
on public.audit_events for select
to authenticated
using (
  private.has_clinic_role(clinic_id, 'owner'::public.clinic_role, (select auth.uid()))
);
