-- Appointment commands are executable only by service_role inside the
-- authenticated Edge Function. Each command repeats tenant and role checks.
create function private.require_appointment_role(
  target_clinic_id uuid,
  actor_user_id uuid,
  allowed_roles public.clinic_role[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from unnest(allowed_roles) as allowed(role)
    where private.has_clinic_role(target_clinic_id, allowed.role, actor_user_id)
  ) then
    raise exception using errcode = 'P0001', message = 'appointment_action_forbidden';
  end if;
end;
$$;

create function private.appointment_target(
  target_appointment_id uuid,
  lock_row boolean default false
)
returns public.appointments
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.appointments%rowtype;
begin
  if lock_row then
    select * into target from public.appointments where id = target_appointment_id for update;
  else
    select * into target from public.appointments where id = target_appointment_id;
  end if;
  if not found then
    raise exception using errcode = 'P0001', message = 'appointment_unavailable';
  end if;
  return target;
end;
$$;

create function private.appointment_lock_participants(
  target_patient_id uuid,
  target_dentist_member_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  patient_lock bigint := hashtextextended(target_patient_id::text, 1);
  dentist_lock bigint := hashtextextended(target_dentist_member_id::text, 1);
begin
  -- A stable order prevents a patient/dentist pair from deadlocking two
  -- concurrent booking requests. Hash collisions only serialize extra work.
  if patient_lock <= dentist_lock then
    perform pg_advisory_xact_lock(patient_lock);
    perform pg_advisory_xact_lock(dentist_lock);
  else
    perform pg_advisory_xact_lock(dentist_lock);
    perform pg_advisory_xact_lock(patient_lock);
  end if;
end;
$$;

create function private.require_active_appointment_patient(
  target_clinic_id uuid,
  target_patient_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.patients patient
    where patient.id = target_patient_id
      and patient.clinic_id = target_clinic_id
      and patient.archived_at is null
  ) then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
end;
$$;

create function private.require_active_appointment_dentist(
  target_clinic_id uuid,
  target_dentist_member_id uuid
)
returns void
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
    where member.id = target_dentist_member_id
      and member.clinic_id = target_clinic_id
      and member.is_active
      and member_role.role = 'dentist'::public.clinic_role
  ) then
    raise exception using errcode = 'P0001', message = 'active_dentist_required';
  end if;
end;
$$;

create function private.appointment_has_patient_overlap(
  target_clinic_id uuid,
  target_patient_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  excluded_appointment_id uuid default null
)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.appointments appointment
    where appointment.clinic_id = target_clinic_id
      and appointment.patient_id = target_patient_id
      and appointment.status in ('scheduled', 'confirmed', 'in_progress')
      and (excluded_appointment_id is null or appointment.id <> excluded_appointment_id)
      and tstzrange(appointment.starts_at, appointment.ends_at, '[)')
        && tstzrange(target_starts_at, target_ends_at, '[)')
  );
$$;

create function private.appointment_has_dentist_overlap(
  target_clinic_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  excluded_appointment_id uuid default null
)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.appointments appointment
    where appointment.clinic_id = target_clinic_id
      and appointment.dentist_member_id = target_dentist_member_id
      and appointment.status in ('scheduled', 'confirmed', 'in_progress')
      and (excluded_appointment_id is null or appointment.id <> excluded_appointment_id)
      and tstzrange(appointment.starts_at, appointment.ends_at, '[)')
        && tstzrange(target_starts_at, target_ends_at, '[)')
  );
$$;

create function private.appointment_availability_conflict(
  target_clinic_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz
)
returns public.appointment_conflict_kind
language plpgsql
security definer
set search_path = ''
as $$
declare
  clinic_time_zone text;
  local_start timestamp;
  local_end timestamp;
  local_date date;
  local_weekday smallint;
  exception_kind public.appointment_conflict_kind;
begin
  select time_zone into clinic_time_zone
  from public.clinics where id = target_clinic_id;
  if clinic_time_zone is null then
    raise exception using errcode = 'P0001', message = 'appointment_unavailable';
  end if;

  local_start := target_starts_at at time zone clinic_time_zone;
  local_end := target_ends_at at time zone clinic_time_zone;
  if local_start::date <> local_end::date then
    return 'working_hours';
  end if;
  local_date := local_start::date;
  local_weekday := extract(isodow from local_start)::smallint;

  select case exception.kind
      when 'leave' then 'leave'::public.appointment_conflict_kind
      else 'unavailable'::public.appointment_conflict_kind
    end
  into exception_kind
  from public.doctor_schedule_exceptions exception
  where exception.clinic_id = target_clinic_id
    and exception.dentist_member_id = target_dentist_member_id
    and tstzrange(exception.starts_at, exception.ends_at, '[)')
      && tstzrange(target_starts_at, target_ends_at, '[)')
  order by exception.starts_at
  limit 1;
  if exception_kind is not null then
    return exception_kind;
  end if;

  if not exists (
    select 1
    from public.doctor_schedule_versions version
    join public.doctor_working_hours hours
      on hours.schedule_version_id = version.id
    where version.clinic_id = target_clinic_id
      and version.dentist_member_id = target_dentist_member_id
      and version.effective_from <= local_date
      and version.effective_from = (
        select max(current_version.effective_from)
        from public.doctor_schedule_versions current_version
        where current_version.dentist_member_id = target_dentist_member_id
          and current_version.effective_from <= local_date
      )
      and hours.weekday = local_weekday
      and hours.starts_at <= local_start::time
      and hours.ends_at >= local_end::time
      and not exists (
        select 1 from public.doctor_schedule_breaks schedule_break
        where schedule_break.working_hours_id = hours.id
          and int4range(
              (extract(epoch from schedule_break.starts_at) / 60)::integer,
              (extract(epoch from schedule_break.ends_at) / 60)::integer,
              '[)'
            ) && int4range(
              (extract(epoch from local_start::time) / 60)::integer,
              (extract(epoch from local_end::time) / 60)::integer,
              '[)'
            )
    )
  ) then
    return 'working_hours';
  end if;
  return null;
end;
$$;

create function private.appointment_require_override_or_clean(
  actor_user_id uuid,
  target_clinic_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  excluded_appointment_id uuid,
  supplied_override_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  availability_conflict public.appointment_conflict_kind;
  has_dentist_overlap boolean;
  normalized_reason text := nullif(btrim(supplied_override_reason), '');
  is_owner boolean;
begin
  has_dentist_overlap := private.appointment_has_dentist_overlap(
    target_clinic_id, target_dentist_member_id, target_starts_at, target_ends_at,
    excluded_appointment_id
  );
  availability_conflict := private.appointment_availability_conflict(
    target_clinic_id, target_dentist_member_id, target_starts_at, target_ends_at
  );
  if not has_dentist_overlap and availability_conflict is null then
    return null;
  end if;

  is_owner := private.has_clinic_role(
    target_clinic_id, 'owner'::public.clinic_role, actor_user_id
  );
  if not is_owner then
    if has_dentist_overlap then
      raise exception using errcode = 'P0001', message = 'dentist_overlap';
    elsif availability_conflict = 'leave' then
      raise exception using errcode = 'P0001', message = 'leave_conflict';
    elsif availability_conflict = 'unavailable' then
      raise exception using errcode = 'P0001', message = 'unavailable_conflict';
    else
      raise exception using errcode = 'P0001', message = 'working_hours_conflict';
    end if;
  end if;
  if normalized_reason is null then
    raise exception using errcode = 'P0001', message = 'override_reason_required';
  end if;
  return normalized_reason;
end;
$$;

create function private.appointment_record_override_audit(
  actor_user_id uuid,
  target_clinic_id uuid,
  target_appointment_id uuid,
  override_reason text
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, reason, safe_metadata
  ) values (
    target_clinic_id, actor_user_id, 'appointment_conflict_overridden',
    'appointment', target_appointment_id, override_reason, '{}'::jsonb
  );
$$;

create function public.appointment_create(
  actor_user_id uuid,
  target_clinic_id uuid,
  target_patient_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  appointment_purpose text default null,
  supplied_override_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_appointment_id uuid;
  effective_override_reason text;
begin
  perform private.require_appointment_role(
    target_clinic_id, actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if target_starts_at >= target_ends_at then
    raise exception using errcode = 'P0001', message = 'invalid_appointment_input';
  end if;
  perform private.require_active_appointment_patient(target_clinic_id, target_patient_id);
  perform private.require_active_appointment_dentist(target_clinic_id, target_dentist_member_id);
  perform private.appointment_lock_participants(target_patient_id, target_dentist_member_id);
  if private.appointment_has_patient_overlap(
    target_clinic_id, target_patient_id, target_starts_at, target_ends_at
  ) then
    raise exception using errcode = 'P0001', message = 'patient_overlap';
  end if;
  effective_override_reason := private.appointment_require_override_or_clean(
    actor_user_id, target_clinic_id, target_dentist_member_id,
    target_starts_at, target_ends_at, null, supplied_override_reason
  );

  insert into public.appointments (
    clinic_id, patient_id, dentist_member_id, starts_at, ends_at, purpose,
    override_reason, overridden_by, overridden_at, created_by
  ) values (
    target_clinic_id, target_patient_id, target_dentist_member_id,
    target_starts_at, target_ends_at, nullif(btrim(appointment_purpose), ''),
    effective_override_reason,
    case when effective_override_reason is null then null else actor_user_id end,
    case when effective_override_reason is null then null else now() end,
    actor_user_id
  ) returning id into created_appointment_id;
  if effective_override_reason is not null then
    perform private.appointment_record_override_audit(
      actor_user_id, target_clinic_id, created_appointment_id, effective_override_reason
    );
  end if;
  return created_appointment_id;
exception
  when check_violation or invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_appointment_input';
  when exclusion_violation then
    raise exception using errcode = 'P0001', message = 'patient_overlap';
end;
$$;

create function public.appointment_reschedule(
  actor_user_id uuid,
  target_appointment_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  supplied_override_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.appointments%rowtype;
  effective_override_reason text;
begin
  target := private.appointment_target(target_appointment_id, true);
  perform private.require_appointment_role(
    target.clinic_id, actor_user_id,
    array['owner', 'receptionist']::public.clinic_role[]
  );
  if target.status not in ('scheduled', 'confirmed') or target_starts_at >= target_ends_at then
    raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
  end if;
  perform private.appointment_lock_participants(target.patient_id, target.dentist_member_id);
  if private.appointment_has_patient_overlap(
    target.clinic_id, target.patient_id, target_starts_at, target_ends_at, target.id
  ) then
    raise exception using errcode = 'P0001', message = 'patient_overlap';
  end if;
  effective_override_reason := private.appointment_require_override_or_clean(
    actor_user_id, target.clinic_id, target.dentist_member_id,
    target_starts_at, target_ends_at, target.id, supplied_override_reason
  );
  update public.appointments
  set starts_at = target_starts_at,
      ends_at = target_ends_at,
      override_reason = effective_override_reason,
      overridden_by = case when effective_override_reason is null then null else actor_user_id end,
      overridden_at = case when effective_override_reason is null then null else now() end
  where id = target.id;
  if effective_override_reason is not null then
    perform private.appointment_record_override_audit(
      actor_user_id, target.clinic_id, target.id, effective_override_reason
    );
  end if;
exception
  when check_violation or invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_appointment_input';
  when exclusion_violation then
    raise exception using errcode = 'P0001', message = 'patient_overlap';
end;
$$;

create function public.appointment_transition(
  actor_user_id uuid,
  target_appointment_id uuid,
  next_status public.appointment_status,
  supplied_cancellation_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.appointments%rowtype;
  normalized_cancellation_reason text := nullif(btrim(supplied_cancellation_reason), '');
begin
  target := private.appointment_target(target_appointment_id, true);
  case next_status
    when 'confirmed' then
      perform private.require_appointment_role(
        target.clinic_id, actor_user_id,
        array['owner', 'receptionist']::public.clinic_role[]
      );
      if target.status <> 'scheduled' then
        raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
      end if;
    when 'in_progress' then
      perform private.require_appointment_role(
        target.clinic_id, actor_user_id,
        array['owner', 'dentist']::public.clinic_role[]
      );
      if target.status not in ('scheduled', 'confirmed') then
        raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
      end if;
    when 'completed' then
      perform private.require_appointment_role(
        target.clinic_id, actor_user_id,
        array['owner', 'dentist']::public.clinic_role[]
      );
      if target.status <> 'in_progress' or target.starts_at > now() then
        raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
      end if;
    when 'cancelled' then
      perform private.require_appointment_role(
        target.clinic_id, actor_user_id,
        array['owner', 'dentist', 'receptionist']::public.clinic_role[]
      );
      if target.status not in ('scheduled', 'confirmed', 'in_progress') or normalized_cancellation_reason is null then
        raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
      end if;
    when 'no_show' then
      perform private.require_appointment_role(
        target.clinic_id, actor_user_id,
        array['owner', 'dentist', 'receptionist']::public.clinic_role[]
      );
      if target.status not in ('scheduled', 'confirmed') then
        raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
      end if;
    else
      raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
  end case;

  update public.appointments
  set status = next_status,
      cancellation_reason = case
        when next_status = 'cancelled' then normalized_cancellation_reason else null
      end,
      status_changed_by = actor_user_id,
      status_changed_at = now()
  where id = target.id;
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_appointment_transition';
end;
$$;

create function public.appointment_upsert_preparation_note(
  actor_user_id uuid,
  target_appointment_id uuid,
  next_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.appointments%rowtype;
begin
  target := private.appointment_target(target_appointment_id, true);
  perform private.require_appointment_role(
    target.clinic_id, actor_user_id,
    array['owner', 'dentist', 'assistant']::public.clinic_role[]
  );
  insert into public.appointment_preparation_notes (appointment_id, note, created_by)
  values (target.id, nullif(btrim(next_note), ''), actor_user_id)
  on conflict (appointment_id) do update
  set note = excluded.note;
exception
  when check_violation or not_null_violation then
    raise exception using errcode = 'P0001', message = 'invalid_preparation_note';
end;
$$;

revoke all on function private.require_appointment_role(uuid, uuid, public.clinic_role[]) from public;
revoke all on function private.appointment_target(uuid, boolean) from public;
revoke all on function private.appointment_lock_participants(uuid, uuid) from public;
revoke all on function private.require_active_appointment_patient(uuid, uuid) from public;
revoke all on function private.require_active_appointment_dentist(uuid, uuid) from public;
revoke all on function private.appointment_has_patient_overlap(uuid, uuid, timestamptz, timestamptz, uuid) from public;
revoke all on function private.appointment_has_dentist_overlap(uuid, uuid, timestamptz, timestamptz, uuid) from public;
revoke all on function private.appointment_availability_conflict(uuid, uuid, timestamptz, timestamptz) from public;
revoke all on function private.appointment_require_override_or_clean(uuid, uuid, uuid, timestamptz, timestamptz, uuid, text) from public;
revoke all on function private.appointment_record_override_audit(uuid, uuid, uuid, text) from public;
revoke all on function public.appointment_create(uuid, uuid, uuid, uuid, timestamptz, timestamptz, text, text)
  from public, anon, authenticated;
revoke all on function public.appointment_reschedule(uuid, uuid, timestamptz, timestamptz, text)
  from public, anon, authenticated;
revoke all on function public.appointment_transition(uuid, uuid, public.appointment_status, text)
  from public, anon, authenticated;
revoke all on function public.appointment_upsert_preparation_note(uuid, uuid, text)
  from public, anon, authenticated;
grant execute on function public.appointment_create(uuid, uuid, uuid, uuid, timestamptz, timestamptz, text, text)
  to service_role;
grant execute on function public.appointment_reschedule(uuid, uuid, timestamptz, timestamptz, text)
  to service_role;
grant execute on function public.appointment_transition(uuid, uuid, public.appointment_status, text)
  to service_role;
grant execute on function public.appointment_upsert_preparation_note(uuid, uuid, text)
  to service_role;
