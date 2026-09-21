create function public.billing_financial_entries(
  actor_user_id uuid,
  target_invoice_id uuid
)
returns table(
  entry_id uuid,
  kind public.financial_entry_kind,
  amount text,
  reversible_remaining text,
  reason text,
  created_at timestamptz
) language plpgsql security definer set search_path = '' as $$
declare target public.invoices%rowtype;
begin
  target := private.billing_invoice_target(target_invoice_id, false);
  perform private.require_billing_role(
    target.clinic_id, actor_user_id, array['owner']::public.clinic_role[]
  );
  return query
  select entry.id, entry.kind, entry.amount::text,
    greatest(
      entry.amount - coalesce((
        select sum(reversal.amount)
        from public.financial_ledger_entries reversal
        where reversal.reverses_entry_id = entry.id
      ), 0),
      0
    )::text,
    entry.reason, entry.created_at
  from public.financial_ledger_entries entry
  left join public.payments payment on payment.id = entry.payment_id
  where coalesce(entry.invoice_id, payment.received_for_invoice_id) = target.id
  order by entry.created_at desc, entry.id desc;
end;
$$;

revoke all on function public.billing_financial_entries(uuid,uuid)
from public, anon, authenticated;
grant execute on function public.billing_financial_entries(uuid,uuid)
to service_role;
