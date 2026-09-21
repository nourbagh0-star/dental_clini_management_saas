-- Phase 3 server commands. These public RPC names are callable only by the
-- service role inside the authenticated Edge Function; browser roles have no
-- execute privilege. Each command rechecks the supplied actor's owner role.
alter table public.clinic_invitations
  add constraint clinic_invitations_token_digest_length
    check (octet_length(token_digest) = 32);

create function private.require_active_owner(
  candidate_clinic_id uuid,
  candidate_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.has_clinic_role(
    candidate_clinic_id,
    'owner'::public.clinic_role,
    candidate_user_id
  ) then
    raise exception using errcode = 'P0001', message = 'owner_required';
  end if;
end;
$$;

create function private.require_roles(candidate_roles public.clinic_role[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if coalesce(cardinality(candidate_roles), 0) = 0 then
    raise exception using errcode = 'P0001', message = 'roles_required';
  end if;
end;
$$;

create function public.staff_create_invitation(
  actor_user_id uuid,
  target_clinic_id uuid,
  invited_email text,
  raw_token_digest bytea,
  invited_roles public.clinic_role[]
)
returns table (invitation_id uuid, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  canonical_email text := lower(btrim(invited_email));
  created_invitation public.clinic_invitations%rowtype;
begin
  perform private.require_active_owner(target_clinic_id, actor_user_id);
  perform private.require_roles(invited_roles);
  if canonical_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    or char_length(canonical_email) not between 3 and 320 then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_email';
  end if;
  if octet_length(raw_token_digest) <> 32 then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_token';
  end if;
  if exists (
    select 1
    from public.clinic_members member
    where member.clinic_id = target_clinic_id
      and member.email = canonical_email
      and member.is_active
  ) then
    raise exception using errcode = 'P0001', message = 'already_active_member';
  end if;

  update public.clinic_invitations invitation
  set status = 'expired', updated_at = now()
  where invitation.clinic_id = target_clinic_id
    and invitation.email = canonical_email
    and invitation.status = 'pending'
    and invitation.expires_at <= now();

  if exists (
    select 1
    from public.clinic_invitations invitation
    where invitation.clinic_id = target_clinic_id
      and invitation.email = canonical_email
      and invitation.status = 'pending'
  ) then
    raise exception using errcode = 'P0001', message = 'pending_invitation_exists';
  end if;

  insert into public.clinic_invitations (
    clinic_id, email, token_digest, expires_at, created_by
  ) values (
    target_clinic_id, canonical_email, raw_token_digest,
    now() + interval '7 days', actor_user_id
  ) returning * into created_invitation;

  insert into public.clinic_invitation_roles (clinic_invitation_id, role)
  select created_invitation.id, role
  from unnest(invited_roles) as role;

  return query select created_invitation.id, created_invitation.expires_at;
end;
$$;

create function public.staff_resend_invitation(
  actor_user_id uuid,
  target_invitation_id uuid,
  raw_token_digest bytea
)
returns table (invitation_id uuid, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  invitation public.clinic_invitations%rowtype;
begin
  select * into invitation
  from public.clinic_invitations
  where id = target_invitation_id
  for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  perform private.require_active_owner(invitation.clinic_id, actor_user_id);
  if invitation.status not in ('pending', 'expired') then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  if octet_length(raw_token_digest) <> 32 then
    raise exception using errcode = 'P0001', message = 'invalid_invitation_token';
  end if;

  update public.clinic_invitations
  set token_digest = raw_token_digest,
      status = 'pending',
      expires_at = now() + interval '7 days',
      last_sent_at = now(),
      resend_count = resend_count + 1,
      updated_at = now()
  where id = invitation.id
  returning * into invitation;
  return query select invitation.id, invitation.expires_at;
end;
$$;

create function public.staff_revoke_invitation(
  actor_user_id uuid,
  target_invitation_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  invitation public.clinic_invitations%rowtype;
begin
  select * into invitation
  from public.clinic_invitations
  where id = target_invitation_id
  for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  perform private.require_active_owner(invitation.clinic_id, actor_user_id);
  if invitation.status not in ('pending', 'expired') then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  update public.clinic_invitations
  set status = 'revoked', revoked_by = actor_user_id, revoked_at = now(), updated_at = now()
  where id = invitation.id;
end;
$$;

create function public.staff_accept_invitation(
  actor_user_id uuid,
  raw_token_digest bytea
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  invitation public.clinic_invitations%rowtype;
  verified_email text;
  member public.clinic_members%rowtype;
begin
  if octet_length(raw_token_digest) <> 32 then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  select lower(email) into verified_email
  from auth.users
  where id = actor_user_id and email_confirmed_at is not null;
  if verified_email is null then
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;
  select * into invitation
  from public.clinic_invitations
  where token_digest = raw_token_digest
    and status = 'pending'
  for update;
  if not found or invitation.expires_at <= now()
    or invitation.email <> verified_email then
    if found and invitation.expires_at <= now() then
      update public.clinic_invitations
      set status = 'expired', updated_at = now()
      where id = invitation.id;
    end if;
    raise exception using errcode = 'P0001', message = 'invitation_unavailable';
  end if;

  select * into member
  from public.clinic_members
  where clinic_id = invitation.clinic_id and user_id = actor_user_id
  for update;
  if found and member.is_active then
    raise exception using errcode = 'P0001', message = 'already_active_member';
  end if;
  if found then
    update public.clinic_members
    set is_active = true,
        email = verified_email,
        deactivated_at = null,
        deactivated_by = null,
        updated_at = now()
    where id = member.id
    returning * into member;
    delete from public.clinic_member_roles
    where clinic_member_id = member.id;
  else
    insert into public.clinic_members (clinic_id, user_id, email)
    values (invitation.clinic_id, actor_user_id, verified_email)
    returning * into member;
  end if;

  insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
  select member.id, invitation_role.role, invitation.created_by
  from public.clinic_invitation_roles invitation_role
  where invitation_role.clinic_invitation_id = invitation.id;

  update public.clinic_invitations
  set status = 'accepted',
      accepted_member_id = member.id,
      accepted_at = now(),
      updated_at = now()
  where id = invitation.id;
  return invitation.clinic_id;
end;
$$;

create function public.staff_replace_member_roles(
  actor_user_id uuid,
  target_member_id uuid,
  replacement_roles public.clinic_role[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  member public.clinic_members%rowtype;
begin
  select * into member from public.clinic_members where id = target_member_id for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'member_unavailable';
  end if;
  perform private.require_active_owner(member.clinic_id, actor_user_id);
  perform private.require_roles(replacement_roles);
  delete from public.clinic_member_roles as existing_member_role
  where existing_member_role.clinic_member_id = member.id
    and not (existing_member_role.role = any(replacement_roles));
  insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
  select member.id, role, actor_user_id
  from unnest(replacement_roles) as role
  on conflict do nothing;
end;
$$;

create function public.staff_set_member_active(
  actor_user_id uuid,
  target_member_id uuid,
  next_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  member public.clinic_members%rowtype;
begin
  select * into member from public.clinic_members where id = target_member_id for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'member_unavailable';
  end if;
  perform private.require_active_owner(member.clinic_id, actor_user_id);
  if member.is_active = next_is_active then return; end if;
  update public.clinic_members
  set is_active = next_is_active,
      deactivated_at = case when next_is_active then null else now() end,
      deactivated_by = case when next_is_active then null else actor_user_id end,
      updated_at = now()
  where id = member.id;
end;
$$;

revoke all on function private.require_active_owner(uuid, uuid) from public;
revoke all on function private.require_roles(public.clinic_role[]) from public;
revoke all on function public.staff_create_invitation(uuid, uuid, text, bytea, public.clinic_role[]) from public, anon, authenticated;
revoke all on function public.staff_resend_invitation(uuid, uuid, bytea) from public, anon, authenticated;
revoke all on function public.staff_revoke_invitation(uuid, uuid) from public, anon, authenticated;
revoke all on function public.staff_accept_invitation(uuid, bytea) from public, anon, authenticated;
revoke all on function public.staff_replace_member_roles(uuid, uuid, public.clinic_role[]) from public, anon, authenticated;
revoke all on function public.staff_set_member_active(uuid, uuid, boolean) from public, anon, authenticated;
grant execute on function public.staff_create_invitation(uuid, uuid, text, bytea, public.clinic_role[]) to service_role;
grant execute on function public.staff_resend_invitation(uuid, uuid, bytea) to service_role;
grant execute on function public.staff_revoke_invitation(uuid, uuid) to service_role;
grant execute on function public.staff_accept_invitation(uuid, bytea) to service_role;
grant execute on function public.staff_replace_member_roles(uuid, uuid, public.clinic_role[]) to service_role;
grant execute on function public.staff_set_member_active(uuid, uuid, boolean) to service_role;
