begin;
create extension if not exists pgtap with schema extensions;
select plan(32);

select ok(
  not has_table_privilege('service_role', 'private.security_session_leases', 'select'),
  'service credentials cannot inspect private lock leases directly'
);
select ok(
  not has_function_privilege(
    'authenticated', 'public.security_session_open(uuid,uuid)', 'execute'
  ),
  'browser clients cannot open a server lease through the Data API'
);
select ok(
  has_function_privilege(
    'service_role', 'public.security_session_assert(uuid,uuid)', 'execute'
  ),
  'the authenticated Edge boundary can assert a server lease'
);
select is(
  (select count(*) from information_schema.role_table_grants
   where grantee = 'authenticated' and table_schema = 'public'
     and privilege_type = 'SELECT'),
  0::bigint,
  'authenticated clients have no direct business table or view reads'
);
select ok(
  not has_table_privilege('authenticated', 'public.clinics', 'insert'),
  'clinic creation is no longer exposed through the Data API'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.security_workspace_create_clinic(uuid,text,text,text)', 'execute'
  ),
  'the workspace Edge boundary can create a clinic'
);
select ok(
  not has_function_privilege(
    'service_role',
    'public.billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text)',
    'execute'
  ),
  'the service role cannot bypass the proof-aware financial reversal wrapper'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.security_billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text,uuid,bytea,bytea)',
    'execute'
  ),
  'the Edge boundary can execute the proof-aware financial reversal wrapper'
);

insert into auth.users (id, email) values
  ('14000000-0000-4000-8000-000000000001', 'lease-user@example.test'),
  ('14000000-0000-4000-8000-000000000002', 'other-user@example.test');
insert into auth.sessions (id, user_id, created_at, updated_at) values
  ('14000000-0000-4000-8000-000000000010',
   '14000000-0000-4000-8000-000000000001', now(), now());
insert into public.clinics (
  id, name, currency_code, time_zone, created_by
) values (
  '14000000-0000-4000-8000-000000000020', 'Security Test Clinic',
  'RUB', 'Europe/Moscow', '14000000-0000-4000-8000-000000000001'
);

select throws_ok(
  $$select public.security_session_assert(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  )$$,
  'P0001', 'security_session_locked',
  'a live Auth session starts locked until password unlock'
);
select lives_ok(
  $$select public.security_session_open(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  )$$,
  'password-verified server code can open the original session lease'
);
select is(
  (select unlocked_until - last_renewed_at
   from private.security_session_leases
   where session_id = '14000000-0000-4000-8000-000000000010'),
  interval '3 days',
  'a new fictional-demo lease lasts exactly three days by server time'
);
select is(
  (public.security_session_assert(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  ) ->> 'revision')::integer,
  1,
  'an open lease returns its concurrency revision'
);
select throws_ok(
  $$select public.security_staff_create_invitation(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000020', 'proof-owner@example.test',
    decode(repeat('11', 32), 'hex'), array['owner']::public.clinic_role[],
    '14000000-0000-4000-8000-000000000010',
    decode(repeat('ee', 32), 'hex'), null
  )$$,
  'P0001', 'owner_proof_required',
  'an Owner invitation cannot bypass action proof consumption'
);
select lives_ok(
  $$select public.security_owner_proof_issue(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'owner_invitation_create', null,
    decode(repeat('ee', 32), 'hex'), decode(repeat('ff', 32), 'hex')
  )$$,
  'an exact Owner invitation proof can be issued'
);
select lives_ok(
  $$select public.security_staff_create_invitation(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000020', 'proof-owner@example.test',
    decode(repeat('11', 32), 'hex'), array['owner']::public.clinic_role[],
    '14000000-0000-4000-8000-000000000010',
    decode(repeat('ee', 32), 'hex'), decode(repeat('ff', 32), 'hex')
  )$$,
  'the proof-aware wrapper consumes proof and creates the invitation atomically'
);
select lives_ok(
  $$select public.security_owner_proof_issue(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'staff_roles_replace', null,
    decode(repeat('aa', 32), 'hex'), decode(repeat('bb', 32), 'hex')
  )$$,
  'an unlocked active Owner can issue an action-bound proof'
);
select lives_ok(
  $$select private.security_owner_proof_consume(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'staff_roles_replace', null,
    decode(repeat('aa', 32), 'hex'), decode(repeat('bb', 32), 'hex')
  )$$,
  'the exact user, session, clinic, action, target, and input consumes once'
);
select throws_ok(
  $$select private.security_owner_proof_consume(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'staff_roles_replace', null,
    decode(repeat('aa', 32), 'hex'), decode(repeat('bb', 32), 'hex')
  )$$,
  'P0001', 'owner_proof_required',
  'an Owner proof cannot be replayed'
);
select lives_ok(
  $$select public.security_owner_proof_issue(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'financial_entry_reverse', null,
    decode(repeat('cc', 32), 'hex'), decode(repeat('dd', 32), 'hex')
  )$$,
  'a second proof can be issued for another exact action'
);
select throws_ok(
  $$select private.security_owner_proof_consume(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'billing_settings_update', null,
    decode(repeat('cc', 32), 'hex'), decode(repeat('dd', 32), 'hex')
  )$$,
  'P0001', 'owner_proof_required',
  'a proof cannot authorize a different action'
);
select lives_ok(
  $$select private.security_owner_proof_consume(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010',
    '14000000-0000-4000-8000-000000000020',
    'financial_entry_reverse', null,
    decode(repeat('cc', 32), 'hex'), decode(repeat('dd', 32), 'hex')
  )$$,
  'a mismatch does not consume the valid proof'
);
select throws_ok(
  $$select public.security_session_assert(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000011'
  )$$,
  'P0001', 'security_session_revoked',
  'a nonexistent Auth session is rejected'
);
select throws_ok(
  $$select public.security_session_assert(
    '14000000-0000-4000-8000-000000000002',
    '14000000-0000-4000-8000-000000000010'
  )$$,
  'P0001', 'security_session_revoked',
  'a session cannot be substituted onto another user'
);
select throws_ok(
  $$select public.security_session_renew(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010', 99
  )$$,
  'P0001', 'security_session_locked',
  'a stale lease revision cannot renew the session'
);
select is(
  (public.security_session_renew(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010', 1
  ) ->> 'revision')::integer,
  2,
  'the current revision renews once and advances atomically'
);
select is(
  (select unlocked_until - last_renewed_at
   from private.security_session_leases
   where session_id = '14000000-0000-4000-8000-000000000010'),
  interval '3 days',
  'human-activity renewal extends the lease by exactly three server days'
);
select lives_ok(
  $$select public.security_session_lock(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  )$$,
  'manual lock closes the server lease'
);
select throws_ok(
  $$select public.security_session_assert(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  )$$,
  'P0001', 'security_session_locked',
  'a manually locked lease cannot authorize data'
);
select throws_ok(
  $$select public.security_session_renew(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010', 3
  )$$,
  'P0001', 'security_session_locked',
  'renew cannot reopen a closed lease'
);
select is(
  (public.security_session_open(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  ) ->> 'revision')::integer,
  4,
  'a new password unlock reopens and advances the lease'
);
delete from auth.sessions
where id = '14000000-0000-4000-8000-000000000010';
select throws_ok(
  $$select public.security_session_assert(
    '14000000-0000-4000-8000-000000000001',
    '14000000-0000-4000-8000-000000000010'
  )$$,
  'P0001', 'security_session_revoked',
  'revoking Auth invalidates an otherwise unexpired access lease'
);
select is(
  (select count(*) from private.security_session_leases
   where session_id = '14000000-0000-4000-8000-000000000010'),
  0::bigint,
  'Auth session cascade removes the matching lease'
);

select * from finish();
rollback;
