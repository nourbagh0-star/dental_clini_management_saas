-- Phase 4 server commands. Only the authenticated Edge Function's service
-- role can execute these commands; every command independently rechecks the
-- actor's present clinic role.
create function private.require_schedule_editor(
  actor_user_id uuid,
  target_dentist_member_id uuid
)
returns table (clinic_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_member public.clinic_members%rowtype;
begin
  select * into target_member
  from public.clinic_members member
  where member.id = target_dentist_member_id
  for update;

  if not found
    or not target_member.is_active
    or not exists (
      select 1
      from public.clinic_member_roles member_role
      where member_role.clinic_member_id = target_member.id
        and member_role.role = 'dentist'::public.clinic_role
    ) then
    raise exception using errcode = 'P0001', message = 'active_dentist_required';
  end if;

  if target_member.user_id <> actor_user_id
    and not private.has_clinic_role(
      target_member.clinic_id,
      'owner'::public.clinic_role,
      actor_user_id
    ) then
    raise exception using errcode = 'P0001', message = 'schedule_edit_forbidden';
  end if;

  return query select target_member.clinic_id;
end;
$$;

create function private.require_future_schedule_effective_date(
  target_clinic_id uuid,
  target_effective_from date
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  minimum_effective_date date;
begin
  select (now() at time zone clinic.time_zone)::date + 1
    into minimum_effective_date
  from public.clinics clinic
  where clinic.id = target_clinic_id;

  if minimum_effective_date is null
    or target_effective_from < minimum_effective_date then
    raise exception using errcode = 'P0001', message = 'schedule_effective_date_invalid';
  end if;
end;
$$;

create function public.doctor_schedule_replace_weekly(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  target_effective_from date,
  working_periods jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_clinic_id uuid;
  v_schedule_version_id uuid;
  working_hours_id uuid;
  period jsonb;
  pause jsonb;
  period_weekday smallint;
  period_starts_at time;
  period_ends_at time;
  pause_starts_at time;
  pause_ends_at time;
begin
  select clinic_id into target_clinic_id
  from private.require_schedule_editor(actor_user_id, target_dentist_member_id);
  perform private.require_future_schedule_effective_date(
    target_clinic_id,
    target_effective_from
  );

  if jsonb_typeof(working_periods) <> 'array' then
    raise exception using errcode = 'P0001', message = 'invalid_schedule_payload';
  end if;

  insert into public.doctor_schedule_versions (
    clinic_id, dentist_member_id, effective_from, created_by
  ) values (
    target_clinic_id, target_dentist_member_id, target_effective_from, actor_user_id
  ) on conflict (dentist_member_id, effective_from)
  do update set effective_from = excluded.effective_from
  returning id into v_schedule_version_id;

  delete from public.doctor_schedule_breaks schedule_break
  using public.doctor_working_hours working_hours
  where working_hours.id = schedule_break.working_hours_id
    and working_hours.schedule_version_id = v_schedule_version_id;
  delete from public.doctor_working_hours
  where doctor_working_hours.schedule_version_id = v_schedule_version_id;

  for period in select value from jsonb_array_elements(working_periods)
  loop
    if jsonb_typeof(period) <> 'object'
      or not (period ? 'weekday')
      or not (period ? 'startsAt')
      or not (period ? 'endsAt')
      or (period ? 'breaks' and jsonb_typeof(period -> 'breaks') <> 'array') then
      raise exception using errcode = 'P0001', message = 'invalid_schedule_payload';
    end if;

    begin
      period_weekday := (period ->> 'weekday')::smallint;
      period_starts_at := (period ->> 'startsAt')::time;
      period_ends_at := (period ->> 'endsAt')::time;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception using errcode = 'P0001', message = 'invalid_schedule_payload';
    end;

    insert into public.doctor_working_hours (
      schedule_version_id, weekday, starts_at, ends_at
    ) values (
      v_schedule_version_id, period_weekday, period_starts_at, period_ends_at
    ) returning id into working_hours_id;

    for pause in
      select value from jsonb_array_elements(coalesce(period -> 'breaks', '[]'::jsonb))
    loop
      if jsonb_typeof(pause) <> 'object'
        or not (pause ? 'startsAt')
        or not (pause ? 'endsAt') then
        raise exception using errcode = 'P0001', message = 'invalid_schedule_payload';
      end if;
      begin
        pause_starts_at := (pause ->> 'startsAt')::time;
        pause_ends_at := (pause ->> 'endsAt')::time;
      exception when invalid_text_representation or numeric_value_out_of_range then
        raise exception using errcode = 'P0001', message = 'invalid_schedule_payload';
      end;
      insert into public.doctor_schedule_breaks (
        working_hours_id, starts_at, ends_at
      ) values (
        working_hours_id, pause_starts_at, pause_ends_at
      );
    end loop;
  end loop;

  return v_schedule_version_id;
exception
  when check_violation or exclusion_violation then
    raise exception using errcode = 'P0001', message = 'invalid_schedule_payload';
end;
$$;

create function public.doctor_schedule_create_exception(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  exception_kind text,
  exception_starts_at timestamptz,
  exception_ends_at timestamptz,
  exception_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_clinic_id uuid;
  exception_id uuid;
begin
  select clinic_id into target_clinic_id
  from private.require_schedule_editor(actor_user_id, target_dentist_member_id);

  insert into public.doctor_schedule_exceptions (
    clinic_id, dentist_member_id, kind, starts_at, ends_at, reason, created_by
  ) values (
    target_clinic_id, target_dentist_member_id, exception_kind,
    exception_starts_at, exception_ends_at, nullif(btrim(exception_reason), ''), actor_user_id
  ) returning id into exception_id;
  return exception_id;
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_schedule_exception';
end;
$$;

create function public.doctor_schedule_update_exception(
  actor_user_id uuid,
  target_exception_id uuid,
  exception_kind text,
  exception_starts_at timestamptz,
  exception_ends_at timestamptz,
  exception_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_exception public.doctor_schedule_exceptions%rowtype;
begin
  select * into target_exception
  from public.doctor_schedule_exceptions
  where id = target_exception_id
  for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'schedule_exception_unavailable';
  end if;
  perform private.require_schedule_editor(actor_user_id, target_exception.dentist_member_id);

  update public.doctor_schedule_exceptions
  set kind = exception_kind,
      starts_at = exception_starts_at,
      ends_at = exception_ends_at,
      reason = nullif(btrim(exception_reason), '')
  where id = target_exception.id;
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_schedule_exception';
end;
$$;

create function public.doctor_schedule_delete_exception(
  actor_user_id uuid,
  target_exception_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_exception public.doctor_schedule_exceptions%rowtype;
begin
  select * into target_exception
  from public.doctor_schedule_exceptions
  where id = target_exception_id
  for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'schedule_exception_unavailable';
  end if;
  perform private.require_schedule_editor(actor_user_id, target_exception.dentist_member_id);
  delete from public.doctor_schedule_exceptions where id = target_exception.id;
end;
$$;

revoke all on function private.require_schedule_editor(uuid, uuid) from public;
revoke all on function private.require_future_schedule_effective_date(uuid, date) from public;
revoke all on function public.doctor_schedule_replace_weekly(uuid, uuid, date, jsonb)
  from public, anon, authenticated;
revoke all on function public.doctor_schedule_create_exception(
  uuid, uuid, text, timestamptz, timestamptz, text
) from public, anon, authenticated;
revoke all on function public.doctor_schedule_update_exception(
  uuid, uuid, text, timestamptz, timestamptz, text
) from public, anon, authenticated;
revoke all on function public.doctor_schedule_delete_exception(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.doctor_schedule_replace_weekly(uuid, uuid, date, jsonb)
  to service_role;
grant execute on function public.doctor_schedule_create_exception(
  uuid, uuid, text, timestamptz, timestamptz, text
) to service_role;
grant execute on function public.doctor_schedule_update_exception(
  uuid, uuid, text, timestamptz, timestamptz, text
) to service_role;
grant execute on function public.doctor_schedule_delete_exception(uuid, uuid)
  to service_role;
