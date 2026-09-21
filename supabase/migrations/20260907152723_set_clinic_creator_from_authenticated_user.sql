-- Ownership is derived in PostgreSQL from the verified access-token subject.
-- Clients never supply a user ID when creating a clinic.
alter table public.clinics
  alter column created_by set default auth.uid();
