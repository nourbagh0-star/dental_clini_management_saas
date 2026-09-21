begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.clinical_sessions'::regclass),
  'clinical sessions have RLS'
);
select ok(
  not has_table_privilege('authenticated', 'public.clinical_sessions', 'insert'),
  'browser cannot insert clinical sessions'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'other-dentist@example.test'),
  ('44444444-4444-4444-8444-444444444444', 'assistant@example.test'),
  ('55555555-5555-4555-8555-555555555555', 'reception@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'Clinical Demo', 'RUB', 'Europe/Moscow',
  '11111111-1111-1111-1111-111111111111'
);

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'other-dentist@example.test'),
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '44444444-4444-4444-8444-444444444444', 'assistant@example.test'),
  ('ffffffff-ffff-4fff-8fff-ffffffffffff', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '55555555-5555-4555-8555-555555555555', 'reception@example.test');

insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'dentist', '11111111-1111-1111-1111-111111111111'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'dentist', '11111111-1111-1111-1111-111111111111'),
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'assistant', '11111111-1111-1111-1111-111111111111'),
  ('ffffffff-ffff-4fff-8fff-ffffffffffff', 'receptionist', '11111111-1111-1111-1111-111111111111');

insert into public.patients (
  id, clinic_id, patient_number, first_name, last_name, phone,
  birth_date_precision, created_by
) values (
  '12121212-1212-4212-8212-121212121212',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'PAT-00001', 'Ada', 'Demo', '+79990000000', 'unknown',
  '11111111-1111-1111-1111-111111111111'
);

insert into public.appointments (
  id, clinic_id, patient_id, dentist_member_id, starts_at, ends_at,
  status, purpose, created_by
) values (
  '13131313-1313-4313-8313-131313131313',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  '12121212-1212-4212-8212-121212121212',
  'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
  now() - interval '1 hour', now(), 'in_progress', 'Check-up',
  '11111111-1111-1111-1111-111111111111'
);

select lives_ok(
  $$select public.clinical_session_create(
    '44444444-4444-4444-8444-444444444444',
    '12121212-1212-4212-8212-121212121212',
    '13131313-1313-4313-8313-131313131313',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc', now()
  )$$,
  'assistant creates an appointment-linked draft'
);
select throws_ok(
  $$select public.clinical_session_create(
    '44444444-4444-4444-8444-444444444444',
    '12121212-1212-4212-8212-121212121212',
    '13131313-1313-4313-8313-131313131313',
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc', now()
  )$$,
  'P0001', 'appointment_already_has_session',
  'an appointment has only one clinical session'
);
select lives_ok(
  $$select public.clinical_session_update_draft(
    '44444444-4444-4444-8444-444444444444',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'),
    'Clinical findings', 'Return in six months', 1
  )$$,
  'assistant edits a draft'
);
select throws_ok(
  $$select public.clinical_session_update_draft(
    '11111111-1111-1111-1111-111111111111',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'),
    'Owner edit', null, 2
  )$$,
  'P0001', 'clinical_session_forbidden',
  'owner without Dentist role cannot edit clinical notes'
);
select throws_ok(
  $$select public.clinical_session_finalize(
    '33333333-3333-3333-3333-333333333333',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'), 2
  )$$,
  'P0001', 'clinical_session_forbidden',
  'a different Dentist cannot finalize the assigned session'
);
select lives_ok(
  $$select public.clinical_session_finalize(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'), 2
  )$$,
  'assigned Dentist finalizes the session'
);
select is(
  (select status::text from public.clinical_sessions
    where appointment_id = '13131313-1313-4313-8313-131313131313'),
  'finalized', 'session is finalized'
);
select throws_ok(
  $$select public.clinical_session_update_draft(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'),
    'Changed history', null, 3
  )$$,
  'P0001', 'clinical_session_draft_only',
  'finalized session cannot be edited'
);
select throws_ok(
  $$select public.clinical_session_add_amendment(
    '44444444-4444-4444-8444-444444444444',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'),
    'Correction', 'Typographical correction'
  )$$,
  'P0001', 'clinical_session_forbidden',
  'assistant cannot amend finalized history'
);
select lives_ok(
  $$select public.clinical_session_add_amendment(
    '33333333-3333-3333-3333-333333333333',
    (select id from public.clinical_sessions
      where appointment_id = '13131313-1313-4313-8313-131313131313'),
    'Correction', 'Typographical correction'
  )$$,
  'any active Dentist may add an amendment'
);
select throws_ok(
  $$update public.clinical_session_amendments set amendment_text = 'Overwritten'$$,
  'P0001', 'clinical_session_amendment_immutable',
  'amendments are immutable'
);

select lives_ok(
  $$select public.clinical_session_create(
    '44444444-4444-4444-8444-444444444444',
    '12121212-1212-4212-8212-121212121212', null,
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc', now() - interval '2 hours'
  )$$,
  'assistant creates a walk-in draft'
);
select lives_ok(
  $$select public.clinical_session_mark_in_error(
    '44444444-4444-4444-8444-444444444444',
    (select id from public.clinical_sessions
      where patient_id = '12121212-1212-4212-8212-121212121212'
        and appointment_id is null order by created_at limit 1),
    1, 'Created for the wrong visit'
  )$$,
  'assistant marks an incorrect draft in error'
);
select is(
  (select status::text from public.clinical_sessions
    where patient_id = '12121212-1212-4212-8212-121212121212'
      and appointment_id is null order by created_at limit 1),
  'entered_in_error', 'incorrect draft is preserved with terminal status'
);
select throws_ok(
  $$select public.clinical_session_create(
    '44444444-4444-4444-8444-444444444444',
    '12121212-1212-4212-8212-121212121212', null,
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc', now() + interval '1 day'
  )$$,
  'P0001', 'invalid_clinical_session_input',
  'walk-in session cannot be future-dated'
);
select lives_ok(
  $$select public.clinical_session_create(
    '22222222-2222-2222-2222-222222222222',
    '12121212-1212-4212-8212-121212121212', null,
    'cccccccc-cccc-4ccc-8ccc-cccccccccccc', now() - interval '30 minutes'
  )$$,
  'Dentist creates another walk-in draft for revision test'
);
select lives_ok(
  $$select public.clinical_session_update_draft(
    '22222222-2222-2222-2222-222222222222',
    (select id from public.clinical_sessions
      where patient_id = '12121212-1212-4212-8212-121212121212'
        and appointment_id is null and status = 'draft'),
    'Latest draft', null, 1
  )$$,
  'current revision saves successfully'
);
select throws_ok(
  $$select public.clinical_session_update_draft(
    '44444444-4444-4444-8444-444444444444',
    (select id from public.clinical_sessions
      where patient_id = '12121212-1212-4212-8212-121212121212'
        and appointment_id is null and status = 'draft'),
    'Stale overwrite', null, 1
  )$$,
  'P0001', 'clinical_session_revision_conflict',
  'stale draft cannot overwrite a newer save'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '55555555-5555-4555-8555-555555555555';
select is((select count(*)::integer from public.clinical_sessions), 0,
  'receptionist cannot read clinical sessions');
select is((select count(*)::integer from public.clinical_session_amendments), 0,
  'receptionist cannot read amendments');
reset role;

set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
select is((select count(*)::integer from public.clinical_sessions), 3,
  'owner can read clinical history');
select is((select count(*)::integer from public.clinical_session_amendments), 1,
  'owner can read session amendments');
reset role;

select is(
  (select count(*)::integer from public.audit_events
    where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
      and event_type like 'clinical_session_%'),
  3, 'terminal clinical actions create safe audit events'
);

select * from finish();
rollback;
