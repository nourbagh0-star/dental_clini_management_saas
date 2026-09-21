grant select on table public.financial_ledger_entries to authenticated;
create policy "owners read financial ledger" on public.financial_ledger_entries
for select to authenticated using (
  private.has_clinic_role(clinic_id, 'owner', (select auth.uid()))
);

create view public.billing_invoice_list_rows with (security_invoker = true) as
select invoice.id, invoice.clinic_id, invoice.patient_id,
  coalesce(invoice.patient_name_snapshot,
    concat_ws(' ', patient.first_name, patient.middle_name, patient.last_name))
    as patient_display_name,
  coalesce(invoice.patient_number_snapshot, patient.patient_number)
    as patient_display_number,
  invoice.invoice_number, invoice.document_status, invoice.payment_status,
  invoice.currency_code, invoice.total::text as total,
  invoice.paid_amount::text as paid_amount,
  invoice.outstanding_balance::text as outstanding_balance,
  invoice.document_locale, invoice.clinical_approved_at, invoice.prepared_by,
  invoice.finalized_at, invoice.cancelled_at, invoice.revision,
  invoice.financial_revision, invoice.created_at, invoice.updated_at
from public.invoices invoice
join public.patients patient on patient.id = invoice.patient_id;

revoke all on table public.billing_invoice_list_rows from anon, authenticated;
grant select on table public.billing_invoice_list_rows to authenticated;

create function public.billing_eligible_treatment_items(
  actor_user_id uuid,
  target_patient_id uuid
)
returns table(
  item_id uuid,
  procedure_id uuid,
  procedure_name text,
  tooth_number smallint,
  description text,
  estimated_price text,
  item_status public.treatment_plan_item_status
) language plpgsql security definer set search_path = '' as $$
declare patient public.patients%rowtype;
begin
  patient := private.patient_target(target_patient_id, false);
  perform private.require_billing_role(
    patient.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]
  );
  return query
  select item.id, item.procedure_id, procedure.name, item.tooth_number,
    item.description, item.estimated_price::text, item.status
  from public.treatment_plan_items item
  join public.treatment_plans plan on plan.id = item.treatment_plan_id
  join public.procedures procedure on procedure.id = item.procedure_id
  where plan.patient_id = patient.id
    and item.status <> 'cancelled'
    and not exists (
      select 1 from public.invoice_treatment_item_claims claim
      where claim.treatment_plan_item_id = item.id and claim.released_at is null
    )
  order by plan.updated_at desc, item.sort_order, item.id;
end;
$$;

create function public.billing_invoice_document_exported(
  actor_user_id uuid,
  target_document_id uuid
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform * from public.billing_invoice_document_authorize(
    actor_user_id, target_document_id
  );
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  )
  select document.clinic_id, actor_user_id, 'invoice_pdf_exported',
    'invoice_document', document.id,
    jsonb_build_object(
      'invoice_id', document.invoice_id,
      'financial_revision', document.financial_revision,
      'locale', document.locale
    )
  from public.invoice_documents document where document.id = target_document_id;
end;
$$;

revoke all on function public.billing_eligible_treatment_items(uuid,uuid),
  public.billing_invoice_document_exported(uuid,uuid)
from public, anon, authenticated;
grant execute on function public.billing_eligible_treatment_items(uuid,uuid),
  public.billing_invoice_document_exported(uuid,uuid)
to service_role;
