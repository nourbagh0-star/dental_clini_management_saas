-- Active operational staff need dentist names to view a clinic calendar, but
-- this narrow read command does not expose general staff roles or mutations.
create function public.doctor_schedule_readable_dentists(target_clinic_id uuid)
returns table (member_id uuid, email text)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_active_clinic_member(target_clinic_id, (select auth.uid())) then
    return;
  end if;

  return query
  select member.id, member.email
  from public.clinic_members member
  join public.clinic_member_roles member_role
    on member_role.clinic_member_id = member.id
  where member.clinic_id = target_clinic_id
    and member.is_active
    and member_role.role = 'dentist'::public.clinic_role
  order by member.email;
end;
$$;

revoke all on function public.doctor_schedule_readable_dentists(uuid)
  from public, anon;
grant execute on function public.doctor_schedule_readable_dentists(uuid)
  to authenticated;
