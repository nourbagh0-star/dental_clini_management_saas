-- Phase 14: server-recognized Auth sessions and ten-minute privacy leases.
create table private.security_session_leases (
  session_id uuid primary key references auth.sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  unlocked_until timestamptz not null,
  last_renewed_at timestamptz not null,
  locked_at timestamptz,
  revision integer not null default 1,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint security_session_lease_revision check (revision > 0),
  constraint security_session_lease_time check (
    unlocked_until >= last_renewed_at
  )
);

create index security_session_leases_expiry_idx
  on private.security_session_leases (unlocked_until)
  where locked_at is null;

create function private.security_live_auth_session(
  actor_user_id uuid,
  target_session_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from auth.sessions session
    where session.id = target_session_id
      and session.user_id = actor_user_id
  );
$$;

create function public.security_session_open(
  actor_user_id uuid,
  target_session_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare result private.security_session_leases%rowtype;
begin
  if not private.security_live_auth_session(actor_user_id, target_session_id) then
    raise exception using errcode = 'P0001', message = 'security_session_revoked';
  end if;
  insert into private.security_session_leases (
    session_id, user_id, unlocked_until, last_renewed_at, locked_at
  ) values (
    target_session_id, actor_user_id,
    statement_timestamp() + interval '10 minutes', statement_timestamp(), null
  )
  on conflict (session_id) do update set
    user_id = excluded.user_id,
    unlocked_until = excluded.unlocked_until,
    last_renewed_at = excluded.last_renewed_at,
    locked_at = null,
    revision = private.security_session_leases.revision + 1,
    updated_at = statement_timestamp()
  returning * into result;
  return jsonb_build_object(
    'unlockedUntil', result.unlocked_until,
    'revision', result.revision
  );
end;
$$;

create function public.security_session_renew(
  actor_user_id uuid,
  target_session_id uuid,
  expected_revision integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare result private.security_session_leases%rowtype;
begin
  if not private.security_live_auth_session(actor_user_id, target_session_id) then
    raise exception using errcode = 'P0001', message = 'security_session_revoked';
  end if;
  update private.security_session_leases lease set
    unlocked_until = statement_timestamp() + interval '10 minutes',
    last_renewed_at = statement_timestamp(),
    revision = lease.revision + 1,
    updated_at = statement_timestamp()
  where lease.session_id = target_session_id
    and lease.user_id = actor_user_id
    and lease.locked_at is null
    and lease.unlocked_until > statement_timestamp()
    and lease.revision = expected_revision
  returning * into result;
  if not found then
    raise exception using errcode = 'P0001', message = 'security_session_locked';
  end if;
  return jsonb_build_object(
    'unlockedUntil', result.unlocked_until,
    'revision', result.revision
  );
end;
$$;

create function public.security_session_lock(
  actor_user_id uuid,
  target_session_id uuid
)
returns void
language sql
security definer
set search_path = ''
as $$
  update private.security_session_leases lease set
    locked_at = statement_timestamp(),
    updated_at = statement_timestamp(),
    revision = lease.revision + 1
  where lease.session_id = target_session_id
    and lease.user_id = actor_user_id;
$$;

create function public.security_session_assert(
  actor_user_id uuid,
  target_session_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare result private.security_session_leases%rowtype;
begin
  if not private.security_live_auth_session(actor_user_id, target_session_id) then
    raise exception using errcode = 'P0001', message = 'security_session_revoked';
  end if;
  select * into result from private.security_session_leases lease
  where lease.session_id = target_session_id
    and lease.user_id = actor_user_id
    and lease.locked_at is null
    and lease.unlocked_until > statement_timestamp();
  if not found then
    raise exception using errcode = 'P0001', message = 'security_session_locked';
  end if;
  return jsonb_build_object(
    'unlockedUntil', result.unlocked_until,
    'revision', result.revision
  );
end;
$$;

revoke all on table private.security_session_leases
  from public, anon, authenticated, service_role;
revoke all on function private.security_live_auth_session(uuid,uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.security_session_open(uuid,uuid),
  public.security_session_renew(uuid,uuid,integer),
  public.security_session_lock(uuid,uuid),
  public.security_session_assert(uuid,uuid)
from public, anon, authenticated;
grant execute on function public.security_session_open(uuid,uuid),
  public.security_session_renew(uuid,uuid,integer),
  public.security_session_lock(uuid,uuid),
  public.security_session_assert(uuid,uuid)
to service_role;

-- Feature Edge handlers use these fixed scope checks before their bounded,
-- allow-listed reads. They are service-only and never trust a Flutter user ID.
create function public.security_clinic_read_assert(
  actor_user_id uuid, target_clinic_id uuid, clinical_access boolean default false
)
returns void language plpgsql stable security definer set search_path = '' as $$
begin
  if not private.is_active_clinic_member(target_clinic_id, actor_user_id) then
    raise exception using errcode = 'P0001', message = 'business_read_forbidden';
  end if;
  if clinical_access and not (
    private.has_clinic_role(target_clinic_id, 'owner', actor_user_id)
    or private.has_clinic_role(target_clinic_id, 'dentist', actor_user_id)
    or private.has_clinic_role(target_clinic_id, 'assistant', actor_user_id)
  ) then
    raise exception using errcode = 'P0001', message = 'business_read_forbidden';
  end if;
end;
$$;

create function public.security_patient_read_scope(
  actor_user_id uuid, target_patient_id uuid, clinical_access boolean default false
)
returns uuid language plpgsql stable security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select patient.clinic_id into target_clinic_id
  from public.patients patient where patient.id = target_patient_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  perform public.security_clinic_read_assert(
    actor_user_id, target_clinic_id, clinical_access
  );
  return target_clinic_id;
end;
$$;

create function public.security_workspace_create_clinic(
  actor_user_id uuid, supplied_name text, supplied_currency_code text,
  supplied_time_zone text
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare result public.clinics%rowtype;
begin
  if not exists (select 1 from auth.users where id = actor_user_id) then
    raise exception using errcode = 'P0001', message = 'authentication_required';
  end if;
  insert into public.clinics (name, currency_code, time_zone, created_by)
  values (
    btrim(supplied_name), upper(btrim(supplied_currency_code)),
    btrim(supplied_time_zone), actor_user_id
  ) returning * into result;
  return jsonb_build_object(
    'id', result.id, 'name', result.name,
    'currency_code', result.currency_code, 'time_zone', result.time_zone
  );
exception when check_violation or not_null_violation or string_data_right_truncation then
  raise exception using errcode = 'P0001', message = 'invalid_workspace_input';
end;
$$;

revoke all on function public.security_clinic_read_assert(uuid,uuid,boolean),
  public.security_patient_read_scope(uuid,uuid,boolean),
  public.security_workspace_create_clinic(uuid,text,text,text)
from public, anon, authenticated;
grant execute on function public.security_clinic_read_assert(uuid,uuid,boolean),
  public.security_patient_read_scope(uuid,uuid,boolean),
  public.security_workspace_create_clinic(uuid,text,text,text)
to service_role;

-- Authenticated clients use Auth and Edge Functions only. Business relations
-- and views no longer expose Data API reads to Flutter.
revoke select on all tables in schema public from authenticated;
revoke insert on table public.clinics from authenticated;
grant select on all tables in schema public to service_role;

create type public.owner_security_action as enum (
  'owner_invitation_create',
  'owner_invitation_resend',
  'owner_invitation_revoke',
  'staff_roles_replace',
  'staff_deactivate',
  'billing_settings_update',
  'financial_entry_reverse'
);

create table private.security_owner_proofs (
  id uuid primary key default gen_random_uuid(),
  proof_digest bytea not null unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references auth.sessions(id) on delete cascade,
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  action public.owner_security_action not null,
  target_id uuid,
  input_digest bytea not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default statement_timestamp(),
  constraint security_owner_proof_digest_size check (
    octet_length(proof_digest) = 32 and octet_length(input_digest) = 32
  ),
  constraint security_owner_proof_expiry check (
    expires_at > created_at and expires_at <= created_at + interval '5 minutes'
  )
);

create index security_owner_proofs_expiry_idx
  on private.security_owner_proofs (expires_at)
  where consumed_at is null;

create function public.security_owner_proof_issue(
  actor_user_id uuid,
  target_session_id uuid,
  target_clinic_id uuid,
  target_action public.owner_security_action,
  target_id uuid,
  target_input_digest bytea,
  target_proof_digest bytea
)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare expiry timestamptz := statement_timestamp() + interval '5 minutes';
begin
  perform public.security_session_assert(actor_user_id, target_session_id);
  if not private.has_clinic_role(
    target_clinic_id, 'owner'::public.clinic_role, actor_user_id
  ) or octet_length(target_input_digest) <> 32
    or octet_length(target_proof_digest) <> 32 then
    raise exception using errcode = 'P0001', message = 'owner_proof_forbidden';
  end if;
  delete from private.security_owner_proofs proof
  where proof.expires_at < statement_timestamp() - interval '1 day';
  insert into private.security_owner_proofs (
    proof_digest, user_id, session_id, clinic_id, action, target_id,
    input_digest, expires_at
  ) values (
    target_proof_digest, actor_user_id, target_session_id, target_clinic_id,
    target_action, target_id, target_input_digest, expiry
  );
  return expiry;
exception when unique_violation then
  raise exception using errcode = 'P0001', message = 'owner_proof_forbidden';
end;
$$;

create function private.security_owner_proof_consume(
  actor_user_id uuid,
  target_session_id uuid,
  target_clinic_id uuid,
  target_action public.owner_security_action,
  target_id uuid,
  target_input_digest bytea,
  target_proof_digest bytea
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare proof private.security_owner_proofs%rowtype;
begin
  perform public.security_session_assert(actor_user_id, target_session_id);
  select * into proof from private.security_owner_proofs candidate
  where candidate.proof_digest = target_proof_digest
  for update;
  if not found or proof.consumed_at is not null
    or proof.expires_at <= statement_timestamp()
    or proof.user_id <> actor_user_id
    or proof.session_id <> target_session_id
    or proof.clinic_id <> target_clinic_id
    or proof.action <> target_action
    or proof.target_id is distinct from target_id
    or proof.input_digest <> target_input_digest then
    raise exception using errcode = 'P0001', message = 'owner_proof_required';
  end if;
  if not private.has_clinic_role(
    target_clinic_id, 'owner'::public.clinic_role, actor_user_id
  ) then
    raise exception using errcode = 'P0001', message = 'owner_proof_required';
  end if;
  update private.security_owner_proofs
  set consumed_at = statement_timestamp()
  where id = proof.id;
end;
$$;

revoke all on table private.security_owner_proofs
  from public, anon, authenticated, service_role;
revoke all on function private.security_owner_proof_consume(
  uuid,uuid,uuid,public.owner_security_action,uuid,bytea,bytea
) from public, anon, authenticated, service_role;
revoke all on function public.security_owner_proof_issue(
  uuid,uuid,uuid,public.owner_security_action,uuid,bytea,bytea
) from public, anon, authenticated;
grant execute on function public.security_owner_proof_issue(
  uuid,uuid,uuid,public.owner_security_action,uuid,bytea,bytea
) to service_role;

-- Sensitive commands enter through proof-aware wrappers. The original audited
-- commands remain implementation details and are no longer callable by the
-- service role directly.
create function public.security_staff_create_invitation(
  actor_user_id uuid, target_clinic_id uuid, invited_email text,
  raw_token_digest bytea, invited_roles public.clinic_role[],
  target_session_id uuid, target_input_digest bytea,
  target_proof_digest bytea
)
returns table(invitation_id uuid, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
begin
  if 'owner'::public.clinic_role = any(invited_roles) then
    perform private.security_owner_proof_consume(
      actor_user_id, target_session_id, target_clinic_id,
      'owner_invitation_create', null, target_input_digest, target_proof_digest
    );
  end if;
  return query select * from public.staff_create_invitation(
    actor_user_id, target_clinic_id, invited_email, raw_token_digest, invited_roles
  );
end;
$$;

create function public.security_staff_resend_invitation(
  actor_user_id uuid, target_invitation_id uuid, raw_token_digest bytea,
  target_session_id uuid, target_input_digest bytea,
  target_proof_digest bytea
)
returns table(invitation_id uuid, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid; protects_owner boolean;
begin
  select invitation.clinic_id, exists (
    select 1 from public.clinic_invitation_roles role
    where role.clinic_invitation_id = invitation.id and role.role = 'owner'
  ) into target_clinic_id, protects_owner
  from public.clinic_invitations invitation where invitation.id = target_invitation_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  if protects_owner then
    perform private.security_owner_proof_consume(
      actor_user_id, target_session_id, target_clinic_id,
      'owner_invitation_resend', target_invitation_id,
      target_input_digest, target_proof_digest
    );
  end if;
  return query select * from public.staff_resend_invitation(
    actor_user_id, target_invitation_id, raw_token_digest
  );
end;
$$;

create function public.security_staff_revoke_invitation(
  actor_user_id uuid, target_invitation_id uuid, target_session_id uuid,
  target_input_digest bytea, target_proof_digest bytea
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid; protects_owner boolean;
begin
  select invitation.clinic_id, exists (
    select 1 from public.clinic_invitation_roles role
    where role.clinic_invitation_id = invitation.id and role.role = 'owner'
  ) into target_clinic_id, protects_owner
  from public.clinic_invitations invitation where invitation.id = target_invitation_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  if protects_owner then
    perform private.security_owner_proof_consume(
      actor_user_id, target_session_id, target_clinic_id,
      'owner_invitation_revoke', target_invitation_id,
      target_input_digest, target_proof_digest
    );
  end if;
  perform public.staff_revoke_invitation(actor_user_id, target_invitation_id);
end;
$$;

create function public.security_staff_replace_member_roles(
  actor_user_id uuid, target_member_id uuid,
  replacement_roles public.clinic_role[], target_session_id uuid,
  target_input_digest bytea, target_proof_digest bytea
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid; protects_owner boolean;
begin
  select member.clinic_id, (
    'owner'::public.clinic_role = any(replacement_roles) or exists (
      select 1 from public.clinic_member_roles role
      where role.clinic_member_id = member.id and role.role = 'owner'
    )
  ) into target_clinic_id, protects_owner
  from public.clinic_members member where member.id = target_member_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'member_unavailable';
  end if;
  if protects_owner then
    perform private.security_owner_proof_consume(
      actor_user_id, target_session_id, target_clinic_id,
      'staff_roles_replace', target_member_id,
      target_input_digest, target_proof_digest
    );
  end if;
  perform public.staff_replace_member_roles(
    actor_user_id, target_member_id, replacement_roles
  );
end;
$$;

create function public.security_staff_set_member_active(
  actor_user_id uuid, target_member_id uuid, next_is_active boolean,
  target_session_id uuid, target_input_digest bytea,
  target_proof_digest bytea
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select member.clinic_id into target_clinic_id
  from public.clinic_members member where member.id = target_member_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'member_unavailable';
  end if;
  if not next_is_active then
    perform private.security_owner_proof_consume(
      actor_user_id, target_session_id, target_clinic_id,
      'staff_deactivate', target_member_id,
      target_input_digest, target_proof_digest
    );
  end if;
  perform public.staff_set_member_active(
    actor_user_id, target_member_id, next_is_active
  );
end;
$$;

create function public.security_billing_settings_update(
  actor_user_id uuid, target_clinic_id uuid, supplied_tax_rate numeric,
  supplied_invoice_prefix text, target_session_id uuid,
  target_input_digest bytea, target_proof_digest bytea
)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform private.security_owner_proof_consume(
    actor_user_id, target_session_id, target_clinic_id,
    'billing_settings_update', target_clinic_id,
    target_input_digest, target_proof_digest
  );
  perform public.billing_settings_update(
    actor_user_id, target_clinic_id, supplied_tax_rate, supplied_invoice_prefix
  );
end;
$$;

create function public.security_billing_financial_entry_reverse(
  actor_user_id uuid, target_entry_id uuid, supplied_amount numeric,
  reversal_action text, supplied_reason text, target_command_id uuid,
  target_input_hash text, target_session_id uuid,
  target_input_digest bytea, target_proof_digest bytea
)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select entry.clinic_id into target_clinic_id
  from public.financial_ledger_entries entry where entry.id = target_entry_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'financial_entry_unavailable';
  end if;
  perform private.security_owner_proof_consume(
    actor_user_id, target_session_id, target_clinic_id,
    'financial_entry_reverse', target_entry_id,
    target_input_digest, target_proof_digest
  );
  return public.billing_financial_entry_reverse(
    actor_user_id, target_entry_id, supplied_amount, reversal_action,
    supplied_reason, target_command_id, target_input_hash
  );
end;
$$;

revoke all on function
  public.staff_create_invitation(uuid,uuid,text,bytea,public.clinic_role[]),
  public.staff_resend_invitation(uuid,uuid,bytea),
  public.staff_revoke_invitation(uuid,uuid),
  public.staff_replace_member_roles(uuid,uuid,public.clinic_role[]),
  public.staff_set_member_active(uuid,uuid,boolean),
  public.billing_settings_update(uuid,uuid,numeric,text),
  public.billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text)
from service_role;

revoke all on function
  public.security_staff_create_invitation(uuid,uuid,text,bytea,public.clinic_role[],uuid,bytea,bytea),
  public.security_staff_resend_invitation(uuid,uuid,bytea,uuid,bytea,bytea),
  public.security_staff_revoke_invitation(uuid,uuid,uuid,bytea,bytea),
  public.security_staff_replace_member_roles(uuid,uuid,public.clinic_role[],uuid,bytea,bytea),
  public.security_staff_set_member_active(uuid,uuid,boolean,uuid,bytea,bytea),
  public.security_billing_settings_update(uuid,uuid,numeric,text,uuid,bytea,bytea),
  public.security_billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text,uuid,bytea,bytea)
from public, anon, authenticated;

grant execute on function
  public.security_staff_create_invitation(uuid,uuid,text,bytea,public.clinic_role[],uuid,bytea,bytea),
  public.security_staff_resend_invitation(uuid,uuid,bytea,uuid,bytea,bytea),
  public.security_staff_revoke_invitation(uuid,uuid,uuid,bytea,bytea),
  public.security_staff_replace_member_roles(uuid,uuid,public.clinic_role[],uuid,bytea,bytea),
  public.security_staff_set_member_active(uuid,uuid,boolean,uuid,bytea,bytea),
  public.security_billing_settings_update(uuid,uuid,numeric,text,uuid,bytea,bytea),
  public.security_billing_financial_entry_reverse(uuid,uuid,numeric,text,text,uuid,text,uuid,bytea,bytea)
to service_role;
