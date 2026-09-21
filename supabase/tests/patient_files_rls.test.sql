begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

select ok(
  (select relrowsecurity from pg_class where oid = 'public.patient_files'::regclass),
  'patient files have RLS'
);
select ok(
  not has_table_privilege('authenticated', 'public.patient_files', 'insert'),
  'browser cannot insert patient-file metadata'
);
select ok(
  not has_table_privilege('authenticated', 'public.patient_files', 'update'),
  'browser cannot update patient-file metadata'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname = 'clinical uploaders create exact pending storage objects'
  ),
  'Storage has an exact pending-object upload policy'
);

insert into auth.users (id, email) values
  ('10101010-1010-4010-8010-101010101010', 'file-owner@example.test'),
  ('20202020-2020-4020-8020-202020202020', 'file-dentist@example.test'),
  ('30303030-3030-4030-8030-303030303030', 'file-assistant@example.test'),
  ('40404040-4040-4040-8040-404040404040', 'file-reception@example.test');

insert into public.clinics (id, name, currency_code, time_zone, created_by)
values (
  'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0',
  'Files Demo', 'RUB', 'Europe/Moscow',
  '10101010-1010-4010-8010-101010101010'
);

insert into public.clinic_members (id, clinic_id, user_id, email) values
  ('b0b0b0b0-b0b0-40b0-80b0-b0b0b0b0b0b0', 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0', '20202020-2020-4020-8020-202020202020', 'file-dentist@example.test'),
  ('c0c0c0c0-c0c0-40c0-80c0-c0c0c0c0c0c0', 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0', '30303030-3030-4030-8030-303030303030', 'file-assistant@example.test'),
  ('d0d0d0d0-d0d0-40d0-80d0-d0d0d0d0d0d0', 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0', '40404040-4040-4040-8040-404040404040', 'file-reception@example.test');

insert into public.clinic_member_roles (clinic_member_id, role, assigned_by) values
  ('b0b0b0b0-b0b0-40b0-80b0-b0b0b0b0b0b0', 'dentist', '10101010-1010-4010-8010-101010101010'),
  ('c0c0c0c0-c0c0-40c0-80c0-c0c0c0c0c0c0', 'assistant', '10101010-1010-4010-8010-101010101010'),
  ('d0d0d0d0-d0d0-40d0-80d0-d0d0d0d0d0d0', 'receptionist', '10101010-1010-4010-8010-101010101010');

insert into public.patients (
  id, clinic_id, patient_number, first_name, last_name, phone,
  birth_date_precision, created_by
) values
  ('e0e0e0e0-e0e0-40e0-80e0-e0e0e0e0e0e0', 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0', 'PAT-10001', 'File', 'Patient', '+79990000101', 'unknown', '10101010-1010-4010-8010-101010101010'),
  ('f0f0f0f0-f0f0-40f0-80f0-f0f0f0f0f0f0', 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0', 'PAT-10002', 'Other', 'Patient', '+79990000102', 'unknown', '10101010-1010-4010-8010-101010101010');

select lives_ok(
  $$select public.patient_file_create_upload(
    '30303030-3030-4030-8030-303030303030',
    'e0e0e0e0-e0e0-40e0-80e0-e0e0e0e0e0e0', null, null, null,
    'x_ray', 'Initial radiograph', 'scan.jpeg', 'jpeg', 'image/jpeg'
  )$$,
  'Assistant creates a pending upload'
);
select is(
  (select extension from public.patient_files
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
  'jpg', 'JPEG extension is normalized'
);
select matches(
  (select storage_object_path from public.patient_files
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
  '^a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0/e0e0e0e0-e0e0-40e0-80e0-e0e0e0e0e0e0/[0-9a-f-]+/file\.jpg$',
  'object path is server generated and correctly scoped'
);
select throws_ok(
  $$select public.patient_file_create_upload(
    '10101010-1010-4010-8010-101010101010',
    'e0e0e0e0-e0e0-40e0-80e0-e0e0e0e0e0e0', null, null, null,
    'other', null, 'owner.pdf', 'pdf', 'application/pdf'
  )$$,
  'P0001', 'patient_file_forbidden',
  'Owner without Dentist role cannot upload'
);
select throws_ok(
  $$select public.patient_file_create_upload(
    '30303030-3030-4030-8030-303030303030',
    'e0e0e0e0-e0e0-40e0-80e0-e0e0e0e0e0e0', null, null, null,
    'other', null, 'malware.exe', 'exe', 'application/octet-stream'
  )$$,
  'P0001', 'patient_file_type_not_allowed',
  'unsupported file type is rejected'
);
select throws_ok(
  $$select public.patient_file_complete_upload(
    '20202020-2020-4020-8020-202020202020',
    (select id from public.patient_files
     where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
    'image/jpeg', 1200
  )$$,
  'P0001', 'patient_file_forbidden',
  'another clinical user cannot complete the upload'
);
select lives_ok(
  $$select public.patient_file_complete_upload(
    '30303030-3030-4030-8030-303030303030',
    (select id from public.patient_files
     where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
    'image/jpeg', 1200
  )$$,
  'uploader completes a validated upload'
);
select is(
  (select status::text from public.patient_files
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
  'available', 'completed upload is available'
);
select lives_ok(
  $$select public.patient_file_complete_upload(
    '30303030-3030-4030-8030-303030303030',
    (select id from public.patient_files
     where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
    'image/jpeg', 1200
  )$$,
  'completion is idempotent'
);
select throws_ok(
  $$select public.patient_file_archive(
    '30303030-3030-4030-8030-303030303030',
    (select id from public.patient_files
     where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
    'Assistant archive'
  )$$,
  'P0001', 'patient_file_forbidden',
  'Assistant cannot archive an accepted file'
);
select lives_ok(
  $$select public.patient_file_archive(
    '10101010-1010-4010-8010-101010101010',
    (select id from public.patient_files
     where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
    'Superseded by newer image'
  )$$,
  'Owner archives an accepted file'
);
select is(
  (select status::text from public.patient_files
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
  'archived', 'file is archived without deletion'
);
select lives_ok(
  $$select public.patient_file_restore(
    '20202020-2020-4020-8020-202020202020',
    (select id from public.patient_files
     where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1)
  )$$,
  'Dentist restores an archived file'
);
select is(
  (select status::text from public.patient_files
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0' limit 1),
  'available', 'restored file is available again'
);
select throws_ok(
  $$delete from public.patient_files where true$$,
  'P0001', 'patient_file_immutable',
  'accepted file metadata cannot be deleted'
);

-- Preserve the legacy RLS behavior checks inside this rolled-back test only.
grant select on all tables in schema public to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = '40404040-4040-4040-8040-404040404040';
select is((select count(*)::integer from public.patient_files), 0,
  'Receptionist cannot discover patient files');
reset role;

set local role authenticated;
set local request.jwt.claim.sub = '10101010-1010-4010-8010-101010101010';
select is((select count(*)::integer from public.patient_files), 1,
  'Owner can read accepted patient files');
reset role;

set local role authenticated;
set local request.jwt.claim.sub = '30303030-3030-4030-8030-303030303030';
select is((select count(*)::integer from public.patient_files), 1,
  'Assistant can read accepted patient files');
reset role;

select is(
  (select count(*)::integer from public.audit_events
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0'
     and event_type like 'patient_file_%'),
  3, 'upload, archive, and restore create audit events'
);
select is(
  (select count(*)::integer from public.audit_events
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0'
     and event_type like 'patient_file_%'
     and safe_metadata ? 'original_filename'),
  0, 'audit metadata excludes filenames'
);
select is(
  (select count(*)::integer from public.audit_events
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0'
     and event_type like 'patient_file_%'
     and safe_metadata ? 'storage_object_path'),
  0, 'audit metadata excludes Storage paths'
);
select is(
  (select count(*)::integer from public.patient_files
   where clinic_id = 'a0a0a0a0-a0a0-40a0-80a0-a0a0a0a0a0a0'
     and size_bytes <= 15728640),
  1, 'accepted size remains within the product limit'
);

select * from finish();
rollback;
