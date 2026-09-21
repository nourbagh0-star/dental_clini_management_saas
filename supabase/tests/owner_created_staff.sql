-- Run inside a transaction; all fixtures must be rolled back.
do $$
declare
  owner_id uuid := gen_random_uuid();
  owner_session uuid := gen_random_uuid();
  v_clinic_id uuid := gen_random_uuid();
  staff_id uuid := gen_random_uuid();
  staff_session uuid := gen_random_uuid();
  new_session uuid := gen_random_uuid();
  outsider uuid := gen_random_uuid();
  outsider_session uuid := gen_random_uuid();
  rejected_id uuid := gen_random_uuid();
  metadata jsonb;
begin
  if has_function_privilege('authenticated', 'public.staff_password_setup_complete(uuid,uuid)', 'execute')
    or has_table_privilege('authenticated', 'private.staff_account_setup', 'select')
    or has_table_privilege('service_role', 'private.staff_account_setup', 'select') then
    raise exception 'FAIL: setup privileges';
  end if;
  insert into auth.users(id,email) values
    (owner_id, owner_id::text || '@example.test'), (outsider, outsider::text || '@example.test');
  insert into auth.sessions(id,user_id,created_at,updated_at) values
    (owner_session,owner_id,clock_timestamp(),clock_timestamp()),
    (outsider_session,outsider,clock_timestamp(),clock_timestamp());
  insert into public.clinics(id,name,currency_code,time_zone,created_by)
    values(v_clinic_id,'Fictional staff setup test','USD','Asia/Damascus',owner_id);
  perform public.security_session_open(owner_id,owner_session);
  perform public.security_session_open(outsider,outsider_session);
  metadata := jsonb_build_object('staff_setup',jsonb_build_object(
    'owner_id',owner_id,'clinic_id',v_clinic_id,'session_id',owner_session,'roles',jsonb_build_array('dentist')));
  insert into auth.users(id,email,encrypted_password,raw_app_meta_data)
    values(staff_id,staff_id::text || '@example.test','fictional-initial-hash',metadata);
  if not exists(select 1 from public.clinic_members m join public.clinic_member_roles r
    on m.id = r.clinic_member_id where m.user_id = staff_id and m.clinic_id = v_clinic_id and r.role = 'dentist') then
    raise exception 'FAIL: membership';
  end if;
  if not exists(select 1 from public.audit_events e where e.clinic_id = v_clinic_id
    and e.event_type = 'staff_account_created' and e.safe_metadata = '{}'::jsonb) then
    raise exception 'FAIL: audit';
  end if;
  insert into auth.sessions(id,user_id,created_at,updated_at)
    values(staff_session,staff_id,clock_timestamp(),clock_timestamp());
  if not public.staff_password_setup_pending(staff_id,staff_session) then raise exception 'FAIL: pending'; end if;
  begin
    perform public.security_session_open(staff_id,staff_session);
    raise exception 'FAIL: temporary credentials opened clinic';
  exception when raise_exception then
    if sqlerrm <> 'security_session_revoked' then raise; end if;
  end;
  begin
    perform public.staff_password_setup_complete(staff_id,staff_session);
    raise exception 'FAIL: unchanged password completed setup';
  exception when raise_exception then
    if sqlerrm <> 'password_change_required' then raise; end if;
  end;
  update auth.users set raw_user_meta_data = '{"password_change_required":false}' where id = staff_id;
  if not public.staff_password_setup_pending(staff_id,staff_session) then raise exception 'FAIL: metadata bypass'; end if;
  update auth.users set encrypted_password = 'fictional-replacement-hash' where id = staff_id;
  perform public.staff_password_setup_complete(staff_id,staff_session);
  if public.staff_password_setup_pending(staff_id,staff_session) then raise exception 'FAIL: still pending'; end if;
  if private.security_live_auth_session(staff_id,staff_session) then raise exception 'FAIL: old session survives'; end if;
  if exists(select 1 from private.staff_account_setup s where s.user_id = staff_id and s.initial_password_hash is not null) then
    raise exception 'FAIL: baseline retained';
  end if;
  insert into auth.sessions(id,user_id,created_at,updated_at)
    values(new_session,staff_id,clock_timestamp(),clock_timestamp());
  perform public.security_session_open(staff_id,new_session);
  perform public.security_session_assert(staff_id,new_session);
  begin
    insert into auth.users(id,email,encrypted_password,raw_app_meta_data)
      values(rejected_id,rejected_id::text || '@example.test','fictional',jsonb_build_object('staff_setup',jsonb_build_object(
        'owner_id',outsider,'clinic_id',v_clinic_id,'session_id',outsider_session,'roles',jsonb_build_array('owner'))));
    raise exception 'FAIL: non-owner created staff';
  exception when raise_exception then
    if sqlerrm <> 'staff_creation_forbidden' then raise; end if;
  end;
  if exists(select 1 from auth.users where id = rejected_id) then raise exception 'FAIL: partial account left behind'; end if;
end;
$$;
select 'Staff setup, role isolation, audit, password gate, session invalidation, and rollback checks passed' as result;
