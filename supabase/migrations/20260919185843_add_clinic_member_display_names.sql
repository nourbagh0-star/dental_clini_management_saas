-- Clinic memberships are the operational identity used throughout the app.
-- Login email remains contact data; display_name is what staff and patients see.
alter table public.clinic_members
  add column display_name text not null default 'Team member';

update public.clinic_members
set display_name = case
  when char_length(split_part(email, '@', 1)) >= 2 then left(
    initcap(replace(replace(split_part(email, '@', 1), '.', ' '), '_', ' ')),
    120
  )
  else 'Team member'
end
where display_name = 'Team member';

alter table public.clinic_members
  add constraint clinic_members_display_name_valid check (
    display_name = btrim(display_name)
    and char_length(display_name) between 2 and 120
  );

-- The owner membership is made by the clinic creation trigger, so name it
-- immediately after the clinic is inserted in the protected command.
drop function public.security_workspace_create_clinic(uuid, text, text, text);
create function public.security_workspace_create_clinic(
  actor_user_id uuid,
  supplied_name text,
  supplied_currency_code text,
  supplied_time_zone text,
  supplied_owner_display_name text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result public.clinics%rowtype;
begin
  if not exists (select 1 from auth.users where id = actor_user_id) then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;
  if supplied_owner_display_name <> btrim(supplied_owner_display_name)
    or char_length(supplied_owner_display_name) not between 2 and 120 then
    raise exception using errcode = 'P0001', message = 'invalid_workspace_input';
  end if;
  insert into public.clinics (name, currency_code, time_zone, created_by)
  values (
    btrim(supplied_name), upper(btrim(supplied_currency_code)),
    btrim(supplied_time_zone), actor_user_id
  ) returning * into result;
  update public.clinic_members
  set display_name = btrim(supplied_owner_display_name)
  where clinic_id = result.id and user_id = actor_user_id;
  return jsonb_build_object(
    'id', result.id, 'name', result.name,
    'currency_code', result.currency_code, 'time_zone', result.time_zone
  );
exception when check_violation or not_null_violation or string_data_right_truncation then
  raise exception using errcode = 'P0001', message = 'invalid_workspace_input';
end;
$$;
revoke all on function public.security_workspace_create_clinic(uuid, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.security_workspace_create_clinic(uuid, text, text, text, text)
  to service_role;

-- Owner-created accounts carry a server-controlled name in app metadata while
-- the provisioning trigger atomically creates their membership and roles.
create or replace function private.provision_owner_created_staff()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  setup jsonb := new.raw_app_meta_data -> 'staff_setup';
  owner_id uuid;
  setup_clinic_id uuid;
  member_id uuid;
  chosen_roles public.clinic_role[];
  supplied_display_name text;
begin
  if setup is null then return new; end if;
  if exists(select 1 from private.staff_account_setup where user_id = new.id) then return new; end if;
  owner_id := (setup ->> 'owner_id')::uuid;
  setup_clinic_id := (setup ->> 'clinic_id')::uuid;
  supplied_display_name := setup ->> 'display_name';
  perform public.staff_account_create_assert(owner_id, (setup ->> 'session_id')::uuid, setup_clinic_id);
  select array_agg(distinct value::public.clinic_role) into chosen_roles
    from jsonb_array_elements_text(setup -> 'roles');
  if coalesce(cardinality(chosen_roles), 0) not between 1 and 4
    or supplied_display_name is null
    or supplied_display_name <> btrim(supplied_display_name)
    or char_length(supplied_display_name) not between 2 and 120
    or new.encrypted_password is null or new.encrypted_password = '' then
    raise exception 'staff_creation_invalid';
  end if;
  insert into private.staff_account_setup(user_id, clinic_id, created_by, initial_password_hash)
    values (new.id, setup_clinic_id, owner_id, new.encrypted_password);
  insert into public.clinic_members(clinic_id, user_id, email, display_name, is_active)
    values (setup_clinic_id, new.id, lower(btrim(new.email)), supplied_display_name, true)
    returning id into member_id;
  insert into public.clinic_member_roles(clinic_member_id, role, assigned_by)
    select member_id, unnest(chosen_roles), owner_id;
  insert into public.audit_events(clinic_id, actor_user_id, event_type, subject_type, subject_id,
    safe_metadata, category, actor_member_id, actor_email_snapshot, actor_roles_snapshot)
    select setup_clinic_id, owner_id, 'staff_account_created', 'clinic_member', member_id,
      '{}'::jsonb, 'staff_security', m.id, m.email,
      array(select r.role from public.clinic_member_roles r where r.clinic_member_id = m.id)
    from public.clinic_members m where m.clinic_id = setup_clinic_id and m.user_id = owner_id;
  return new;
end;
$$;

drop function public.doctor_schedule_readable_dentists(uuid);
create function public.doctor_schedule_readable_dentists(target_clinic_id uuid)
returns table (member_id uuid, display_name text)
language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_active_clinic_member(target_clinic_id, (select auth.uid())) then
    return;
  end if;
  return query
  select member.id, member.display_name
  from public.clinic_members member
  join public.clinic_member_roles member_role
    on member_role.clinic_member_id = member.id
  where member.clinic_id = target_clinic_id
    and member.is_active
    and member_role.role = 'dentist'::public.clinic_role
  order by member.display_name;
end;
$$;
revoke all on function public.doctor_schedule_readable_dentists(uuid)
  from public, anon;
grant execute on function public.doctor_schedule_readable_dentists(uuid)
  to authenticated;
