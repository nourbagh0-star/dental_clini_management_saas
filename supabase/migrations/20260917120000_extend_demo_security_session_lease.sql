-- Phase 16: three-day fictional-demo lease. Revisit before real patient data.
create or replace function public.security_session_open(
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
    statement_timestamp() + interval '3 days', statement_timestamp(), null
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

create or replace function public.security_session_renew(
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
    unlocked_until = statement_timestamp() + interval '3 days',
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

revoke all on function public.security_session_open(uuid,uuid),
  public.security_session_renew(uuid,uuid,integer)
from public, anon, authenticated;
grant execute on function public.security_session_open(uuid,uuid),
  public.security_session_renew(uuid,uuid,integer)
to service_role;
