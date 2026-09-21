begin;
create extension if not exists pgtap with schema extensions;
select plan(25);

select ok(
  not has_function_privilege(
    'authenticated', 'public.dashboard_snapshot(uuid,uuid)', 'execute'
  ),
  'browser clients cannot execute the privileged dashboard snapshot'
);
select ok(
  has_function_privilege(
    'service_role', 'public.dashboard_snapshot(uuid,uuid)', 'execute'
  ),
  'the Edge service role can execute the dashboard snapshot'
);

insert into auth.users (id, email) values
  ('12000000-0000-4000-8000-000000000001', 'dashboard-owner@example.test'),
  ('12000000-0000-4000-8000-000000000002', 'dashboard-dentist@example.test'),
  ('12000000-0000-4000-8000-000000000003', 'dashboard-reception@example.test'),
  ('12000000-0000-4000-8000-000000000004', 'dashboard-assistant@example.test'),
  ('12000000-0000-4000-8000-000000000005', 'dashboard-outsider@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by)
values
  ('12000000-0000-4000-8000-000000000010', 'Dashboard Clinic', 'RUB',
    'Europe/Moscow', '12000000-0000-4000-8000-000000000001'),
  ('12000000-0000-4000-8000-000000000011', 'Other Dashboard Clinic', 'USD',
    'America/New_York', '12000000-0000-4000-8000-000000000005');

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('12000000-0000-4000-8000-000000000020',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000002',
    'dashboard-dentist@example.test'),
  ('12000000-0000-4000-8000-000000000021',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000003',
    'dashboard-reception@example.test'),
  ('12000000-0000-4000-8000-000000000022',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000004',
    'dashboard-assistant@example.test');

insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
values
  ('12000000-0000-4000-8000-000000000020', 'dentist',
    '12000000-0000-4000-8000-000000000001'),
  ('12000000-0000-4000-8000-000000000021', 'receptionist',
    '12000000-0000-4000-8000-000000000001'),
  ('12000000-0000-4000-8000-000000000022', 'assistant',
    '12000000-0000-4000-8000-000000000001');

insert into public.patients (
  id, clinic_id, patient_number, first_name, last_name, phone,
  birth_date_precision, created_by, archived_at, archived_by
) values
  ('12000000-0000-4000-8000-000000000030',
    '12000000-0000-4000-8000-000000000010', 'PAT-12001', 'Ada', 'Demo',
    '+79991200001', 'unknown', '12000000-0000-4000-8000-000000000001',
    null, null),
  ('12000000-0000-4000-8000-000000000031',
    '12000000-0000-4000-8000-000000000010', 'PAT-12002', 'Grace', 'Demo',
    '+79991200002', 'unknown', '12000000-0000-4000-8000-000000000001',
    null, null),
  ('12000000-0000-4000-8000-000000000032',
    '12000000-0000-4000-8000-000000000010', 'PAT-12003', 'Linus', 'Demo',
    '+79991200003', 'unknown', '12000000-0000-4000-8000-000000000001',
    null, null),
  ('12000000-0000-4000-8000-000000000033',
    '12000000-0000-4000-8000-000000000010', 'PAT-12004', 'Archived', 'Demo',
    '+79991200004', 'unknown', '12000000-0000-4000-8000-000000000001',
    timestamptz '2026-09-01 09:00+00',
    '12000000-0000-4000-8000-000000000001');

insert into public.appointments (
  id, clinic_id, patient_id, dentist_member_id, starts_at, ends_at, status,
  purpose, cancellation_reason, created_by
) values
  ('12000000-0000-4000-8000-000000000040',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000030',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-13 08:00+00', timestamptz '2026-09-13 08:30+00',
    'scheduled', 'Hidden purpose', null,
    '12000000-0000-4000-8000-000000000003'),
  ('12000000-0000-4000-8000-000000000041',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000031',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-13 09:00+00', timestamptz '2026-09-13 09:30+00',
    'cancelled', null, 'Demo cancellation',
    '12000000-0000-4000-8000-000000000003'),
  ('12000000-0000-4000-8000-000000000042',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000032',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-13 10:00+00', timestamptz '2026-09-13 10:30+00',
    'no_show', null, null, '12000000-0000-4000-8000-000000000003'),
  ('12000000-0000-4000-8000-000000000043',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000030',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-07 07:00+00', timestamptz '2026-09-07 07:30+00',
    'completed', null, null, '12000000-0000-4000-8000-000000000002'),
  ('12000000-0000-4000-8000-000000000044',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000031',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-14 07:00+00', timestamptz '2026-09-14 07:30+00',
    'confirmed', null, null, '12000000-0000-4000-8000-000000000003'),
  ('12000000-0000-4000-8000-000000000045',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000032',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-20 07:00+00', timestamptz '2026-09-20 07:30+00',
    'scheduled', null, null, '12000000-0000-4000-8000-000000000003'),
  ('12000000-0000-4000-8000-000000000046',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000030',
    '12000000-0000-4000-8000-000000000020',
    timestamptz '2026-09-21 21:00+00', timestamptz '2026-09-21 21:30+00',
    'scheduled', null, null, '12000000-0000-4000-8000-000000000003');

insert into public.procedures (
  id, clinic_id, name, category, default_price, duration_minutes
) values (
  '12000000-0000-4000-8000-000000000050',
  '12000000-0000-4000-8000-000000000010', 'Dashboard procedure',
  'Demo', 100, 30
);
insert into public.treatment_plans (
  id, clinic_id, patient_id, dentist_member_id, status
) values (
  '12000000-0000-4000-8000-000000000051',
  '12000000-0000-4000-8000-000000000010',
  '12000000-0000-4000-8000-000000000030',
  '12000000-0000-4000-8000-000000000020', 'active'
);
insert into public.treatment_plan_items (
  id, clinic_id, treatment_plan_id, procedure_id, estimated_price, status,
  assigned_dentist_id, sort_order, completed_at, completed_by
) values
  ('12000000-0000-4000-8000-000000000052',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000051',
    '12000000-0000-4000-8000-000000000050', 100, 'completed',
    '12000000-0000-4000-8000-000000000020', 0,
    timestamptz '2026-09-05 09:00+00',
    '12000000-0000-4000-8000-000000000002'),
  ('12000000-0000-4000-8000-000000000053',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000051',
    '12000000-0000-4000-8000-000000000050', 100, 'in_progress',
    '12000000-0000-4000-8000-000000000020', 1, null, null);

insert into public.invoices (
  id, clinic_id, patient_id, invoice_number, sequence_number, document_status,
  payment_status, currency_code, subtotal, total, paid_amount,
  outstanding_balance, prepared_by, finalized_by, finalized_at,
  patient_name_snapshot, patient_number_snapshot, clinic_name_snapshot
) values
  ('12000000-0000-4000-8000-000000000060',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000030', 'INV-12001', 12001,
    'finalized', 'unpaid', 'RUB', 100, 100, 0, 100,
    '12000000-0000-4000-8000-000000000002',
    '12000000-0000-4000-8000-000000000001',
    timestamptz '2026-09-02 09:00+00', 'Ada Demo', 'PAT-12001',
    'Dashboard Clinic'),
  ('12000000-0000-4000-8000-000000000061',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000031', 'INV-12002', 12002,
    'finalized', 'partially_paid', 'RUB', 100, 100, 60, 40,
    '12000000-0000-4000-8000-000000000002',
    '12000000-0000-4000-8000-000000000001',
    timestamptz '2026-09-03 09:00+00', 'Grace Demo', 'PAT-12002',
    'Dashboard Clinic'),
  ('12000000-0000-4000-8000-000000000062',
    '12000000-0000-4000-8000-000000000010',
    '12000000-0000-4000-8000-000000000032', null, null,
    'draft', 'unpaid', 'RUB', 50, 50, 0, 50,
    '12000000-0000-4000-8000-000000000002', null, null, null, null, null);

select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{metrics,totalPatients}')::integer,
  3,
  'owner sees only active patients'
);
select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{metrics,appointmentsThisWeek}')::integer,
  3,
  'week count uses Monday through Sunday and excludes cancelled appointments'
);
select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{metrics,completedTreatmentsThisMonth}')::integer,
  1,
  'owner sees completed treatments in the clinic-local month'
);
select is(
  private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{metrics,financial,outstandingAmount}',
  '140.00',
  'outstanding amount is an exact decimal and excludes drafts'
);
select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{metrics,financial,outstandingInvoiceCount}')::integer,
  2,
  'outstanding invoice count includes unpaid and partially paid finalized invoices'
);
select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{todayAppointments,totalCount}')::integer,
  2,
  'today includes no-show and excludes cancelled appointments'
);
select is(
  jsonb_array_length(private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #> '{todayAppointments,items}'),
  2,
  'today preview is bounded and populated'
);
select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{upcomingAppointments,totalCount}')::integer,
  2,
  'upcoming covers seven clinic-local days after today'
);
select is(
  jsonb_array_length(private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #> '{upcomingAppointments,items}'),
  2,
  'upcoming preview returns only scheduled and confirmed records'
);
select is(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{periods,todayStart}')::timestamptz,
  timestamptz '2026-09-12 21:00+00',
  'today boundary uses the clinic time zone rather than UTC or device time'
);
select ok(
  not ((private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #> '{todayAppointments,items,0}') ? 'purpose'),
  'appointment previews omit purpose and clinical-adjacent fields'
);
select is(
  private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000004',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{capabilities,canViewFinancialSummary}',
  'false',
  'assistant financial capability is false'
);
select ok(
  not ((private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000004',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) -> 'metrics') ? 'financial'),
  'assistant response omits the financial object'
);
select ok(
  not ((private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000004',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) -> 'metrics') ? 'completedTreatmentsThisMonth'),
  'assistant response omits treatment completion totals'
);
select is(
  private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000003',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) #>> '{capabilities,canViewFinancialSummary}',
  'true',
  'receptionist receives the approved financial capability'
);
select ok(
  not ((private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000003',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) -> 'metrics') ? 'completedTreatmentsThisMonth'),
  'receptionist response omits treatment completion totals'
);
select ok(
  (private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000002',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) -> 'metrics') ?& array['financial', 'completedTreatmentsThisMonth'],
  'dentist receives both approved metric groups'
);
select throws_ok(
  $$select private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000005',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  )$$,
  'P0001', 'dashboard_forbidden',
  'another clinic owner cannot obtain the target clinic snapshot'
);
select lives_ok(
  $$select public.treatment_plan_item_transition(
    '12000000-0000-4000-8000-000000000002',
    '12000000-0000-4000-8000-000000000053', 'completed'
  )$$,
  'dentist completion records explicit completion metadata'
);
select is(
  (select completed_by from public.treatment_plan_items
    where id = '12000000-0000-4000-8000-000000000053'),
  '12000000-0000-4000-8000-000000000002'::uuid,
  'completion metadata records the acting user'
);
select ok(
  (select completed_at is not null from public.treatment_plan_items
    where id = '12000000-0000-4000-8000-000000000053'),
  'completion metadata records an exact server instant'
);
select throws_ok(
  $$select public.treatment_plan_item_transition(
    '12000000-0000-4000-8000-000000000002',
    '12000000-0000-4000-8000-000000000053', 'cancelled'
  )$$,
  'P0001', 'invalid_treatment_plan_item_transition',
  'completed treatment items remain terminal'
);
select is(
  private.dashboard_snapshot_at(
    '12000000-0000-4000-8000-000000000001',
    '12000000-0000-4000-8000-000000000010',
    timestamptz '2026-09-13 09:00+00'
  ) ->> 'clinicId',
  '12000000-0000-4000-8000-000000000010',
  'snapshot identifies the active clinic used for every metric'
);

select * from finish();
rollback;
