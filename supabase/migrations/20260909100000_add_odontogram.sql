-- Phase 7: clinical dental chart records. Browser clients may read only the
-- clinical data permitted by RLS; dentists mutate it through protected commands.
create type public.tooth_surface as enum (
  'whole',
  'mesial',
  'distal',
  'occlusal',
  'buccal',
  'lingual'
);

create type public.tooth_condition_type as enum (
  'caries',
  'filling',
  'crown',
  'root_canal',
  'fracture',
  'missing',
  'extraction_required',
  'implant'
);

create type public.tooth_condition_status as enum (
  'active',
  'resolved',
  'entered_in_error'
);

create table public.tooth_conditions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  tooth_number smallint not null,
  surface public.tooth_surface not null,
  condition_type public.tooth_condition_type not null,
  status public.tooth_condition_status not null default 'active',
  notes text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  resolved_by uuid references auth.users(id) on delete restrict,
  resolved_at timestamptz,
  error_reason text,
  marked_in_error_by uuid references auth.users(id) on delete restrict,
  marked_in_error_at timestamptz,
  constraint tooth_conditions_valid_fdi_number check (
    tooth_number between 11 and 18
    or tooth_number between 21 and 28
    or tooth_number between 31 and 38
    or tooth_number between 41 and 48
    or tooth_number between 51 and 55
    or tooth_number between 61 and 65
    or tooth_number between 71 and 75
    or tooth_number between 81 and 85
  ),
  constraint tooth_conditions_notes check (
    notes is null or (notes = btrim(notes) and char_length(notes) between 1 and 2000)
  ),
  constraint tooth_conditions_whole_tooth_types check (
    condition_type not in (
      'missing'::public.tooth_condition_type,
      'root_canal'::public.tooth_condition_type,
      'extraction_required'::public.tooth_condition_type,
      'implant'::public.tooth_condition_type
    ) or surface = 'whole'::public.tooth_surface
  ),
  constraint tooth_conditions_status_metadata check (
    (status = 'active'::public.tooth_condition_status
      and resolved_by is null and resolved_at is null
      and error_reason is null and marked_in_error_by is null and marked_in_error_at is null)
    or (status = 'resolved'::public.tooth_condition_status
      and resolved_by is not null and resolved_at is not null
      and error_reason is null and marked_in_error_by is null and marked_in_error_at is null)
    or (status = 'entered_in_error'::public.tooth_condition_status
      and resolved_by is null and resolved_at is null
      and error_reason = btrim(error_reason) and char_length(error_reason) between 1 and 1000
      and marked_in_error_by is not null and marked_in_error_at is not null)
  )
);

create unique index tooth_conditions_one_active_kind_per_surface_idx
  on public.tooth_conditions (patient_id, tooth_number, surface, condition_type)
  where status = 'active'::public.tooth_condition_status;
create index tooth_conditions_active_chart_idx
  on public.tooth_conditions (clinic_id, patient_id, tooth_number)
  where status = 'active'::public.tooth_condition_status;
create index tooth_conditions_history_idx
  on public.tooth_conditions (clinic_id, patient_id, created_at desc, id desc);

create function private.assert_tooth_condition_patient_clinic()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.patients patient
    where patient.id = new.patient_id
      and patient.clinic_id = new.clinic_id
  ) then
    raise exception using errcode = 'P0001', message = 'patient_clinic_mismatch';
  end if;
  return new;
end;
$$;

create function private.assert_tooth_condition_immutable()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.clinic_id <> new.clinic_id
    or old.patient_id <> new.patient_id
    or old.tooth_number <> new.tooth_number
    or old.surface <> new.surface
    or old.condition_type <> new.condition_type
    or old.notes is distinct from new.notes
    or old.created_by <> new.created_by
    or old.created_at <> new.created_at then
    raise exception using errcode = 'P0001', message = 'tooth_condition_history_immutable';
  end if;

  if old.status <> 'active'::public.tooth_condition_status
    or new.status not in (
      'resolved'::public.tooth_condition_status,
      'entered_in_error'::public.tooth_condition_status
    ) then
    raise exception using errcode = 'P0001', message = 'tooth_condition_not_active';
  end if;
  return new;
end;
$$;

create trigger tooth_conditions_match_patient_clinic
before insert or update of clinic_id, patient_id
on public.tooth_conditions
for each row execute function private.assert_tooth_condition_patient_clinic();

create trigger tooth_conditions_are_immutable
before update on public.tooth_conditions
for each row execute function private.assert_tooth_condition_immutable();

alter table public.tooth_conditions enable row level security;
revoke all on table public.tooth_conditions from anon, authenticated;
grant select on table public.tooth_conditions to authenticated;

create policy "clinical staff read tooth conditions"
on public.tooth_conditions for select
to authenticated
using (
  private.has_clinic_role(clinic_id, 'owner'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
);

create function private.require_odontogram_role(
  target_clinic_id uuid,
  actor_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.has_clinic_role(
    target_clinic_id,
    'dentist'::public.clinic_role,
    actor_user_id
  ) then
    raise exception using errcode = 'P0001', message = 'tooth_condition_edit_forbidden';
  end if;
end;
$$;

create function private.lock_tooth_condition_scope(
  target_patient_id uuid,
  target_tooth_number smallint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_patient_id::text || ':' || target_tooth_number::text, 0)
  );
end;
$$;

create function private.tooth_condition_target(
  target_condition_id uuid,
  lock_row boolean default false
)
returns public.tooth_conditions
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.tooth_conditions%rowtype;
begin
  if lock_row then
    select * into target
    from public.tooth_conditions
    where id = target_condition_id
    for update;
  else
    select * into target
    from public.tooth_conditions
    where id = target_condition_id;
  end if;
  if not found then
    raise exception using errcode = 'P0001', message = 'tooth_condition_unavailable';
  end if;
  return target;
end;
$$;

create function public.tooth_condition_create(
  actor_user_id uuid,
  target_patient_id uuid,
  condition_input jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  patient public.patients%rowtype;
  created_condition_id uuid;
  target_tooth_number smallint;
  target_surface public.tooth_surface;
  target_condition_type public.tooth_condition_type;
  target_notes text;
begin
  patient := private.patient_target(target_patient_id, true);
  perform private.require_odontogram_role(patient.clinic_id, actor_user_id);
  if patient.archived_at is not null or jsonb_typeof(condition_input) <> 'object' then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;

  target_tooth_number := nullif(condition_input ->> 'toothNumber', '')::smallint;
  target_surface := nullif(condition_input ->> 'surface', '')::public.tooth_surface;
  target_condition_type := nullif(condition_input ->> 'conditionType', '')::public.tooth_condition_type;
  target_notes := nullif(btrim(condition_input ->> 'notes'), '');
  if target_tooth_number is null or target_surface is null or target_condition_type is null then
    raise exception using errcode = 'P0001', message = 'invalid_tooth_condition_input';
  end if;

  perform private.lock_tooth_condition_scope(patient.id, target_tooth_number);
  if target_condition_type = 'missing'::public.tooth_condition_type
    and exists (
      select 1 from public.tooth_conditions condition
      where condition.patient_id = patient.id
        and condition.tooth_number = target_tooth_number
        and condition.status = 'active'::public.tooth_condition_status
        and condition.condition_type in (
          'caries'::public.tooth_condition_type,
          'filling'::public.tooth_condition_type,
          'crown'::public.tooth_condition_type,
          'root_canal'::public.tooth_condition_type,
          'fracture'::public.tooth_condition_type,
          'extraction_required'::public.tooth_condition_type
        )
    ) then
    raise exception using errcode = 'P0001', message = 'missing_tooth_conflict';
  end if;
  if target_condition_type in (
      'caries'::public.tooth_condition_type,
      'filling'::public.tooth_condition_type,
      'crown'::public.tooth_condition_type,
      'root_canal'::public.tooth_condition_type,
      'fracture'::public.tooth_condition_type,
      'extraction_required'::public.tooth_condition_type
    ) and exists (
      select 1 from public.tooth_conditions condition
      where condition.patient_id = patient.id
        and condition.tooth_number = target_tooth_number
        and condition.status = 'active'::public.tooth_condition_status
        and condition.condition_type = 'missing'::public.tooth_condition_type
    ) then
    raise exception using errcode = 'P0001', message = 'missing_tooth_conflict';
  end if;

  insert into public.tooth_conditions (
    clinic_id, patient_id, tooth_number, surface, condition_type, notes, created_by
  ) values (
    patient.clinic_id, patient.id, target_tooth_number, target_surface,
    target_condition_type, target_notes, actor_user_id
  ) returning id into created_condition_id;
  return created_condition_id;
exception
  when check_violation or invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_tooth_condition_input';
  when unique_violation then
    raise exception using errcode = 'P0001', message = 'duplicate_active_tooth_condition';
end;
$$;

create function public.tooth_condition_resolve(
  actor_user_id uuid,
  target_condition_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.tooth_conditions%rowtype;
  patient public.patients%rowtype;
begin
  target := private.tooth_condition_target(target_condition_id, true);
  patient := private.patient_target(target.patient_id, true);
  perform private.require_odontogram_role(target.clinic_id, actor_user_id);
  if patient.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  if target.status <> 'active'::public.tooth_condition_status then
    raise exception using errcode = 'P0001', message = 'tooth_condition_not_active';
  end if;
  update public.tooth_conditions
  set status = 'resolved'::public.tooth_condition_status,
      resolved_by = actor_user_id,
      resolved_at = now()
  where id = target.id;
end;
$$;

create function public.tooth_condition_mark_in_error(
  actor_user_id uuid,
  target_condition_id uuid,
  correction_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.tooth_conditions%rowtype;
  patient public.patients%rowtype;
  normalized_reason text;
begin
  target := private.tooth_condition_target(target_condition_id, true);
  patient := private.patient_target(target.patient_id, true);
  perform private.require_odontogram_role(target.clinic_id, actor_user_id);
  normalized_reason := nullif(btrim(correction_reason), '');
  if patient.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  if target.status <> 'active'::public.tooth_condition_status then
    raise exception using errcode = 'P0001', message = 'tooth_condition_not_active';
  end if;
  if normalized_reason is null or char_length(normalized_reason) > 1000 then
    raise exception using errcode = 'P0001', message = 'invalid_tooth_condition_input';
  end if;
  update public.tooth_conditions
  set status = 'entered_in_error'::public.tooth_condition_status,
      error_reason = normalized_reason,
      marked_in_error_by = actor_user_id,
      marked_in_error_at = now()
  where id = target.id;
end;
$$;

revoke all on function private.assert_tooth_condition_patient_clinic() from public;
revoke all on function private.assert_tooth_condition_immutable() from public;
revoke all on function private.require_odontogram_role(uuid, uuid) from public;
revoke all on function private.lock_tooth_condition_scope(uuid, smallint) from public;
revoke all on function private.tooth_condition_target(uuid, boolean) from public;
revoke all on function public.tooth_condition_create(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.tooth_condition_resolve(uuid, uuid) from public, anon, authenticated;
revoke all on function public.tooth_condition_mark_in_error(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.tooth_condition_create(uuid, uuid, jsonb) to service_role;
grant execute on function public.tooth_condition_resolve(uuid, uuid) to service_role;
grant execute on function public.tooth_condition_mark_in_error(uuid, uuid, text) to service_role;
