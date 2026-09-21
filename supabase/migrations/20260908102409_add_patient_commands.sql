-- Patient mutations run only through the authenticated Edge Function. These
-- commands independently enforce role and tenant rules before changing data.
create function private.require_patient_role(
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
    raise exception using errcode = 'P0001', message = 'patient_edit_forbidden';
  end if;
end;
$$;

create function private.patient_target(
  target_patient_id uuid,
  lock_row boolean default false
)
returns public.patients
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patients%rowtype;
begin
  if lock_row then
    select * into target from public.patients where id = target_patient_id for update;
  else
    select * into target from public.patients where id = target_patient_id;
  end if;
  if not found then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  return target;
end;
$$;

create function private.next_patient_number(target_clinic_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  allocated_number integer;
begin
  insert into public.clinic_patient_counters (clinic_id, next_patient_number)
  values (target_clinic_id, 2)
  on conflict (clinic_id) do update
  set next_patient_number = public.clinic_patient_counters.next_patient_number + 1
  returning next_patient_number - 1 into allocated_number;

  return 'PAT-' || lpad(allocated_number::text, 5, '0');
end;
$$;

create function public.patient_create(
  actor_user_id uuid,
  target_clinic_id uuid,
  demographic jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_patient_id uuid;
begin
  perform private.require_patient_role(
    target_clinic_id,
    actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if jsonb_typeof(demographic) <> 'object' then
    raise exception using errcode = 'P0001', message = 'invalid_patient_input';
  end if;

  insert into public.patients (
    clinic_id, patient_number, first_name, last_name, middle_name, phone,
    email, address, gender, birth_date, birth_date_precision,
    approximate_age_years, age_assessed_at, is_minor_declared,
    guardian_name, guardian_phone, guardian_email, emergency_contact,
    administrative_notes, created_by
  ) values (
    target_clinic_id,
    private.next_patient_number(target_clinic_id),
    nullif(btrim(demographic ->> 'firstName'), ''),
    nullif(btrim(demographic ->> 'lastName'), ''),
    nullif(btrim(demographic ->> 'middleName'), ''),
    nullif(btrim(demographic ->> 'phone'), ''),
    nullif(lower(btrim(demographic ->> 'email')), ''),
    nullif(btrim(demographic ->> 'address'), ''),
    nullif(btrim(demographic ->> 'gender'), ''),
    nullif(demographic ->> 'birthDate', '')::date,
    coalesce(nullif(demographic ->> 'birthDatePrecision', '')::public.patient_birth_date_precision, 'unknown'),
    nullif(demographic ->> 'approximateAgeYears', '')::smallint,
    nullif(demographic ->> 'ageAssessedAt', '')::date,
    coalesce(nullif(demographic ->> 'isMinorDeclared', '')::boolean, false),
    nullif(btrim(demographic ->> 'guardianName'), ''),
    nullif(btrim(demographic ->> 'guardianPhone'), ''),
    nullif(lower(btrim(demographic ->> 'guardianEmail')), ''),
    nullif(btrim(demographic ->> 'emergencyContact'), ''),
    nullif(btrim(demographic ->> 'administrativeNotes'), ''),
    actor_user_id
  ) returning id into created_patient_id;
  return created_patient_id;
exception
  when check_violation or invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_patient_input';
end;
$$;

create function public.patient_update_demographics(
  actor_user_id uuid,
  target_patient_id uuid,
  demographic jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patients%rowtype;
begin
  target := private.patient_target(target_patient_id, true);
  perform private.require_patient_role(
    target.clinic_id,
    actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if target.archived_at is not null or jsonb_typeof(demographic) <> 'object' then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;

  update public.patients
  set first_name = nullif(btrim(demographic ->> 'firstName'), ''),
      last_name = nullif(btrim(demographic ->> 'lastName'), ''),
      middle_name = nullif(btrim(demographic ->> 'middleName'), ''),
      phone = nullif(btrim(demographic ->> 'phone'), ''),
      email = nullif(lower(btrim(demographic ->> 'email')), ''),
      address = nullif(btrim(demographic ->> 'address'), ''),
      gender = nullif(btrim(demographic ->> 'gender'), ''),
      birth_date = nullif(demographic ->> 'birthDate', '')::date,
      birth_date_precision = coalesce(nullif(demographic ->> 'birthDatePrecision', '')::public.patient_birth_date_precision, 'unknown'),
      approximate_age_years = nullif(demographic ->> 'approximateAgeYears', '')::smallint,
      age_assessed_at = nullif(demographic ->> 'ageAssessedAt', '')::date,
      is_minor_declared = coalesce(nullif(demographic ->> 'isMinorDeclared', '')::boolean, false),
      guardian_name = nullif(btrim(demographic ->> 'guardianName'), ''),
      guardian_phone = nullif(btrim(demographic ->> 'guardianPhone'), ''),
      guardian_email = nullif(lower(btrim(demographic ->> 'guardianEmail')), ''),
      emergency_contact = nullif(btrim(demographic ->> 'emergencyContact'), ''),
      administrative_notes = nullif(btrim(demographic ->> 'administrativeNotes'), '')
  where id = target.id;
exception
  when check_violation or invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_patient_input';
end;
$$;

create function public.patient_update_contacts(
  actor_user_id uuid,
  target_patient_id uuid,
  contact jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patients%rowtype;
begin
  target := private.patient_target(target_patient_id, true);
  perform private.require_patient_role(
    target.clinic_id,
    actor_user_id,
    array['owner', 'dentist', 'receptionist', 'assistant']::public.clinic_role[]
  );
  if target.archived_at is not null or jsonb_typeof(contact) <> 'object' then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;

  update public.patients
  set phone = nullif(btrim(contact ->> 'phone'), ''),
      email = nullif(lower(btrim(contact ->> 'email')), ''),
      address = nullif(btrim(contact ->> 'address'), ''),
      guardian_name = nullif(btrim(contact ->> 'guardianName'), ''),
      guardian_phone = nullif(btrim(contact ->> 'guardianPhone'), ''),
      guardian_email = nullif(lower(btrim(contact ->> 'guardianEmail')), ''),
      emergency_contact = nullif(btrim(contact ->> 'emergencyContact'), '')
  where id = target.id;
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_patient_input';
end;
$$;

create function public.patient_upsert_medical_profile(
  actor_user_id uuid,
  target_patient_id uuid,
  medical jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patients%rowtype;
begin
  target := private.patient_target(target_patient_id, true);
  perform private.require_patient_role(
    target.clinic_id,
    actor_user_id,
    array['dentist']::public.clinic_role[]
  );
  if target.archived_at is not null or jsonb_typeof(medical) <> 'object' then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;

  insert into public.patient_medical_profiles (
    clinic_id, patient_id, allergies, current_medications, chronic_conditions,
    important_medical_notes, created_by, updated_by
  ) values (
    target.clinic_id, target.id,
    nullif(btrim(medical ->> 'allergies'), ''),
    nullif(btrim(medical ->> 'currentMedications'), ''),
    nullif(btrim(medical ->> 'chronicConditions'), ''),
    nullif(btrim(medical ->> 'importantMedicalNotes'), ''),
    actor_user_id, actor_user_id
  ) on conflict (patient_id) do update
  set allergies = excluded.allergies,
      current_medications = excluded.current_medications,
      chronic_conditions = excluded.chronic_conditions,
      important_medical_notes = excluded.important_medical_notes,
      updated_by = actor_user_id;
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_medical_input';
end;
$$;

create function public.patient_set_archived(
  actor_user_id uuid,
  target_patient_id uuid,
  next_archived boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patients%rowtype;
begin
  target := private.patient_target(target_patient_id, true);
  perform private.require_patient_role(
    target.clinic_id,
    actor_user_id,
    array['owner']::public.clinic_role[]
  );
  update public.patients
  set archived_at = case when next_archived then now() else null end,
      archived_by = case when next_archived then actor_user_id else null end
  where id = target.id;
end;
$$;

revoke all on function private.require_patient_role(uuid, uuid, public.clinic_role[]) from public;
revoke all on function private.patient_target(uuid, boolean) from public;
revoke all on function private.next_patient_number(uuid) from public;
revoke all on function public.patient_create(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.patient_update_demographics(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.patient_update_contacts(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.patient_upsert_medical_profile(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.patient_set_archived(uuid, uuid, boolean) from public, anon, authenticated;
grant execute on function public.patient_create(uuid, uuid, jsonb) to service_role;
grant execute on function public.patient_update_demographics(uuid, uuid, jsonb) to service_role;
grant execute on function public.patient_update_contacts(uuid, uuid, jsonb) to service_role;
grant execute on function public.patient_upsert_medical_profile(uuid, uuid, jsonb) to service_role;
grant execute on function public.patient_set_archived(uuid, uuid, boolean) to service_role;
