-- PostgreSQL applies RETURNING's SELECT policy before the AFTER INSERT trigger
-- has created the owner membership. The creator predicate is restricted to the
-- verified JWT subject and lets the client receive only its own new row.
drop policy "active members read their clinics" on public.clinics;

create policy "active members read their clinics"
on public.clinics for select
to authenticated
using (
  created_by = (select auth.uid())
  or exists (
    select 1
    from public.clinic_members member
    where member.clinic_id = clinics.id
      and member.user_id = (select auth.uid())
      and member.is_active
  )
);
