-- Official Phase 4: patient demographics are separated from medical data so
-- receptionist access can remain strictly administrative.
create type public.patient_birth_date_precision as enum (
  'exact',
  'approximate',
  'unknown'
);

create table public.clinic_patient_counters (
  clinic_id uuid primary key references public.clinics(id) on delete restrict,
  next_patient_number integer not null default 1,
  constraint clinic_patient_counters_next_positive check (next_patient_number > 0)
);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_number text not null,
  first_name text not null,
  last_name text not null,
  middle_name text,
  phone text,
  email text,
  address text,
  gender text,
  birth_date date,
  birth_date_precision public.patient_birth_date_precision not null default 'unknown',
  approximate_age_years smallint,
  age_assessed_at date,
  is_minor_declared boolean not null default false,
  guardian_name text,
  guardian_phone text,
  guardian_email text,
  emergency_contact text,
  administrative_notes text,
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint patients_number_format check (patient_number ~ '^PAT-[0-9]{5,}$'),
  constraint patients_first_name check (
    first_name = btrim(first_name) and char_length(first_name) between 1 and 120
  ),
  constraint patients_last_name check (
    last_name = btrim(last_name) and char_length(last_name) between 1 and 120
  ),
  constraint patients_middle_name check (
    middle_name is null or (middle_name = btrim(middle_name) and char_length(middle_name) between 1 and 120)
  ),
  constraint patients_phone check (
    phone is null or (phone = btrim(phone) and phone ~ '^[0-9+(). -]{3,32}$')
  ),
  constraint patients_email check (
    email is null or (
      email = lower(btrim(email))
      and char_length(email) between 3 and 320
      and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    )
  ),
  constraint patients_guardian_name check (
    guardian_name is null or (guardian_name = btrim(guardian_name) and char_length(guardian_name) between 1 and 240)
  ),
  constraint patients_guardian_phone check (
    guardian_phone is null or (guardian_phone = btrim(guardian_phone) and guardian_phone ~ '^[0-9+(). -]{3,32}$')
  ),
  constraint patients_guardian_email check (
    guardian_email is null or (
      guardian_email = lower(btrim(guardian_email))
      and char_length(guardian_email) between 3 and 320
      and guardian_email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    )
  ),
  constraint patients_approximate_age check (
    approximate_age_years is null or approximate_age_years between 0 and 130
  ),
  constraint patients_birth_precision_consistency check (
    (birth_date_precision = 'exact' and birth_date is not null and approximate_age_years is null and age_assessed_at is null)
    or (birth_date_precision = 'approximate' and birth_date is null and approximate_age_years is not null and age_assessed_at is not null)
    or (birth_date_precision = 'unknown' and birth_date is null and approximate_age_years is null and age_assessed_at is null)
  ),
  constraint patients_contact_method check (
    phone is not null or email is not null or guardian_phone is not null or guardian_email is not null
  ),
  constraint patients_guardian_for_minor check (
    not is_minor_declared
    or (guardian_name is not null and (guardian_phone is not null or guardian_email is not null))
  ),
  constraint patients_archive_consistency check (
    (archived_at is null and archived_by is null)
    or (archived_at is not null and archived_by is not null)
  ),
  constraint patients_clinic_number_unique unique (clinic_id, patient_number)
);

create table public.patient_medical_profiles (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null unique references public.patients(id) on delete restrict,
  allergies text,
  current_medications text,
  chronic_conditions text,
  important_medical_notes text,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint patient_medical_profiles_allergies_length check (
    allergies is null or char_length(allergies) <= 5000
  ),
  constraint patient_medical_profiles_medications_length check (
    current_medications is null or char_length(current_medications) <= 5000
  ),
  constraint patient_medical_profiles_conditions_length check (
    chronic_conditions is null or char_length(chronic_conditions) <= 5000
  ),
  constraint patient_medical_profiles_notes_length check (
    important_medical_notes is null or char_length(important_medical_notes) <= 10000
  )
);

create index patients_active_clinic_name_idx
  on public.patients (clinic_id, last_name, first_name, id)
  where archived_at is null;
create index patients_active_clinic_phone_idx
  on public.patients (clinic_id, phone)
  where archived_at is null and phone is not null;
create index patients_active_clinic_email_idx
  on public.patients (clinic_id, email)
  where archived_at is null and email is not null;
create index patient_medical_profiles_clinic_patient_idx
  on public.patient_medical_profiles (clinic_id, patient_id);

create function private.assert_medical_profile_patient_clinic()
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

create function private.assert_patient_guardian_requirement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  clinic_today date;
  guardian_required boolean;
begin
  select (now() at time zone clinic.time_zone)::date
    into clinic_today
  from public.clinics clinic
  where clinic.id = new.clinic_id;

  guardian_required := new.is_minor_declared
    or (new.birth_date_precision = 'exact'::public.patient_birth_date_precision
        and new.birth_date > clinic_today - interval '18 years')
    or (new.birth_date_precision = 'approximate' and new.approximate_age_years < 18);

  if guardian_required
    and (new.guardian_name is null
      or (new.guardian_phone is null and new.guardian_email is null)) then
    raise exception using errcode = 'P0001', message = 'guardian_required_for_minor';
  end if;
  return new;
end;
$$;

revoke all on function private.assert_medical_profile_patient_clinic() from public;
revoke all on function private.assert_patient_guardian_requirement() from public;

create trigger patient_medical_profiles_match_patient_clinic
before insert or update of clinic_id, patient_id
on public.patient_medical_profiles
for each row execute function private.assert_medical_profile_patient_clinic();

create trigger patients_set_updated_at
before update on public.patients
for each row execute function private.set_updated_at();

create trigger patients_require_guardian_for_minors
before insert or update of clinic_id, birth_date, birth_date_precision,
  approximate_age_years, is_minor_declared, guardian_name, guardian_phone,
  guardian_email on public.patients
for each row execute function private.assert_patient_guardian_requirement();

create trigger patient_medical_profiles_set_updated_at
before update on public.patient_medical_profiles
for each row execute function private.set_updated_at();

alter table public.clinic_patient_counters enable row level security;
alter table public.patients enable row level security;
alter table public.patient_medical_profiles enable row level security;

revoke all on table public.clinic_patient_counters from anon, authenticated;
revoke all on table public.patients from anon, authenticated;
revoke all on table public.patient_medical_profiles from anon, authenticated;
grant select on table public.patients to authenticated;
grant select on table public.patient_medical_profiles to authenticated;

create policy "active members read clinic patients"
on public.patients for select
to authenticated
using (private.is_active_clinic_member(clinic_id, (select auth.uid())));

create policy "clinical staff read medical profiles"
on public.patient_medical_profiles for select
to authenticated
using (
  private.has_clinic_role(clinic_id, 'owner'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
);
