begin;
create extension if not exists pgtap with schema extensions;
select plan(31);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass),
  'audit events keeps RLS enabled'
);
select ok(
  not has_table_privilege('authenticated', 'public.audit_events', 'select'),
  'browser clients cannot read the audit ledger directly'
);
select ok(
  not has_table_privilege('service_role', 'public.audit_events', 'update'),
  'service credentials cannot update the audit ledger directly'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.audit_event_page(uuid,uuid,date,date,uuid,public.audit_event_category,text,text,integer,timestamptz,uuid)',
    'execute'
  ),
  'browser clients cannot execute the audit page function'
);
select ok(
  has_function_privilege(
    'service_role',
    'public.audit_event_page(uuid,uuid,date,date,uuid,public.audit_event_category,text,text,integer,timestamptz,uuid)',
    'execute'
  ),
  'the Edge service role can execute the audit page function'
);

insert into auth.users (id, email) values
  ('13000000-0000-4000-8000-000000000001', 'audit-owner@example.test'),
  ('13000000-0000-4000-8000-000000000002', 'audit-dentist@example.test'),
  ('13000000-0000-4000-8000-000000000003', 'audit-reception@example.test'),
  ('13000000-0000-4000-8000-000000000004', 'audit-other-owner@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by) values
  ('13000000-0000-4000-8000-000000000010', 'Audit Clinic', 'RUB',
   'Europe/Moscow', '13000000-0000-4000-8000-000000000001'),
  ('13000000-0000-4000-8000-000000000011', 'Other Audit Clinic', 'USD',
   'America/New_York', '13000000-0000-4000-8000-000000000004');

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('13000000-0000-4000-8000-000000000020',
   '13000000-0000-4000-8000-000000000010',
   '13000000-0000-4000-8000-000000000002', 'audit-dentist@example.test'),
  ('13000000-0000-4000-8000-000000000021',
   '13000000-0000-4000-8000-000000000010',
   '13000000-0000-4000-8000-000000000003', 'audit-reception@example.test');
insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('13000000-0000-4000-8000-000000000020', 'dentist',
   '13000000-0000-4000-8000-000000000001'),
  ('13000000-0000-4000-8000-000000000021', 'receptionist',
   '13000000-0000-4000-8000-000000000001');

insert into public.patients (
  id, clinic_id, patient_number, first_name, last_name, phone,
  birth_date_precision, created_by
) values (
  '13000000-0000-4000-8000-000000000030',
  '13000000-0000-4000-8000-000000000010', 'PAT-13001', 'Fictional',
  'Audit', '+79991300001', 'unknown',
  '13000000-0000-4000-8000-000000000001'
);

select lives_ok(
  $$select private.audit_write(
    '13000000-0000-4000-8000-000000000002',
    '13000000-0000-4000-8000-000000000010',
    'patient_profile_opened', 'patient',
    '13000000-0000-4000-8000-000000000030'
  )$$,
  'the protected writer appends a recognized safe event'
);
select is(
  (select category::text from public.audit_events
   where actor_user_id = '13000000-0000-4000-8000-000000000002'),
  'access',
  'the database derives the event category'
);
select is(
  (select actor_email_snapshot from public.audit_events
   where actor_user_id = '13000000-0000-4000-8000-000000000002'),
  'audit-dentist@example.test',
  'the database snapshots the verified member email'
);
select is(
  (select actor_roles_snapshot::text from public.audit_events
   where actor_user_id = '13000000-0000-4000-8000-000000000002'),
  '{dentist}',
  'the database snapshots roles at event time'
);

insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
values ('13000000-0000-4000-8000-000000000020', 'assistant',
  '13000000-0000-4000-8000-000000000001');
select is(
  (select actor_roles_snapshot::text from public.audit_events
   where actor_user_id = '13000000-0000-4000-8000-000000000002'),
  '{dentist}',
  'later role changes cannot rewrite an event snapshot'
);
select throws_ok(
  $$update public.audit_events set reason = 'changed'$$,
  'P0001', 'audit_event_immutable',
  'audit events cannot be updated'
);
select throws_ok(
  $$delete from public.audit_events$$,
  'P0001', 'audit_event_immutable',
  'audit events cannot be deleted'
);
select throws_ok(
  $$insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    '13000000-0000-4000-8000-000000000010',
    '13000000-0000-4000-8000-000000000001',
    'patient_profile_opened', 'patient',
    '13000000-0000-4000-8000-000000000030',
    '{"patient_name":"must not be stored"}'::jsonb
  )$$,
  'P0001', 'invalid_audit_event',
  'unsafe metadata keys are rejected'
);

select lives_ok(
  $$select public.audit_record_access(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010', 'audit_log',
    '13000000-0000-4000-8000-000000000010',
    '13000000-0000-4000-8000-000000000040'
  )$$,
  'an active owner records opening the audit log'
);
select lives_ok(
  $$select public.audit_record_access(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010', 'audit_log',
    '13000000-0000-4000-8000-000000000010',
    '13000000-0000-4000-8000-000000000040'
  )$$,
  'retrying the same access request succeeds idempotently'
);
select is(
  (select count(*) from public.audit_events
   where request_id = '13000000-0000-4000-8000-000000000040'),
  1::bigint,
  'an access request UUID creates only one event'
);
select throws_ok(
  $$select public.audit_record_access(
    '13000000-0000-4000-8000-000000000003',
    '13000000-0000-4000-8000-000000000010', 'medical_record',
    '13000000-0000-4000-8000-000000000030',
    '13000000-0000-4000-8000-000000000041'
  )$$,
  'P0001', 'audit_access_forbidden',
  'a receptionist cannot record or open a clinical area'
);
select throws_ok(
  $$select public.audit_record_access(
    '13000000-0000-4000-8000-000000000002',
    '13000000-0000-4000-8000-000000000011', 'patient_profile',
    '13000000-0000-4000-8000-000000000030',
    '13000000-0000-4000-8000-000000000042'
  )$$,
  'P0001', 'audit_access_forbidden',
  'cross-clinic access recording is denied'
);

select lives_ok(
  $$select public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    (now() at time zone 'Europe/Moscow')::date - 1,
    (now() at time zone 'Europe/Moscow')::date + 1
  )$$,
  'an active owner can request an audit page'
);
select is(
  public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    (now() at time zone 'Europe/Moscow')::date - 1,
    (now() at time zone 'Europe/Moscow')::date + 1
  ) ->> 'clinicTimeZone',
  'Europe/Moscow',
  'the page returns the authoritative clinic time zone'
);
select is(
  jsonb_array_length(public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    (now() at time zone 'Europe/Moscow')::date - 1,
    (now() at time zone 'Europe/Moscow')::date + 1,
    null, 'access'::public.audit_event_category
  ) -> 'items'),
  2,
  'category filtering returns only matching clinic events'
);
select is(
  (public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    (now() at time zone 'Europe/Moscow')::date - 1,
    (now() at time zone 'Europe/Moscow')::date + 1,
    null, null, null, null, 1
  ) ->> 'hasMore')::boolean,
  true,
  'bounded pages report when more events exist'
);
select ok(
  public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    (now() at time zone 'Europe/Moscow')::date - 1,
    (now() at time zone 'Europe/Moscow')::date + 1,
    null, null, null, null, 1
  ) -> 'nextCursor' is not null,
  'a bounded page returns the two-part next cursor'
);
select throws_ok(
  $$select public.audit_event_page(
    '13000000-0000-4000-8000-000000000002',
    '13000000-0000-4000-8000-000000000010',
    current_date - 1, current_date + 1
  )$$,
  'P0001', 'audit_read_forbidden',
  'a non-owner cannot read audit events'
);
select throws_ok(
  $$select public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000011',
    current_date - 1, current_date + 1
  )$$,
  'P0001', 'audit_read_forbidden',
  'an owner cannot read another clinic audit log'
);
select throws_ok(
  $$select public.audit_event_page(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    current_date - 100, current_date + 1
  )$$,
  'P0001', 'invalid_audit_query',
  'one request cannot scan more than ninety days'
);

select lives_ok(
  $$select public.patient_create(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000010',
    '{"firstName":"Demo","lastName":"Patient","phone":"+79991300002","birthDatePrecision":"unknown"}'::jsonb
  )$$,
  'patient creation remains available through the audited command wrapper'
);
select is(
  (select category::text from public.audit_events
   where event_type = 'patient_created'
     and actor_user_id = '13000000-0000-4000-8000-000000000001'
   order by occurred_at desc
   limit 1),
  'patient_administration',
  'patient creation is recorded atomically in the patient category'
);
select lives_ok(
  $$select public.staff_replace_member_roles(
    '13000000-0000-4000-8000-000000000001',
    '13000000-0000-4000-8000-000000000020',
    array['dentist']::public.clinic_role[]
  )$$,
  'staff role replacement remains available through the audited command wrapper'
);
select is(
  (select category::text from public.audit_events
   where event_type = 'staff_roles_changed'
     and actor_user_id = '13000000-0000-4000-8000-000000000001'
   order by occurred_at desc
   limit 1),
  'staff_security',
  'staff role replacement is recorded atomically in the security category'
);

set local role authenticated;
set local request.jwt.claim.sub = '13000000-0000-4000-8000-000000000001';
select throws_ok(
  $$select * from public.audit_events$$,
  '42501', null,
  'even an owner cannot bypass the protected audit read API'
);

reset role;
select * from finish();
rollback;
