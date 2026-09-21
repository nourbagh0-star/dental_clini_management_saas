-- Phase 11: exact invoice snapshots, append-only payment/credit ledger, and
-- private invoice-document metadata. All mutations are added in the following
-- service-command migration; browser roles receive read-only, role-scoped RLS.
create type public.invoice_document_status as enum ('draft', 'finalized', 'cancelled');
create type public.invoice_payment_status as enum ('unpaid', 'partially_paid', 'paid');
create type public.invoice_discount_type as enum ('none', 'fixed', 'percentage');
create type public.invoice_item_source as enum ('catalogue', 'treatment_plan_item');
create type public.payment_method as enum ('cash', 'card', 'bank_transfer', 'other');
create type public.financial_entry_kind as enum (
  'payment_applied',
  'credit_created',
  'credit_applied',
  'credit_application_reversed',
  'refund_invoice',
  'refund_credit',
  'correction_invoice',
  'correction_credit'
);
create type public.invoice_document_generation_status as enum ('pending', 'available', 'failed');
create type public.invoice_document_locale as enum ('en', 'ru', 'ar');

create table public.clinic_billing_settings (
  clinic_id uuid primary key references public.clinics(id) on delete restrict,
  default_tax_rate numeric(5,2) not null default 0,
  invoice_prefix text not null default 'INV',
  updated_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  constraint clinic_billing_settings_tax check (default_tax_rate between 0 and 100),
  constraint clinic_billing_settings_prefix check (
    invoice_prefix = upper(btrim(invoice_prefix))
    and invoice_prefix ~ '^[A-Z0-9]{1,12}$'
  )
);

create table public.clinic_invoice_counters (
  clinic_id uuid primary key references public.clinics(id) on delete restrict,
  next_number bigint not null default 1,
  constraint clinic_invoice_counters_positive check (next_number > 0)
);

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  invoice_number text,
  sequence_number bigint,
  document_status public.invoice_document_status not null default 'draft',
  payment_status public.invoice_payment_status not null default 'unpaid',
  currency_code text not null,
  discount_type public.invoice_discount_type not null default 'none',
  discount_value numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  tax_rate numeric(5,2) not null default 0,
  subtotal numeric(14,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  total numeric(14,2) not null default 0,
  paid_amount numeric(14,2) not null default 0,
  outstanding_balance numeric(14,2) not null default 0,
  document_locale public.invoice_document_locale not null default 'en',
  clinical_approved_by uuid references auth.users(id) on delete restrict,
  clinical_approved_at timestamptz,
  prepared_by uuid not null references auth.users(id) on delete restrict,
  finalized_by uuid references auth.users(id) on delete restrict,
  finalized_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete restrict,
  cancelled_at timestamptz,
  cancellation_reason text,
  patient_name_snapshot text,
  patient_number_snapshot text,
  clinic_name_snapshot text,
  revision integer not null default 1,
  financial_revision bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invoices_number_pair check (
    (invoice_number is null and sequence_number is null)
    or (invoice_number is not null and sequence_number is not null and sequence_number > 0)
  ),
  constraint invoices_number_format check (
    invoice_number is null or invoice_number ~ '^[A-Z0-9]{1,12}-[0-9]{5,}$'
  ),
  constraint invoices_currency check (currency_code ~ '^[A-Z]{3}$'),
  constraint invoices_discount check (
    discount_value >= 0 and discount_amount >= 0
    and ((discount_type = 'none' and discount_value = 0 and discount_amount = 0)
      or (discount_type = 'fixed' and discount_value <= subtotal and discount_amount = discount_value)
      or (discount_type = 'percentage' and discount_value <= 100))
  ),
  constraint invoices_amounts check (
    tax_rate between 0 and 100 and subtotal >= 0 and tax_amount >= 0
    and total >= 0 and paid_amount >= 0 and paid_amount <= total
    and outstanding_balance = total - paid_amount
  ),
  constraint invoices_approval_pair check (
    (clinical_approved_by is null and clinical_approved_at is null)
    or (clinical_approved_by is not null and clinical_approved_at is not null)
  ),
  constraint invoices_cancel_reason check (
    cancellation_reason is null or (
      cancellation_reason = btrim(cancellation_reason)
      and char_length(cancellation_reason) between 1 and 1000
    )
  ),
  constraint invoices_revision check (revision > 0 and financial_revision >= 0),
  constraint invoices_status_metadata check (
    (document_status = 'draft'
      and invoice_number is null and finalized_by is null and finalized_at is null
      and cancelled_by is null and cancelled_at is null and cancellation_reason is null
      and patient_name_snapshot is null and patient_number_snapshot is null
      and clinic_name_snapshot is null and paid_amount = 0 and payment_status = 'unpaid')
    or (document_status = 'finalized'
      and invoice_number is not null and finalized_by is not null and finalized_at is not null
      and cancelled_by is null and cancelled_at is null and cancellation_reason is null
      and patient_name_snapshot is not null and patient_number_snapshot is not null
      and clinic_name_snapshot is not null)
    or (document_status = 'cancelled'
      and cancelled_by is not null and cancelled_at is not null and cancellation_reason is not null
      and paid_amount = 0 and payment_status = 'unpaid'
      and ((invoice_number is null and finalized_by is null and finalized_at is null
          and patient_name_snapshot is null and patient_number_snapshot is null
          and clinic_name_snapshot is null)
        or (invoice_number is not null and finalized_by is not null and finalized_at is not null
          and patient_name_snapshot is not null and patient_number_snapshot is not null
          and clinic_name_snapshot is not null)))
  ),
  constraint invoices_payment_status_consistency check (
    (payment_status = 'unpaid' and paid_amount = 0)
    or (payment_status = 'partially_paid' and paid_amount > 0 and paid_amount < total)
    or (payment_status = 'paid' and paid_amount = total and total > 0)
  ),
  constraint invoices_clinic_number_unique unique (clinic_id, invoice_number),
  constraint invoices_clinic_sequence_unique unique (clinic_id, sequence_number)
);

create table public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  source public.invoice_item_source not null,
  procedure_id uuid not null references public.procedures(id) on delete restrict,
  treatment_plan_item_id uuid references public.treatment_plan_items(id) on delete restrict,
  procedure_name_snapshot text not null,
  category_snapshot text not null,
  description_snapshot text,
  tooth_number_snapshot smallint,
  quantity numeric(8,2) not null,
  unit_price numeric(14,2) not null,
  line_total numeric(14,2) not null,
  sort_order integer not null,
  created_at timestamptz not null default now(),
  constraint invoice_items_source check (
    (source = 'catalogue' and treatment_plan_item_id is null)
    or (source = 'treatment_plan_item' and treatment_plan_item_id is not null)
  ),
  constraint invoice_items_name check (
    procedure_name_snapshot = btrim(procedure_name_snapshot)
    and char_length(procedure_name_snapshot) between 1 and 160
  ),
  constraint invoice_items_category check (
    category_snapshot = btrim(category_snapshot)
    and char_length(category_snapshot) between 1 and 100
  ),
  constraint invoice_items_description check (
    description_snapshot is null or (
      description_snapshot = btrim(description_snapshot)
      and char_length(description_snapshot) between 1 and 2000
    )
  ),
  constraint invoice_items_tooth check (
    tooth_number_snapshot is null
    or tooth_number_snapshot between 11 and 18
    or tooth_number_snapshot between 21 and 28
    or tooth_number_snapshot between 31 and 38
    or tooth_number_snapshot between 41 and 48
    or tooth_number_snapshot between 51 and 55
    or tooth_number_snapshot between 61 and 65
    or tooth_number_snapshot between 71 and 75
    or tooth_number_snapshot between 81 and 85
  ),
  constraint invoice_items_amounts check (
    quantity > 0 and quantity <= 999.99 and unit_price >= 0
    and line_total = round(quantity * unit_price, 2)
  ),
  constraint invoice_items_sort check (sort_order >= 0),
  constraint invoice_items_sort_unique unique (invoice_id, sort_order)
);

create table public.invoice_treatment_item_claims (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  treatment_plan_item_id uuid not null references public.treatment_plan_items(id) on delete restrict,
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  constraint invoice_treatment_item_claims_pair unique (treatment_plan_item_id, invoice_id)
);
create unique index invoice_treatment_item_claims_active_idx
  on public.invoice_treatment_item_claims (treatment_plan_item_id)
  where released_at is null;

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  received_for_invoice_id uuid not null references public.invoices(id) on delete restrict,
  amount_received numeric(14,2) not null,
  method public.payment_method not null,
  reference text,
  received_at timestamptz not null,
  recorded_by uuid not null references auth.users(id) on delete restrict,
  command_id uuid not null,
  created_at timestamptz not null default now(),
  constraint payments_amount check (amount_received > 0),
  constraint payments_reference check (
    reference is null or (
      reference = btrim(reference) and char_length(reference) between 1 and 200
    )
  ),
  constraint payments_command_unique unique (clinic_id, command_id)
);

create table public.patient_credit_accounts (
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  currency_code text not null,
  balance numeric(14,2) not null default 0,
  revision bigint not null default 0,
  updated_at timestamptz not null default now(),
  primary key (clinic_id, patient_id, currency_code),
  constraint patient_credit_accounts_currency check (currency_code ~ '^[A-Z]{3}$'),
  constraint patient_credit_accounts_balance check (balance >= 0),
  constraint patient_credit_accounts_revision check (revision >= 0)
);

create table public.financial_ledger_entries (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  invoice_id uuid references public.invoices(id) on delete restrict,
  payment_id uuid references public.payments(id) on delete restrict,
  reverses_entry_id uuid references public.financial_ledger_entries(id) on delete restrict,
  command_id uuid not null,
  kind public.financial_entry_kind not null,
  amount numeric(14,2) not null,
  invoice_delta numeric(14,2) not null default 0,
  credit_delta numeric(14,2) not null default 0,
  reason text,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint financial_ledger_amount check (amount > 0),
  constraint financial_ledger_reason check (
    reason is null or (reason = btrim(reason) and char_length(reason) between 1 and 1000)
  ),
  constraint financial_ledger_shape check (
    (kind = 'payment_applied' and invoice_id is not null and payment_id is not null
      and reverses_entry_id is null and invoice_delta = amount and credit_delta = 0 and reason is null)
    or (kind = 'credit_created' and invoice_id is null and payment_id is not null
      and reverses_entry_id is null and invoice_delta = 0 and credit_delta = amount and reason is null)
    or (kind = 'credit_applied' and invoice_id is not null and payment_id is null
      and reverses_entry_id is null and invoice_delta = amount and credit_delta = -amount and reason is null)
    or (kind = 'credit_application_reversed' and invoice_id is not null and payment_id is null
      and reverses_entry_id is not null and invoice_delta = -amount and credit_delta = amount
      and reason is not null)
    or (kind in ('refund_invoice', 'correction_invoice') and invoice_id is not null
      and payment_id is not null and reverses_entry_id is not null
      and invoice_delta = -amount and credit_delta = 0 and reason is not null)
    or (kind in ('refund_credit', 'correction_credit') and invoice_id is null
      and payment_id is not null and reverses_entry_id is not null
      and invoice_delta = 0 and credit_delta = -amount and reason is not null)
  )
);

create table public.billing_command_receipts (
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  command_id uuid not null,
  action text not null,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  input_hash text not null,
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key (clinic_id, command_id),
  constraint billing_command_receipts_action check (
    action = btrim(action) and action ~ '^[a-z_]{1,80}$'
  ),
  constraint billing_command_receipts_hash check (input_hash ~ '^[0-9a-f]{64}$'),
  constraint billing_command_receipts_response check (jsonb_typeof(response) = 'object')
);

create table public.invoice_documents (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  invoice_id uuid not null references public.invoices(id) on delete restrict,
  financial_revision bigint not null,
  locale public.invoice_document_locale not null,
  template_version smallint not null default 1,
  status public.invoice_document_generation_status not null default 'pending',
  storage_bucket text not null default 'invoice-pdfs',
  storage_object_path text not null unique,
  content_sha256 text,
  size_bytes bigint,
  generated_by uuid not null references auth.users(id) on delete restrict,
  generated_at timestamptz,
  failure_code text,
  created_at timestamptz not null default now(),
  constraint invoice_documents_version check (financial_revision >= 0 and template_version > 0),
  constraint invoice_documents_bucket check (storage_bucket = 'invoice-pdfs'),
  constraint invoice_documents_path check (
    storage_object_path = concat(clinic_id::text, '/', invoice_id::text, '/', id::text, '/invoice.pdf')
  ),
  constraint invoice_documents_hash check (
    content_sha256 is null or content_sha256 ~ '^[0-9a-f]{64}$'
  ),
  constraint invoice_documents_size check (size_bytes is null or size_bytes between 1 and 2097152),
  constraint invoice_documents_failure check (
    failure_code is null or failure_code ~ '^invoice_pdf_[a-z_]{1,80}$'
  ),
  constraint invoice_documents_status_metadata check (
    (status = 'pending' and content_sha256 is null and size_bytes is null
      and generated_at is null and failure_code is null)
    or (status = 'available' and content_sha256 is not null and size_bytes is not null
      and generated_at is not null and failure_code is null)
    or (status = 'failed' and content_sha256 is null and size_bytes is null
      and generated_at is null and failure_code is not null)
  ),
  constraint invoice_documents_version_unique unique (
    invoice_id, financial_revision, locale, template_version
  )
);

create index invoices_clinic_finalized_idx
  on public.invoices (clinic_id, finalized_at desc, id desc);
create index invoices_patient_history_idx
  on public.invoices (clinic_id, patient_id, created_at desc, id desc);
create index invoices_status_idx
  on public.invoices (clinic_id, document_status, payment_status, finalized_at desc);
create index invoice_items_invoice_sort_idx on public.invoice_items (invoice_id, sort_order);
create index invoice_items_procedure_idx on public.invoice_items (procedure_id);
create index invoice_items_treatment_item_idx on public.invoice_items (treatment_plan_item_id)
  where treatment_plan_item_id is not null;
create index invoice_treatment_item_claims_invoice_idx on public.invoice_treatment_item_claims (invoice_id);
create index payments_patient_history_idx on public.payments (clinic_id, patient_id, received_at desc, id desc);
create index payments_invoice_history_idx on public.payments (received_for_invoice_id, received_at desc, id desc);
create index financial_ledger_invoice_idx on public.financial_ledger_entries (invoice_id, created_at, id)
  where invoice_id is not null;
create index financial_ledger_patient_idx on public.financial_ledger_entries (clinic_id, patient_id, created_at, id);
create index financial_ledger_payment_idx on public.financial_ledger_entries (payment_id)
  where payment_id is not null;
create index financial_ledger_reversal_idx on public.financial_ledger_entries (reverses_entry_id)
  where reverses_entry_id is not null;
create index invoice_documents_invoice_idx
  on public.invoice_documents (invoice_id, financial_revision, locale, template_version);

create trigger clinic_billing_settings_set_updated_at before update on public.clinic_billing_settings
for each row execute function private.set_updated_at();
create trigger invoices_set_updated_at before update on public.invoices
for each row execute function private.set_updated_at();
create trigger patient_credit_accounts_set_updated_at before update on public.patient_credit_accounts
for each row execute function private.set_updated_at();

create function private.block_financial_record_change()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  raise exception using errcode = 'P0001', message = 'financial_record_immutable';
end;
$$;

create function private.assert_invoice_scope()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.patients patient
    where patient.id = new.patient_id and patient.clinic_id = new.clinic_id
  ) then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  return new;
end;
$$;

create function private.assert_invoice_item_scope()
returns trigger language plpgsql security definer set search_path = '' as $$
declare target_invoice public.invoices%rowtype;
begin
  select * into target_invoice from public.invoices where id = new.invoice_id;
  if not found or target_invoice.clinic_id <> new.clinic_id then
    raise exception using errcode = 'P0001', message = 'invoice_unavailable';
  end if;
  if not exists (
    select 1 from public.procedures procedure
    where procedure.id = new.procedure_id and procedure.clinic_id = new.clinic_id
  ) then
    raise exception using errcode = 'P0001', message = 'procedure_unavailable';
  end if;
  if new.treatment_plan_item_id is not null and not exists (
    select 1 from public.treatment_plan_items item
    join public.treatment_plans plan on plan.id = item.treatment_plan_id
    where item.id = new.treatment_plan_item_id
      and item.procedure_id = new.procedure_id
      and item.clinic_id = new.clinic_id
      and plan.patient_id = target_invoice.patient_id
  ) then
    raise exception using errcode = 'P0001', message = 'treatment_plan_item_unavailable';
  end if;
  return new;
end;
$$;

create function private.assert_payment_scope()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.invoices invoice
    where invoice.id = new.received_for_invoice_id
      and invoice.clinic_id = new.clinic_id and invoice.patient_id = new.patient_id
  ) then
    raise exception using errcode = 'P0001', message = 'invoice_unavailable';
  end if;
  return new;
end;
$$;

create function private.assert_invoice_document_scope()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.invoices invoice
    where invoice.id = new.invoice_id and invoice.clinic_id = new.clinic_id
      and invoice.patient_id = new.patient_id
      and invoice.document_status = 'finalized'
      and invoice.financial_revision = new.financial_revision
  ) then
    raise exception using errcode = 'P0001', message = 'invoice_unavailable';
  end if;
  return new;
end;
$$;

revoke all on function private.block_financial_record_change() from public;
revoke all on function private.assert_invoice_scope() from public;
revoke all on function private.assert_invoice_item_scope() from public;
revoke all on function private.assert_payment_scope() from public;
revoke all on function private.assert_invoice_document_scope() from public;

create trigger invoices_assert_scope before insert or update of clinic_id, patient_id
on public.invoices for each row execute function private.assert_invoice_scope();
create trigger invoice_items_assert_scope before insert or update of clinic_id, invoice_id, procedure_id, treatment_plan_item_id
on public.invoice_items for each row execute function private.assert_invoice_item_scope();
create trigger payments_assert_scope before insert or update of clinic_id, patient_id, received_for_invoice_id
on public.payments for each row execute function private.assert_payment_scope();
create trigger invoice_documents_assert_scope before insert or update of clinic_id, patient_id, invoice_id, financial_revision
on public.invoice_documents for each row execute function private.assert_invoice_document_scope();

create trigger payments_immutable before update or delete on public.payments
for each row execute function private.block_financial_record_change();
create trigger financial_ledger_immutable before update or delete on public.financial_ledger_entries
for each row execute function private.block_financial_record_change();
create trigger billing_receipts_immutable before update or delete on public.billing_command_receipts
for each row execute function private.block_financial_record_change();

alter table public.clinic_billing_settings enable row level security;
alter table public.clinic_invoice_counters enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.invoice_treatment_item_claims enable row level security;
alter table public.payments enable row level security;
alter table public.patient_credit_accounts enable row level security;
alter table public.financial_ledger_entries enable row level security;
alter table public.billing_command_receipts enable row level security;
alter table public.invoice_documents enable row level security;

revoke all on table public.clinic_billing_settings, public.clinic_invoice_counters,
  public.invoices, public.invoice_items, public.invoice_treatment_item_claims,
  public.payments, public.patient_credit_accounts, public.financial_ledger_entries,
  public.billing_command_receipts, public.invoice_documents from anon, authenticated;
grant select on table public.clinic_billing_settings, public.invoices,
  public.invoice_items, public.payments, public.patient_credit_accounts to authenticated;

create policy "owners read clinic billing settings" on public.clinic_billing_settings
for select to authenticated using (
  private.has_clinic_role(clinic_id, 'owner', (select auth.uid()))
);
create policy "billing staff read invoice summaries" on public.invoices
for select to authenticated using (
  private.has_clinic_role(clinic_id, 'owner', (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'dentist', (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'receptionist', (select auth.uid()))
);
create policy "owners and dentists read invoice items" on public.invoice_items
for select to authenticated using (
  private.has_clinic_role(clinic_id, 'owner', (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'dentist', (select auth.uid()))
);
create policy "owners and receptionists read payments" on public.payments
for select to authenticated using (
  private.has_clinic_role(clinic_id, 'owner', (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'receptionist', (select auth.uid()))
);
create policy "owners and receptionists read patient credit" on public.patient_credit_accounts
for select to authenticated using (
  private.has_clinic_role(clinic_id, 'owner', (select auth.uid()))
  or private.has_clinic_role(clinic_id, 'receptionist', (select auth.uid()))
);
