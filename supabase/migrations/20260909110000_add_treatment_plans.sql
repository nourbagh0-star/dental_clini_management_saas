-- Phase 8: owner-managed procedures and dentist-managed clinical treatment plans.
create type public.treatment_plan_status as enum ('draft', 'active', 'completed', 'cancelled');
create type public.treatment_plan_item_status as enum ('planned', 'approved', 'in_progress', 'completed', 'cancelled');

create table public.procedures (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  name text not null,
  category text not null,
  default_price numeric(12,2) not null,
  duration_minutes smallint not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint procedures_name check (name = btrim(name) and char_length(name) between 1 and 160),
  constraint procedures_category check (category = btrim(category) and char_length(category) between 1 and 100),
  constraint procedures_price check (default_price >= 0),
  constraint procedures_duration check (duration_minutes between 5 and 720)
);
create unique index procedures_clinic_name_normalized_idx on public.procedures (clinic_id, lower(name));
create index procedures_clinic_active_name_idx on public.procedures (clinic_id, active, name);

create table public.treatment_plans (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  dentist_member_id uuid not null references public.clinic_members(id) on delete restrict,
  status public.treatment_plan_status not null default 'draft',
  notes text,
  total_estimated_cost numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint treatment_plans_notes check (notes is null or (notes = btrim(notes) and char_length(notes) between 1 and 5000)),
  constraint treatment_plans_total check (total_estimated_cost >= 0)
);
create unique index treatment_plans_one_active_per_patient_idx
  on public.treatment_plans (patient_id) where status = 'active'::public.treatment_plan_status;
create index treatment_plans_clinic_patient_updated_idx on public.treatment_plans (clinic_id, patient_id, updated_at desc, id desc);

create table public.treatment_plan_items (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  treatment_plan_id uuid not null references public.treatment_plans(id) on delete restrict,
  procedure_id uuid not null references public.procedures(id) on delete restrict,
  tooth_number smallint,
  description text,
  estimated_price numeric(12,2) not null,
  status public.treatment_plan_item_status not null default 'planned',
  assigned_dentist_id uuid references public.clinic_members(id) on delete restrict,
  sort_order integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint treatment_plan_items_fdi check (tooth_number is null or tooth_number between 11 and 18 or tooth_number between 21 and 28 or tooth_number between 31 and 38 or tooth_number between 41 and 48 or tooth_number between 51 and 55 or tooth_number between 61 and 65 or tooth_number between 71 and 75 or tooth_number between 81 and 85),
  constraint treatment_plan_items_description check (description is null or (description = btrim(description) and char_length(description) between 1 and 2000)),
  constraint treatment_plan_items_price check (estimated_price >= 0),
  constraint treatment_plan_items_sort check (sort_order >= 0)
);
create unique index treatment_plan_items_sort_order_idx on public.treatment_plan_items (treatment_plan_id, sort_order);

create trigger procedures_set_updated_at before update on public.procedures for each row execute function private.set_updated_at();
create trigger treatment_plans_set_updated_at before update on public.treatment_plans for each row execute function private.set_updated_at();
create trigger treatment_plan_items_set_updated_at before update on public.treatment_plan_items for each row execute function private.set_updated_at();

alter table public.procedures enable row level security;
alter table public.treatment_plans enable row level security;
alter table public.treatment_plan_items enable row level security;
revoke all on table public.procedures, public.treatment_plans, public.treatment_plan_items from anon, authenticated;
grant select on table public.procedures, public.treatment_plans, public.treatment_plan_items to authenticated;

create policy "active members read clinic procedures" on public.procedures for select to authenticated using (private.is_active_clinic_member(clinic_id, (select auth.uid())));
create policy "active members read clinic treatment plans" on public.treatment_plans for select to authenticated using (private.is_active_clinic_member(clinic_id, (select auth.uid())));
create policy "active members read clinic treatment plan items" on public.treatment_plan_items for select to authenticated using (private.is_active_clinic_member(clinic_id, (select auth.uid())));

create function private.require_treatment_plan_role(target_clinic_id uuid, actor_user_id uuid, allowed public.clinic_role[])
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from unnest(allowed) as role_value where private.has_clinic_role(target_clinic_id, role_value, actor_user_id)) then
    raise exception using errcode = 'P0001', message = 'treatment_plan_edit_forbidden';
  end if;
end; $$;

create function private.treatment_plan_target(target_plan_id uuid, lock_row boolean default false)
returns public.treatment_plans language plpgsql security definer set search_path = '' as $$
declare target public.treatment_plans%rowtype;
begin
  if lock_row then select * into target from public.treatment_plans where id = target_plan_id for update; else select * into target from public.treatment_plans where id = target_plan_id; end if;
  if not found then raise exception using errcode = 'P0001', message = 'treatment_plan_unavailable'; end if;
  return target;
end; $$;

create function private.treatment_plan_item_target(target_item_id uuid, lock_row boolean default false)
returns public.treatment_plan_items language plpgsql security definer set search_path = '' as $$
declare target public.treatment_plan_items%rowtype;
begin
  if lock_row then select * into target from public.treatment_plan_items where id = target_item_id for update; else select * into target from public.treatment_plan_items where id = target_item_id; end if;
  if not found then raise exception using errcode = 'P0001', message = 'treatment_plan_item_unavailable'; end if;
  return target;
end; $$;

create function private.recalculate_treatment_plan_total(target_plan_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.treatment_plans set total_estimated_cost = coalesce((select sum(estimated_price) from public.treatment_plan_items where treatment_plan_id = target_plan_id and status <> 'cancelled'::public.treatment_plan_item_status), 0) where id = target_plan_id;
end; $$;

create function private.assert_treatment_plan_item_scope()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.treatment_plans plan where plan.id = new.treatment_plan_id and plan.clinic_id = new.clinic_id) then raise exception using errcode = 'P0001', message = 'treatment_plan_scope_mismatch'; end if;
  if not exists (select 1 from public.procedures procedure where procedure.id = new.procedure_id and procedure.clinic_id = new.clinic_id) then raise exception using errcode = 'P0001', message = 'procedure_scope_mismatch'; end if;
  if new.assigned_dentist_id is not null and not exists (select 1 from public.clinic_members member join public.clinic_member_roles role on role.clinic_member_id = member.id where member.id = new.assigned_dentist_id and member.clinic_id = new.clinic_id and member.is_active and role.role = 'dentist'::public.clinic_role) then raise exception using errcode = 'P0001', message = 'assigned_dentist_unavailable'; end if;
  return new;
end; $$;
create trigger treatment_plan_items_match_scope before insert or update of clinic_id, treatment_plan_id, procedure_id, assigned_dentist_id on public.treatment_plan_items for each row execute function private.assert_treatment_plan_item_scope();

create function public.procedure_create(actor_user_id uuid, target_clinic_id uuid, input jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare result_id uuid;
begin
  perform private.require_treatment_plan_role(target_clinic_id, actor_user_id, array['owner']::public.clinic_role[]);
  insert into public.procedures (clinic_id, name, category, default_price, duration_minutes) values (target_clinic_id, nullif(btrim(input->>'name'), ''), nullif(btrim(input->>'category'), ''), (input->>'defaultPrice')::numeric, (input->>'durationMinutes')::smallint) returning id into result_id;
  return result_id;
exception when check_violation or unique_violation or invalid_text_representation or numeric_value_out_of_range then raise exception using errcode = 'P0001', message = 'invalid_procedure_input'; end; $$;

create function public.procedure_update(actor_user_id uuid, target_procedure_id uuid, input jsonb)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.procedures%rowtype;
begin
  select * into target from public.procedures where id = target_procedure_id for update;
  if not found then raise exception using errcode = 'P0001', message = 'procedure_unavailable'; end if;
  perform private.require_treatment_plan_role(target.clinic_id, actor_user_id, array['owner']::public.clinic_role[]);
  update public.procedures set name = nullif(btrim(input->>'name'), ''), category = nullif(btrim(input->>'category'), ''), default_price = (input->>'defaultPrice')::numeric, duration_minutes = (input->>'durationMinutes')::smallint where id = target.id;
exception when check_violation or unique_violation or invalid_text_representation or numeric_value_out_of_range then raise exception using errcode = 'P0001', message = 'invalid_procedure_input'; end; $$;

create function public.procedure_set_active(actor_user_id uuid, target_procedure_id uuid, next_active boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.procedures%rowtype;
begin select * into target from public.procedures where id = target_procedure_id for update; if not found then raise exception using errcode = 'P0001', message = 'procedure_unavailable'; end if; perform private.require_treatment_plan_role(target.clinic_id, actor_user_id, array['owner']::public.clinic_role[]); update public.procedures set active = next_active where id = target.id; end; $$;

create function public.treatment_plan_create(actor_user_id uuid, target_patient_id uuid, target_dentist_member_id uuid, plan_notes text default null)
returns uuid language plpgsql security definer set search_path = '' as $$
declare patient public.patients%rowtype; result_id uuid;
begin
  patient := private.patient_target(target_patient_id, true); perform private.require_treatment_plan_role(patient.clinic_id, actor_user_id, array['dentist']::public.clinic_role[]);
  if patient.archived_at is not null then raise exception using errcode = 'P0001', message = 'patient_unavailable'; end if;
  if not exists (select 1 from public.clinic_members member join public.clinic_member_roles role on role.clinic_member_id=member.id where member.id=target_dentist_member_id and member.clinic_id=patient.clinic_id and member.is_active and role.role='dentist'::public.clinic_role) then raise exception using errcode = 'P0001', message = 'assigned_dentist_unavailable'; end if;
  insert into public.treatment_plans (clinic_id, patient_id, dentist_member_id, notes) values (patient.clinic_id, patient.id, target_dentist_member_id, nullif(btrim(plan_notes), '')) returning id into result_id; return result_id;
exception when check_violation then raise exception using errcode='P0001', message='invalid_treatment_plan_input'; end; $$;

create function public.treatment_plan_update_draft(actor_user_id uuid, target_plan_id uuid, plan_notes text)
returns void language plpgsql security definer set search_path = '' as $$ declare target public.treatment_plans%rowtype; begin target:=private.treatment_plan_target(target_plan_id,true); perform private.require_treatment_plan_role(target.clinic_id,actor_user_id,array['dentist']::public.clinic_role[]); if target.status <> 'draft'::public.treatment_plan_status then raise exception using errcode='P0001',message='treatment_plan_draft_only'; end if; update public.treatment_plans set notes=nullif(btrim(plan_notes),'') where id=target.id; exception when check_violation then raise exception using errcode='P0001',message='invalid_treatment_plan_input'; end; $$;

create function public.treatment_plan_transition(actor_user_id uuid, target_plan_id uuid, next_status public.treatment_plan_status)
returns void language plpgsql security definer set search_path = '' as $$ declare target public.treatment_plans%rowtype; begin target:=private.treatment_plan_target(target_plan_id,true); perform private.require_treatment_plan_role(target.clinic_id,actor_user_id,array['dentist']::public.clinic_role[]); if (target.status='draft'::public.treatment_plan_status and next_status not in ('active'::public.treatment_plan_status,'cancelled'::public.treatment_plan_status)) or (target.status='active'::public.treatment_plan_status and next_status not in ('completed'::public.treatment_plan_status,'cancelled'::public.treatment_plan_status)) then raise exception using errcode='P0001',message='invalid_treatment_plan_transition'; end if; if next_status='active'::public.treatment_plan_status and not exists (select 1 from public.treatment_plan_items where treatment_plan_id=target.id and status <> 'cancelled'::public.treatment_plan_item_status) then raise exception using errcode='P0001',message='treatment_plan_items_required'; end if; update public.treatment_plans set status=next_status where id=target.id; end; $$;

create function public.treatment_plan_item_add(actor_user_id uuid, target_plan_id uuid, input jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare target public.treatment_plans%rowtype; result_id uuid; target_procedure public.procedures%rowtype; price numeric(12,2); next_sort integer;
begin
  target:=private.treatment_plan_target(target_plan_id,true); perform private.require_treatment_plan_role(target.clinic_id,actor_user_id,array['dentist']::public.clinic_role[]); if target.status <> 'draft'::public.treatment_plan_status then raise exception using errcode='P0001',message='treatment_plan_draft_only'; end if;
  select * into target_procedure from public.procedures where id=(input->>'procedureId')::uuid and clinic_id=target.clinic_id and active=true; if not found then raise exception using errcode='P0001',message='procedure_unavailable'; end if;
  price:=coalesce(nullif(input->>'estimatedPrice','')::numeric,target_procedure.default_price); select coalesce(max(sort_order)+1,0) into next_sort from public.treatment_plan_items where treatment_plan_id=target.id;
  insert into public.treatment_plan_items (clinic_id,treatment_plan_id,procedure_id,tooth_number,description,estimated_price,assigned_dentist_id,sort_order) values (target.clinic_id,target.id,target_procedure.id,nullif(input->>'toothNumber','')::smallint,nullif(btrim(input->>'description'),''),price,nullif(input->>'assignedDentistId','')::uuid,next_sort) returning id into result_id; perform private.recalculate_treatment_plan_total(target.id); return result_id;
exception when check_violation or invalid_text_representation or numeric_value_out_of_range then raise exception using errcode='P0001',message='invalid_treatment_plan_item_input'; end; $$;

create function public.treatment_plan_item_transition(actor_user_id uuid, target_item_id uuid, next_status public.treatment_plan_item_status)
returns void language plpgsql security definer set search_path = '' as $$ declare target public.treatment_plan_items%rowtype; plan public.treatment_plans%rowtype; begin target:=private.treatment_plan_item_target(target_item_id,true); plan:=private.treatment_plan_target(target.treatment_plan_id,true); perform private.require_treatment_plan_role(plan.clinic_id,actor_user_id,array['dentist']::public.clinic_role[]); if plan.status <> 'active'::public.treatment_plan_status then raise exception using errcode='P0001',message='treatment_plan_active_required'; end if; if (target.status='planned'::public.treatment_plan_item_status and next_status not in ('approved'::public.treatment_plan_item_status,'in_progress'::public.treatment_plan_item_status,'cancelled'::public.treatment_plan_item_status)) or (target.status='approved'::public.treatment_plan_item_status and next_status not in ('in_progress'::public.treatment_plan_item_status,'cancelled'::public.treatment_plan_item_status)) or (target.status='in_progress'::public.treatment_plan_item_status and next_status not in ('completed'::public.treatment_plan_item_status,'cancelled'::public.treatment_plan_item_status)) then raise exception using errcode='P0001',message='invalid_treatment_plan_item_transition'; end if; update public.treatment_plan_items set status=next_status where id=target.id; perform private.recalculate_treatment_plan_total(plan.id); end; $$;

revoke all on function private.require_treatment_plan_role(uuid,uuid,public.clinic_role[]) from public;
revoke all on function private.treatment_plan_target(uuid,boolean) from public;
revoke all on function private.treatment_plan_item_target(uuid,boolean) from public;
revoke all on function private.recalculate_treatment_plan_total(uuid) from public;
revoke all on function private.assert_treatment_plan_item_scope() from public;
revoke all on function public.procedure_create(uuid,uuid,jsonb), public.procedure_update(uuid,uuid,jsonb), public.procedure_set_active(uuid,uuid,boolean), public.treatment_plan_create(uuid,uuid,uuid,text), public.treatment_plan_update_draft(uuid,uuid,text), public.treatment_plan_transition(uuid,uuid,public.treatment_plan_status), public.treatment_plan_item_add(uuid,uuid,jsonb), public.treatment_plan_item_transition(uuid,uuid,public.treatment_plan_item_status) from public,anon,authenticated;
grant execute on function public.procedure_create(uuid,uuid,jsonb), public.procedure_update(uuid,uuid,jsonb), public.procedure_set_active(uuid,uuid,boolean), public.treatment_plan_create(uuid,uuid,uuid,text), public.treatment_plan_update_draft(uuid,uuid,text), public.treatment_plan_transition(uuid,uuid,public.treatment_plan_status), public.treatment_plan_item_add(uuid,uuid,jsonb), public.treatment_plan_item_transition(uuid,uuid,public.treatment_plan_item_status) to service_role;
