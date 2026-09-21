begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.patients'::regclass),
  'patients has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.patient_medical_profiles'::regclass),
  'patient medical profiles has RLS enabled'
);
select ok(
  not has_table_privilege('authenticated', 'public.patients', 'insert'),
  'authenticated clients cannot directly create patients'
);
select ok(
  not has_function_privilege(
    'authenticated', 'public.patient_create(uuid, uuid, jsonb)', 'execute'
  ),
  'authenticated clients cannot execute patient creation commands directly'
);
select ok(
  has_function_privilege(
    'service_role', 'public.patient_create(uuid, uuid, jsonb)', 'execute'
  ),
  'only the server role can execute patient creation commands'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'reception@example.test'),
  ('44444444-4444-4444-8444-444444444444', 'assistant@example.test'),
  ('55555555-5555-4555-8555-555555555555', 'outsider@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'North Demo Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'South Demo Clinic', 'USD', 'America/New_York', '55555555-5555-4555-8555-555555555555');

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'reception@example.test'),
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-8444-444444444444', 'assistant@example.test');
insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'dentist', '11111111-1111-1111-1111-111111111111'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'receptionist', '11111111-1111-1111-1111-111111111111'),
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'assistant', '11111111-1111-1111-1111-111111111111');

insert into public.patients (
  id, clinic_id, patient_number, first_name, last_name, phone,
  birth_date_precision, created_by
) values (
  'ffffffff-ffff-4fff-8fff-ffffffffffff',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PAT-00001', 'Ada', 'Demo', '+79990000000',
  'unknown', '11111111-1111-1111-1111-111111111111'
);
insert into public.patient_medical_profiles (
  id, clinic_id, patient_id, allergies, created_by, updated_by
) values (
  '99999999-9999-4999-8999-999999999999',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ffffffff-ffff-4fff-8fff-ffffffffffff',
  'Penicillin', '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111'
);
insert into public.clinic_patient_counters (clinic_id, next_patient_number) values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 2
);

select throws_ok(
  $$insert into public.patients (
      clinic_id, patient_number, first_name, last_name, phone, birth_date,
      birth_date_precision, created_by
    ) values (
      'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PAT-00002', 'Child', 'Demo', '+79990000001',
      date '2020-01-01', 'exact', '11111111-1111-1111-1111-111111111111'
    )$$,
  'P0001', 'guardian_required_for_minor',
  'a known minor requires guardian details'
);
select throws_ok(
  $$insert into public.patient_medical_profiles (
      clinic_id, patient_id, created_by, updated_by
    ) values (
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'ffffffff-ffff-4fff-8fff-ffffffffffff',
      '55555555-5555-4555-8555-555555555555', '55555555-5555-4555-8555-555555555555'
    )$$,
  'P0001', 'patient_clinic_mismatch',
  'medical data cannot be attached to a patient from another clinic'
);
select lives_ok(
  $$select public.patient_create(
    '33333333-3333-3333-3333-333333333333',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '{"firstName":"New","lastName":"Patient","phone":"+79990000002","birthDatePrecision":"unknown"}'::jsonb
  )$$,
  'receptionist can register a patient through the protected command'
);
select results_eq(
  $$select patient_number from public.patients
    where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    order by patient_number$$,
  array['PAT-00001', 'PAT-00002'],
  'the protected command allocates the next clinic-specific patient number'
);
select lives_ok(
  $$select public.patient_update_contacts(
    '44444444-4444-4444-8444-444444444444',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"phone":"+79990000003","email":"ada@example.test"}'::jsonb
  )$$,
  'assistant can update limited patient contact details through the protected command'
);
select throws_ok(
  $$select public.patient_upsert_medical_profile(
    '33333333-3333-3333-3333-333333333333',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"allergies":"None"}'::jsonb
  )$$,
  'P0001', 'patient_edit_forbidden',
  'receptionist cannot alter medical information through the server command'
);
select lives_ok(
  $$select public.patient_set_archived(
    '11111111-1111-1111-1111-111111111111',
    'ffffffff-ffff-4fff-8fff-ffffffffffff', true
  )$$,
  'owner can archive a patient through the protected command'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
select results_eq(
  $$select patient_number from public.patients
    where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    order by patient_number$$,
  array['PAT-00001', 'PAT-00002'],
  'receptionist reads clinic patient demographics'
);
select is_empty(
  $$select * from public.patient_medical_profiles$$,
  'receptionist cannot read medical profiles'
);
select throws_ok(
  $$insert into public.patients (clinic_id, patient_number, first_name, last_name, phone, created_by)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PAT-00003', 'New', 'Patient', '+79990000002', '33333333-3333-3333-3333-333333333333')$$,
  '42501', null,
  'receptionist cannot directly create a patient'
);

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select results_eq(
  $$select allergies from public.patient_medical_profiles$$,
  array['Penicillin'],
  'dentist reads medical profiles'
);

set local request.jwt.claim.sub = '44444444-4444-4444-8444-444444444444';
select results_eq(
  $$select allergies from public.patient_medical_profiles$$,
  array['Penicillin'],
  'assistant reads medical profiles'
);

set local request.jwt.claim.sub = '55555555-5555-4555-8555-555555555555';
select is_empty(
  $$select * from public.patients$$,
  'members cannot read patients from another clinic'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from public.patients$$,
  '42501', null,
  'anonymous callers cannot read patients'
);

select * from finish();
rollback;
