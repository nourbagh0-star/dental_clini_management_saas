begin;
create extension if not exists pgtap with schema extensions;
select plan(27);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.appointments'::regclass),
  'appointments has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.appointment_conflict_flags'::regclass),
  'appointment conflict flags have RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass),
  'audit events have RLS enabled'
);
select ok(
  not has_table_privilege('authenticated', 'public.appointments', 'insert,update,delete'),
  'browser clients cannot directly mutate appointments'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.appointment_create(uuid, uuid, uuid, uuid, timestamptz, timestamptz, text, text)',
    'execute'
  ),
  'browser clients cannot execute appointment creation commands'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.appointment_create(uuid, uuid, uuid, uuid, timestamptz, timestamptz, text, text)',
    'execute'
  ),
  'only the server role can execute appointment creation commands'
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
  id, clinic_id, patient_number, first_name, last_name, phone, birth_date_precision, created_by
) values
  ('ffffffff-ffff-4fff-8fff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PAT-00001', 'Ada', 'Demo', '+79990000000', 'unknown', '11111111-1111-1111-1111-111111111111'),
  ('99999999-9999-4999-8999-999999999999', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PAT-00002', 'Grace', 'Demo', '+79990000001', 'unknown', '11111111-1111-1111-1111-111111111111'),
  ('88888888-8888-4888-8888-888888888888', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'PAT-00003', 'Archived', 'Demo', '+79990000002', 'unknown', '11111111-1111-1111-1111-111111111111');
update public.patients set archived_at = now(), archived_by = '11111111-1111-1111-1111-111111111111'
where id = '88888888-8888-4888-8888-888888888888';
insert into public.doctor_schedule_versions (
  id, clinic_id, dentist_member_id, effective_from, created_by
) values (
  '77777777-7777-4777-8777-777777777777',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'cccccccc-cccc-cccc-cccc-cccccccccccc', date '2020-01-01',
  '11111111-1111-1111-1111-111111111111'
);
insert into public.doctor_working_hours (id, schedule_version_id, weekday, starts_at, ends_at) values (
  '66666666-6666-4666-8666-666666666666',
  '77777777-7777-4777-8777-777777777777', 1, time '09:00', time '17:00'
);

select lives_ok(
  $$select public.appointment_create(
    '33333333-3333-3333-3333-333333333333',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    timestamptz '2030-01-07 07:00+00', timestamptz '2030-01-07 07:30+00',
    'Consultation', null
  )$$,
  'receptionist creates an available appointment through the protected command'
);
select results_eq(
  $$select status::text || ':' || purpose from public.appointments
    where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      and patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
    order by starts_at limit 1$$,
  array['scheduled:Consultation'],
  'the protected command stores the safe booking fields'
);
select throws_ok(
  $$select public.appointment_create(
    '33333333-3333-3333-3333-333333333333',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'ffffffff-ffff-4fff-8fff-ffffffffffff',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    timestamptz '2030-01-07 07:15+00', timestamptz '2030-01-07 07:45+00', null, null
  )$$,
  'P0001', 'patient_overlap',
  'patient overlap remains a hard block'
);
select throws_ok(
  $$select public.appointment_create(
    '22222222-2222-2222-2222-222222222222',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '99999999-9999-4999-8999-999999999999',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    timestamptz '2030-01-07 07:15+00', timestamptz '2030-01-07 07:45+00', null, null
  )$$,
  'P0001', 'dentist_overlap',
  'dentist cannot override a dentist overlap'
);
select lives_ok(
  $$select public.appointment_create(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '99999999-9999-4999-8999-999999999999',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    timestamptz '2030-01-07 07:15+00', timestamptz '2030-01-07 07:45+00',
    null, 'Emergency walk-in'
  )$$,
  'owner can record a dentist-overlap override with a reason'
);
select results_eq(
  $$select event_type || ':' || reason from public.audit_events
    where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      and event_type = 'appointment_conflict_overridden'$$,
  array['appointment_conflict_overridden:Emergency walk-in'],
  'an owner override writes a safe audit event'
);
select throws_ok(
  $$select public.appointment_create(
    '33333333-3333-3333-3333-333333333333',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '88888888-8888-4888-8888-888888888888',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    timestamptz '2030-01-07 08:00+00', timestamptz '2030-01-07 08:30+00', null, null
  )$$,
  'P0001', 'patient_unavailable',
  'archived patients cannot receive a new appointment'
);
select lives_ok(
  $$select public.appointment_upsert_preparation_note(
    '44444444-4444-4444-8444-444444444444',
    (select id from public.appointments
      where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        and patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
      order by starts_at limit 1), 'Prepare room'
  )$$,
  'assistant can add an operational preparation note'
);
select throws_ok(
  $$select public.appointment_upsert_preparation_note(
    '33333333-3333-3333-3333-333333333333',
    (select id from public.appointments
      where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        and patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
      order by starts_at limit 1), 'Prepare room'
  )$$,
  'P0001', 'appointment_action_forbidden',
  'receptionist cannot write assistant preparation notes'
);
select lives_ok(
  $$select public.appointment_transition(
    '33333333-3333-3333-3333-333333333333',
    (select id from public.appointments
      where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        and patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
      order by starts_at limit 1), 'confirmed', null
  )$$,
  'receptionist can confirm an appointment'
);
select throws_ok(
  $$select public.appointment_transition(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.appointments
      where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
        and patient_id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'
      order by starts_at limit 1), 'completed', null
  )$$,
  'P0001', 'invalid_appointment_transition',
  'a future appointment cannot be completed early'
);
insert into public.appointments (
  id, clinic_id, patient_id, dentist_member_id, starts_at, ends_at, status, created_by
) values (
  '12121212-1212-4121-8121-121212121212',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-4999-8999-999999999999',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  timestamptz '2026-09-07 07:00+00', timestamptz '2026-09-07 07:30+00', 'in_progress',
  '11111111-1111-1111-1111-111111111111'
);
select lives_ok(
  $$select public.appointment_transition(
    '22222222-2222-2222-2222-222222222222',
    '12121212-1212-4121-8121-121212121212', 'completed', null
  )$$,
  'dentist completes an in-progress appointment that has started'
);
select results_eq(
  $$select ((public.doctor_schedule_preview_exception_impact(
    '11111111-1111-1111-1111-111111111111',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    timestamptz '2030-01-07 07:00+00', timestamptz '2030-01-07 08:00+00'
  ) ->> 'count')::integer)$$,
  array[2],
  'owner preview reports future appointments affected by a schedule exception'
);
select lives_ok(
  $$select public.doctor_schedule_create_exception_with_impact(
    '11111111-1111-1111-1111-111111111111',
    'cccccccc-cccc-cccc-cccc-cccccccccccc', 'leave',
    timestamptz '2030-01-07 07:00+00', timestamptz '2030-01-07 08:00+00',
    'Leave', true, 'Owner reviewed affected bookings'
  )$$,
  'owner confirmation preserves bookings and records conflict flags'
);
select results_eq(
  $$select count(*)::integer from public.appointment_conflict_flags flag
    join public.appointments appointment on appointment.id = flag.appointment_id
    where appointment.clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      and flag.resolved_at is null$$,
  array[2],
  'each affected future appointment receives a manual-resolution flag'
);
select results_eq(
  $$select ((public.doctor_schedule_preview_weekly_impact(
    '11111111-1111-1111-1111-111111111111',
    'cccccccc-cccc-cccc-cccc-cccccccccccc', date '2030-01-01', '[]'::jsonb
  ) ->> 'count')::integer)$$,
  array[2],
  'owner preview reports future appointments affected by weekly-hour changes'
);
select lives_ok(
  $$select public.doctor_schedule_replace_weekly_with_impact(
    '11111111-1111-1111-1111-111111111111',
    'cccccccc-cccc-cccc-cccc-cccccccccccc', date '2030-01-01', '[]'::jsonb,
    true, 'Owner reviewed changed weekly availability'
  )$$,
  'owner confirmation saves weekly hours while preserving affected bookings'
);
select results_eq(
  $$select count(*)::integer from public.appointment_conflict_flags flag
    join public.appointments appointment on appointment.id = flag.appointment_id
    where appointment.clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      and flag.resolved_at is null$$,
  array[4],
  'weekly-hour impacts add their own manual-resolution flags'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
select ok(
  (select count(*) from public.appointments) = 3,
  'a clinic receptionist reads only their clinic appointments'
);
set local request.jwt.claim.sub = '55555555-5555-4555-8555-555555555555';
select is_empty(
  $$select * from public.appointments$$,
  'an outsider cannot read another clinic appointments'
);
reset role;
set local role anon;
select throws_ok(
  $$select * from public.appointments$$,
  '42501', null,
  'anonymous callers cannot read appointments'
);

select * from finish();
rollback;
