create function public.doctor_schedule_update_exception_with_impact(
  actor_user_id uuid,
  target_exception_id uuid,
  exception_kind text,
  exception_starts_at timestamptz,
  exception_ends_at timestamptz,
  exception_reason text default null,
  confirm_affected_appointments boolean default false,
  appointment_impact_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_exception public.doctor_schedule_exceptions%rowtype;
  affected_count integer;
  flag_kind public.appointment_conflict_kind;
begin
  select * into target_exception
  from public.doctor_schedule_exceptions
  where id = target_exception_id
  for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'schedule_exception_unavailable';
  end if;
  perform 1 from private.require_schedule_editor(actor_user_id, target_exception.dentist_member_id);
  flag_kind := case exception_kind when 'leave' then 'leave'::public.appointment_conflict_kind
    else 'unavailable'::public.appointment_conflict_kind end;
  affected_count := private.schedule_record_appointment_impacts(
    actor_user_id, target_exception.dentist_member_id, exception_starts_at, exception_ends_at, flag_kind
  );
  perform private.schedule_require_appointment_impact_confirmation(
    actor_user_id, target_exception.clinic_id, affected_count, confirm_affected_appointments, appointment_impact_reason
  );
  perform public.doctor_schedule_update_exception(
    actor_user_id, target_exception_id, exception_kind,
    exception_starts_at, exception_ends_at, exception_reason
  );
  if affected_count > 0 then
    perform private.schedule_flag_appointment_impacts(
      actor_user_id, target_exception.dentist_member_id,
      exception_starts_at, exception_ends_at, flag_kind
    );
  end if;
end;
$$;

revoke all on function public.doctor_schedule_update_exception_with_impact(uuid, uuid, text, timestamptz, timestamptz, text, boolean, text) from public, anon, authenticated;
grant execute on function public.doctor_schedule_update_exception_with_impact(uuid, uuid, text, timestamptz, timestamptz, text, boolean, text) to service_role;
