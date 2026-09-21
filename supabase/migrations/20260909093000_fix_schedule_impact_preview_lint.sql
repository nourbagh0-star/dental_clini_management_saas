create or replace function public.doctor_schedule_preview_exception_impact(
  actor_user_id uuid,
  target_dentist_member_id uuid,
  exception_starts_at timestamptz,
  exception_ends_at timestamptz
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  affected_count integer;
begin
  perform 1
  from private.require_schedule_editor(actor_user_id, target_dentist_member_id);
  affected_count := private.schedule_record_appointment_impacts(
    actor_user_id, target_dentist_member_id, exception_starts_at,
    exception_ends_at, 'unavailable'::public.appointment_conflict_kind
  );
  return jsonb_build_object('count', affected_count);
end;
$$;
