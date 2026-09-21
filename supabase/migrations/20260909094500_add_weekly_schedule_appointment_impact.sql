create function private.schedule_weekly_appointment_impact_count(
  target_dentist_member_id uuid,
  target_effective_from date,
  candidate_periods jsonb
)
returns integer
language sql
security definer
set search_path = ''
as $$
  with future_appointments as (
    select appointment.id,
      appointment.starts_at at time zone clinic.time_zone as local_starts_at,
      appointment.ends_at at time zone clinic.time_zone as local_ends_at
    from public.appointments appointment
    join public.clinics clinic on clinic.id = appointment.clinic_id
    where appointment.dentist_member_id = target_dentist_member_id
      and appointment.status in ('scheduled', 'confirmed', 'in_progress')
      and appointment.starts_at >= now()
  )
  select count(*)::integer
  from future_appointments appointment
  where appointment.local_starts_at::date >= target_effective_from
    and (
      appointment.local_starts_at::date <> appointment.local_ends_at::date
      or not exists (
        select 1
        from jsonb_array_elements(candidate_periods) period
        where (period ->> 'weekday')::smallint = extract(isodow from appointment.local_starts_at)::smallint
          and (period ->> 'startsAt')::time <= appointment.local_starts_at::time
          and (period ->> 'endsAt')::time >= appointment.local_ends_at::time
          and not exists (
            select 1
            from jsonb_array_elements(coalesce(period -> 'breaks', '[]'::jsonb)) schedule_break
            where int4range(
                (extract(epoch from (schedule_break ->> 'startsAt')::time) / 60)::integer,
                (extract(epoch from (schedule_break ->> 'endsAt')::time) / 60)::integer,
                '[)'
              ) && int4range(
                (extract(epoch from appointment.local_starts_at::time) / 60)::integer,
                (extract(epoch from appointment.local_ends_at::time) / 60)::integer,
                '[)'
              )
          )
      )
    );
$$;

create function private.schedule_flag_weekly_appointment_impacts(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  target_effective_from date,
  candidate_periods jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.appointment_conflict_flags (appointment_id, kind, detected_by)
  select appointment.id, 'working_hours'::public.appointment_conflict_kind, actor_user_id
  from public.appointments appointment
  join public.clinics clinic on clinic.id = appointment.clinic_id
  where appointment.dentist_member_id = target_dentist_member_id
    and appointment.status in ('scheduled', 'confirmed', 'in_progress')
    and appointment.starts_at >= now()
    and (appointment.starts_at at time zone clinic.time_zone)::date >= target_effective_from
    and (
      (appointment.starts_at at time zone clinic.time_zone)::date <> (appointment.ends_at at time zone clinic.time_zone)::date
      or not exists (
        select 1 from jsonb_array_elements(candidate_periods) period
        where (period ->> 'weekday')::smallint = extract(isodow from appointment.starts_at at time zone clinic.time_zone)::smallint
          and (period ->> 'startsAt')::time <= (appointment.starts_at at time zone clinic.time_zone)::time
          and (period ->> 'endsAt')::time >= (appointment.ends_at at time zone clinic.time_zone)::time
          and not exists (
            select 1 from jsonb_array_elements(coalesce(period -> 'breaks', '[]'::jsonb)) schedule_break
            where int4range((extract(epoch from (schedule_break ->> 'startsAt')::time) / 60)::integer, (extract(epoch from (schedule_break ->> 'endsAt')::time) / 60)::integer, '[)')
              && int4range((extract(epoch from (appointment.starts_at at time zone clinic.time_zone)::time) / 60)::integer, (extract(epoch from (appointment.ends_at at time zone clinic.time_zone)::time) / 60)::integer, '[)')
          )
      )
    )
    and not exists (
      select 1 from public.appointment_conflict_flags flag
      where flag.appointment_id = appointment.id
        and flag.kind = 'working_hours'::public.appointment_conflict_kind
        and flag.resolved_at is null
    );
$$;

create function public.doctor_schedule_preview_weekly_impact(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  target_effective_from date,
  working_periods jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_count integer;
begin
  perform 1 from private.require_schedule_editor(actor_user_id, target_dentist_member_id);
  affected_count := private.schedule_weekly_appointment_impact_count(
    target_dentist_member_id, target_effective_from, working_periods
  );
  return jsonb_build_object('count', affected_count);
end;
$$;

create function public.doctor_schedule_replace_weekly_with_impact(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  target_effective_from date,
  working_periods jsonb,
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
  schedule_version_id uuid;
begin
  select clinic_id into target_clinic_id
  from private.require_schedule_editor(actor_user_id, target_dentist_member_id);
  affected_count := private.schedule_weekly_appointment_impact_count(
    target_dentist_member_id, target_effective_from, working_periods
  );
  perform private.schedule_require_appointment_impact_confirmation(
    actor_user_id, target_clinic_id, affected_count, confirm_affected_appointments, appointment_impact_reason
  );
  schedule_version_id := public.doctor_schedule_replace_weekly(
    actor_user_id, target_dentist_member_id, target_effective_from, working_periods
  );
  if affected_count > 0 then
    perform private.schedule_flag_weekly_appointment_impacts(
      actor_user_id, target_dentist_member_id, target_effective_from, working_periods
    );
  end if;
  return schedule_version_id;
end;
$$;

revoke all on function private.schedule_weekly_appointment_impact_count(uuid, date, jsonb) from public;
revoke all on function private.schedule_flag_weekly_appointment_impacts(uuid, uuid, date, jsonb) from public;
revoke all on function public.doctor_schedule_preview_weekly_impact(uuid, uuid, date, jsonb) from public, anon, authenticated;
revoke all on function public.doctor_schedule_replace_weekly_with_impact(uuid, uuid, date, jsonb, boolean, text) from public, anon, authenticated;
grant execute on function public.doctor_schedule_preview_weekly_impact(uuid, uuid, date, jsonb) to service_role;
grant execute on function public.doctor_schedule_replace_weekly_with_impact(uuid, uuid, date, jsonb, boolean, text) to service_role;
