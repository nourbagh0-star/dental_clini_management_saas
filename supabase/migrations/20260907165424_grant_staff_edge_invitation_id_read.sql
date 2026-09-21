-- The resend lookup filters on the invitation primary key and returns only its
-- recipient address. PostgreSQL requires SELECT on both referenced columns.
grant select (id, email) on table public.clinic_invitations to service_role;
