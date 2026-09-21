-- Phase 9: immutable clinical sessions with assistant-authored drafts,
-- assigned-dentist finalization, and append-only amendments.
create type public.clinical_session_status as enum (
  'draft',
  'finalized',
  'entered_in_error'
);

create table public.clinical_sessions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  appointment_id uuid unique references public.appointments(id) on delete restrict,
  dentist_member_id uuid not null references public.clinic_members(id) on delete restrict,
  session_date timestamptz not null,
  clinical_notes text,
  recommendations text,
  status public.clinical_session_status not null default 'draft',
  revision integer not null default 1,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  finalized_by uuid references auth.users(id) on delete restrict,
  finalized_at timestamptz,
  error_reason text,
  marked_in_error_by uuid references auth.users(id) on delete restrict,
  marked_in_error_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clinical_sessions_notes check (
    clinical_notes is null
    or (clinical_notes = btrim(clinical_notes)
      and char_length(clinical_notes) between 1 and 20000)
  ),
  constraint clinical_sessions_recommendations check (
    recommendations is null
    or (recommendations = btrim(recommendations)
      and char_length(recommendations) between 1 and 5000)
  ),
  constraint clinical_sessions_revision check (revision >= 1),
  constraint clinical_sessions_status_metadata check (
    (status = 'draft'::public.clinical_session_status
      and finalized_by is null and finalized_at is null
      and error_reason is null and marked_in_error_by is null
      and marked_in_error_at is null)
    or (status = 'finalized'::public.clinical_session_status
      and clinical_notes is not null
      and finalized_by is not null and finalized_at is not null
      and error_reason is null and marked_in_error_by is null
      and marked_in_error_at is null)
    or (status = 'entered_in_error'::public.clinical_session_status
      and finalized_by is null and finalized_at is null
      and error_reason = btrim(error_reason)
      and char_length(error_reason) between 1 and 1000
      and marked_in_error_by is not null and marked_in_error_at is not null)
  )
);

create table public.clinical_session_amendments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  clinical_session_id uuid not null references public.clinical_sessions(id) on delete restrict,
  amendment_text text not null,
  reason text not null,
  amended_by uuid not null references auth.users(id) on delete restrict,
  amended_at timestamptz not null default now(),
  constraint clinical_session_amendments_text check (
    amendment_text = btrim(amendment_text)
    and char_length(amendment_text) between 1 and 10000
  ),
  constraint clinical_session_amendments_reason check (
    reason = btrim(reason) and char_length(reason) between 1 and 1000
  )
);

create index clinical_sessions_patient_history_idx
  on public.clinical_sessions (clinic_id, patient_id, session_date desc, id desc);
create index clinical_sessions_dentist_history_idx
  on public.clinical_sessions (clinic_id, dentist_member_id, session_date desc);
create index clinical_session_amendments_history_idx
  on public.clinical_session_amendments (clinical_session_id, amended_at, id);

create function private.assert_clinical_session_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  linked_appointment public.appointments%rowtype;
begin
  if not exists (
    select 1 from public.patients patient
    where patient.id = new.patient_id and patient.clinic_id = new.clinic_id
  ) then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  if not exists (
    select 1
    from public.clinic_members member
    join public.clinic_member_roles role on role.clinic_member_id = member.id
    where member.id = new.dentist_member_id
      and member.clinic_id = new.clinic_id
      and member.is_active
      and role.role = 'dentist'::public.clinic_role
  ) then
    raise exception using errcode = 'P0001', message = 'dentist_unavailable';
  end if;
  if new.appointment_id is not null then
    select * into linked_appointment
    from public.appointments appointment
    where appointment.id = new.appointment_id;
    if not found then
      raise exception using errcode = 'P0001', message = 'appointment_unavailable';
    end if;
    if linked_appointment.clinic_id <> new.clinic_id
      or linked_appointment.patient_id <> new.patient_id then
      raise exception using errcode = 'P0001', message = 'appointment_unavailable';
    end if;
    if linked_appointment.dentist_member_id <> new.dentist_member_id then
      raise exception using errcode = 'P0001', message = 'assigned_dentist_mismatch';
    end if;
  end if;
  return new;
end;
$$;

create function private.assert_clinical_session_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status <> 'draft'::public.clinical_session_status then
    raise exception using errcode = 'P0001', message = 'clinical_session_immutable';
  end if;
  if old.clinic_id <> new.clinic_id
    or old.patient_id <> new.patient_id
    or old.appointment_id is distinct from new.appointment_id
    or old.dentist_member_id <> new.dentist_member_id
    or old.session_date <> new.session_date
    or old.created_by <> new.created_by
    or old.created_at <> new.created_at then
    raise exception using errcode = 'P0001', message = 'clinical_session_identity_immutable';
  end if;
  if new.status not in (
    'draft'::public.clinical_session_status,
    'finalized'::public.clinical_session_status,
    'entered_in_error'::public.clinical_session_status
  ) then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_transition';
  end if;
  return new;
end;
$$;

create function private.assert_clinical_session_amendment_immutable()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception using errcode = 'P0001', message = 'clinical_session_amendment_immutable';
end;
$$;

create trigger clinical_sessions_match_scope
before insert or update of clinic_id, patient_id, appointment_id, dentist_member_id
on public.clinical_sessions
for each row execute function private.assert_clinical_session_scope();

create trigger clinical_sessions_enforce_lifecycle
before update on public.clinical_sessions
for each row execute function private.assert_clinical_session_lifecycle();

create trigger clinical_sessions_set_updated_at
before update on public.clinical_sessions
for each row execute function private.set_updated_at();

create trigger clinical_session_amendments_are_immutable
before update or delete on public.clinical_session_amendments
for each row execute function private.assert_clinical_session_amendment_immutable();

alter table public.clinical_sessions enable row level security;
alter table public.clinical_session_amendments enable row level security;

revoke all on table public.clinical_sessions from anon, authenticated;
revoke all on table public.clinical_session_amendments from anon, authenticated;
grant select on table public.clinical_sessions to authenticated;
grant select on table public.clinical_session_amendments to authenticated;

create policy "clinical staff read sessions"
on public.clinical_sessions for select
to authenticated
using (
  private.has_clinic_role(clinic_id, 'owner'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
);

create policy "clinical staff read session amendments"
on public.clinical_session_amendments for select
to authenticated
using (
  private.has_clinic_role(clinic_id, 'owner'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
);

create function private.require_clinical_session_role(
  target_clinic_id uuid,
  actor_user_id uuid,
  allowed public.clinic_role[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from unnest(allowed) role_value
    where private.has_clinic_role(target_clinic_id, role_value, actor_user_id)
  ) then
    raise exception using errcode = 'P0001', message = 'clinical_session_forbidden';
  end if;
end;
$$;

create function private.clinical_session_target(
  target_session_id uuid,
  lock_row boolean default false
)
returns public.clinical_sessions
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.clinical_sessions%rowtype;
begin
  if lock_row then
    select * into target from public.clinical_sessions
    where id = target_session_id for update;
  else
    select * into target from public.clinical_sessions
    where id = target_session_id;
  end if;
  if not found then
    raise exception using errcode = 'P0001', message = 'clinical_session_unavailable';
  end if;
  return target;
end;
$$;

create function public.clinical_session_create(
  actor_user_id uuid,
  target_patient_id uuid,
  target_appointment_id uuid,
  target_dentist_member_id uuid,
  target_session_date timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  patient public.patients%rowtype;
  linked_appointment public.appointments%rowtype;
  effective_dentist_id uuid;
  effective_session_date timestamptz;
  result_id uuid;
begin
  select * into patient from public.patients
  where id = target_patient_id for share;
  if not found or patient.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  perform private.require_clinical_session_role(
    patient.clinic_id,
    actor_user_id,
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if target_appointment_id is not null then
    select * into linked_appointment from public.appointments
    where id = target_appointment_id for update;
    if not found
      or linked_appointment.clinic_id <> patient.clinic_id
      or linked_appointment.patient_id <> patient.id then
      raise exception using errcode = 'P0001', message = 'appointment_unavailable';
    end if;
    if linked_appointment.status not in (
      'scheduled'::public.appointment_status,
      'confirmed'::public.appointment_status,
      'in_progress'::public.appointment_status,
      'completed'::public.appointment_status
    ) then
      raise exception using errcode = 'P0001', message = 'appointment_not_eligible';
    end if;
    effective_dentist_id := linked_appointment.dentist_member_id;
    effective_session_date := linked_appointment.starts_at;
  else
    if target_dentist_member_id is null or target_session_date is null
      or target_session_date > now() then
      raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
    end if;
    effective_dentist_id := target_dentist_member_id;
    effective_session_date := target_session_date;
  end if;
  insert into public.clinical_sessions (
    clinic_id, patient_id, appointment_id, dentist_member_id, session_date,
    created_by, updated_by
  ) values (
    patient.clinic_id, patient.id, target_appointment_id,
    effective_dentist_id, effective_session_date, actor_user_id, actor_user_id
  ) returning id into result_id;
  return result_id;
exception
  when unique_violation then
    raise exception using errcode = 'P0001', message = 'appointment_already_has_session';
  when check_violation or not_null_violation then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
end;
$$;

create function public.clinical_session_update_draft(
  actor_user_id uuid,
  target_session_id uuid,
  next_clinical_notes text,
  next_recommendations text,
  expected_revision integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.clinical_sessions%rowtype;
begin
  target := private.clinical_session_target(target_session_id, true);
  perform private.require_clinical_session_role(
    target.clinic_id,
    actor_user_id,
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if target.status <> 'draft'::public.clinical_session_status then
    raise exception using errcode = 'P0001', message = 'clinical_session_draft_only';
  end if;
  if target.revision <> expected_revision then
    raise exception using errcode = 'P0001', message = 'clinical_session_revision_conflict';
  end if;
  update public.clinical_sessions
  set clinical_notes = nullif(btrim(next_clinical_notes), ''),
      recommendations = nullif(btrim(next_recommendations), ''),
      updated_by = actor_user_id,
      revision = revision + 1
  where id = target.id;
exception
  when check_violation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
end;
$$;

create function public.clinical_session_finalize(
  actor_user_id uuid,
  target_session_id uuid,
  expected_revision integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.clinical_sessions%rowtype;
  linked_appointment public.appointments%rowtype;
begin
  target := private.clinical_session_target(target_session_id, true);
  if not exists (
    select 1
    from public.clinic_members member
    join public.clinic_member_roles role on role.clinic_member_id = member.id
    where member.id = target.dentist_member_id
      and member.user_id = actor_user_id
      and member.is_active
      and role.role = 'dentist'::public.clinic_role
  ) then
    raise exception using errcode = 'P0001', message = 'clinical_session_forbidden';
  end if;
  if target.status <> 'draft'::public.clinical_session_status then
    raise exception using errcode = 'P0001', message = 'clinical_session_draft_only';
  end if;
  if target.revision <> expected_revision then
    raise exception using errcode = 'P0001', message = 'clinical_session_revision_conflict';
  end if;
  if target.clinical_notes is null then
    raise exception using errcode = 'P0001', message = 'clinical_notes_required';
  end if;
  if target.appointment_id is not null then
    select * into linked_appointment from public.appointments
    where id = target.appointment_id for share;
    if not found then
      raise exception using errcode = 'P0001', message = 'appointment_unavailable';
    end if;
    if linked_appointment.status not in (
      'in_progress'::public.appointment_status,
      'completed'::public.appointment_status
    ) or linked_appointment.starts_at > now() then
      raise exception using errcode = 'P0001', message = 'appointment_not_eligible';
    end if;
  elsif target.session_date > now() then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
  end if;
  update public.clinical_sessions
  set status = 'finalized'::public.clinical_session_status,
      updated_by = actor_user_id,
      finalized_by = actor_user_id,
      finalized_at = now(),
      revision = revision + 1
  where id = target.id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'clinical_session_finalized',
    'clinical_session', target.id, '{}'::jsonb
  );
end;
$$;

create function public.clinical_session_mark_in_error(
  actor_user_id uuid,
  target_session_id uuid,
  expected_revision integer,
  supplied_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.clinical_sessions%rowtype;
  normalized_reason text := nullif(btrim(supplied_reason), '');
begin
  target := private.clinical_session_target(target_session_id, true);
  perform private.require_clinical_session_role(
    target.clinic_id,
    actor_user_id,
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if target.status <> 'draft'::public.clinical_session_status then
    raise exception using errcode = 'P0001', message = 'clinical_session_draft_only';
  end if;
  if target.revision <> expected_revision then
    raise exception using errcode = 'P0001', message = 'clinical_session_revision_conflict';
  end if;
  if normalized_reason is null then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
  end if;
  update public.clinical_sessions
  set status = 'entered_in_error'::public.clinical_session_status,
      updated_by = actor_user_id,
      error_reason = normalized_reason,
      marked_in_error_by = actor_user_id,
      marked_in_error_at = now(),
      revision = revision + 1
  where id = target.id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'clinical_session_marked_in_error',
    'clinical_session', target.id, '{}'::jsonb
  );
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
end;
$$;

create function public.clinical_session_add_amendment(
  actor_user_id uuid,
  target_session_id uuid,
  next_amendment_text text,
  supplied_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.clinical_sessions%rowtype;
  result_id uuid;
begin
  target := private.clinical_session_target(target_session_id, true);
  perform private.require_clinical_session_role(
    target.clinic_id,
    actor_user_id,
    array['dentist']::public.clinic_role[]
  );
  if target.status <> 'finalized'::public.clinical_session_status then
    raise exception using errcode = 'P0001', message = 'clinical_session_finalized_required';
  end if;
  insert into public.clinical_session_amendments (
    clinic_id, clinical_session_id, amendment_text, reason, amended_by
  ) values (
    target.clinic_id, target.id, nullif(btrim(next_amendment_text), ''),
    nullif(btrim(supplied_reason), ''), actor_user_id
  ) returning id into result_id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'clinical_session_amendment_added',
    'clinical_session', target.id,
    jsonb_build_object('amendment_id', result_id)
  );
  return result_id;
exception
  when check_violation or not_null_violation then
    raise exception using errcode = 'P0001', message = 'invalid_clinical_session_input';
end;
$$;

revoke all on function private.assert_clinical_session_scope() from public;
revoke all on function private.assert_clinical_session_lifecycle() from public;
revoke all on function private.assert_clinical_session_amendment_immutable() from public;
revoke all on function private.require_clinical_session_role(uuid, uuid, public.clinic_role[]) from public;
revoke all on function private.clinical_session_target(uuid, boolean) from public;

revoke all on function public.clinical_session_create(uuid, uuid, uuid, uuid, timestamptz)
  from public, anon, authenticated;
revoke all on function public.clinical_session_update_draft(uuid, uuid, text, text, integer)
  from public, anon, authenticated;
revoke all on function public.clinical_session_finalize(uuid, uuid, integer)
  from public, anon, authenticated;
revoke all on function public.clinical_session_mark_in_error(uuid, uuid, integer, text)
  from public, anon, authenticated;
revoke all on function public.clinical_session_add_amendment(uuid, uuid, text, text)
  from public, anon, authenticated;

grant execute on function public.clinical_session_create(uuid, uuid, uuid, uuid, timestamptz)
  to service_role;
grant execute on function public.clinical_session_update_draft(uuid, uuid, text, text, integer)
  to service_role;
grant execute on function public.clinical_session_finalize(uuid, uuid, integer)
  to service_role;
grant execute on function public.clinical_session_mark_in_error(uuid, uuid, integer, text)
  to service_role;
grant execute on function public.clinical_session_add_amendment(uuid, uuid, text, text)
  to service_role;
