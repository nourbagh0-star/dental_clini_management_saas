-- Phase 6 links schedule changes to future appointments. The original schedule
-- commands remain for migration compatibility; the Edge Function uses these
-- impact-aware commands exclusively.
create function private.schedule_record_appointment_impacts(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  target_kind public.appointment_conflict_kind
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_count integer;
begin
  select count(*)::integer into affected_count
  from public.appointments appointment
  where appointment.dentist_member_id = target_dentist_member_id
    and appointment.status in ('scheduled', 'confirmed', 'in_progress')
    and appointment.starts_at >= now()
    and tstzrange(appointment.starts_at, appointment.ends_at, '[)')
      && tstzrange(target_starts_at, target_ends_at, '[)');
  return affected_count;
end;
$$;

create function private.schedule_require_appointment_impact_confirmation(
  actor_user_id uuid,
  target_clinic_id uuid,
  affected_count integer,
  confirmed boolean,
  reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if affected_count = 0 then return; end if;
  if not private.has_clinic_role(target_clinic_id, 'owner'::public.clinic_role, actor_user_id)
    or not confirmed
    or nullif(btrim(reason), '') is null then
    raise exception using errcode = 'P0001', message = 'schedule_change_affects_appointments';
  end if;
end;
$$;

create function private.schedule_flag_appointment_impacts(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  target_kind public.appointment_conflict_kind
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.appointment_conflict_flags (
    appointment_id, kind, detected_by
  )
  select appointment.id, target_kind, actor_user_id
  from public.appointments appointment
  where appointment.dentist_member_id = target_dentist_member_id
    and appointment.status in ('scheduled', 'confirmed', 'in_progress')
    and appointment.starts_at >= now()
    and tstzrange(appointment.starts_at, appointment.ends_at, '[)')
      && tstzrange(target_starts_at, target_ends_at, '[)')
    and not exists (
      select 1 from public.appointment_conflict_flags flag
      where flag.appointment_id = appointment.id
        and flag.kind = target_kind
        and flag.resolved_at is null
    );
$$;

create function public.doctor_schedule_create_exception_with_impact(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  exception_kind text,
  exception_starts_at timestamptz,
  exception_ends_at timestamptz,
  exception_reason text default null,
  confirm_affected_appointments boolean default false,
  appointment_impact_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_clinic_id uuid;
  affected_count integer;
  exception_id uuid;
  flag_kind public.appointment_conflict_kind;
begin
  select clinic_id into target_clinic_id
  from private.require_schedule_editor(actor_user_id, target_dentist_member_id);
  flag_kind := case exception_kind when 'leave' then 'leave'::public.appointment_conflict_kind
    else 'unavailable'::public.appointment_conflict_kind end;
  affected_count := private.schedule_record_appointment_impacts(
    actor_user_id, target_dentist_member_id, exception_starts_at, exception_ends_at, flag_kind
  );
  perform private.schedule_require_appointment_impact_confirmation(
    actor_user_id, target_clinic_id, affected_count, confirm_affected_appointments, appointment_impact_reason
  );
  exception_id := public.doctor_schedule_create_exception(
    actor_user_id, target_dentist_member_id, exception_kind,
    exception_starts_at, exception_ends_at, exception_reason
  );
  if affected_count > 0 then
    perform private.schedule_flag_appointment_impacts(
      actor_user_id, target_dentist_member_id, exception_starts_at, exception_ends_at, flag_kind
    );
  end if;
  return exception_id;
end;
$$;

revoke all on function private.schedule_record_appointment_impacts(uuid, uuid, timestamptz, timestamptz, public.appointment_conflict_kind) from public;
revoke all on function private.schedule_require_appointment_impact_confirmation(uuid, uuid, integer, boolean, text) from public;
revoke all on function private.schedule_flag_appointment_impacts(uuid, uuid, timestamptz, timestamptz, public.appointment_conflict_kind) from public;
revoke all on function public.doctor_schedule_create_exception_with_impact(uuid, uuid, text, timestamptz, timestamptz, text, boolean, text) from public, anon, authenticated;
grant execute on function public.doctor_schedule_create_exception_with_impact(uuid, uuid, text, timestamptz, timestamptz, text, boolean, text) to service_role;
