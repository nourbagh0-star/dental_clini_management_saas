begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.doctor_schedule_versions'::regclass),
  'doctor schedule versions has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.doctor_working_hours'::regclass),
  'doctor working hours has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.doctor_schedule_breaks'::regclass),
  'doctor schedule breaks has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.doctor_schedule_exceptions'::regclass),
  'doctor schedule exceptions has RLS enabled'
);
select ok(
  not has_table_privilege('authenticated', 'public.doctor_schedule_versions', 'insert'),
  'authenticated clients cannot directly create schedule versions'
);
select ok(
  not has_table_privilege('authenticated', 'public.doctor_schedule_exceptions', 'update'),
  'authenticated clients cannot directly update schedule exceptions'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.doctor_schedule_replace_weekly(uuid, uuid, date, jsonb)',
    'execute'
  ),
  'authenticated clients cannot execute the schedule replacement command directly'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.doctor_schedule_delete_exception(uuid, uuid)',
    'execute'
  ),
  'anonymous callers cannot execute schedule exception commands'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.doctor_schedule_replace_weekly(uuid, uuid, date, jsonb)',
    'execute'
  ),
  'only the server role can execute schedule replacement commands'
);
select ok(
  has_function_privilege(
    'authenticated',
    'public.doctor_schedule_readable_dentists(uuid)',
    'execute'
  ),
  'authenticated clinic staff can use the narrow schedule dentist directory'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.doctor_schedule_readable_dentists(uuid)',
    'execute'
  ),
  'anonymous callers cannot use the schedule dentist directory'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'assistant@example.test'),
  ('44444444-4444-4444-8444-444444444444', 'outsider@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'North Demo Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'South Demo Clinic', 'USD', 'America/New_York', '44444444-4444-4444-8444-444444444444');

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', 'dentist@example.test'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'assistant@example.test');
insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'dentist', '11111111-1111-1111-1111-111111111111'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'assistant', '11111111-1111-1111-1111-111111111111');

insert into public.doctor_schedule_versions (
  id, clinic_id, dentist_member_id, effective_from, created_by
) values (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  (now() at time zone 'Europe/Moscow')::date + 1,
  '11111111-1111-1111-1111-111111111111'
);
insert into public.doctor_working_hours (
  id, schedule_version_id, weekday, starts_at, ends_at
) values (
  'ffffffff-ffff-4fff-8fff-ffffffffffff',
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 1, time '09:00', time '17:00'
);
insert into public.doctor_schedule_breaks (id, working_hours_id, starts_at, ends_at) values (
  '99999999-9999-4999-8999-999999999999',
  'ffffffff-ffff-4fff-8fff-ffffffffffff', time '12:00', time '13:00'
);
insert into public.doctor_schedule_exceptions (
  id, clinic_id, dentist_member_id, kind, starts_at, ends_at, reason, created_by
) values (
  '88888888-8888-4888-8888-888888888888',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  'leave', timestamptz '2026-10-01 06:00:00+00', timestamptz '2026-10-03 15:00:00+00',
  'Annual leave', '11111111-1111-1111-1111-111111111111'
);

select throws_ok(
  $$insert into public.doctor_schedule_versions (clinic_id, dentist_member_id, effective_from, created_by)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'dddddddd-dddd-dddd-dddd-dddddddddddd', (now() at time zone 'Europe/Moscow')::date + 1, '11111111-1111-1111-1111-111111111111')$$,
  'P0001', 'active_dentist_required',
  'only an active dentist membership can receive a schedule'
);
select throws_ok(
  $$insert into public.doctor_working_hours (schedule_version_id, weekday, starts_at, ends_at)
    values ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 1, time '16:00', time '18:00')$$,
  '23P01', null,
  'working periods cannot overlap within a weekly schedule version'
);
select throws_ok(
  $$insert into public.doctor_schedule_breaks (working_hours_id, starts_at, ends_at)
    values ('ffffffff-ffff-4fff-8fff-ffffffffffff', time '08:30', time '09:30')$$,
  'P0001', 'break_outside_working_hours',
  'a break must be contained in its working period'
);
select lives_ok(
  $$select public.doctor_schedule_replace_weekly(
    '11111111-1111-1111-1111-111111111111',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    (now() at time zone 'Europe/Moscow')::date + 1,
    '[{"weekday":1,"startsAt":"09:00","endsAt":"17:00","breaks":[{"startsAt":"12:00","endsAt":"13:00"}]}]'::jsonb
  )$$,
  'owner can atomically replace a dentist weekly schedule through the server command'
);
select throws_ok(
  $$select public.doctor_schedule_replace_weekly(
    '33333333-3333-3333-3333-333333333333',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    (now() at time zone 'Europe/Moscow')::date + 1,
    '[]'::jsonb
  )$$,
  'P0001', 'schedule_edit_forbidden',
  'a non-owner cannot change another dentist schedule through a server command'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
select results_eq(
  $$select id from public.doctor_schedule_versions order by id$$,
  array['eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid],
  'owner reads every schedule in their active clinic'
);

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select results_eq(
  $$select id from public.doctor_schedule_exceptions order by id$$,
  array['88888888-8888-4888-8888-888888888888'::uuid],
  'dentist reads their clinic schedule exceptions'
);

set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';
select is(
  (select count(*) from public.doctor_schedule_breaks),
  1::bigint,
  'assistant reads the clinic schedule needed for operational work'
);
select results_eq(
  $$select email from public.doctor_schedule_readable_dentists('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid)$$,
  array['dentist@example.test'],
  'assistant reads the dentist directory needed to select a clinic schedule'
);
select throws_ok(
  $$insert into public.doctor_schedule_exceptions (clinic_id, dentist_member_id, kind, starts_at, ends_at, created_by)
    values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'leave', now(), now() + interval '1 hour', '33333333-3333-3333-3333-333333333333')$$,
  '42501', null,
  'staff cannot directly create schedule exceptions'
);

set local request.jwt.claim.sub = '44444444-4444-4444-8444-444444444444';
select is_empty(
  $$select * from public.doctor_schedule_versions$$,
  'members cannot read schedules from another clinic'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from public.doctor_schedule_versions$$,
  '42501', null,
  'anonymous callers cannot read schedules'
);

select * from finish();
rollback;
