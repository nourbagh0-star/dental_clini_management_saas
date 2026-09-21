begin;
create extension if not exists pgtap with schema extensions;
select plan(32);

select ok((select relrowsecurity from pg_class where oid = 'public.invoices'::regclass), 'invoices have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.invoice_items'::regclass), 'invoice items have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.payments'::regclass), 'payments have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.patient_credit_accounts'::regclass), 'credits have RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.financial_ledger_entries'::regclass), 'ledger has RLS');
select ok(not has_table_privilege('authenticated', 'public.invoices', 'insert'), 'browser cannot insert invoices');
select ok(not has_function_privilege('authenticated', 'public.billing_payment_record(uuid,uuid,numeric,public.payment_method,text,timestamptz,uuid,text)', 'execute'), 'browser cannot call protected payment command');

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner-billing@example.test'),
  ('22222222-2222-4222-8222-222222222222', 'dentist-billing@example.test'),
  ('33333333-3333-4333-8333-333333333333', 'reception-billing@example.test'),
  ('44444444-4444-4444-8444-444444444444', 'assistant-billing@example.test');
insert into public.clinics (id, name, currency_code, time_zone, created_by)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Billing Demo', 'RUB', 'Europe/Moscow', '11111111-1111-1111-1111-111111111111');
insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '22222222-2222-4222-8222-222222222222', 'dentist-billing@example.test'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '33333333-3333-4333-8333-333333333333', 'reception-billing@example.test'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '44444444-4444-4444-8444-444444444444', 'assistant-billing@example.test');
insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'dentist', '11111111-1111-1111-1111-111111111111'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc', 'receptionist', '11111111-1111-1111-1111-111111111111'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddddd', 'assistant', '11111111-1111-1111-1111-111111111111');
insert into public.patients (
  id, clinic_id, patient_number, first_name, last_name, phone,
  birth_date_precision, created_by
) values (
  'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'PAT-00001', 'Ada',
  'Demo', '+79990000000', 'unknown', '11111111-1111-1111-1111-111111111111'
);
insert into public.procedures (
  id, clinic_id, name, category, default_price, duration_minutes
) values (
  'ffffffff-ffff-4fff-8fff-ffffffffffff',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Crown', 'Restoration',
  100.10, 60
);

select lives_ok($$
  select public.billing_settings_update(
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 10, 'inv'
  )
$$, 'owner updates billing settings');
select throws_ok($$
  select public.billing_settings_update(
    '33333333-3333-4333-8333-333333333333',
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 10, 'INV'
  )
$$, 'P0001', 'billing_forbidden', 'receptionist cannot update billing settings');
select lives_ok($$
  select public.billing_invoice_create_draft(
    '22222222-2222-4222-8222-222222222222',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'en',
    '10000000-0000-4000-8000-000000000001', repeat('a', 64)
  )
$$, 'dentist creates invoice draft');
select throws_ok($$
  select public.billing_invoice_create_draft(
    '33333333-3333-4333-8333-333333333333',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'en',
    '10000000-0000-4000-8000-000000000002', repeat('b', 64)
  )
$$, 'P0001', 'billing_forbidden', 'receptionist cannot create invoice draft');
select lives_ok($$
  select public.billing_invoice_item_add(
    '22222222-2222-4222-8222-222222222222',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'),
    'ffffffff-ffff-4fff-8fff-ffffffffffff', null, 1, 1
  )
$$, 'dentist adds a catalogue item');
select is((select subtotal from public.invoices
  where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 100.10::numeric, 'subtotal is exact');
select lives_ok($$
  select public.billing_invoice_content_approval(
    '22222222-2222-4222-8222-222222222222',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 2, true
  )
$$, 'dentist approves clinical content');
select lives_ok($$
  select public.billing_invoice_set_financials(
    '11111111-1111-1111-1111-111111111111',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'),
    jsonb_build_array(jsonb_build_object(
      'itemId', (select item.id from public.invoice_items item
        join public.invoices invoice on invoice.id = item.invoice_id
        where invoice.patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'),
      'unitPrice', '100.10'
    )), 'fixed', 0.10, 10, 'en', 3
  )
$$, 'owner sets prices, discount, tax, and locale');
select is((select total from public.invoices
  where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 110.00::numeric, 'discount then tax produces exact total');
select lives_ok($$
  select public.billing_invoice_finalize(
    '11111111-1111-1111-1111-111111111111',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 4,
    '10000000-0000-4000-8000-000000000003', repeat('c', 64)
  )
$$, 'owner finalizes approved invoice');
select is((select invoice_number from public.invoices
  where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 'INV-00001', 'finalization allocates clinic number');
select is(
  (select public.billing_invoice_finalize(
    '11111111-1111-1111-1111-111111111111',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 4,
    '10000000-0000-4000-8000-000000000003', repeat('c', 64)
  )->>'invoiceNumber'),
  'INV-00001', 'idempotent finalization returns original result'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '44444444-4444-4444-8444-444444444444';
select is((select count(*)::integer from public.invoices), 0, 'assistant cannot read invoices');
reset role;
set local role authenticated;
set local request.jwt.claim.sub = '33333333-3333-4333-8333-333333333333';
select is((select count(*)::integer from public.invoices), 1, 'receptionist reads invoice summaries');
select is((select count(*)::integer from public.invoice_items), 0, 'receptionist cannot read clinical invoice items');
reset role;
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
select is((select count(*)::integer from public.invoice_items), 1, 'dentist reads clinical invoice items');
select is((select count(*)::integer from public.payments), 0, 'dentist cannot read payments');
reset role;

select lives_ok($$
  select public.billing_payment_record(
    '33333333-3333-4333-8333-333333333333',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'),
    120, 'card', 'DEMO-001', now(),
    '10000000-0000-4000-8000-000000000004', repeat('d', 64)
  )
$$, 'receptionist records payment and overpayment credit');
select is((select paid_amount from public.invoices
  where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 110.00::numeric, 'payment applies only outstanding amount');
select is((select balance from public.patient_credit_accounts
  where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 10.00::numeric, 'overpayment becomes patient credit');
select throws_ok($$
  select public.billing_invoice_cancel(
    '11111111-1111-1111-1111-111111111111',
    (select id from public.invoices
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 5, 'Duplicate'
  )
$$, 'P0001', 'invoice_nonzero_paid_balance', 'paid invoice cannot be cancelled');
select throws_ok($$
  update public.financial_ledger_entries set amount = 1
$$, 'P0001', 'financial_record_immutable', 'ledger entries are immutable');
select lives_ok($$
  select public.billing_financial_entry_reverse(
    '11111111-1111-1111-1111-111111111111',
    (select id from public.financial_ledger_entries
      where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
        and kind = 'credit_created'),
    4, 'refund', 'Demo refund',
    '10000000-0000-4000-8000-000000000005', repeat('e', 64)
  )
$$, 'owner refunds part of the overpayment credit');
select is((select balance from public.patient_credit_accounts
  where patient_id = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'), 6.00::numeric, 'credit refund updates balance exactly');
select is((select default_price from public.procedure_money_rows
  where id = 'ffffffff-ffff-4fff-8fff-ffffffffffff'), '100.10', 'money view exposes canonical decimal text');

select * from finish();
rollback;
