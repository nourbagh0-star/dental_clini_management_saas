-- The Edge Function needs the exact pending object target only after the
-- current uploader and role have been revalidated in PostgreSQL.
create function public.patient_file_authorize_pending(
  actor_user_id uuid,
  target_file_id uuid
)
returns table(
  bucket_id text,
  object_path text,
  declared_mime_type text,
  file_status text,
  expires_at timestamptz
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
    array['dentist', 'assistant']::public.clinic_role[]
  );
  if target.uploaded_by <> actor_user_id then
    raise exception using errcode = 'P0001', message = 'patient_file_forbidden';
  end if;
  if target.status = 'available'::public.patient_file_status then
    return query select target.storage_bucket, target.storage_object_path,
      target.declared_mime_type, target.status::text, target.upload_expires_at;
    return;
  end if;
  if target.status <> 'pending_upload'::public.patient_file_status then
    raise exception using errcode = 'P0001', message = 'patient_file_pending_only';
  end if;
  if target.upload_expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'patient_file_upload_expired';
  end if;
  return query select target.storage_bucket, target.storage_object_path,
    target.declared_mime_type, target.status::text, target.upload_expires_at;
end;
$$;

revoke all on function public.patient_file_authorize_pending(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.patient_file_authorize_pending(uuid, uuid)
  to service_role;
