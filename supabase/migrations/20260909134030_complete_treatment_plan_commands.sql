-- Completes the Phase 8 draft editing API and returns a stable error when a
-- patient already has another active treatment plan.
create or replace function public.treatment_plan_transition(
  actor_user_id uuid,
  target_plan_id uuid,
  next_status public.treatment_plan_status
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.treatment_plans%rowtype;
begin
  target := private.treatment_plan_target(target_plan_id, true);
  perform private.require_treatment_plan_role(
    target.clinic_id,
    actor_user_id,
    array['dentist']::public.clinic_role[]
  );
  if (target.status = 'draft'::public.treatment_plan_status
      and next_status not in ('active'::public.treatment_plan_status, 'cancelled'::public.treatment_plan_status))
    or (target.status = 'active'::public.treatment_plan_status
      and next_status not in ('completed'::public.treatment_plan_status, 'cancelled'::public.treatment_plan_status)) then
    raise exception using errcode = 'P0001', message = 'invalid_treatment_plan_transition';
  end if;
  if next_status = 'active'::public.treatment_plan_status then
    if not exists (
      select 1 from public.treatment_plan_items
      where treatment_plan_id = target.id
        and status <> 'cancelled'::public.treatment_plan_item_status
    ) then
      raise exception using errcode = 'P0001', message = 'treatment_plan_items_required';
    end if;
    if exists (
      select 1 from public.treatment_plans plan
      where plan.patient_id = target.patient_id
        and plan.id <> target.id
        and plan.status = 'active'::public.treatment_plan_status
    ) then
      raise exception using errcode = 'P0001', message = 'treatment_plan_active_exists';
    end if;
  end if;
  update public.treatment_plans set status = next_status where id = target.id;
end;
$$;

create function public.treatment_plan_item_update_draft(
  actor_user_id uuid,
  target_item_id uuid,
  input jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.treatment_plan_items%rowtype;
  plan public.treatment_plans%rowtype;
  target_procedure public.procedures%rowtype;
begin
  target := private.treatment_plan_item_target(target_item_id, true);
  plan := private.treatment_plan_target(target.treatment_plan_id, true);
  perform private.require_treatment_plan_role(
    plan.clinic_id,
    actor_user_id,
    array['dentist']::public.clinic_role[]
  );
  if plan.status <> 'draft'::public.treatment_plan_status then
    raise exception using errcode = 'P0001', message = 'treatment_plan_draft_only';
  end if;
  select * into target_procedure
  from public.procedures
  where id = (input ->> 'procedureId')::uuid
    and clinic_id = plan.clinic_id
    and active;
  if not found then
    raise exception using errcode = 'P0001', message = 'procedure_unavailable';
  end if;
  update public.treatment_plan_items
  set procedure_id = target_procedure.id,
      tooth_number = nullif(input ->> 'toothNumber', '')::smallint,
      description = nullif(btrim(input ->> 'description'), ''),
      estimated_price = coalesce(
        nullif(input ->> 'estimatedPrice', '')::numeric,
        target_procedure.default_price
      ),
      assigned_dentist_id = nullif(input ->> 'assignedDentistId', '')::uuid
  where id = target.id;
  perform private.recalculate_treatment_plan_total(plan.id);
exception
  when check_violation or invalid_text_representation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_treatment_plan_item_input';
end;
$$;

create function public.treatment_plan_items_reorder_draft(
  actor_user_id uuid,
  target_plan_id uuid,
  ordered_item_ids jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.treatment_plans%rowtype;
  expected_count integer;
begin
  target := private.treatment_plan_target(target_plan_id, true);
  perform private.require_treatment_plan_role(
    target.clinic_id,
    actor_user_id,
    array['dentist']::public.clinic_role[]
  );
  if target.status <> 'draft'::public.treatment_plan_status then
    raise exception using errcode = 'P0001', message = 'treatment_plan_draft_only';
  end if;
  if jsonb_typeof(ordered_item_ids) <> 'array' then
    raise exception using errcode = 'P0001', message = 'invalid_treatment_plan_item_order';
  end if;
  select count(*) into expected_count
  from public.treatment_plan_items
  where treatment_plan_id = target.id;
  if jsonb_array_length(ordered_item_ids) <> expected_count
    or (select count(distinct value) from jsonb_array_elements_text(ordered_item_ids)) <> expected_count
    or exists (
      select 1 from jsonb_array_elements_text(ordered_item_ids) entry(value)
      where not exists (
        select 1 from public.treatment_plan_items item
        where item.id = entry.value::uuid and item.treatment_plan_id = target.id
      )
    ) then
    raise exception using errcode = 'P0001', message = 'invalid_treatment_plan_item_order';
  end if;
  update public.treatment_plan_items
  set sort_order = sort_order + 100000
  where treatment_plan_id = target.id;
  update public.treatment_plan_items item
  set sort_order = ordered.ordinality - 1
  from jsonb_array_elements_text(ordered_item_ids) with ordinality as ordered(value, ordinality)
  where item.id = ordered.value::uuid
    and item.treatment_plan_id = target.id;
end;
$$;

revoke all on function public.treatment_plan_item_update_draft(uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke all on function public.treatment_plan_items_reorder_draft(uuid, uuid, jsonb)
  from public, anon, authenticated;
grant execute on function public.treatment_plan_item_update_draft(uuid, uuid, jsonb)
  to service_role;
grant execute on function public.treatment_plan_items_reorder_draft(uuid, uuid, jsonb)
  to service_role;
