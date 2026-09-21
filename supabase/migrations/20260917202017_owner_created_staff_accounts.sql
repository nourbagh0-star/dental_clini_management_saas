-- Credentials remain in Auth. This private baseline is needed only until setup
-- completes, and is never exposed to application roles or audit records.
create table private.staff_account_setup (
  user_id uuid primary key references auth.users(id) on delete cascade,
  clinic_id uuid not null references public.clinics(id),
  created_by uuid not null references auth.users(id),
  initial_password_hash text,
  created_at timestamptz not null default clock_timestamp(),
  completed_at timestamptz,
  check ((completed_at is null and initial_password_hash is not null)
    or (completed_at is not null and initial_password_hash is null))
);
alter table private.staff_account_setup enable row level security;
create index staff_account_setup_creator_time_idx on private.staff_account_setup(created_by, created_at);
revoke all on private.staff_account_setup from public, anon, authenticated, service_role;

create function public.staff_account_create_assert(actor_user_id uuid, target_session_id uuid, target_clinic_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform public.security_session_assert(actor_user_id, target_session_id);
  if not private.has_clinic_role(target_clinic_id, 'owner', actor_user_id) then
    raise exception 'staff_creation_forbidden';
  end if;
  perform 1 from public.clinics where id = target_clinic_id for update;
  if (select count(*) from private.staff_account_setup where created_by = actor_user_id
      and created_at > statement_timestamp() - interval '1 hour') >= 20 then
    raise exception 'staff_creation_rate_limited';
  end if;
end;
$$;

create or replace function private.provision_owner_created_staff()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  setup jsonb := new.raw_app_meta_data -> 'staff_setup';
  owner_id uuid;
  setup_clinic_id uuid;
  member_id uuid;
  chosen_roles public.clinic_role[];
begin
  if setup is null then return new; end if;
  if exists(select 1 from private.staff_account_setup where user_id = new.id) then return new; end if;
  owner_id := (setup ->> 'owner_id')::uuid;
  setup_clinic_id := (setup ->> 'clinic_id')::uuid;
  perform public.staff_account_create_assert(owner_id, (setup ->> 'session_id')::uuid, setup_clinic_id);
  select array_agg(distinct value::public.clinic_role) into chosen_roles
    from jsonb_array_elements_text(setup -> 'roles');
  if coalesce(cardinality(chosen_roles), 0) not between 1 and 4
    or new.encrypted_password is null or new.encrypted_password = '' then
    raise exception 'staff_creation_invalid';
  end if;
  insert into private.staff_account_setup(user_id, clinic_id, created_by, initial_password_hash)
    values (new.id, setup_clinic_id, owner_id, new.encrypted_password);
  insert into public.clinic_members(clinic_id, user_id, email, is_active)
    values (setup_clinic_id, new.id, lower(btrim(new.email)), true) returning id into member_id;
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
revoke all on function private.provision_owner_created_staff() from public, anon, authenticated, service_role;
create trigger provision_owner_created_staff after insert or update of raw_app_meta_data on auth.users
for each row execute function private.provision_owner_created_staff();

create function public.staff_password_setup_pending(actor_user_id uuid, target_session_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  if not exists(select 1 from auth.sessions where id = target_session_id and user_id = actor_user_id) then
    raise exception 'security_session_revoked';
  end if;
  return exists(select 1 from private.staff_account_setup where user_id = actor_user_id and completed_at is null);
end;
$$;

create function public.staff_password_setup_complete(actor_user_id uuid, target_session_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare setup private.staff_account_setup%rowtype; current_hash text;
begin
  perform public.staff_password_setup_pending(actor_user_id, target_session_id);
  select * into setup from private.staff_account_setup where user_id = actor_user_id for update;
  if not found then raise exception 'password_setup_unavailable'; end if;
  if setup.completed_at is not null then return; end if;
  select encrypted_password into current_hash from auth.users where id = actor_user_id;
  if current_hash is null or current_hash = '' or current_hash = setup.initial_password_hash then
    raise exception 'password_change_required';
  end if;
  update private.staff_account_setup set initial_password_hash = null, completed_at = clock_timestamp()
    where user_id = actor_user_id;
  delete from private.security_session_leases where user_id = actor_user_id;
end;
$$;

create or replace function private.security_live_auth_session(actor_user_id uuid, target_session_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from auth.sessions s
    where s.id = target_session_id and s.user_id = actor_user_id
      and not exists (select 1 from private.staff_account_setup setup
        where setup.user_id = actor_user_id
          and (setup.completed_at is null or s.created_at <= setup.completed_at))
  );
$$;
revoke all on function public.staff_account_create_assert(uuid,uuid,uuid),
  public.staff_password_setup_pending(uuid,uuid), public.staff_password_setup_complete(uuid,uuid)
  from public, anon, authenticated;
grant execute on function public.staff_account_create_assert(uuid,uuid,uuid),
  public.staff_password_setup_pending(uuid,uuid), public.staff_password_setup_complete(uuid,uuid)
  to service_role;
