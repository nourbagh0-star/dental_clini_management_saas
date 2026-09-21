begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.clinic_member_roles'::regclass),
  'clinic member roles has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.clinic_invitations'::regclass),
  'clinic invitations has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_class where oid = 'public.clinic_invitation_roles'::regclass),
  'clinic invitation roles has RLS enabled'
);
select ok(
  exists (select 1 from pg_type where typname = 'clinic_role'),
  'clinic role enum is available'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.staff_create_invitation(uuid, uuid, text, bytea, public.clinic_role[])',
    'execute'
  ),
  'authenticated clients cannot execute the staff invitation command directly'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.staff_accept_invitation(uuid, bytea)',
    'execute'
  ),
  'anonymous clients cannot execute invitation acceptance directly'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.staff_create_invitation(uuid, uuid, text, bytea, public.clinic_role[])',
    'execute'
  ),
  'the server role cannot bypass the proof-aware invitation wrapper'
);
select ok(
  has_table_privilege('service_role', 'public.clinic_member_roles', 'select'),
  'the server role can read member roles for protected confirmation checks'
);
select ok(
  has_column_privilege(
    'service_role',
    'public.clinic_invitations',
    'id',
    'select'
  ),
  'the server role can filter the resend lookup by invitation ID'
);
select ok(
  has_column_privilege(
    'service_role',
    'public.clinic_invitations',
    'email',
    'select'
  ),
  'the server role can read the recipient address for resends'
);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner-one@example.test'),
  ('22222222-2222-2222-2222-222222222222', 'owner-two@example.test'),
  ('33333333-3333-3333-3333-333333333333', 'dentist@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'North Demo Clinic', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'South Demo Clinic', 'USD', 'America/New_York', '22222222-2222-2222-2222-222222222222');

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '33333333-3333-3333-3333-333333333333', 'dentist@example.test');
insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'dentist', '11111111-1111-1111-1111-111111111111');
insert into public.clinic_invitations (
  id, clinic_id, email, token_digest, expires_at, created_by
) values (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'assistant@example.test',
  decode(repeat('ab', 32), 'hex'),
  now() + interval '7 days',
  '11111111-1111-1111-1111-111111111111'
);
insert into public.clinic_invitation_roles (clinic_invitation_id, role) values
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'assistant');

select is(
  (
    select count(*)
    from public.clinic_member_roles member_role
    join public.clinic_members member on member.id = member_role.clinic_member_id
    where member_role.role = 'owner'::public.clinic_role
      and member.clinic_id in (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid
      )
  ),
  2::bigint,
  'existing Phase 2 clinic creators are migrated to owner roles'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';

select results_eq(
  $$select user_id from public.clinic_members where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid order by user_id$$,
  array[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid
  ],
  'owner reads the complete staff directory for their clinic'
);
select results_eq(
  $$select role::text from public.clinic_member_roles order by role::text$$,
  array['dentist', 'owner'],
  'owner reads roles for their clinic but not another clinic'
);
select results_eq(
  $$select id from public.clinic_invitations order by id$$,
  array['dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid],
  'owner reads invitations for their clinic'
);
select throws_ok(
  $$insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
    values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'assistant', '11111111-1111-1111-1111-111111111111')$$,
  '42501', null,
  'owner cannot directly assign a role outside server workflows'
);

set local request.jwt.claim.sub = '33333333-3333-3333-3333-333333333333';

select results_eq(
  $$select user_id from public.clinic_members order by user_id$$,
  array['33333333-3333-3333-3333-333333333333'::uuid],
  'staff member reads only their own membership'
);
select results_eq(
  $$select role::text from public.clinic_member_roles order by role::text$$,
  array['dentist'],
  'staff member reads only their own roles'
);
select is_empty(
  $$select * from public.clinic_invitations$$,
  'staff member cannot read invitations'
);
select throws_ok(
  $$update public.clinic_members set email = 'other@example.test'
    where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'$$,
  '42501', null,
  'staff member cannot directly edit membership records'
);

reset role;
set local role anon;
select throws_ok(
  $$select * from public.clinic_member_roles$$,
  '42501', null,
  'anonymous callers cannot read staff roles'
);
select throws_ok(
  $$select * from public.clinic_invitations$$,
  '42501', null,
  'anonymous callers cannot read invitations'
);

reset role;
select throws_ok(
  $$delete from public.clinic_member_roles
    where role = 'owner'::public.clinic_role
      and clinic_member_id = (
        select id from public.clinic_members
        where clinic_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid
          and user_id = '11111111-1111-1111-1111-111111111111'::uuid
      )$$,
  'P0001', 'last_active_owner',
  'database blocks removal of the last active owner role'
);
select throws_ok(
  $$update public.clinic_members
    set is_active = false,
        deactivated_at = now(),
        deactivated_by = '11111111-1111-1111-1111-111111111111'::uuid
    where clinic_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid
      and user_id = '22222222-2222-2222-2222-222222222222'::uuid$$,
  'P0001', 'last_active_owner',
  'database blocks deactivation of the last active owner'
);

select * from finish();
rollback;
