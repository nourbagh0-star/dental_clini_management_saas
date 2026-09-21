-- Phase 11 protected billing commands. These functions are service-only APIs
-- invoked by authenticated Edge Functions. Each command revalidates its actor.
create function private.require_billing_role(
  target_clinic_id uuid,
  actor_user_id uuid,
  allowed public.clinic_role[]
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from unnest(allowed) role_value
    where private.has_clinic_role(target_clinic_id, role_value, actor_user_id)
  ) then
    raise exception using errcode = 'P0001', message = 'billing_forbidden';
  end if;
end;
$$;

create function public.billing_credit_apply(
  actor_user_id uuid,
  target_invoice_id uuid,
  supplied_amount numeric,
  target_command_id uuid,
  target_input_hash text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  initial_target public.invoices%rowtype;
  target public.invoices%rowtype;
  existing jsonb;
  result jsonb;
  available numeric(14,2);
  next_paid numeric(14,2);
  next_balance numeric(14,2);
  next_credit numeric(14,2);
begin
  initial_target := private.billing_invoice_target(target_invoice_id, false);
  perform private.require_billing_role(
    initial_target.clinic_id, actor_user_id,
    array['owner', 'receptionist']::public.clinic_role[]
  );
  existing := private.billing_existing_receipt(
    initial_target.clinic_id, target_command_id, 'apply_patient_credit', actor_user_id, target_input_hash
  );
  if existing is not null then return existing; end if;
  select balance into available from public.patient_credit_accounts
  where clinic_id = initial_target.clinic_id and patient_id = initial_target.patient_id
    and currency_code = initial_target.currency_code for update;
  if not found then available := 0; end if;
  target := private.billing_invoice_target(target_invoice_id, true);
  if target.document_status <> 'finalized' then
    raise exception using errcode = 'P0001', message = 'invoice_finalized_only';
  end if;
  if supplied_amount <= 0 or supplied_amount > available then
    raise exception using errcode = 'P0001', message = 'insufficient_patient_credit';
  end if;
  if supplied_amount > target.outstanding_balance then
    raise exception using errcode = 'P0001', message = 'credit_exceeds_invoice_balance';
  end if;
  insert into public.financial_ledger_entries (
    clinic_id, patient_id, invoice_id, command_id, kind, amount,
    invoice_delta, credit_delta, created_by
  ) values (
    target.clinic_id, target.patient_id, target.id, target_command_id,
    'credit_applied', supplied_amount, supplied_amount, -supplied_amount, actor_user_id
  );
  next_paid := target.paid_amount + supplied_amount;
  next_balance := target.total - next_paid;
  update public.invoices set
    paid_amount = next_paid, outstanding_balance = next_balance,
    payment_status = private.billing_payment_status(target.total, next_paid),
    financial_revision = financial_revision + 1
  where id = target.id;
  update public.patient_credit_accounts set
    balance = balance - supplied_amount, revision = revision + 1
  where clinic_id = target.clinic_id and patient_id = target.patient_id
    and currency_code = target.currency_code returning balance into next_credit;
  result := jsonb_build_object(
    'applied', supplied_amount::text, 'paidAmount', next_paid::text,
    'outstandingBalance', next_balance::text, 'creditBalance', next_credit::text
  );
  perform private.billing_store_receipt(
    target.clinic_id, target_command_id, 'apply_patient_credit', actor_user_id,
    target_input_hash, result
  );
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'patient_credit_applied', 'invoice', target.id,
    jsonb_build_object(
      'patient_id', target.patient_id, 'currency', target.currency_code,
      'amount', supplied_amount::text, 'command_id', target_command_id
    )
  );
  return result;
exception when check_violation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_credit_application';
end;
$$;

create function public.billing_financial_entry_reverse(
  actor_user_id uuid,
  target_entry_id uuid,
  supplied_amount numeric,
  reversal_action text,
  supplied_reason text,
  target_command_id uuid,
  target_input_hash text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  initial_entry public.financial_ledger_entries%rowtype;
  target_entry public.financial_ledger_entries%rowtype;
  target public.invoices%rowtype;
  existing jsonb;
  result jsonb;
  reversed numeric(14,2);
  remaining numeric(14,2);
  next_paid numeric(14,2);
  next_balance numeric(14,2);
  next_credit numeric(14,2);
  next_kind public.financial_entry_kind;
  invoice_effect numeric(14,2) := 0;
  credit_effect numeric(14,2) := 0;
  payment uuid;
begin
  select * into initial_entry from public.financial_ledger_entries where id = target_entry_id;
  if not found then raise exception using errcode = 'P0001', message = 'financial_entry_unavailable'; end if;
  perform private.require_billing_role(initial_entry.clinic_id, actor_user_id, array['owner']::public.clinic_role[]);
  if reversal_action not in ('refund', 'correction') then
    raise exception using errcode = 'P0001', message = 'invalid_financial_reversal';
  end if;
  existing := private.billing_existing_receipt(
    initial_entry.clinic_id, target_command_id, reversal_action || '_financial_entry',
    actor_user_id, target_input_hash
  );
  if existing is not null then return existing; end if;
  insert into public.patient_credit_accounts (clinic_id, patient_id, currency_code)
  select initial_entry.clinic_id, initial_entry.patient_id, invoice.currency_code
  from public.invoices invoice where invoice.id = initial_entry.invoice_id
  on conflict (clinic_id, patient_id, currency_code) do nothing;
  if initial_entry.invoice_id is null then
    insert into public.patient_credit_accounts (clinic_id, patient_id, currency_code)
    select initial_entry.clinic_id, initial_entry.patient_id, clinic.currency_code
    from public.clinics clinic where clinic.id = initial_entry.clinic_id
    on conflict (clinic_id, patient_id, currency_code) do nothing;
  end if;
  perform 1 from public.patient_credit_accounts account
  where account.clinic_id = initial_entry.clinic_id and account.patient_id = initial_entry.patient_id
  order by account.currency_code for update;
  if initial_entry.invoice_id is not null then
    target := private.billing_invoice_target(initial_entry.invoice_id, true);
  end if;
  select * into target_entry from public.financial_ledger_entries
  where id = target_entry_id for update;
  if target_entry.kind not in ('payment_applied', 'credit_created', 'credit_applied') then
    raise exception using errcode = 'P0001', message = 'financial_entry_not_reversible';
  end if;
  select coalesce(sum(entry.amount), 0) into reversed
  from public.financial_ledger_entries entry where entry.reverses_entry_id = target_entry.id;
  remaining := target_entry.amount - reversed;
  if supplied_amount <= 0 or supplied_amount > remaining then
    raise exception using errcode = 'P0001', message = 'financial_reversal_exceeds_available';
  end if;
  if target_entry.kind = 'payment_applied' then
    next_kind := case when reversal_action = 'refund' then 'refund_invoice'::public.financial_entry_kind
      else 'correction_invoice'::public.financial_entry_kind end;
    invoice_effect := -supplied_amount;
    payment := target_entry.payment_id;
  elsif target_entry.kind = 'credit_created' then
    next_kind := case when reversal_action = 'refund' then 'refund_credit'::public.financial_entry_kind
      else 'correction_credit'::public.financial_entry_kind end;
    credit_effect := -supplied_amount;
    payment := target_entry.payment_id;
  else
    next_kind := 'credit_application_reversed';
    invoice_effect := -supplied_amount;
    credit_effect := supplied_amount;
  end if;
  if credit_effect < 0 and not exists (
    select 1 from public.patient_credit_accounts account
    where account.clinic_id = target_entry.clinic_id and account.patient_id = target_entry.patient_id
      and account.balance >= -credit_effect
  ) then
    raise exception using errcode = 'P0001', message = 'insufficient_patient_credit';
  end if;
  insert into public.financial_ledger_entries (
    clinic_id, patient_id, invoice_id, payment_id, reverses_entry_id,
    command_id, kind, amount, invoice_delta, credit_delta, reason, created_by
  ) values (
    target_entry.clinic_id, target_entry.patient_id, target_entry.invoice_id,
    payment, target_entry.id, target_command_id, next_kind, supplied_amount,
    invoice_effect, credit_effect, nullif(btrim(supplied_reason), ''), actor_user_id
  );
  if invoice_effect <> 0 then
    next_paid := target.paid_amount + invoice_effect;
    next_balance := target.total - next_paid;
    if next_paid < 0 then
      raise exception using errcode = 'P0001', message = 'invalid_financial_reversal';
    end if;
    update public.invoices set
      paid_amount = next_paid, outstanding_balance = next_balance,
      payment_status = private.billing_payment_status(target.total, next_paid),
      financial_revision = financial_revision + 1
    where id = target.id;
  else
    next_paid := 0; next_balance := 0;
  end if;
  if credit_effect <> 0 then
    update public.patient_credit_accounts set
      balance = balance + credit_effect, revision = revision + 1
    where clinic_id = target_entry.clinic_id and patient_id = target_entry.patient_id
    returning balance into next_credit;
  else
    select balance into next_credit from public.patient_credit_accounts
    where clinic_id = target_entry.clinic_id and patient_id = target_entry.patient_id limit 1;
  end if;
  result := jsonb_build_object(
    'entryId', target_entry.id, 'reversed', supplied_amount::text,
    'paidAmount', next_paid::text, 'outstandingBalance', next_balance::text,
    'creditBalance', coalesce(next_credit, 0)::text
  );
  perform private.billing_store_receipt(
    target_entry.clinic_id, target_command_id, reversal_action || '_financial_entry',
    actor_user_id, target_input_hash, result
  );
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target_entry.clinic_id, actor_user_id,
    case when reversal_action = 'refund' then 'payment_refunded' else 'payment_corrected' end,
    'financial_ledger_entry', target_entry.id,
    jsonb_build_object(
      'patient_id', target_entry.patient_id, 'invoice_id', target_entry.invoice_id,
      'amount', supplied_amount::text, 'command_id', target_command_id
    )
  );
  return result;
exception when check_violation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_financial_reversal';
end;
$$;

create function public.billing_invoice_document_claim(
  actor_user_id uuid,
  target_invoice_id uuid,
  supplied_locale public.invoice_document_locale
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare target public.invoices%rowtype; document public.invoice_documents%rowtype; document_id uuid;
begin
  target := private.billing_invoice_target(target_invoice_id, false);
  perform private.require_billing_role(
    target.clinic_id, actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if target.document_status <> 'finalized' then
    raise exception using errcode = 'P0001', message = 'invoice_finalized_only';
  end if;
  select * into document from public.invoice_documents
  where invoice_id = target.id and financial_revision = target.financial_revision
    and locale = supplied_locale and template_version = 1;
  if found and document.status = 'available' then
    return jsonb_build_object(
      'documentId', document.id, 'status', document.status,
      'bucket', document.storage_bucket, 'objectPath', document.storage_object_path
    );
  end if;
  if found and document.status = 'pending'
    and document.created_at > now() - interval '5 minutes' then
    raise exception using errcode = 'P0001', message = 'invoice_pdf_pending';
  end if;
  if found then
    update public.invoice_documents set
      status = 'pending', content_sha256 = null, size_bytes = null,
      generated_at = null, failure_code = null, generated_by = actor_user_id,
      created_at = now()
    where id = document.id;
    document_id := document.id;
  else
    document_id := gen_random_uuid();
    insert into public.invoice_documents (
      id, clinic_id, patient_id, invoice_id, financial_revision, locale,
      storage_object_path, generated_by
    ) values (
      document_id, target.clinic_id, target.patient_id, target.id,
      target.financial_revision, supplied_locale,
      concat(target.clinic_id, '/', target.id, '/', document_id, '/invoice.pdf'),
      actor_user_id
    );
  end if;
  return jsonb_build_object(
    'documentId', document_id, 'status', 'pending', 'bucket', 'invoice-pdfs',
    'objectPath', concat(target.clinic_id, '/', target.id, '/', document_id, '/invoice.pdf')
  );
end;
$$;

create function public.billing_invoice_document_complete(
  actor_user_id uuid,
  target_document_id uuid,
  supplied_sha256 text,
  supplied_size_bytes bigint
)
returns void language plpgsql security definer set search_path = '' as $$
declare document public.invoice_documents%rowtype;
begin
  select * into document from public.invoice_documents where id = target_document_id for update;
  if not found then raise exception using errcode = 'P0001', message = 'invoice_pdf_unavailable'; end if;
  perform private.require_billing_role(
    document.clinic_id, actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if document.status <> 'pending' then
    raise exception using errcode = 'P0001', message = 'invoice_pdf_pending_only';
  end if;
  update public.invoice_documents set
    status = 'available', content_sha256 = lower(supplied_sha256),
    size_bytes = supplied_size_bytes, generated_at = now()
  where id = document.id;
end;
$$;

create function public.billing_invoice_document_fail(
  actor_user_id uuid,
  target_document_id uuid,
  supplied_failure_code text
)
returns void language plpgsql security definer set search_path = '' as $$
declare document public.invoice_documents%rowtype;
begin
  select * into document from public.invoice_documents where id = target_document_id for update;
  if not found then return; end if;
  perform private.require_billing_role(
    document.clinic_id, actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if document.status = 'pending' then
    update public.invoice_documents set status = 'failed',
      failure_code = supplied_failure_code where id = document.id;
  end if;
end;
$$;

create function public.billing_invoice_document_authorize(
  actor_user_id uuid,
  target_document_id uuid
)
returns table(bucket_id text, object_path text) language plpgsql security definer set search_path = '' as $$
declare document public.invoice_documents%rowtype; target public.invoices%rowtype;
begin
  select * into document from public.invoice_documents where id = target_document_id;
  if not found or document.status <> 'available' then
    raise exception using errcode = 'P0001', message = 'invoice_pdf_unavailable';
  end if;
  target := private.billing_invoice_target(document.invoice_id, false);
  perform private.require_billing_role(
    target.clinic_id, actor_user_id,
    array['owner', 'dentist', 'receptionist']::public.clinic_role[]
  );
  if target.document_status <> 'finalized'
    or target.financial_revision <> document.financial_revision then
    raise exception using errcode = 'P0001', message = 'invoice_pdf_stale';
  end if;
  return query select document.storage_bucket, document.storage_object_path;
end;
$$;

create view public.procedure_money_rows with (security_invoker = true) as
select id, clinic_id, name, category, default_price::text as default_price,
  duration_minutes, active from public.procedures;
create view public.treatment_plan_money_rows with (security_invoker = true) as
select id, clinic_id, patient_id, dentist_member_id, status, notes,
  total_estimated_cost::text as total_estimated_cost, updated_at from public.treatment_plans;
create view public.treatment_plan_item_money_rows with (security_invoker = true) as
select id, treatment_plan_id, procedure_id, tooth_number, description,
  estimated_price::text as estimated_price, status, assigned_dentist_id, sort_order
from public.treatment_plan_items;
create view public.billing_invoice_rows with (security_invoker = true) as
select id, clinic_id, patient_id, invoice_number, document_status, payment_status,
  currency_code, discount_type, discount_value::text as discount_value,
  discount_amount::text as discount_amount, tax_rate::text as tax_rate,
  subtotal::text as subtotal, tax_amount::text as tax_amount, total::text as total,
  paid_amount::text as paid_amount, outstanding_balance::text as outstanding_balance,
  document_locale, clinical_approved_by, clinical_approved_at, prepared_by,
  finalized_at, cancelled_at, cancellation_reason, revision, financial_revision,
  created_at, updated_at from public.invoices;
create view public.billing_invoice_item_rows with (security_invoker = true) as
select id, clinic_id, invoice_id, source, procedure_id, treatment_plan_item_id,
  procedure_name_snapshot, category_snapshot, description_snapshot,
  tooth_number_snapshot, quantity::text as quantity, unit_price::text as unit_price,
  line_total::text as line_total, sort_order, created_at from public.invoice_items;
create view public.billing_payment_rows with (security_invoker = true) as
select id, clinic_id, patient_id, received_for_invoice_id,
  amount_received::text as amount_received, method, reference, received_at,
  recorded_by, created_at from public.payments;
create view public.billing_credit_rows with (security_invoker = true) as
select clinic_id, patient_id, currency_code, balance::text as balance,
  revision, updated_at from public.patient_credit_accounts;

revoke all on public.procedure_money_rows, public.treatment_plan_money_rows,
  public.treatment_plan_item_money_rows, public.billing_invoice_rows,
  public.billing_invoice_item_rows, public.billing_payment_rows,
  public.billing_credit_rows from anon, authenticated;
grant select on public.procedure_money_rows, public.treatment_plan_money_rows,
  public.treatment_plan_item_money_rows, public.billing_invoice_rows,
  public.billing_invoice_item_rows, public.billing_payment_rows,
  public.billing_credit_rows to authenticated;

create function private.billing_invoice_target(target_invoice_id uuid, lock_row boolean default false)
returns public.invoices language plpgsql security definer set search_path = '' as $$
declare target public.invoices%rowtype;
begin
  if lock_row then
    select * into target from public.invoices where id = target_invoice_id for update;
  else
    select * into target from public.invoices where id = target_invoice_id;
  end if;
  if not found then
    raise exception using errcode = 'P0001', message = 'invoice_unavailable';
  end if;
  return target;
end;
$$;

create function private.billing_require_draft(target public.invoices, expected_revision integer)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if target.document_status <> 'draft' then
    raise exception using errcode = 'P0001', message = 'invoice_draft_only';
  end if;
  if target.revision <> expected_revision then
    raise exception using errcode = 'P0001', message = 'invoice_revision_conflict';
  end if;
end;
$$;

create function private.billing_payment_status(total numeric, paid numeric)
returns public.invoice_payment_status language sql immutable set search_path = '' as $$
  select case
    when paid = 0 then 'unpaid'::public.invoice_payment_status
    when paid < total then 'partially_paid'::public.invoice_payment_status
    else 'paid'::public.invoice_payment_status
  end;
$$;

create function private.billing_recalculate_draft(target_invoice_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target public.invoices%rowtype;
  next_subtotal numeric(14,2);
  next_discount numeric(14,2);
  next_tax numeric(14,2);
  next_total numeric(14,2);
begin
  target := private.billing_invoice_target(target_invoice_id, true);
  if target.document_status <> 'draft' then
    raise exception using errcode = 'P0001', message = 'invoice_draft_only';
  end if;
  select coalesce(sum(item.line_total), 0)::numeric(14,2)
    into next_subtotal from public.invoice_items item where item.invoice_id = target.id;
  next_discount := case target.discount_type
    when 'none' then 0
    when 'fixed' then least(target.discount_value, next_subtotal)
    else round(next_subtotal * target.discount_value / 100, 2)
  end;
  next_tax := round((next_subtotal - next_discount) * target.tax_rate / 100, 2);
  next_total := next_subtotal - next_discount + next_tax;
  update public.invoices set
    subtotal = next_subtotal,
    discount_amount = next_discount,
    tax_amount = next_tax,
    total = next_total,
    outstanding_balance = next_total
  where id = target.id;
end;
$$;

create function private.billing_existing_receipt(
  target_clinic_id uuid,
  target_command_id uuid,
  target_action text,
  actor_user_id uuid,
  target_input_hash text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare receipt public.billing_command_receipts%rowtype;
begin
  perform pg_advisory_xact_lock(hashtextextended(target_command_id::text, 0));
  select * into receipt from public.billing_command_receipts
  where clinic_id = target_clinic_id and command_id = target_command_id;
  if not found then return null; end if;
  if receipt.action <> target_action or receipt.actor_user_id <> actor_user_id
    or receipt.input_hash <> target_input_hash then
    raise exception using errcode = 'P0001', message = 'billing_command_conflict';
  end if;
  return receipt.response;
end;
$$;

create function private.billing_store_receipt(
  target_clinic_id uuid,
  target_command_id uuid,
  target_action text,
  actor_user_id uuid,
  target_input_hash text,
  target_response jsonb
)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  insert into public.billing_command_receipts (
    clinic_id, command_id, action, actor_user_id, input_hash, response
  ) values (
    target_clinic_id, target_command_id, target_action, actor_user_id,
    target_input_hash, target_response
  );
  return target_response;
end;
$$;

create function public.billing_settings_update(
  actor_user_id uuid,
  target_clinic_id uuid,
  supplied_tax_rate numeric,
  supplied_invoice_prefix text
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.require_billing_role(target_clinic_id, actor_user_id, array['owner']::public.clinic_role[]);
  insert into public.clinic_billing_settings (
    clinic_id, default_tax_rate, invoice_prefix, updated_by
  ) values (
    target_clinic_id, supplied_tax_rate, upper(btrim(supplied_invoice_prefix)), actor_user_id
  ) on conflict (clinic_id) do update set
    default_tax_rate = excluded.default_tax_rate,
    invoice_prefix = excluded.invoice_prefix,
    updated_by = excluded.updated_by;
exception when check_violation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_billing_settings';
end;
$$;

create function public.billing_invoice_create_draft(
  actor_user_id uuid,
  target_patient_id uuid,
  supplied_locale public.invoice_document_locale,
  target_command_id uuid,
  target_input_hash text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  patient public.patients%rowtype;
  clinic public.clinics%rowtype;
  default_tax numeric(5,2);
  result_id uuid;
  existing jsonb;
  result jsonb;
begin
  patient := private.patient_target(target_patient_id, true);
  perform private.require_billing_role(patient.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]);
  existing := private.billing_existing_receipt(
    patient.clinic_id, target_command_id, 'create_invoice_draft', actor_user_id, target_input_hash
  );
  if existing is not null then return existing; end if;
  if patient.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'patient_archived';
  end if;
  select * into clinic from public.clinics where id = patient.clinic_id;
  select coalesce(settings.default_tax_rate, 0) into default_tax
  from (select 1) seed left join public.clinic_billing_settings settings
    on settings.clinic_id = patient.clinic_id;
  insert into public.invoices (
    clinic_id, patient_id, currency_code, tax_rate, document_locale,
    prepared_by
  ) values (
    patient.clinic_id, patient.id, clinic.currency_code, default_tax,
    supplied_locale, actor_user_id
  ) returning id into result_id;
  result := jsonb_build_object('invoiceId', result_id, 'revision', 1);
  perform private.billing_store_receipt(
    patient.clinic_id, target_command_id, 'create_invoice_draft', actor_user_id,
    target_input_hash, result
  );
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    patient.clinic_id, actor_user_id, 'invoice_draft_created', 'invoice', result_id,
    jsonb_build_object('patient_id', patient.id, 'command_id', target_command_id)
  );
  return result;
end;
$$;

create function public.billing_invoice_item_add(
  actor_user_id uuid,
  target_invoice_id uuid,
  target_procedure_id uuid,
  target_treatment_plan_item_id uuid,
  supplied_quantity numeric,
  expected_revision integer
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  target public.invoices%rowtype;
  procedure public.procedures%rowtype;
  plan_item public.treatment_plan_items%rowtype;
  result_id uuid;
  next_sort integer;
  selected_price numeric(14,2);
  selected_description text;
  selected_tooth smallint;
begin
  target := private.billing_invoice_target(target_invoice_id, true);
  perform private.require_billing_role(target.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]);
  perform private.billing_require_draft(target, expected_revision);
  if target.clinical_approved_at is not null then
    raise exception using errcode = 'P0001', message = 'invoice_content_approved';
  end if;
  if (select count(*) from public.invoice_items where invoice_id = target.id) >= 100 then
    raise exception using errcode = 'P0001', message = 'invoice_item_limit';
  end if;
  select * into procedure from public.procedures
  where id = target_procedure_id and clinic_id = target.clinic_id and active;
  if not found then
    raise exception using errcode = 'P0001', message = 'procedure_unavailable';
  end if;
  selected_price := procedure.default_price;
  if target_treatment_plan_item_id is not null then
    select item.* into plan_item
    from public.treatment_plan_items item
    join public.treatment_plans source_plan on source_plan.id = item.treatment_plan_id
    where item.id = target_treatment_plan_item_id
      and item.clinic_id = target.clinic_id
      and item.procedure_id = procedure.id
      and item.status <> 'cancelled'
      and source_plan.patient_id = target.patient_id;
    if not found then
      raise exception using errcode = 'P0001', message = 'treatment_plan_item_unavailable';
    end if;
    insert into public.invoice_treatment_item_claims (
      clinic_id, treatment_plan_item_id, invoice_id
    ) values (target.clinic_id, plan_item.id, target.id);
    selected_price := plan_item.estimated_price;
    selected_description := plan_item.description;
    selected_tooth := plan_item.tooth_number;
  end if;
  select coalesce(max(sort_order) + 1, 0) into next_sort
  from public.invoice_items where invoice_id = target.id;
  insert into public.invoice_items (
    clinic_id, invoice_id, source, procedure_id, treatment_plan_item_id,
    procedure_name_snapshot, category_snapshot, description_snapshot,
    tooth_number_snapshot, quantity, unit_price, line_total, sort_order
  ) values (
    target.clinic_id, target.id,
    case when target_treatment_plan_item_id is null then 'catalogue'::public.invoice_item_source
      else 'treatment_plan_item'::public.invoice_item_source end,
    procedure.id, target_treatment_plan_item_id, procedure.name, procedure.category,
    selected_description, selected_tooth, supplied_quantity, selected_price,
    round(supplied_quantity * selected_price, 2), next_sort
  ) returning id into result_id;
  perform private.billing_recalculate_draft(target.id);
  update public.invoices set revision = revision + 1 where id = target.id;
  return jsonb_build_object('itemId', result_id, 'revision', target.revision + 1);
exception when unique_violation then
  raise exception using errcode = 'P0001', message = 'invoice_treatment_item_already_claimed';
when check_violation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_invoice_item';
end;
$$;

create function public.billing_invoice_content_approval(
  actor_user_id uuid,
  target_invoice_id uuid,
  expected_revision integer,
  approved boolean
)
returns integer language plpgsql security definer set search_path = '' as $$
declare target public.invoices%rowtype;
begin
  target := private.billing_invoice_target(target_invoice_id, true);
  perform private.require_billing_role(target.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]);
  perform private.billing_require_draft(target, expected_revision);
  if approved and not exists (select 1 from public.invoice_items where invoice_id = target.id) then
    raise exception using errcode = 'P0001', message = 'invoice_items_required';
  end if;
  update public.invoices set
    clinical_approved_by = case when approved then actor_user_id else null end,
    clinical_approved_at = case when approved then now() else null end,
    revision = revision + 1
  where id = target.id;
  if approved then
    insert into public.audit_events (
      clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
    ) values (
      target.clinic_id, actor_user_id, 'invoice_content_approved', 'invoice', target.id,
      jsonb_build_object('patient_id', target.patient_id)
    );
  end if;
  return target.revision + 1;
end;
$$;

create function public.billing_invoice_set_financials(
  actor_user_id uuid,
  target_invoice_id uuid,
  supplied_item_prices jsonb,
  supplied_discount_type public.invoice_discount_type,
  supplied_discount_value numeric,
  supplied_tax_rate numeric,
  supplied_locale public.invoice_document_locale,
  expected_revision integer
)
returns integer language plpgsql security definer set search_path = '' as $$
declare
  target public.invoices%rowtype;
  next_subtotal numeric(14,2);
  next_discount numeric(14,2);
  next_tax numeric(14,2);
  next_total numeric(14,2);
  supplied_count integer;
begin
  target := private.billing_invoice_target(target_invoice_id, true);
  perform private.require_billing_role(target.clinic_id, actor_user_id, array['owner']::public.clinic_role[]);
  perform private.billing_require_draft(target, expected_revision);
  if jsonb_typeof(supplied_item_prices) <> 'array' then
    raise exception using errcode = 'P0001', message = 'invalid_invoice_financials';
  end if;
  select count(*) into supplied_count from jsonb_array_elements(supplied_item_prices);
  if supplied_count <> (select count(*) from public.invoice_items where invoice_id = target.id)
    or exists (
      select 1 from jsonb_to_recordset(supplied_item_prices) as price("itemId" uuid, "unitPrice" numeric)
      where price."unitPrice" < 0 or not exists (
        select 1 from public.invoice_items item
        where item.id = price."itemId" and item.invoice_id = target.id
      )
    ) or supplied_count <> (
      select count(distinct price."itemId")
      from jsonb_to_recordset(supplied_item_prices) as price("itemId" uuid, "unitPrice" numeric)
    ) then
    raise exception using errcode = 'P0001', message = 'invalid_invoice_financials';
  end if;
  update public.invoice_items item set
    unit_price = price."unitPrice",
    line_total = round(item.quantity * price."unitPrice", 2)
  from jsonb_to_recordset(supplied_item_prices) as price("itemId" uuid, "unitPrice" numeric)
  where item.id = price."itemId" and item.invoice_id = target.id;
  select coalesce(sum(line_total), 0)::numeric(14,2) into next_subtotal
  from public.invoice_items where invoice_id = target.id;
  next_discount := case supplied_discount_type
    when 'none' then 0
    when 'fixed' then least(supplied_discount_value, next_subtotal)
    else round(next_subtotal * supplied_discount_value / 100, 2)
  end;
  next_tax := round((next_subtotal - next_discount) * supplied_tax_rate / 100, 2);
  next_total := next_subtotal - next_discount + next_tax;
  update public.invoices set
    discount_type = supplied_discount_type,
    discount_value = case when supplied_discount_type = 'none' then 0 else supplied_discount_value end,
    discount_amount = next_discount,
    tax_rate = supplied_tax_rate,
    tax_amount = next_tax,
    subtotal = next_subtotal,
    total = next_total,
    outstanding_balance = next_total,
    document_locale = supplied_locale,
    revision = revision + 1
  where id = target.id;
  return target.revision + 1;
exception when check_violation or invalid_text_representation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_invoice_financials';
end;
$$;

create function public.billing_invoice_finalize(
  actor_user_id uuid,
  target_invoice_id uuid,
  expected_revision integer,
  target_command_id uuid,
  target_input_hash text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  target public.invoices%rowtype;
  patient public.patients%rowtype;
  clinic public.clinics%rowtype;
  prefix text;
  allocated bigint;
  number text;
  existing jsonb;
  result jsonb;
begin
  target := private.billing_invoice_target(target_invoice_id, true);
  perform private.require_billing_role(target.clinic_id, actor_user_id, array['owner']::public.clinic_role[]);
  existing := private.billing_existing_receipt(
    target.clinic_id, target_command_id, 'finalize_invoice', actor_user_id, target_input_hash
  );
  if existing is not null then return existing; end if;
  perform private.billing_require_draft(target, expected_revision);
  if target.clinical_approved_at is null then
    raise exception using errcode = 'P0001', message = 'invoice_clinical_approval_required';
  end if;
  if not exists (select 1 from public.invoice_items where invoice_id = target.id) then
    raise exception using errcode = 'P0001', message = 'invoice_items_required';
  end if;
  select * into patient from public.patients where id = target.patient_id;
  if patient.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'patient_archived';
  end if;
  select * into clinic from public.clinics where id = target.clinic_id;
  select coalesce(settings.invoice_prefix, 'INV') into prefix
  from (select 1) seed left join public.clinic_billing_settings settings
    on settings.clinic_id = target.clinic_id;
  insert into public.clinic_invoice_counters (clinic_id, next_number)
  values (target.clinic_id, 1) on conflict (clinic_id) do nothing;
  select next_number into allocated from public.clinic_invoice_counters
  where clinic_id = target.clinic_id for update;
  update public.clinic_invoice_counters set next_number = allocated + 1
  where clinic_id = target.clinic_id;
  number := prefix || '-' || lpad(allocated::text, 5, '0');
  update public.invoices set
    invoice_number = number,
    sequence_number = allocated,
    document_status = 'finalized',
    patient_name_snapshot = concat_ws(' ', patient.first_name, patient.middle_name, patient.last_name),
    patient_number_snapshot = patient.patient_number,
    clinic_name_snapshot = clinic.name,
    finalized_by = actor_user_id,
    finalized_at = now(),
    revision = revision + 1
  where id = target.id;
  result := jsonb_build_object(
    'invoiceId', target.id, 'invoiceNumber', number,
    'revision', target.revision + 1
  );
  perform private.billing_store_receipt(
    target.clinic_id, target_command_id, 'finalize_invoice', actor_user_id,
    target_input_hash, result
  );
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'invoice_finalized', 'invoice', target.id,
    jsonb_build_object(
      'patient_id', target.patient_id, 'invoice_number', number,
      'currency', target.currency_code, 'total', target.total::text,
      'command_id', target_command_id
    )
  );
  return result;
end;
$$;

create function public.billing_invoice_cancel(
  actor_user_id uuid,
  target_invoice_id uuid,
  expected_revision integer,
  supplied_reason text
)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.invoices%rowtype; owner_allowed boolean; dentist_allowed boolean;
begin
  target := private.billing_invoice_target(target_invoice_id, true);
  owner_allowed := private.has_clinic_role(target.clinic_id, 'owner', actor_user_id);
  dentist_allowed := private.has_clinic_role(target.clinic_id, 'dentist', actor_user_id);
  if target.revision <> expected_revision then
    raise exception using errcode = 'P0001', message = 'invoice_revision_conflict';
  end if;
  if target.document_status = 'draft' and not (owner_allowed or (dentist_allowed and target.prepared_by = actor_user_id)) then
    raise exception using errcode = 'P0001', message = 'billing_forbidden';
  end if;
  if target.document_status = 'finalized' and not owner_allowed then
    raise exception using errcode = 'P0001', message = 'billing_forbidden';
  end if;
  if target.document_status not in ('draft', 'finalized') then
    raise exception using errcode = 'P0001', message = 'invoice_not_cancellable';
  end if;
  if target.paid_amount <> 0 then
    raise exception using errcode = 'P0001', message = 'invoice_nonzero_paid_balance';
  end if;
  update public.invoice_treatment_item_claims set released_at = now()
  where invoice_id = target.id and released_at is null;
  update public.invoices set
    document_status = 'cancelled', cancelled_by = actor_user_id,
    cancelled_at = now(), cancellation_reason = nullif(btrim(supplied_reason), ''),
    payment_status = 'unpaid', revision = revision + 1
  where id = target.id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, reason, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'invoice_cancelled', 'invoice', target.id,
    nullif(btrim(supplied_reason), ''), jsonb_build_object('patient_id', target.patient_id)
  );
exception when check_violation then
  raise exception using errcode = 'P0001', message = 'invalid_invoice_cancellation';
end;
$$;

create function public.billing_payment_record(
  actor_user_id uuid,
  target_invoice_id uuid,
  supplied_amount numeric,
  supplied_method public.payment_method,
  supplied_reference text,
  supplied_received_at timestamptz,
  target_command_id uuid,
  target_input_hash text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  initial_target public.invoices%rowtype;
  target public.invoices%rowtype;
  existing jsonb;
  result jsonb;
  payment_id uuid;
  applied numeric(14,2);
  credit numeric(14,2);
  next_paid numeric(14,2);
  next_balance numeric(14,2);
  next_credit numeric(14,2);
begin
  initial_target := private.billing_invoice_target(target_invoice_id, false);
  perform private.require_billing_role(
    initial_target.clinic_id, actor_user_id,
    array['owner', 'receptionist']::public.clinic_role[]
  );
  existing := private.billing_existing_receipt(
    initial_target.clinic_id, target_command_id, 'record_payment', actor_user_id, target_input_hash
  );
  if existing is not null then return existing; end if;
  insert into public.patient_credit_accounts (clinic_id, patient_id, currency_code)
  values (initial_target.clinic_id, initial_target.patient_id, initial_target.currency_code)
  on conflict (clinic_id, patient_id, currency_code) do nothing;
  perform 1 from public.patient_credit_accounts
  where clinic_id = initial_target.clinic_id and patient_id = initial_target.patient_id
    and currency_code = initial_target.currency_code for update;
  target := private.billing_invoice_target(target_invoice_id, true);
  if target.document_status <> 'finalized' then
    raise exception using errcode = 'P0001', message = 'invoice_finalized_only';
  end if;
  if target.outstanding_balance <= 0 then
    raise exception using errcode = 'P0001', message = 'invoice_already_paid';
  end if;
  if supplied_received_at > now() + interval '5 minutes' then
    raise exception using errcode = 'P0001', message = 'invalid_payment';
  end if;
  applied := least(supplied_amount, target.outstanding_balance);
  credit := supplied_amount - applied;
  insert into public.payments (
    clinic_id, patient_id, received_for_invoice_id, amount_received, method,
    reference, received_at, recorded_by, command_id
  ) values (
    target.clinic_id, target.patient_id, target.id, supplied_amount,
    supplied_method, nullif(btrim(supplied_reference), ''), supplied_received_at,
    actor_user_id, target_command_id
  ) returning id into payment_id;
  insert into public.financial_ledger_entries (
    clinic_id, patient_id, invoice_id, payment_id, command_id, kind,
    amount, invoice_delta, credit_delta, created_by
  ) values (
    target.clinic_id, target.patient_id, target.id, payment_id, target_command_id,
    'payment_applied', applied, applied, 0, actor_user_id
  );
  if credit > 0 then
    insert into public.financial_ledger_entries (
      clinic_id, patient_id, payment_id, command_id, kind,
      amount, invoice_delta, credit_delta, created_by
    ) values (
      target.clinic_id, target.patient_id, payment_id, target_command_id,
      'credit_created', credit, 0, credit, actor_user_id
    );
  end if;
  next_paid := target.paid_amount + applied;
  next_balance := target.total - next_paid;
  update public.invoices set
    paid_amount = next_paid,
    outstanding_balance = next_balance,
    payment_status = private.billing_payment_status(target.total, next_paid),
    financial_revision = financial_revision + 1
  where id = target.id;
  update public.patient_credit_accounts set
    balance = balance + credit, revision = revision + 1
  where clinic_id = target.clinic_id and patient_id = target.patient_id
    and currency_code = target.currency_code returning balance into next_credit;
  result := jsonb_build_object(
    'paymentId', payment_id, 'applied', applied::text, 'creditCreated', credit::text,
    'paidAmount', next_paid::text, 'outstandingBalance', next_balance::text,
    'creditBalance', next_credit::text
  );
  perform private.billing_store_receipt(
    target.clinic_id, target_command_id, 'record_payment', actor_user_id,
    target_input_hash, result
  );
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'payment_recorded', 'payment', payment_id,
    jsonb_build_object(
      'patient_id', target.patient_id, 'invoice_id', target.id,
      'currency', target.currency_code, 'amount', supplied_amount::text,
      'command_id', target_command_id
    )
  );
  if credit > 0 then
    insert into public.audit_events (
      clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
    ) values (
      target.clinic_id, actor_user_id, 'patient_credit_created', 'payment', payment_id,
      jsonb_build_object(
        'patient_id', target.patient_id, 'currency', target.currency_code,
        'amount', credit::text, 'command_id', target_command_id
      )
    );
  end if;
  return result;
exception when check_violation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_payment';
end;
$$;

create function public.billing_invoice_item_update(
  actor_user_id uuid,
  target_item_id uuid,
  supplied_quantity numeric,
  expected_revision integer
)
returns integer language plpgsql security definer set search_path = '' as $$
declare target_item public.invoice_items%rowtype; target public.invoices%rowtype;
begin
  select * into target_item from public.invoice_items where id = target_item_id;
  if not found then raise exception using errcode = 'P0001', message = 'invoice_item_unavailable'; end if;
  target := private.billing_invoice_target(target_item.invoice_id, true);
  perform private.require_billing_role(target.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]);
  perform private.billing_require_draft(target, expected_revision);
  if target.clinical_approved_at is not null then
    raise exception using errcode = 'P0001', message = 'invoice_content_approved';
  end if;
  update public.invoice_items set quantity = supplied_quantity,
    line_total = round(supplied_quantity * unit_price, 2) where id = target_item.id;
  perform private.billing_recalculate_draft(target.id);
  update public.invoices set revision = revision + 1 where id = target.id;
  return target.revision + 1;
exception when check_violation or numeric_value_out_of_range then
  raise exception using errcode = 'P0001', message = 'invalid_invoice_item';
end;
$$;

create function public.billing_invoice_item_remove(
  actor_user_id uuid,
  target_item_id uuid,
  expected_revision integer
)
returns integer language plpgsql security definer set search_path = '' as $$
declare target_item public.invoice_items%rowtype; target public.invoices%rowtype;
begin
  select * into target_item from public.invoice_items where id = target_item_id;
  if not found then raise exception using errcode = 'P0001', message = 'invoice_item_unavailable'; end if;
  target := private.billing_invoice_target(target_item.invoice_id, true);
  perform private.require_billing_role(target.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]);
  perform private.billing_require_draft(target, expected_revision);
  if target.clinical_approved_at is not null then
    raise exception using errcode = 'P0001', message = 'invoice_content_approved';
  end if;
  update public.invoice_treatment_item_claims set released_at = now()
  where invoice_id = target.id and treatment_plan_item_id = target_item.treatment_plan_item_id
    and released_at is null;
  delete from public.invoice_items where id = target_item.id;
  perform private.billing_recalculate_draft(target.id);
  update public.invoices set revision = revision + 1 where id = target.id;
  return target.revision + 1;
end;
$$;

revoke all on function private.require_billing_role(uuid,uuid,public.clinic_role[]) from public;
revoke all on function private.billing_invoice_target(uuid,boolean) from public;
revoke all on function private.billing_require_draft(public.invoices,integer) from public;
revoke all on function private.billing_payment_status(numeric,numeric) from public;
revoke all on function private.billing_recalculate_draft(uuid) from public;
revoke all on function private.billing_existing_receipt(uuid,uuid,text,uuid,text) from public;
revoke all on function private.billing_store_receipt(uuid,uuid,text,uuid,text,jsonb) from public;

revoke all on function public.billing_settings_update(uuid,uuid,numeric,text),
  public.billing_invoice_create_draft(uuid,uuid,public.invoice_document_locale,uuid,text),
  public.billing_invoice_item_add(uuid,uuid,uuid,uuid,numeric,integer),
  public.billing_invoice_item_update(uuid,uuid,numeric,integer),
  public.billing_invoice_item_remove(uuid,uuid,integer),
  public.billing_invoice_content_approval(uuid,uuid,integer,boolean),
  public.billing_invoice_set_financials(uuid,uuid,jsonb,public.invoice_discount_type,numeric,numeric,public.invoice_document_locale,integer),
  public.billing_invoice_finalize(uuid,uuid,integer,uuid,text),
  public.billing_invoice_cancel(uuid,uuid,integer,text),
  public.billing_payment_record(uuid,uuid,numeric,public.payment_method,text,timestamptz,uuid,text),
  public.billing_credit_apply(uuid,uuid,numeric,uuid,text),
  public.billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text),
  public.billing_invoice_document_claim(uuid,uuid,public.invoice_document_locale),
  public.billing_invoice_document_complete(uuid,uuid,text,bigint),
  public.billing_invoice_document_fail(uuid,uuid,text),
  public.billing_invoice_document_authorize(uuid,uuid)
from public, anon, authenticated;

grant execute on function public.billing_settings_update(uuid,uuid,numeric,text),
  public.billing_invoice_create_draft(uuid,uuid,public.invoice_document_locale,uuid,text),
  public.billing_invoice_item_add(uuid,uuid,uuid,uuid,numeric,integer),
  public.billing_invoice_item_update(uuid,uuid,numeric,integer),
  public.billing_invoice_item_remove(uuid,uuid,integer),
  public.billing_invoice_content_approval(uuid,uuid,integer,boolean),
  public.billing_invoice_set_financials(uuid,uuid,jsonb,public.invoice_discount_type,numeric,numeric,public.invoice_document_locale,integer),
  public.billing_invoice_finalize(uuid,uuid,integer,uuid,text),
  public.billing_invoice_cancel(uuid,uuid,integer,text),
  public.billing_payment_record(uuid,uuid,numeric,public.payment_method,text,timestamptz,uuid,text),
  public.billing_credit_apply(uuid,uuid,numeric,uuid,text),
  public.billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text),
  public.billing_invoice_document_claim(uuid,uuid,public.invoice_document_locale),
  public.billing_invoice_document_complete(uuid,uuid,text,bigint),
  public.billing_invoice_document_fail(uuid,uuid,text),
  public.billing_invoice_document_authorize(uuid,uuid)
to service_role;
