-- Phase 12: auditable treatment completion time and one bounded, role-aware
-- active-clinic dashboard snapshot.

alter table public.treatment_plan_items
  add column completed_at timestamptz,
  add column completed_by uuid references auth.users(id) on delete restrict;

update public.treatment_plan_items item
set completed_at = item.updated_at,
    completed_by = member.user_id
from public.treatment_plans plan
join public.clinic_members member on member.id = plan.dentist_member_id
where plan.id = item.treatment_plan_id
  and item.status = 'completed'::public.treatment_plan_item_status;

alter table public.treatment_plan_items
  add constraint treatment_plan_items_completion_metadata check (
    (status = 'completed'::public.treatment_plan_item_status
      and completed_at is not null and completed_by is not null)
    or
    (status <> 'completed'::public.treatment_plan_item_status
      and completed_at is null and completed_by is null)
  );

create index treatment_plan_items_dashboard_completed_idx
  on public.treatment_plan_items (clinic_id, completed_at)
  where status = 'completed'::public.treatment_plan_item_status;

create index invoices_dashboard_outstanding_idx
  on public.invoices (clinic_id) include (outstanding_balance)
  where document_status = 'finalized'::public.invoice_document_status
    and outstanding_balance > 0;

create or replace function public.treatment_plan_item_transition(
  actor_user_id uuid,
  target_item_id uuid,
  next_status public.treatment_plan_item_status
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.treatment_plan_items%rowtype;
  plan public.treatment_plans%rowtype;
begin
  target := private.treatment_plan_item_target(target_item_id, true);
  plan := private.treatment_plan_target(target.treatment_plan_id, true);
  perform private.require_treatment_plan_role(
    plan.clinic_id,
    actor_user_id,
    array['dentist']::public.clinic_role[]
  );
  if plan.status <> 'active'::public.treatment_plan_status then
    raise exception using errcode = 'P0001',
      message = 'treatment_plan_active_required';
  end if;
  if not (
    (target.status = 'planned'::public.treatment_plan_item_status and
      next_status in (
        'approved'::public.treatment_plan_item_status,
        'in_progress'::public.treatment_plan_item_status,
        'cancelled'::public.treatment_plan_item_status
      ))
    or
    (target.status = 'approved'::public.treatment_plan_item_status and
      next_status in (
        'in_progress'::public.treatment_plan_item_status,
        'cancelled'::public.treatment_plan_item_status
      ))
    or
    (target.status = 'in_progress'::public.treatment_plan_item_status and
      next_status in (
        'completed'::public.treatment_plan_item_status,
        'cancelled'::public.treatment_plan_item_status
      ))
  ) then
    raise exception using errcode = 'P0001',
      message = 'invalid_treatment_plan_item_transition';
  end if;
  update public.treatment_plan_items
  set status = next_status,
      completed_at = case
        when next_status = 'completed'::public.treatment_plan_item_status
          then now()
        else null
      end,
      completed_by = case
        when next_status = 'completed'::public.treatment_plan_item_status
          then actor_user_id
        else null
      end
  where id = target.id;
  perform private.recalculate_treatment_plan_total(plan.id);
end;
$$;

create function private.dashboard_snapshot_at(
  actor_user_id uuid,
  target_clinic_id uuid,
  reference_at timestamptz
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  clinic public.clinics%rowtype;
  local_reference timestamp;
  today_date date;
  today_start timestamptz;
  tomorrow_start timestamptz;
  upcoming_end timestamptz;
  week_start timestamptz;
  week_end timestamptz;
  month_start timestamptz;
  next_month_start timestamptz;
  can_view_completed boolean;
  can_view_financial boolean;
  today_count bigint;
  upcoming_count bigint;
  total_patients bigint;
  appointments_this_week bigint;
  completed_this_month bigint;
  outstanding_invoice_count bigint;
  outstanding_amount numeric(14,2);
  today_items jsonb;
  upcoming_items jsonb;
  metrics jsonb;
begin
  if reference_at is null then
    raise exception using errcode = 'P0001', message = 'invalid_dashboard_request';
  end if;
  select * into clinic from public.clinics where id = target_clinic_id;
  if not found or not private.is_active_clinic_member(
    target_clinic_id, actor_user_id
  ) then
    raise exception using errcode = 'P0001', message = 'dashboard_forbidden';
  end if;

  can_view_completed :=
    private.has_clinic_role(target_clinic_id, 'owner', actor_user_id)
    or private.has_clinic_role(target_clinic_id, 'dentist', actor_user_id);
  can_view_financial := can_view_completed
    or private.has_clinic_role(
      target_clinic_id, 'receptionist', actor_user_id
    );

  local_reference := reference_at at time zone clinic.time_zone;
  today_date := local_reference::date;
  today_start := today_date::timestamp at time zone clinic.time_zone;
  tomorrow_start := (today_date + 1)::timestamp at time zone clinic.time_zone;
  upcoming_end := (today_date + 8)::timestamp at time zone clinic.time_zone;
  week_start := date_trunc('week', local_reference) at time zone clinic.time_zone;
  week_end := (date_trunc('week', local_reference) + interval '7 days')
    at time zone clinic.time_zone;
  month_start := date_trunc('month', local_reference)
    at time zone clinic.time_zone;
  next_month_start := (date_trunc('month', local_reference) + interval '1 month')
    at time zone clinic.time_zone;

  select count(*) into today_count
  from public.appointments appointment
  where appointment.clinic_id = target_clinic_id
    and appointment.starts_at >= today_start
    and appointment.starts_at < tomorrow_start
    and appointment.status <> 'cancelled'::public.appointment_status;

  select coalesce(jsonb_agg(preview.value order by preview.starts_at, preview.id), '[]'::jsonb)
  into today_items
  from (
    select appointment.id, appointment.starts_at,
      jsonb_build_object(
        'id', appointment.id,
        'patientId', appointment.patient_id,
        'patientName', concat_ws(
          ' ', patient.first_name, patient.middle_name, patient.last_name
        ),
        'patientNumber', patient.patient_number,
        'dentistMemberId', appointment.dentist_member_id,
        'dentistLabel', dentist.email,
        'startsAt', appointment.starts_at,
        'endsAt', appointment.ends_at,
        'status', appointment.status
      ) as value
    from public.appointments appointment
    join public.patients patient on patient.id = appointment.patient_id
    join public.clinic_members dentist on dentist.id = appointment.dentist_member_id
    where appointment.clinic_id = target_clinic_id
      and appointment.starts_at >= today_start
      and appointment.starts_at < tomorrow_start
      and appointment.status <> 'cancelled'::public.appointment_status
    order by appointment.starts_at, appointment.id
    limit 12
  ) preview;

  select count(*) into upcoming_count
  from public.appointments appointment
  where appointment.clinic_id = target_clinic_id
    and appointment.starts_at >= tomorrow_start
    and appointment.starts_at < upcoming_end
    and appointment.status in (
      'scheduled'::public.appointment_status,
      'confirmed'::public.appointment_status
    );

  select coalesce(jsonb_agg(preview.value order by preview.starts_at, preview.id), '[]'::jsonb)
  into upcoming_items
  from (
    select appointment.id, appointment.starts_at,
      jsonb_build_object(
        'id', appointment.id,
        'patientId', appointment.patient_id,
        'patientName', concat_ws(
          ' ', patient.first_name, patient.middle_name, patient.last_name
        ),
        'patientNumber', patient.patient_number,
        'dentistMemberId', appointment.dentist_member_id,
        'dentistLabel', dentist.email,
        'startsAt', appointment.starts_at,
        'endsAt', appointment.ends_at,
        'status', appointment.status
      ) as value
    from public.appointments appointment
    join public.patients patient on patient.id = appointment.patient_id
    join public.clinic_members dentist on dentist.id = appointment.dentist_member_id
    where appointment.clinic_id = target_clinic_id
      and appointment.starts_at >= tomorrow_start
      and appointment.starts_at < upcoming_end
      and appointment.status in (
        'scheduled'::public.appointment_status,
        'confirmed'::public.appointment_status
      )
    order by appointment.starts_at, appointment.id
    limit 10
  ) preview;

  select count(*) into total_patients
  from public.patients patient
  where patient.clinic_id = target_clinic_id and patient.archived_at is null;

  select count(*) into appointments_this_week
  from public.appointments appointment
  where appointment.clinic_id = target_clinic_id
    and appointment.starts_at >= week_start
    and appointment.starts_at < week_end
    and appointment.status <> 'cancelled'::public.appointment_status;

  metrics := jsonb_build_object(
    'totalPatients', total_patients,
    'appointmentsThisWeek', appointments_this_week
  );

  if can_view_completed then
    select count(*) into completed_this_month
    from public.treatment_plan_items item
    where item.clinic_id = target_clinic_id
      and item.status = 'completed'::public.treatment_plan_item_status
      and item.completed_at >= month_start
      and item.completed_at < next_month_start;
    metrics := metrics || jsonb_build_object(
      'completedTreatmentsThisMonth', completed_this_month
    );
  end if;

  if can_view_financial then
    select count(*), coalesce(sum(invoice.outstanding_balance), 0)::numeric(14,2)
    into outstanding_invoice_count, outstanding_amount
    from public.invoices invoice
    where invoice.clinic_id = target_clinic_id
      and invoice.document_status = 'finalized'::public.invoice_document_status
      and invoice.outstanding_balance > 0;
    metrics := metrics || jsonb_build_object(
      'financial', jsonb_build_object(
        'outstandingInvoiceCount', outstanding_invoice_count,
        'outstandingAmount', to_char(
          outstanding_amount, 'FM9999999999990.00'
        ),
        'currencyCode', clinic.currency_code
      )
    );
  end if;

  return jsonb_build_object(
    'clinicId', clinic.id,
    'clinicTimeZone', clinic.time_zone,
    'generatedAt', reference_at,
    'periods', jsonb_build_object(
      'todayStart', today_start,
      'tomorrowStart', tomorrow_start,
      'upcomingEnd', upcoming_end,
      'weekStart', week_start,
      'weekEnd', week_end,
      'monthStart', month_start,
      'nextMonthStart', next_month_start
    ),
    'capabilities', jsonb_build_object(
      'canViewCompletedTreatments', can_view_completed,
      'canViewFinancialSummary', can_view_financial
    ),
    'metrics', metrics,
    'todayAppointments', jsonb_build_object(
      'totalCount', today_count,
      'hasMore', today_count > 12,
      'items', today_items
    ),
    'upcomingAppointments', jsonb_build_object(
      'totalCount', upcoming_count,
      'hasMore', upcoming_count > 10,
      'items', upcoming_items
    )
  );
end;
$$;

create function public.dashboard_snapshot(
  actor_user_id uuid,
  target_clinic_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select private.dashboard_snapshot_at(
    actor_user_id, target_clinic_id, statement_timestamp()
  );
$$;

revoke all on function private.dashboard_snapshot_at(uuid, uuid, timestamptz)
  from public, anon, authenticated, service_role;
revoke all on function public.dashboard_snapshot(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.dashboard_snapshot(uuid, uuid)
  to service_role;
