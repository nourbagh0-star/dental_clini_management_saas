-- Phase 3: reusable staff roles and invitation records. All mutation remains
-- server-controlled; Flutter receives no direct write grants to these tables.
create type public.clinic_role as enum (
  'owner',
  'dentist',
  'assistant',
  'receptionist'
);

alter table public.clinic_members
  add column email text,
  add column deactivated_at timestamptz,
  add column deactivated_by uuid references auth.users(id) on delete restrict;

update public.clinic_members member
set email = lower(account.email)
from auth.users account
where account.id = member.user_id;

alter table public.clinic_members
  alter column email set not null,
  add constraint clinic_members_email_normalized
    check (
      email = lower(btrim(email))
      and char_length(email) between 3 and 320
      and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    ),
  add constraint clinic_members_deactivation_consistency
    check (
      (is_active and deactivated_at is null and deactivated_by is null)
      or (not is_active and deactivated_at is not null and deactivated_by is not null)
    );

create table public.clinic_member_roles (
  clinic_member_id uuid not null
    references public.clinic_members(id) on delete restrict,
  role public.clinic_role not null,
  assigned_at timestamptz not null default now(),
  assigned_by uuid not null references auth.users(id) on delete restrict,
  primary key (clinic_member_id, role)
);

insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
select id, 'owner'::public.clinic_role, user_id
from public.clinic_members;

-- The Phase 2 bootstrap column is fully represented by clinic_member_roles.
alter table public.clinic_members
  drop constraint clinic_members_only_owner,
  drop column ownership;

create table public.clinic_invitations (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  email text not null,
  token_digest bytea not null,
  status text not null default 'pending',
  expires_at timestamptz not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  last_sent_at timestamptz not null default now(),
  resend_count integer not null default 0,
  accepted_member_id uuid references public.clinic_members(id) on delete restrict,
  accepted_at timestamptz,
  revoked_by uuid references auth.users(id) on delete restrict,
  revoked_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint clinic_invitations_email_normalized
    check (
      email = lower(btrim(email))
      and char_length(email) between 3 and 320
      and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
    ),
  constraint clinic_invitations_status
    check (status in ('pending', 'accepted', 'revoked', 'expired')),
  constraint clinic_invitations_expiry
    check (expires_at > created_at),
  constraint clinic_invitations_resend_count
    check (resend_count >= 0),
  constraint clinic_invitations_accepted_consistency
    check (
      (status = 'accepted' and accepted_member_id is not null and accepted_at is not null)
      or (status <> 'accepted' and accepted_member_id is null and accepted_at is null)
    ),
  constraint clinic_invitations_revoked_consistency
    check (
      (status = 'revoked' and revoked_by is not null and revoked_at is not null)
      or (status <> 'revoked' and revoked_by is null and revoked_at is null)
    )
);

create unique index clinic_invitations_one_pending_email_idx
  on public.clinic_invitations (clinic_id, email)
  where status = 'pending';

create index clinic_invitations_pending_expiry_idx
  on public.clinic_invitations (clinic_id, expires_at)
  where status = 'pending';

create table public.clinic_invitation_roles (
  clinic_invitation_id uuid not null
    references public.clinic_invitations(id) on delete restrict,
  role public.clinic_role not null,
  primary key (clinic_invitation_id, role)
);

create index clinic_member_roles_member_idx
  on public.clinic_member_roles (clinic_member_id);

create function private.is_active_clinic_member(
  candidate_clinic_id uuid,
  candidate_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.clinic_members member
    where member.clinic_id = candidate_clinic_id
      and member.user_id = candidate_user_id
      and member.is_active
  );
$$;

create function private.has_clinic_role(
  candidate_clinic_id uuid,
  candidate_role public.clinic_role,
  candidate_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.clinic_members member
    join public.clinic_member_roles member_role
      on member_role.clinic_member_id = member.id
    where member.clinic_id = candidate_clinic_id
      and member.user_id = candidate_user_id
      and member.is_active
      and member_role.role = candidate_role
  );
$$;

create function private.can_read_clinic_member(
  candidate_member_id uuid,
  candidate_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select member.user_id = candidate_user_id
    or private.has_clinic_role(
      member.clinic_id,
      'owner'::public.clinic_role,
      candidate_user_id
    )
  from public.clinic_members member
  where member.id = candidate_member_id;
$$;

create function private.prevent_last_active_owner_loss()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  protected_clinic_id uuid;
  protected_member_id uuid;
begin
  if tg_table_name = 'clinic_member_roles' then
    if old.role <> 'owner'::public.clinic_role then
      return case when tg_op = 'DELETE' then old else new end;
    end if;
    select clinic_id into protected_clinic_id
    from public.clinic_members
    where id = old.clinic_member_id;
    protected_member_id := old.clinic_member_id;
  else
    if old.is_active is not true
      or (tg_op <> 'DELETE' and new.is_active is not false) then
      return case when tg_op = 'DELETE' then old else new end;
    end if;
    protected_clinic_id := old.clinic_id;
    protected_member_id := old.id;
    if not exists (
      select 1
      from public.clinic_member_roles member_role
      where member_role.clinic_member_id = protected_member_id
        and member_role.role = 'owner'::public.clinic_role
    ) then
      return case when tg_op = 'DELETE' then old else new end;
    end if;
  end if;

  if not exists (
    select 1
    from public.clinic_members member
    join public.clinic_member_roles member_role
      on member_role.clinic_member_id = member.id
    where member.clinic_id = protected_clinic_id
      and member.id <> protected_member_id
      and member.is_active
      and member_role.role = 'owner'::public.clinic_role
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'last_active_owner';
  end if;

  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

revoke all on function private.is_active_clinic_member(uuid, uuid) from public;
revoke all on function private.has_clinic_role(uuid, public.clinic_role, uuid) from public;
revoke all on function private.can_read_clinic_member(uuid, uuid) from public;
revoke all on function private.prevent_last_active_owner_loss() from public;
grant execute on function private.is_active_clinic_member(uuid, uuid) to authenticated;
grant execute on function private.has_clinic_role(uuid, public.clinic_role, uuid) to authenticated;
grant execute on function private.can_read_clinic_member(uuid, uuid) to authenticated;

create trigger clinic_member_roles_prevent_last_owner_loss
before delete or update of role on public.clinic_member_roles
for each row execute function private.prevent_last_active_owner_loss();

create trigger clinic_members_prevent_last_owner_deactivation
before delete or update of is_active on public.clinic_members
for each row execute function private.prevent_last_active_owner_loss();

create or replace function private.create_creator_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_member_id uuid;
begin
  insert into public.clinic_members (clinic_id, user_id, email, is_active)
  select new.id, new.created_by, lower(account.email), true
  from auth.users account
  where account.id = new.created_by
  returning id into new_member_id;

  insert into public.clinic_member_roles (clinic_member_id, role, assigned_by)
  values (new_member_id, 'owner'::public.clinic_role, new.created_by);

  return new;
end;
$$;

alter table public.clinic_member_roles enable row level security;
alter table public.clinic_invitations enable row level security;
alter table public.clinic_invitation_roles enable row level security;

revoke all on table public.clinic_members from anon, authenticated;
revoke all on table public.clinic_member_roles from anon, authenticated;
revoke all on table public.clinic_invitations from anon, authenticated;
revoke all on table public.clinic_invitation_roles from anon, authenticated;
grant select on table public.clinic_members to authenticated;
grant select on table public.clinic_member_roles to authenticated;
grant select on table public.clinic_invitations to authenticated;
grant select on table public.clinic_invitation_roles to authenticated;

drop policy "users read their own memberships" on public.clinic_members;
create policy "members read themselves and owners read clinic staff"
on public.clinic_members for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.has_clinic_role(
    clinic_id,
    'owner'::public.clinic_role,
    (select auth.uid())
  )
);

create policy "members read themselves and owners read clinic roles"
on public.clinic_member_roles for select
to authenticated
using (
  private.can_read_clinic_member(
    clinic_member_roles.clinic_member_id,
    (select auth.uid())
  )
);

create policy "owners read clinic invitations"
on public.clinic_invitations for select
to authenticated
using (
  private.has_clinic_role(
    clinic_id,
    'owner'::public.clinic_role,
    (select auth.uid())
  )
);

create policy "owners read invitation roles"
on public.clinic_invitation_roles for select
to authenticated
using (
  private.has_clinic_role(
    (
      select invitation.clinic_id
      from public.clinic_invitations invitation
      where invitation.id = clinic_invitation_roles.clinic_invitation_id
    ),
    'owner'::public.clinic_role,
    (select auth.uid())
  )
);
