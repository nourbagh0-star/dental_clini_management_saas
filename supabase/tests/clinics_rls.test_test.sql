begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.clinics'::regclass),
  'clinics has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.clinic_members'::regclass),
  'clinic_members has RLS enabled'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner-one@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'owner-two@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'North Demo Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'South Demo Clinic', 'USD', 'America/New_York', '22222222-2222-2222-2222-222222222222');

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
grant insert on table public.clinics to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select results_eq(
  $$select id from public.clinics order by id$$,
  array['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid],
  'owner one reads only their clinic'
);
select results_eq(
  $$select clinic_id from public.clinic_members order by clinic_id$$,
  array['aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid],
  'owner one reads only their membership'
);
select lives_ok(
  $$insert into public.clinics (name, currency_code, time_zone, created_by)
    values ('Second Clinic', 'EUR', 'Europe/Paris', '11111111-1111-1111-1111-111111111111')$$,
  'owner one can create a clinic for themselves'
);
select is(
  (select count(*) from public.clinic_members where user_id = '11111111-1111-1111-1111-111111111111'::uuid),
  2::bigint,
  'creation atomically creates an owner membership'
);
select lives_ok(
  $$insert into public.clinics (name, currency_code, time_zone, created_by)
    values ('Returning Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111')
    returning id$$,
  'a creator can read their newly-created clinic in the create response'
);
select lives_ok(
  $$insert into public.clinics (name, currency_code, time_zone)
    values ('Default Creator Clinic', 'RUB', 'Europe/Moscow')
    returning id$$,
  'the authenticated user is derived as creator and can read the response'
);
select throws_ok(
  $$insert into public.clinics (name, currency_code, time_zone, created_by)
    values ('Hijacked Clinic', 'RUB', 'Europe/Moscow', '22222222-2222-2222-2222-222222222222')$$,
  '42501', null,
  'owner one cannot create a clinic for another user'
);
select throws_ok(
  $$insert into public.clinic_members (clinic_id, user_id)
    values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null,
  'owner one cannot manufacture a cross-clinic membership'
);
select throws_ok(
  $$update public.clinics set name = 'Changed' where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  '42501', null,
  'clinic updates are not granted before the settings phase'
);
select throws_ok(
  $$delete from public.clinic_members where user_id = '11111111-1111-1111-1111-111111111111'$$,
  '42501', null,
  'owner membership cannot be removed directly'
);

set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
select results_eq(
  $$select id from public.clinics order by id$$,
  array['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid],
  'owner two cannot read owner one clinics'
);
select results_eq(
  $$select clinic_id from public.clinic_members order by clinic_id$$,
  array['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid],
  'owner two cannot read owner one membership'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from public.clinics$$,
  '42501', null,
  'anonymous callers have no clinic read grant'
);
select throws_ok(
  $$insert into public.clinics (name, currency_code, time_zone, created_by)
    values ('Anonymous Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null,
  'anonymous callers have no clinic write grant'
);

reset role;
select throws_ok(
  $$insert into public.clinics (name, currency_code, time_zone, created_by)
    values ('Invalid Zone', 'RUB', 'Not/AZone', '11111111-1111-1111-1111-111111111111')$$,
  '23514', null,
  'database rejects invalid IANA time zones'
);
select throws_ok(
  $$insert into public.clinics (name, currency_code, time_zone, created_by)
    values ('Wrong Currency', 'rub', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111')$$,
  '23514', null,
  'database rejects non-ISO currency storage'
);

select * from finish();
rollback;
