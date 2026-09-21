-- The staff-invitations Edge Function uses the service role only for the
-- minimum preflight reads needed to decide whether password confirmation is
-- required and to address a resend. Public and ordinary authenticated clients
-- remain unable to read beyond their RLS policies.
grant select on table public.clinic_member_roles to service_role;
grant select on table public.clinic_invitation_roles to service_role;
grant select (email) on table public.clinic_invitations to service_role;
