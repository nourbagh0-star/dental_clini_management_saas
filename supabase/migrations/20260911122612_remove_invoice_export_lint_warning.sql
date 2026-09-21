create or replace function public.billing_invoice_document_exported(
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
