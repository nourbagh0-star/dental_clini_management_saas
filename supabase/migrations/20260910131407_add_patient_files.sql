-- Phase 10: immutable clinical patient-file metadata and a narrowly scoped
-- private Storage upload boundary.
create type public.patient_file_category as enum (
  'x_ray',
  'clinical_photo',
  'consent',
  'referral',
  'laboratory_result',
  'other'
);

create type public.patient_file_status as enum (
  'pending_upload',
  'available',
  'archived',
  'rejected'
);

create table public.patient_files (
  id uuid primary key,
  clinic_id uuid not null references public.clinics(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  appointment_id uuid references public.appointments(id) on delete restrict,
  clinical_session_id uuid references public.clinical_sessions(id) on delete restrict,
  replaces_file_id uuid references public.patient_files(id) on delete restrict,
  category public.patient_file_category not null,
  description text,
  original_filename text not null,
  storage_bucket text not null default 'patient-files',
  storage_object_path text not null unique,
  extension text not null,
  declared_mime_type text not null,
  detected_mime_type text,
  size_bytes bigint,
  status public.patient_file_status not null default 'pending_upload',
  uploaded_by uuid not null references auth.users(id) on delete restrict,
  upload_expires_at timestamptz not null,
  available_at timestamptz,
  archived_at timestamptz,
  archived_by uuid references auth.users(id) on delete restrict,
  archive_reason text,
  rejection_code text,
  rejected_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint patient_files_description check (
    description is null or (
      description = btrim(description)
      and char_length(description) between 1 and 1000
    )
  ),
  constraint patient_files_original_filename check (
    original_filename = btrim(original_filename)
    and char_length(original_filename) between 1 and 255
    and original_filename !~ '[[:cntrl:]/\\]'
  ),
  constraint patient_files_bucket check (storage_bucket = 'patient-files'),
  constraint patient_files_extension check (extension in ('jpg', 'png', 'pdf')),
  constraint patient_files_declared_mime check (
    (extension = 'jpg' and declared_mime_type = 'image/jpeg')
    or (extension = 'png' and declared_mime_type = 'image/png')
    or (extension = 'pdf' and declared_mime_type = 'application/pdf')
  ),
  constraint patient_files_detected_mime check (
    detected_mime_type is null
    or detected_mime_type in ('image/jpeg', 'image/png', 'application/pdf')
  ),
  constraint patient_files_size check (
    size_bytes is null or size_bytes between 1 and 15728640
  ),
  constraint patient_files_archive_reason check (
    archive_reason is null or (
      archive_reason = btrim(archive_reason)
      and char_length(archive_reason) between 1 and 1000
    )
  ),
  constraint patient_files_rejection_code check (
    rejection_code is null or rejection_code ~ '^patient_file_[a-z_]{1,80}$'
  ),
  constraint patient_files_status_metadata check (
    (status = 'pending_upload'::public.patient_file_status
      and detected_mime_type is null and size_bytes is null
      and available_at is null and archived_at is null and archived_by is null
      and archive_reason is null and rejection_code is null and rejected_at is null)
    or (status = 'available'::public.patient_file_status
      and detected_mime_type is not null and size_bytes is not null
      and available_at is not null and archived_at is null and archived_by is null
      and archive_reason is null and rejection_code is null and rejected_at is null)
    or (status = 'archived'::public.patient_file_status
      and detected_mime_type is not null and size_bytes is not null
      and available_at is not null and archived_at is not null and archived_by is not null
      and archive_reason is not null and rejection_code is null and rejected_at is null)
    or (status = 'rejected'::public.patient_file_status
      and archived_at is null and archived_by is null and archive_reason is null
      and rejection_code is not null and rejected_at is not null)
  )
);

create index patient_files_patient_history_idx
  on public.patient_files (clinic_id, patient_id, status, created_at desc, id desc);
create index patient_files_category_idx
  on public.patient_files (clinic_id, patient_id, category, created_at desc);
create index patient_files_appointment_idx
  on public.patient_files (appointment_id) where appointment_id is not null;
create index patient_files_session_idx
  on public.patient_files (clinical_session_id) where clinical_session_id is not null;
create index patient_files_replacement_idx
  on public.patient_files (replaces_file_id) where replaces_file_id is not null;
create index patient_files_pending_expiry_idx
  on public.patient_files (upload_expires_at)
  where status = 'pending_upload'::public.patient_file_status;

create function private.require_patient_file_role(
  target_clinic_id uuid,
  actor_user_id uuid,
  allowed public.clinic_role[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from unnest(allowed) role_value
    where private.has_clinic_role(target_clinic_id, role_value, actor_user_id)
  ) then
    raise exception using errcode = 'P0001', message = 'patient_file_forbidden';
  end if;
end;
$$;

create function private.patient_file_target(
  target_file_id uuid,
  lock_row boolean default false
)
returns public.patient_files
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patient_files%rowtype;
begin
  if lock_row then
    select * into target from public.patient_files
    where id = target_file_id for update;
  else
    select * into target from public.patient_files
    where id = target_file_id;
  end if;
  if not found then
    raise exception using errcode = 'P0001', message = 'patient_file_unavailable';
  end if;
  return target;
end;
$$;

create function private.assert_patient_file_scope()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  linked_session public.clinical_sessions%rowtype;
begin
  if not exists (
    select 1 from public.patients patient
    where patient.id = new.patient_id and patient.clinic_id = new.clinic_id
  ) then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  if new.appointment_id is not null and not exists (
    select 1 from public.appointments appointment
    where appointment.id = new.appointment_id
      and appointment.clinic_id = new.clinic_id
      and appointment.patient_id = new.patient_id
  ) then
    raise exception using errcode = 'P0001', message = 'appointment_unavailable';
  end if;
  if new.clinical_session_id is not null then
    select * into linked_session from public.clinical_sessions
    where id = new.clinical_session_id;
    if not found or linked_session.clinic_id <> new.clinic_id
      or linked_session.patient_id <> new.patient_id
      or linked_session.status = 'entered_in_error'::public.clinical_session_status then
      raise exception using errcode = 'P0001', message = 'clinical_session_unavailable';
    end if;
    if new.appointment_id is not null
      and linked_session.appointment_id is not null
      and new.appointment_id <> linked_session.appointment_id then
      raise exception using errcode = 'P0001', message = 'appointment_unavailable';
    end if;
  end if;
  if new.replaces_file_id is not null and not exists (
    select 1 from public.patient_files replaced
    where replaced.id = new.replaces_file_id
      and replaced.clinic_id = new.clinic_id
      and replaced.patient_id = new.patient_id
      and replaced.status in (
        'available'::public.patient_file_status,
        'archived'::public.patient_file_status
      )
  ) then
    raise exception using errcode = 'P0001', message = 'replacement_file_unavailable';
  end if;
  if new.storage_object_path <> concat(
    new.clinic_id::text, '/', new.patient_id::text, '/', new.id::text,
    '/file.', new.extension
  ) then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
  end if;
  return new;
end;
$$;

create function private.assert_patient_file_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception using errcode = 'P0001', message = 'patient_file_immutable';
  end if;
  if old.id <> new.id or old.clinic_id <> new.clinic_id
    or old.patient_id <> new.patient_id
    or old.appointment_id is distinct from new.appointment_id
    or old.clinical_session_id is distinct from new.clinical_session_id
    or old.replaces_file_id is distinct from new.replaces_file_id
    or old.category <> new.category
    or old.description is distinct from new.description
    or old.original_filename <> new.original_filename
    or old.storage_bucket <> new.storage_bucket
    or old.storage_object_path <> new.storage_object_path
    or old.extension <> new.extension
    or old.declared_mime_type <> new.declared_mime_type
    or old.uploaded_by <> new.uploaded_by
    or old.upload_expires_at <> new.upload_expires_at
    or old.created_at <> new.created_at then
    raise exception using errcode = 'P0001', message = 'patient_file_identity_immutable';
  end if;
  if old.status = 'pending_upload'::public.patient_file_status
    and new.status in (
      'pending_upload'::public.patient_file_status,
      'available'::public.patient_file_status,
      'rejected'::public.patient_file_status
    ) then
    return new;
  end if;
  if old.status = 'available'::public.patient_file_status
    and new.status = 'archived'::public.patient_file_status then
    return new;
  end if;
  if old.status = 'archived'::public.patient_file_status
    and new.status = 'available'::public.patient_file_status then
    return new;
  end if;
  raise exception using errcode = 'P0001', message = 'invalid_patient_file_transition';
end;
$$;

create trigger patient_files_match_scope
before insert or update of clinic_id, patient_id, appointment_id,
  clinical_session_id, replaces_file_id, storage_object_path, extension
on public.patient_files
for each row execute function private.assert_patient_file_scope();

create trigger patient_files_enforce_lifecycle
before update or delete on public.patient_files
for each row execute function private.assert_patient_file_lifecycle();

create trigger patient_files_set_updated_at
before update on public.patient_files
for each row execute function private.set_updated_at();

alter table public.patient_files enable row level security;

revoke all on table public.patient_files from anon, authenticated;
grant select on table public.patient_files to authenticated;

create policy "clinical staff read accepted patient files"
on public.patient_files for select
to authenticated
using (
  status in ('available'::public.patient_file_status, 'archived'::public.patient_file_status)
  and (
    private.has_clinic_role(clinic_id, 'owner'::public.clinic_role, (select auth.uid()))
    or private.has_clinic_role(clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
    or private.has_clinic_role(clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
  )
);

create policy "uploaders read own pending patient files"
on public.patient_files for select
to authenticated
using (
  status = 'pending_upload'::public.patient_file_status
  and uploaded_by = (select auth.uid())
  and upload_expires_at > now()
  and (
    private.has_clinic_role(clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
    or private.has_clinic_role(clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
  )
);

create policy "clinical uploaders create exact pending storage objects"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'patient-files'
  and exists (
    select 1 from public.patient_files file
    where file.storage_object_path = name
      and file.storage_bucket = bucket_id
      and file.status = 'pending_upload'::public.patient_file_status
      and file.uploaded_by = (select auth.uid())
      and file.upload_expires_at > now()
      and (
        private.has_clinic_role(file.clinic_id, 'dentist'::public.clinic_role, (select auth.uid()))
        or private.has_clinic_role(file.clinic_id, 'assistant'::public.clinic_role, (select auth.uid()))
      )
  )
);

create function public.patient_file_create_upload(
  actor_user_id uuid,
  target_patient_id uuid,
  target_appointment_id uuid,
  target_clinical_session_id uuid,
  target_replaces_file_id uuid,
  target_category public.patient_file_category,
  supplied_description text,
  supplied_original_filename text,
  supplied_extension text,
  supplied_mime_type text
)
returns table(file_id uuid, object_path text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  patient public.patients%rowtype;
  normalized_description text := nullif(btrim(supplied_description), '');
  normalized_filename text := btrim(supplied_original_filename);
  normalized_extension text := lower(btrim(supplied_extension));
  normalized_mime text := lower(btrim(supplied_mime_type));
  next_id uuid := gen_random_uuid();
  next_expiry timestamptz := now() + interval '2 hours';
  next_path text;
begin
  select * into patient from public.patients
  where id = target_patient_id for share;
  if not found then
    raise exception using errcode = 'P0001', message = 'patient_unavailable';
  end if;
  if patient.archived_at is not null then
    raise exception using errcode = 'P0001', message = 'patient_archived';
  end if;
  perform private.require_patient_file_role(
    patient.clinic_id, actor_user_id,
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if normalized_extension = 'jpeg' then normalized_extension := 'jpg'; end if;
  if normalized_filename is null or normalized_filename = ''
    or char_length(normalized_filename) > 255
    or normalized_filename ~ '[[:cntrl:]/\\]' then
    raise exception using errcode = 'P0001', message = 'patient_file_invalid_name';
  end if;
  if not (
    (normalized_extension = 'jpg' and normalized_mime = 'image/jpeg')
    or (normalized_extension = 'png' and normalized_mime = 'image/png')
    or (normalized_extension = 'pdf' and normalized_mime = 'application/pdf')
  ) then
    raise exception using errcode = 'P0001', message = 'patient_file_type_not_allowed';
  end if;
  next_path := concat(
    patient.clinic_id::text, '/', patient.id::text, '/', next_id::text,
    '/file.', normalized_extension
  );
  insert into public.patient_files (
    id, clinic_id, patient_id, appointment_id, clinical_session_id,
    replaces_file_id, category, description, original_filename,
    storage_object_path, extension, declared_mime_type, uploaded_by,
    upload_expires_at
  ) values (
    next_id, patient.clinic_id, patient.id, target_appointment_id,
    target_clinical_session_id, target_replaces_file_id, target_category,
    normalized_description, normalized_filename, next_path,
    normalized_extension, normalized_mime, actor_user_id, next_expiry
  );
  return query select next_id, next_path, next_expiry;
exception
  when check_violation or not_null_violation or invalid_text_representation then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
end;
$$;

create function public.patient_file_complete_upload(
  actor_user_id uuid,
  target_file_id uuid,
  actual_mime_type text,
  actual_size_bytes bigint
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patient_files%rowtype;
  normalized_mime text := lower(btrim(actual_mime_type));
begin
  target := private.patient_file_target(target_file_id, true);
  perform private.require_patient_file_role(
    target.clinic_id, actor_user_id,
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if target.uploaded_by <> actor_user_id then
    raise exception using errcode = 'P0001', message = 'patient_file_forbidden';
  end if;
  if target.status = 'available'::public.patient_file_status then
    return target.status::text;
  end if;
  if target.status <> 'pending_upload'::public.patient_file_status then
    raise exception using errcode = 'P0001', message = 'patient_file_pending_only';
  end if;
  if target.upload_expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'patient_file_upload_expired';
  end if;
  if actual_size_bytes is null or actual_size_bytes < 1 then
    raise exception using errcode = 'P0001', message = 'patient_file_empty';
  end if;
  if actual_size_bytes > 15728640 then
    raise exception using errcode = 'P0001', message = 'patient_file_too_large';
  end if;
  if normalized_mime <> target.declared_mime_type then
    raise exception using errcode = 'P0001', message = 'patient_file_signature_mismatch';
  end if;
  update public.patient_files
  set status = 'available'::public.patient_file_status,
      detected_mime_type = normalized_mime,
      size_bytes = actual_size_bytes,
      available_at = now()
  where id = target.id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'patient_file_uploaded',
    'patient_file', target.id,
    jsonb_build_object('patient_id', target.patient_id, 'category', target.category)
  );
  return 'available';
exception
  when check_violation or not_null_violation or numeric_value_out_of_range then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
end;
$$;

create function public.patient_file_reject_upload(
  actor_user_id uuid,
  target_file_id uuid,
  supplied_rejection_code text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patient_files%rowtype;
  normalized_code text := lower(btrim(supplied_rejection_code));
begin
  target := private.patient_file_target(target_file_id, true);
  perform private.require_patient_file_role(
    target.clinic_id, actor_user_id,
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if target.uploaded_by <> actor_user_id then
    raise exception using errcode = 'P0001', message = 'patient_file_forbidden';
  end if;
  if target.status = 'rejected'::public.patient_file_status then return; end if;
  if target.status <> 'pending_upload'::public.patient_file_status then
    raise exception using errcode = 'P0001', message = 'patient_file_pending_only';
  end if;
  if normalized_code !~ '^patient_file_[a-z_]{1,80}$' then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
  end if;
  update public.patient_files
  set status = 'rejected'::public.patient_file_status,
      rejection_code = normalized_code,
      rejected_at = now()
  where id = target.id;
end;
$$;

create function public.patient_file_archive(
  actor_user_id uuid,
  target_file_id uuid,
  supplied_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patient_files%rowtype;
  normalized_reason text := nullif(btrim(supplied_reason), '');
begin
  target := private.patient_file_target(target_file_id, true);
  perform private.require_patient_file_role(
    target.clinic_id, actor_user_id,
    array['owner', 'dentist']::public.clinic_role[]
  );
  if target.status <> 'available'::public.patient_file_status then
    raise exception using errcode = 'P0001', message = 'patient_file_available_only';
  end if;
  if normalized_reason is null then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
  end if;
  update public.patient_files
  set status = 'archived'::public.patient_file_status,
      archived_at = now(), archived_by = actor_user_id,
      archive_reason = normalized_reason
  where id = target.id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id,
    reason, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'patient_file_archived',
    'patient_file', target.id, normalized_reason,
    jsonb_build_object('patient_id', target.patient_id, 'category', target.category)
  );
exception
  when check_violation then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
end;
$$;

create function public.patient_file_restore(
  actor_user_id uuid,
  target_file_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patient_files%rowtype;
begin
  target := private.patient_file_target(target_file_id, true);
  perform private.require_patient_file_role(
    target.clinic_id, actor_user_id,
    array['owner', 'dentist']::public.clinic_role[]
  );
  if target.status <> 'archived'::public.patient_file_status then
    raise exception using errcode = 'P0001', message = 'patient_file_archived_only';
  end if;
  update public.patient_files
  set status = 'available'::public.patient_file_status,
      archived_at = null, archived_by = null, archive_reason = null
  where id = target.id;
  insert into public.audit_events (
    clinic_id, actor_user_id, event_type, subject_type, subject_id, safe_metadata
  ) values (
    target.clinic_id, actor_user_id, 'patient_file_restored',
    'patient_file', target.id,
    jsonb_build_object('patient_id', target.patient_id, 'category', target.category)
  );
end;
$$;

create function public.patient_file_authorize_read(
  actor_user_id uuid,
  target_file_id uuid
)
returns table(
  bucket_id text,
  object_path text,
  mime_type text,
  download_name text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.patient_files%rowtype;
begin
  target := private.patient_file_target(target_file_id, false);
  perform private.require_patient_file_role(
    target.clinic_id, actor_user_id,
    array['owner', 'dentist', 'assistant']::public.clinic_role[]
  );
  if target.status not in (
    'available'::public.patient_file_status,
    'archived'::public.patient_file_status
  ) then
    raise exception using errcode = 'P0001', message = 'patient_file_unavailable';
  end if;
  return query select target.storage_bucket, target.storage_object_path,
    target.detected_mime_type, target.original_filename;
end;
$$;

create function public.patient_file_expire_uploads(
  actor_user_id uuid,
  target_clinic_id uuid,
  batch_limit integer default 20
)
returns table(file_id uuid, object_path text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_patient_file_role(
    target_clinic_id, actor_user_id,
    array['owner', 'dentist', 'assistant']::public.clinic_role[]
  );
  if batch_limit < 1 or batch_limit > 20 then
    raise exception using errcode = 'P0001', message = 'invalid_patient_file_input';
  end if;
  return query
  with expired as (
    select file.id
    from public.patient_files file
    where file.clinic_id = target_clinic_id
      and file.status = 'pending_upload'::public.patient_file_status
      and file.upload_expires_at <= now()
    order by file.upload_expires_at, file.id
    limit batch_limit
    for update skip locked
  ), changed as (
    update public.patient_files file
    set status = 'rejected'::public.patient_file_status,
        rejection_code = 'patient_file_upload_expired',
        rejected_at = now()
    from expired
    where file.id = expired.id
    returning file.id, file.storage_object_path
  )
  select changed.id, changed.storage_object_path from changed;
end;
$$;

revoke all on function private.require_patient_file_role(uuid, uuid, public.clinic_role[]) from public;
revoke all on function private.patient_file_target(uuid, boolean) from public;
revoke all on function private.assert_patient_file_scope() from public;
revoke all on function private.assert_patient_file_lifecycle() from public;

revoke all on function public.patient_file_create_upload(
  uuid, uuid, uuid, uuid, uuid, public.patient_file_category,
  text, text, text, text
) from public, anon, authenticated;
revoke all on function public.patient_file_complete_upload(uuid, uuid, text, bigint)
  from public, anon, authenticated;
revoke all on function public.patient_file_reject_upload(uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function public.patient_file_archive(uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function public.patient_file_restore(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.patient_file_authorize_read(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.patient_file_expire_uploads(uuid, uuid, integer)
  from public, anon, authenticated;

grant execute on function public.patient_file_create_upload(
  uuid, uuid, uuid, uuid, uuid, public.patient_file_category,
  text, text, text, text
) to service_role;
grant execute on function public.patient_file_complete_upload(uuid, uuid, text, bigint)
  to service_role;
grant execute on function public.patient_file_reject_upload(uuid, uuid, text)
  to service_role;
grant execute on function public.patient_file_archive(uuid, uuid, text)
  to service_role;
grant execute on function public.patient_file_restore(uuid, uuid)
  to service_role;
grant execute on function public.patient_file_authorize_read(uuid, uuid)
  to service_role;
grant execute on function public.patient_file_expire_uploads(uuid, uuid, integer)
  to service_role;
