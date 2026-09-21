-- Phase 13: immutable, owner-readable clinic audit ledger with actor snapshots,
-- bounded keyset reads, and idempotent sensitive-access recording.
create type public.audit_event_category as enum (
  'access',
  'patient_administration',
  'scheduling',
  'clinical',
  'financial',
  'staff_security'
);

alter table public.audit_events
  add column actor_member_id uuid references public.clinic_members(id) on delete restrict,
  add column actor_email_snapshot text,
  add column actor_roles_snapshot public.clinic_role[] not null default '{}',
  add column category public.audit_event_category,
  add column request_id uuid,
  add constraint audit_events_email_snapshot check (
    actor_email_snapshot is null or (
      actor_email_snapshot = lower(btrim(actor_email_snapshot))
      and char_length(actor_email_snapshot) between 3 and 320
    )
  ),
  add constraint audit_events_metadata_size check (
    octet_length(safe_metadata::text) <= 4096
  );

update public.audit_events event
set actor_member_id = member.id,
    actor_email_snapshot = member.email,
    actor_roles_snapshot = coalesce((
      select array_agg(role.role order by role.role)
      from public.clinic_member_roles role
      where role.clinic_member_id = member.id
    ), '{}'::public.clinic_role[])
from public.clinic_members member
where member.clinic_id = event.clinic_id
  and member.user_id = event.actor_user_id;

update public.audit_events
set category = case
  when event_type like 'patient_file_%' then 'clinical'::public.audit_event_category
  when event_type like 'clinical_session_%' then 'clinical'::public.audit_event_category
  when event_type = 'appointment_conflict_overridden' then 'scheduling'::public.audit_event_category
  else 'financial'::public.audit_event_category
end;

alter table public.audit_events alter column category set not null;

drop index public.audit_events_clinic_occurred_at_idx;
create index audit_events_clinic_cursor_idx
  on public.audit_events (clinic_id, occurred_at desc, id desc);
create index audit_events_clinic_actor_cursor_idx
  on public.audit_events (clinic_id, actor_user_id, occurred_at desc, id desc);
create index audit_events_clinic_category_cursor_idx
  on public.audit_events (clinic_id, category, occurred_at desc, id desc);
create unique index audit_events_request_id_idx
  on public.audit_events (clinic_id, actor_user_id, request_id)
  where request_id is not null;

create function private.audit_category(candidate_event_type text)
returns public.audit_event_category
language sql
immutable
set search_path = ''
as $$
  select case
    when candidate_event_type in (
      'audit_log_opened', 'patient_search_performed', 'patient_profile_opened',
      'medical_record_opened', 'odontogram_opened', 'treatment_plan_opened',
      'clinical_sessions_opened', 'patient_files_opened',
      'patient_file_preview_authorized', 'patient_file_download_authorized'
    ) then 'access'::public.audit_event_category
    when candidate_event_type in (
      'patient_created', 'patient_updated', 'patient_archived', 'patient_restored'
    ) then 'patient_administration'::public.audit_event_category
    when candidate_event_type in (
      'appointment_created', 'appointment_rescheduled', 'appointment_status_changed',
      'appointment_conflict_overridden', 'doctor_schedule_changed',
      'doctor_schedule_exception_changed'
    ) then 'scheduling'::public.audit_event_category
    when candidate_event_type like 'clinical_session_%'
      or candidate_event_type like 'odontogram_%'
      or candidate_event_type like 'treatment_%'
      or candidate_event_type = 'medical_profile_updated'
      or candidate_event_type in (
        'patient_file_uploaded', 'patient_file_archived', 'patient_file_restored'
      ) then 'clinical'::public.audit_event_category
    when candidate_event_type like 'invoice_%'
      or candidate_event_type like 'payment_%'
      or candidate_event_type like 'patient_credit_%'
      or candidate_event_type like 'financial_%'
      then 'financial'::public.audit_event_category
    when candidate_event_type like 'staff_%'
      or candidate_event_type like 'invitation_%'
      then 'staff_security'::public.audit_event_category
    else null
  end;
$$;

create function private.audit_allowed_metadata(candidate jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select jsonb_typeof(candidate) = 'object'
    and octet_length(candidate::text) <= 4096
    and not exists (
      select 1 from jsonb_object_keys(candidate) key
      where key not in (
        'patient_id', 'invoice_id', 'appointment_id', 'amendment_id',
        'category', 'currency', 'amount', 'total', 'command_id',
        'invoice_number', 'financial_revision', 'locale', 'result_count',
        'page_size', 'search_present', 'access_intent', 'previous_status',
        'next_status', 'member_id', 'roles', 'is_active'
      )
    );
$$;

create function private.audit_events_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor public.clinic_members%rowtype;
  derived_category public.audit_event_category;
begin
  derived_category := private.audit_category(new.event_type);
  if derived_category is null or not private.audit_allowed_metadata(new.safe_metadata) then
    raise exception using errcode = 'P0001', message = 'invalid_audit_event';
  end if;
  select * into actor from public.clinic_members
  where clinic_id = new.clinic_id and user_id = new.actor_user_id;
  if not found then
    raise exception using errcode = 'P0001', message = 'invalid_audit_actor';
  end if;
  new.actor_member_id := actor.id;
  new.actor_email_snapshot := actor.email;
  select coalesce(array_agg(role.role order by role.role), '{}'::public.clinic_role[])
    into new.actor_roles_snapshot
  from public.clinic_member_roles role where role.clinic_member_id = actor.id;
  new.category := derived_category;
  new.occurred_at := statement_timestamp();
  return new;
end;
$$;

create function private.audit_events_immutable()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'P0001', message = 'audit_event_immutable';
end;
$$;

create trigger audit_events_derive_safe_snapshot
before insert on public.audit_events
for each row execute function private.audit_events_before_insert();
create trigger audit_events_block_changes
before update or delete on public.audit_events
for each row execute function private.audit_events_immutable();

revoke all on function private.audit_category(text) from public;
revoke all on function private.audit_allowed_metadata(jsonb) from public;
revoke all on function private.audit_events_before_insert() from public;
revoke all on function private.audit_events_immutable() from public;

create function private.audit_write(
  actor_user_id uuid,
  target_clinic_id uuid,
  next_event_type text,
  next_subject_type text,
  next_subject_id uuid,
  next_reason text default null,
  next_metadata jsonb default '{}'::jsonb,
  target_request_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare result_id uuid;
begin
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id,
    reason, safe_metadata, request_id
  ) values (
    target_clinic_id, actor_user_id, next_event_type, next_subject_type,
    next_subject_id, nullif(btrim(next_reason), ''), coalesce(next_metadata, '{}'::jsonb),
    target_request_id
  )
  on conflict do nothing
  returning id into result_id;
  if result_id is null and target_request_id is not null then
    select event.id into result_id from public.audit_events event
    where event.clinic_id = target_clinic_id
      and event.actor_user_id = audit_write.actor_user_id
      and event.request_id = target_request_id;
  end if;
  return result_id;
end;
$$;

create function public.audit_record_access(
  actor_user_id uuid,
  target_clinic_id uuid,
  access_intent text,
  target_subject_id uuid,
  target_request_id uuid,
  result_count integer default null,
  requested_page_size integer default null,
  search_present boolean default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  next_event_type text;
  next_subject_type text;
  metadata jsonb := '{}'::jsonb;
  allowed boolean := false;
begin
  if not private.is_active_clinic_member(target_clinic_id, actor_user_id) then
    raise exception using errcode = 'P0001', message = 'audit_access_forbidden';
  end if;
  if access_intent = 'audit_log' then
    allowed := private.has_clinic_role(
      target_clinic_id, 'owner'::public.clinic_role, actor_user_id
    ) and target_subject_id = target_clinic_id;
    next_event_type := 'audit_log_opened';
    next_subject_type := 'clinic';
  elsif access_intent = 'patient_search' then
    allowed := target_subject_id = target_clinic_id
      and result_count between 0 and 50
      and requested_page_size between 1 and 50
      and search_present is not null;
    next_event_type := 'patient_search_performed';
    next_subject_type := 'clinic';
    metadata := jsonb_build_object(
      'result_count', result_count,
      'page_size', requested_page_size,
      'search_present', search_present
    );
  elsif access_intent in (
    'patient_profile', 'medical_record', 'odontogram', 'treatment_plan',
    'clinical_sessions', 'patient_files'
  ) then
    allowed := exists (
      select 1 from public.patients patient
      where patient.id = target_subject_id and patient.clinic_id = target_clinic_id
    );
    if access_intent <> 'patient_profile' then
      allowed := allowed and (
        private.has_clinic_role(target_clinic_id, 'owner', actor_user_id)
        or private.has_clinic_role(target_clinic_id, 'dentist', actor_user_id)
        or private.has_clinic_role(target_clinic_id, 'assistant', actor_user_id)
      );
    end if;
    next_event_type := case access_intent
      when 'patient_profile' then 'patient_profile_opened'
      when 'medical_record' then 'medical_record_opened'
      when 'odontogram' then 'odontogram_opened'
      when 'treatment_plan' then 'treatment_plan_opened'
      when 'clinical_sessions' then 'clinical_sessions_opened'
      else 'patient_files_opened'
    end;
    next_subject_type := 'patient';
  elsif access_intent in ('file_preview', 'file_download') then
    allowed := exists (
      select 1 from public.patient_files file
      where file.id = target_subject_id and file.clinic_id = target_clinic_id
        and file.status in ('available', 'archived')
    ) and (
      private.has_clinic_role(target_clinic_id, 'owner', actor_user_id)
      or private.has_clinic_role(target_clinic_id, 'dentist', actor_user_id)
      or private.has_clinic_role(target_clinic_id, 'assistant', actor_user_id)
    );
    next_event_type := case access_intent when 'file_preview'
      then 'patient_file_preview_authorized'
      else 'patient_file_download_authorized' end;
    next_subject_type := 'patient_file';
    metadata := jsonb_build_object('access_intent', access_intent);
  else
    raise exception using errcode = 'P0001', message = 'invalid_audit_access';
  end if;
  if not allowed then
    raise exception using errcode = 'P0001', message = 'audit_access_forbidden';
  end if;
  return private.audit_write(
    actor_user_id, target_clinic_id, next_event_type, next_subject_type,
    target_subject_id, null, metadata, target_request_id
  );
end;
$$;

create function public.audit_event_page(
  actor_user_id uuid,
  target_clinic_id uuid,
  range_from date,
  range_to_exclusive date,
  filter_actor_user_id uuid default null,
  filter_category public.audit_event_category default null,
  filter_event_type text default null,
  filter_subject_type text default null,
  page_limit integer default 50,
  cursor_occurred_at timestamptz default null,
  cursor_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  clinic_zone text;
  from_instant timestamptz;
  to_instant timestamptz;
  items jsonb;
  actors jsonb;
  more boolean;
  next_time timestamptz;
  next_id uuid;
begin
  if not private.has_clinic_role(
    target_clinic_id, 'owner'::public.clinic_role, actor_user_id
  ) then
    raise exception using errcode = 'P0001', message = 'audit_read_forbidden';
  end if;
  select time_zone into clinic_zone from public.clinics where id = target_clinic_id;
  if clinic_zone is null or range_from is null or range_to_exclusive is null
    or range_to_exclusive <= range_from
    or range_to_exclusive - range_from > 90
    or page_limit not between 1 and 50
    or ((cursor_occurred_at is null) <> (cursor_id is null))
    or (filter_event_type is not null and private.audit_category(filter_event_type) is null)
    or (filter_subject_type is not null and (
      filter_subject_type <> btrim(filter_subject_type)
      or char_length(filter_subject_type) not between 1 and 100
    )) then
    raise exception using errcode = 'P0001', message = 'invalid_audit_query';
  end if;
  from_instant := range_from::timestamp at time zone clinic_zone;
  to_instant := range_to_exclusive::timestamp at time zone clinic_zone;

  with matched as (
    select event.* from public.audit_events event
    where event.clinic_id = target_clinic_id
      and event.occurred_at >= from_instant and event.occurred_at < to_instant
      and (filter_actor_user_id is null or event.actor_user_id = filter_actor_user_id)
      and (filter_category is null or event.category = filter_category)
      and (filter_event_type is null or event.event_type = filter_event_type)
      and (filter_subject_type is null or event.subject_type = filter_subject_type)
      and (cursor_occurred_at is null
        or (event.occurred_at, event.id) < (cursor_occurred_at, cursor_id))
    order by event.occurred_at desc, event.id desc
    limit page_limit + 1
  ), visible as (
    select * from matched order by occurred_at desc, id desc limit page_limit
  )
  select
    coalesce(jsonb_agg(jsonb_build_object(
      'id', visible.id,
      'actorUserId', visible.actor_user_id,
      'actorMemberId', visible.actor_member_id,
      'actorEmail', visible.actor_email_snapshot,
      'actorRoles', to_jsonb(visible.actor_roles_snapshot),
      'category', visible.category,
      'eventType', visible.event_type,
      'subjectType', visible.subject_type,
      'subjectId', visible.subject_id,
      'reason', visible.reason,
      'context', visible.safe_metadata,
      'occurredAt', visible.occurred_at
    ) order by visible.occurred_at desc, visible.id desc), '[]'::jsonb),
    (select count(*) > page_limit from matched),
    (array_agg(visible.occurred_at order by visible.occurred_at desc, visible.id desc))[page_limit],
    (array_agg(visible.id order by visible.occurred_at desc, visible.id desc))[page_limit]
  into items, more, next_time, next_id
  from visible;

  select coalesce(jsonb_agg(jsonb_build_object(
    'userId', member.user_id, 'memberId', member.id, 'email', member.email,
    'isActive', member.is_active
  ) order by member.email, member.id), '[]'::jsonb)
  into actors from public.clinic_members member where member.clinic_id = target_clinic_id;

  return jsonb_build_object(
    'clinicId', target_clinic_id,
    'clinicTimeZone', clinic_zone,
    'rangeFrom', range_from,
    'rangeToExclusive', range_to_exclusive,
    'items', items,
    'actors', actors,
    'hasMore', coalesce(more, false),
    'nextCursor', case when coalesce(more, false) then jsonb_build_object(
      'occurredAt', next_time, 'id', next_id
    ) else null end
  );
end;
$$;

revoke all on function private.audit_write(uuid,uuid,text,text,uuid,text,jsonb,uuid) from public;
revoke all on function public.audit_record_access(uuid,uuid,text,uuid,uuid,integer,integer,boolean)
  from public, anon, authenticated;
revoke all on function public.audit_event_page(uuid,uuid,date,date,uuid,public.audit_event_category,text,text,integer,timestamptz,uuid)
  from public, anon, authenticated;
grant execute on function public.audit_record_access(uuid,uuid,text,uuid,uuid,integer,integer,boolean)
  to service_role;
grant execute on function public.audit_event_page(uuid,uuid,date,date,uuid,public.audit_event_category,text,text,integer,timestamptz,uuid)
  to service_role;

revoke all on table public.audit_events from anon, authenticated, service_role;

-- Preserve the existing service APIs while making patient administration and
-- staff security changes atomic with their audit records. The renamed
-- mutation functions are callable only by these migration-owner wrappers.
alter function public.patient_create(uuid,uuid,jsonb)
  rename to patient_create_mutation;
alter function public.patient_update_demographics(uuid,uuid,jsonb)
  rename to patient_update_demographics_mutation;
alter function public.patient_update_contacts(uuid,uuid,jsonb)
  rename to patient_update_contacts_mutation;
alter function public.patient_upsert_medical_profile(uuid,uuid,jsonb)
  rename to patient_upsert_medical_profile_mutation;
alter function public.patient_set_archived(uuid,uuid,boolean)
  rename to patient_set_archived_mutation;

revoke all on function public.patient_create_mutation(uuid,uuid,jsonb),
  public.patient_update_demographics_mutation(uuid,uuid,jsonb),
  public.patient_update_contacts_mutation(uuid,uuid,jsonb),
  public.patient_upsert_medical_profile_mutation(uuid,uuid,jsonb),
  public.patient_set_archived_mutation(uuid,uuid,boolean)
from public, anon, authenticated, service_role;

create function public.patient_create(
  actor_user_id uuid, target_clinic_id uuid, demographic jsonb
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare result_id uuid;
begin
  result_id := public.patient_create_mutation(
    actor_user_id, target_clinic_id, demographic
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'patient_created', 'patient', result_id
  );
  return result_id;
end;
$$;

create function public.patient_update_demographics(
  actor_user_id uuid, target_patient_id uuid, demographic jsonb
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id
  from public.patients where id = target_patient_id;
  perform public.patient_update_demographics_mutation(
    actor_user_id, target_patient_id, demographic
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'patient_updated', 'patient', target_patient_id
  );
end;
$$;

create function public.patient_update_contacts(
  actor_user_id uuid, target_patient_id uuid, contact jsonb
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id
  from public.patients where id = target_patient_id;
  perform public.patient_update_contacts_mutation(
    actor_user_id, target_patient_id, contact
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'patient_updated', 'patient', target_patient_id
  );
end;
$$;

create function public.patient_upsert_medical_profile(
  actor_user_id uuid, target_patient_id uuid, medical jsonb
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id
  from public.patients where id = target_patient_id;
  perform public.patient_upsert_medical_profile_mutation(
    actor_user_id, target_patient_id, medical
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'medical_profile_updated',
    'patient', target_patient_id
  );
end;
$$;

create function public.patient_set_archived(
  actor_user_id uuid, target_patient_id uuid, next_archived boolean
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id
  from public.patients where id = target_patient_id;
  perform public.patient_set_archived_mutation(
    actor_user_id, target_patient_id, next_archived
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id,
    case when next_archived then 'patient_archived' else 'patient_restored' end,
    'patient', target_patient_id
  );
end;
$$;

revoke all on function public.patient_create(uuid,uuid,jsonb),
  public.patient_update_demographics(uuid,uuid,jsonb),
  public.patient_update_contacts(uuid,uuid,jsonb),
  public.patient_upsert_medical_profile(uuid,uuid,jsonb),
  public.patient_set_archived(uuid,uuid,boolean)
from public, anon, authenticated;
grant execute on function public.patient_create(uuid,uuid,jsonb),
  public.patient_update_demographics(uuid,uuid,jsonb),
  public.patient_update_contacts(uuid,uuid,jsonb),
  public.patient_upsert_medical_profile(uuid,uuid,jsonb),
  public.patient_set_archived(uuid,uuid,boolean)
to service_role;

alter function public.staff_create_invitation(uuid,uuid,text,bytea,public.clinic_role[])
  rename to staff_create_invitation_mutation;
alter function public.staff_resend_invitation(uuid,uuid,bytea)
  rename to staff_resend_invitation_mutation;
alter function public.staff_revoke_invitation(uuid,uuid)
  rename to staff_revoke_invitation_mutation;
alter function public.staff_accept_invitation(uuid,bytea)
  rename to staff_accept_invitation_mutation;
alter function public.staff_replace_member_roles(uuid,uuid,public.clinic_role[])
  rename to staff_replace_member_roles_mutation;
alter function public.staff_set_member_active(uuid,uuid,boolean)
  rename to staff_set_member_active_mutation;

revoke all on function
  public.staff_create_invitation_mutation(uuid,uuid,text,bytea,public.clinic_role[]),
  public.staff_resend_invitation_mutation(uuid,uuid,bytea),
  public.staff_revoke_invitation_mutation(uuid,uuid),
  public.staff_accept_invitation_mutation(uuid,bytea),
  public.staff_replace_member_roles_mutation(uuid,uuid,public.clinic_role[]),
  public.staff_set_member_active_mutation(uuid,uuid,boolean)
from public, anon, authenticated, service_role;

create function public.staff_create_invitation(
  actor_user_id uuid, target_clinic_id uuid, invited_email text,
  raw_token_digest bytea, invited_roles public.clinic_role[]
)
returns table(invitation_id uuid, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
begin
  select created.invitation_id, created.expires_at
  into invitation_id, expires_at
  from public.staff_create_invitation_mutation(
    actor_user_id, target_clinic_id, invited_email,
    raw_token_digest, invited_roles
  ) created;
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'invitation_created', 'invitation',
    invitation_id, null, jsonb_build_object('roles', to_jsonb(invited_roles))
  );
  return next;
end;
$$;

create function public.staff_resend_invitation(
  actor_user_id uuid, target_invitation_id uuid, raw_token_digest bytea
)
returns table(invitation_id uuid, expires_at timestamptz)
language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id from public.clinic_invitations
  where id = target_invitation_id;
  select resent.invitation_id, resent.expires_at
  into invitation_id, expires_at
  from public.staff_resend_invitation_mutation(
    actor_user_id, target_invitation_id, raw_token_digest
  ) resent;
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'invitation_resent', 'invitation',
    target_invitation_id
  );
  return next;
end;
$$;

create function public.staff_revoke_invitation(
  actor_user_id uuid, target_invitation_id uuid
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id from public.clinic_invitations
  where id = target_invitation_id;
  perform public.staff_revoke_invitation_mutation(
    actor_user_id, target_invitation_id
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'invitation_revoked', 'invitation',
    target_invitation_id
  );
end;
$$;

create function public.staff_accept_invitation(
  actor_user_id uuid, raw_token_digest bytea
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid; target_member_id uuid; target_invitation_id uuid;
begin
  select id into target_invitation_id from public.clinic_invitations
  where token_digest = raw_token_digest and status = 'pending';
  target_clinic_id := public.staff_accept_invitation_mutation(
    actor_user_id, raw_token_digest
  );
  select id into target_member_id from public.clinic_members
  where clinic_id = target_clinic_id and user_id = actor_user_id;
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'invitation_accepted', 'invitation',
    target_invitation_id, null,
    jsonb_build_object('member_id', target_member_id)
  );
  return target_clinic_id;
end;
$$;

create function public.staff_replace_member_roles(
  actor_user_id uuid, target_member_id uuid,
  replacement_roles public.clinic_role[]
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid;
begin
  select clinic_id into target_clinic_id from public.clinic_members
  where id = target_member_id;
  perform public.staff_replace_member_roles_mutation(
    actor_user_id, target_member_id, replacement_roles
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'staff_roles_changed', 'clinic_member',
    target_member_id, null,
    jsonb_build_object(
      'member_id', target_member_id, 'roles', to_jsonb(replacement_roles)
    )
  );
end;
$$;

create function public.staff_set_member_active(
  actor_user_id uuid, target_member_id uuid, next_is_active boolean
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid; previous_is_active boolean;
begin
  select clinic_id, is_active into target_clinic_id, previous_is_active
  from public.clinic_members where id = target_member_id;
  perform public.staff_set_member_active_mutation(
    actor_user_id, target_member_id, next_is_active
  );
  if previous_is_active is distinct from next_is_active then
    perform private.audit_write(
      actor_user_id, target_clinic_id, 'staff_activation_changed',
      'clinic_member', target_member_id, null,
      jsonb_build_object(
        'member_id', target_member_id, 'is_active', next_is_active
      )
    );
  end if;
end;
$$;

revoke all on function
  public.staff_create_invitation(uuid,uuid,text,bytea,public.clinic_role[]),
  public.staff_resend_invitation(uuid,uuid,bytea),
  public.staff_revoke_invitation(uuid,uuid),
  public.staff_accept_invitation(uuid,bytea),
  public.staff_replace_member_roles(uuid,uuid,public.clinic_role[]),
  public.staff_set_member_active(uuid,uuid,boolean)
from public, anon, authenticated;
grant execute on function
  public.staff_create_invitation(uuid,uuid,text,bytea,public.clinic_role[]),
  public.staff_resend_invitation(uuid,uuid,bytea),
  public.staff_revoke_invitation(uuid,uuid),
  public.staff_accept_invitation(uuid,bytea),
  public.staff_replace_member_roles(uuid,uuid,public.clinic_role[]),
  public.staff_set_member_active(uuid,uuid,boolean)
to service_role;

alter function public.appointment_create(
  uuid,uuid,uuid,uuid,timestamptz,timestamptz,text,text
) rename to appointment_create_mutation;
alter function public.appointment_reschedule(uuid,uuid,timestamptz,timestamptz,text)
  rename to appointment_reschedule_mutation;
alter function public.appointment_transition(uuid,uuid,public.appointment_status,text)
  rename to appointment_transition_mutation;

revoke all on function
  public.appointment_create_mutation(
    uuid,uuid,uuid,uuid,timestamptz,timestamptz,text,text
  ),
  public.appointment_reschedule_mutation(uuid,uuid,timestamptz,timestamptz,text),
  public.appointment_transition_mutation(uuid,uuid,public.appointment_status,text)
from public, anon, authenticated, service_role;

create function public.appointment_create(
  actor_user_id uuid,
  target_clinic_id uuid,
  target_patient_id uuid,
  target_dentist_member_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  appointment_purpose text default null,
  supplied_override_reason text default null
)
returns uuid language plpgsql security definer set search_path = '' as $$
declare result_id uuid;
begin
  result_id := public.appointment_create_mutation(
    actor_user_id, target_clinic_id, target_patient_id,
    target_dentist_member_id, target_starts_at, target_ends_at,
    appointment_purpose, supplied_override_reason
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'appointment_created', 'appointment',
    result_id, null,
    jsonb_build_object('patient_id', target_patient_id)
  );
  return result_id;
end;
$$;

create function public.appointment_reschedule(
  actor_user_id uuid,
  target_appointment_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  supplied_override_reason text default null
)
returns void language plpgsql security definer set search_path = '' as $$
declare target_clinic_id uuid; target_patient_id uuid;
begin
  select clinic_id, patient_id into target_clinic_id, target_patient_id
  from public.appointments where id = target_appointment_id;
  perform public.appointment_reschedule_mutation(
    actor_user_id, target_appointment_id, target_starts_at,
    target_ends_at, supplied_override_reason
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'appointment_rescheduled',
    'appointment', target_appointment_id, null,
    jsonb_build_object('patient_id', target_patient_id)
  );
end;
$$;

create function public.appointment_transition(
  actor_user_id uuid,
  target_appointment_id uuid,
  next_status public.appointment_status,
  supplied_cancellation_reason text default null
)
returns void language plpgsql security definer set search_path = '' as $$
declare
  target_clinic_id uuid;
  target_patient_id uuid;
  previous_status public.appointment_status;
begin
  select clinic_id, patient_id, status
  into target_clinic_id, target_patient_id, previous_status
  from public.appointments where id = target_appointment_id;
  perform public.appointment_transition_mutation(
    actor_user_id, target_appointment_id, next_status,
    supplied_cancellation_reason
  );
  perform private.audit_write(
    actor_user_id, target_clinic_id, 'appointment_status_changed',
    'appointment', target_appointment_id,
    case when next_status = 'cancelled'
      then supplied_cancellation_reason else null end,
    jsonb_build_object(
      'patient_id', target_patient_id,
      'previous_status', previous_status,
      'next_status', next_status
    )
  );
end;
$$;

revoke all on function
  public.appointment_create(
    uuid,uuid,uuid,uuid,timestamptz,timestamptz,text,text
  ),
  public.appointment_reschedule(uuid,uuid,timestamptz,timestamptz,text),
  public.appointment_transition(uuid,uuid,public.appointment_status,text)
from public, anon, authenticated;
grant execute on function
  public.appointment_create(
    uuid,uuid,uuid,uuid,timestamptz,timestamptz,text,text
  ),
  public.appointment_reschedule(uuid,uuid,timestamptz,timestamptz,text),
  public.appointment_transition(uuid,uuid,public.appointment_status,text)
to service_role;
