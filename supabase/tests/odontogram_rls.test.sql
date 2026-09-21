begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.tooth_conditions'::regclass),
  'tooth conditions has RLS enabled'
);
select ok(
  not has_table_privilege('authenticated', 'public.tooth_conditions', 'insert'),
  'authenticated clients cannot directly create tooth conditions'
);
select ok(
  not has_table_privilege('authenticated', 'public.tooth_conditions', 'update'),
  'authenticated clients cannot directly edit tooth conditions'
);
select ok(
  not has_table_privilege('authenticated', 'public.tooth_conditions', 'delete'),
  'authenticated clients cannot delete clinical history'
);
select ok(
  not has_function_privilege(
    'authenticated', 'public.tooth_condition_create(uuid, uuid, jsonb)', 'execute'
  ),
  'authenticated clients cannot directly execute tooth-condition commands'
);
select ok(
  has_function_privilege(
    'service_role', 'public.tooth_condition_create(uuid, uuid, jsonb)', 'execute'
  ),
  'only the server role can execute tooth-condition commands'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'reception@example.test'),
  ('44444444-4444-8444-8444-444444444444', 'assistant@example.test'),
  ('55555555-5555-4555-8555-555555555555', 'outsider@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'North Demo Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'South Demo Clinic', 'USD', 'America/New_York', '55555555-5555-4555-8555-555555555555');

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'reception@example.test'),
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-8444-8444-444444444444', 'assistant@example.test');
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

select lives_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":16,"surface":"occlusal","conditionType":"caries","notes":"Small lesion"}'::jsonb
  )$$,
  'dentist can add a surface-level clinical condition'
);
select results_eq(
  $$select condition_type::text || ':' || surface::text from public.tooth_conditions
    where patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'$$,
  array['caries:occlusal'],
  'condition is stored as one independent clinical record'
);
select throws_ok(
  $$select public.tooth_condition_create(
    '11111111-1111-1111-1111-111111111111',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":17,"surface":"whole","conditionType":"crown"}'::jsonb
  )$$,
  'P0001', 'tooth_condition_edit_forbidden',
  'owner cannot make clinical changes'
);
select throws_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":19,"surface":"whole","conditionType":"crown"}'::jsonb
  )$$,
  'P0001', 'invalid_tooth_condition_input',
  'invalid FDI tooth number is rejected'
);
select throws_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":16,"surface":"mesial","conditionType":"root_canal"}'::jsonb
  )$$,
  'P0001', 'invalid_tooth_condition_input',
  'whole-tooth condition types reject a surface-specific entry'
);
select throws_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":16,"surface":"whole","conditionType":"missing"}'::jsonb
  )$$,
  'P0001', 'missing_tooth_conflict',
  'a missing tooth cannot coexist with active natural-tooth conditions'
);
select lives_ok(
  $$select public.tooth_condition_resolve(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.tooth_conditions
      where patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
        and condition_type = 'caries')
  )$$,
  'dentist can resolve an active condition'
);
select lives_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":16,"surface":"whole","conditionType":"missing"}'::jsonb
  )$$,
  'a missing condition is allowed after conflicting condition is resolved'
);
select lives_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":16,"surface":"whole","conditionType":"implant"}'::jsonb
  )$$,
  'implant may coexist with an active missing condition'
);
select throws_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":16,"surface":"whole","conditionType":"filling"}'::jsonb
  )$$,
  'P0001', 'missing_tooth_conflict',
  'natural-tooth condition is blocked while tooth is active missing'
);
select lives_ok(
  $$select public.tooth_condition_create(
    '22222222-2222-2222-2222-222222222222',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    '{"toothNumber":54,"surface":"whole","conditionType":"crown"}'::jsonb
  )$$,
  'primary FDI dentition is supported'
);
select lives_ok(
  $$select public.tooth_condition_mark_in_error(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.tooth_conditions
      where patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
        and tooth_number = 54),
    'Entered on the wrong patient visit'
  )$$,
  'dentist can preserve an erroneous entry as history'
);
select results_eq(
  $$select status::text || ':' || error_reason from public.tooth_conditions
    where patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
      and tooth_number = 54$$,
  array['entered_in_error:Entered on the wrong patient visit'],
  'error transition records its required reason'
);
select throws_ok(
  $$update public.tooth_conditions set notes = 'Changed'
    where patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
      and tooth_number = 16 and condition_type = 'implant'$$,
  'P0001', 'tooth_condition_history_immutable',
  'clinical condition content is immutable after creation'
);
select throws_ok(
  $$select public.tooth_condition_resolve(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.tooth_conditions
      where patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
        and tooth_number = 54)
  )$$,
  'P0001', 'tooth_condition_not_active',
  'closed history cannot be resolved again'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
select is_empty(
  $$select * from public.tooth_conditions$$,
  'receptionist cannot read clinical Dental Chart data'
);
select throws_ok(
  $$insert into public.tooth_conditions (
    clinic_id, patient_id, tooth_number, surface, condition_type, created_by
  ) values (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ffffffff-ffff-4fff-8fff-ffffffffffff',
    17, 'whole', 'crown', '33333333-3333-3333-3333-333333333333'
  )$$,
  '42501', null,
  'receptionist cannot directly create a clinical condition'
);

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select is(
  (select count(*)::integer from public.tooth_conditions),
  4,
  'dentist can read the active chart and preserved history'
);

set local request.jwt.claim.sub = '44444444-4444-8444-8444-444444444444';
select is(
  (select count(*)::integer from public.tooth_conditions),
  4,
  'assistant can read the active chart and preserved history'
);

set local request.jwt.claim.sub = '55555555-5555-4555-8555-555555555555';
select is_empty(
  $$select * from public.tooth_conditions$$,
  'users from another clinic cannot read clinical data'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from public.tooth_conditions$$,
  '42501', null,
  'anonymous callers cannot read clinical data'
);

select * from finish();
rollback;
