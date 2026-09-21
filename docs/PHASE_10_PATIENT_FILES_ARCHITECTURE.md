# Phase 10 — Patient Files Architecture

Status: approved and implemented; final verification recorded below.

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 10–16,
41–42, 53, 55–56, 69–70, 76–77, 80–85, plus the product decisions approved on
2026-09-10.

## Approved product decisions

- Every file introduced in Phase 10 is clinical information. Receptionists
  cannot see the files screen, file metadata, previews, or download actions.
- Dentists and Assistants may upload files. Owners, Dentists, and Assistants
  may read them.
- Owners and Dentists may archive and restore files. Assistants cannot change
  file lifecycle state after an upload becomes available.
- Files are immutable. A replacement is a new object and a new database record;
  an existing Storage object is never overwritten.
- Every file requires one category: X-ray, clinical photo, consent, referral,
  laboratory result, or other. A description is optional.
- A file may optionally refer to an appointment or clinical session.
- Storage is private. The application never creates or displays a public URL.
- Initial formats are JPG/JPEG, PNG, and PDF, with a maximum size of 15 MiB per
  file. DICOM and HEIC remain future work.
- Uploads are resumable and show progress and retry controls.
- Extension, declared MIME type, detected file signature, and size are
  validated before a file becomes available.
- Images have an in-app preview. PDFs open through a short-lived private URL.
- Archived files remain stored and auditable. Normal application flows never
  permanently delete an accepted file.
- Phase 10 uses the platform file picker. Camera capture is deferred.
- Only fictional or demonstration files may be used during the free-tier MVP.
  The model leaves a validation boundary for production malware scanning.

## Goal and scope

Phase 10 adds a secure **Files** area to each patient profile. Authorized staff
can upload, inspect, preview, download, archive, restore, and replace clinical
files without making Storage public or weakening clinic isolation.

This phase does not add camera capture, DICOM/HEIC support, image editing,
annotations, OCR, malware scanning, billing attachments, bulk patient exports,
or permanent deletion. It does not change clinical-session content when a file
is linked to a visit. Billing and invoice PDFs remain Phase 11 work.

## Core workflows

### Upload

1. A Dentist or Assistant opens a patient's Files screen and selects one file.
2. Flutter performs fast local checks for supported extension, declared MIME
   type, signature, and size. These checks provide immediate feedback but are
   not trusted as the security boundary.
3. Flutter calls the protected `patient-files` Edge Function with
   `create_upload`. The command verifies the active clinic membership, clinical
   upload role, patient status, category, and optional appointment/session
   links.
4. PostgreSQL creates a `pending_upload` record and a unique object path. The
   server returns the file ID, exact upload target, and expiry. The Storage
   adapter supplies the current user's access token directly to Storage.
5. The Storage adapter uploads directly from Flutter to Supabase Storage using
   the TUS resumable protocol. The object is never proxied through the Edge
   Function. Upload progress is visible and a network interruption can resume
   while the selected local file remains available.
6. Flutter calls `complete_upload`. The server rechecks authorization and reads
   the object metadata plus only the bytes needed to identify its signature.
7. A valid object becomes `available`. An invalid object is removed through the
   Storage API and its metadata record becomes `rejected` with a safe reason
   code.
8. The Files list refreshes and displays the accepted record.

The completion operation is idempotent. Retrying it after an uncertain network
response returns the existing result instead of duplicating the file.

### View or download

1. An authorized Owner, Dentist, or Assistant selects an available or archived
   file.
2. Flutter requests `create_read_url` for that exact file ID.
3. The Edge Function verifies current membership and patient/file scope, then
   creates a private URL valid for 60 seconds.
4. Images are fetched into memory and shown in the application. PDFs open in a
   browser or platform viewer using that URL. The application does not persist
   preview bytes or URLs in preferences, analytics, or logs.

The short lifetime limits exposure if a URL is copied. Supabase signed URLs
remain usable until they expire, so the application never creates long-lived
links.

### Archive, restore, and replace

- An Owner or Dentist archives a file with a required reason. The object stays
  in private Storage and the record remains readable through the archived-file
  filter.
- An Owner or Dentist may restore an archived file. Both actions are audited.
- **Upload replacement** starts the normal upload flow with
  `replaces_file_id`. The earlier file is not changed automatically. After the
  new upload succeeds, the user may archive the older file explicitly.
- Rejected and abandoned uploads are not clinical records. Their invalid or
  incomplete objects may be removed during cleanup, while their safe metadata
  status is retained for troubleshooting.

## Storage architecture

### Bucket

The initial adapter uses one private bucket:

```text
patient-files
  public: false
  file size limit: 15728640 bytes (15 MiB)
  allowed MIME types:
    image/jpeg
    image/png
    application/pdf
```

Local development declares the bucket in `supabase/config.toml`. Hosted setup
creates or updates it through the supported Supabase Storage API as a deployment
step. Migrations do not insert, update, or delete rows in the internal
`storage` schema because Supabase documents those tables as service-owned.

The global free-tier limit remains at least 15 MiB; the bucket applies the
smaller product-specific limit. Current Supabase documentation states that
Free projects can configure a global maximum up to 50 MB and recommends
resumable TUS uploads for files larger than 6 MB.

### Object path

```text
clinic_id/patient_id/file_id/file.ext
```

`file_id` is a server-generated random UUID. The final object name is generated
from the verified format, such as `file.pdf` or `file.jpg`. The patient's name
and the user's original filename never appear in the Storage path. The original
filename is stored only in the protected metadata table for display.

Paths are created by the server. The client cannot choose or alter a clinic ID,
patient ID, file ID, or extension. Uploads use create-only semantics and never
set an upsert flag.

### Transfer protocol and portability

The Supabase adapter uses the direct Storage hostname in hosted environments
and the local Storage endpoint during development. It creates one TUS upload
with a 6 MiB chunk size, sends the current user access token, rejects overwrite,
and reports progress through a stream.

The domain layer depends on a `FileTransferClient`, not on Supabase Storage.
Changing providers later requires a new transfer adapter and server-side object
gateway; patient-file screens, state, and domain models remain unchanged.

Resume support covers network interruption and retry while the application
still has access to the selected local file. Browser refresh discards the file
handle for security, so the user must select the same file again or cancel the
pending upload. The server safely reconciles the pending record in either case.

## Validation pipeline

The accepted combinations are exact:

| Extension | Declared MIME | Required leading signature |
| --- | --- | --- |
| `.jpg`, `.jpeg` | `image/jpeg` | JPEG SOI marker |
| `.png` | `image/png` | PNG eight-byte signature |
| `.pdf` | `application/pdf` | `%PDF-` |

Validation occurs twice:

- Flutter checks before transfer to avoid wasting bandwidth.
- The Edge Function verifies the actual Storage object before changing its
  status to `available`.

The server confirms the exact path, bucket, recorded byte length, declared
content type, allowed extension, and signature. Signature inspection uses a
bounded streaming read and cancels after enough bytes are available; it does
not buffer the full 15 MiB object. A mismatch rejects the upload and removes the
object through the Storage API.

These checks detect accidental or simple format spoofing. They are not malware
scanning and cannot prove that a complex PDF or image is safe. Production
activation with real patient data requires a reviewed quarantine and malware
scanning service. The `pending_upload` state is the future quarantine boundary,
so adding that service will not require a Flutter workflow rewrite.

## Data model

### Types

```text
patient_file_category
  x_ray
  clinical_photo
  consent
  referral
  laboratory_result
  other

patient_file_status
  pending_upload
  available
  archived
  rejected
```

### Patient files

```text
patient_files
  id uuid primary key
  clinic_id uuid
  patient_id uuid
  appointment_id uuid nullable
  clinical_session_id uuid nullable
  replaces_file_id uuid nullable
  category patient_file_category
  description text nullable
  original_filename text
  storage_bucket text
  storage_object_path text unique
  extension text
  declared_mime_type text
  detected_mime_type text nullable
  size_bytes bigint nullable
  status patient_file_status
  uploaded_by uuid
  upload_expires_at timestamptz
  available_at timestamptz nullable
  archived_at timestamptz nullable
  archived_by uuid nullable
  archive_reason text nullable
  rejection_code text nullable
  rejected_at timestamptz nullable
  created_at timestamptz
  updated_at timestamptz
```

`description` allows up to 1,000 characters and is trimmed. The original
filename allows up to 255 characters and is normalized for display; control
characters and path separators are rejected. It is never used as an object
path. The archive reason allows up to 1,000 characters and is required when an
accepted file is archived.

`storage_bucket` is fixed to `patient-files` by a database constraint for this
adapter. Keeping it in the record makes object location explicit and supports a
future migration in which old and new providers coexist.

`upload_expires_at` is two hours after creation. A pending record is invisible
in the normal list. The uploader can see its own pending item only through the
upload recovery command. Available and archived records show their uploader
and lifecycle timestamps.

### State constraints

```text
pending_upload:
  no detected MIME, size, availability, archive, or rejection fields

available:
  detected MIME, valid size, and available_at required
  no archive or rejection fields

archived:
  detected MIME, valid size, available_at, archived_at, archived_by,
  and archive_reason required
  no rejection fields

rejected:
  rejection_code and rejected_at required
  no archive fields
```

Only these transitions are legal:

```text
pending_upload -> available
pending_upload -> rejected
available -> archived
archived -> available
```

Identity, path, original filename, category, links, upload author, detected
format, and accepted size become immutable when the row leaves
`pending_upload`. Description is also immutable; corrections use a replacement
record rather than editing clinical metadata.

## Relational integrity

Foreign keys use `ON DELETE RESTRICT`. Database validation guarantees:

- patient, appointment, clinical session, replacement file, and all actor
  memberships belong to the same clinic;
- the patient is active when an upload begins;
- an optional appointment belongs to the selected patient;
- an optional clinical session belongs to the selected patient and is not
  `entered_in_error`;
- if a linked clinical session has an appointment, an explicitly supplied
  appointment link cannot conflict with it;
- a replacement points to an accepted file for the same patient;
- upload authors have an active Dentist or Assistant role;
- archive and restore actors have an active Owner or Dentist role;
- size is greater than zero and no more than 15,728,640 bytes;
- object paths match the record's clinic, patient, ID, and approved extension.

Indexes support patient history by clinic, patient, status, creation time, and
ID; category filters; appointment and session links; replacement lineage;
pending expiry cleanup; and exact object-path lookup.

## Authorization matrix

| Capability | Owner only | Dentist | Assistant | Receptionist |
| --- | ---: | ---: | ---: | ---: |
| List metadata | Yes | Yes | Yes | No |
| View/download available file | Yes | Yes | Yes | No |
| View/download archived file | Yes | Yes | Yes | No |
| Upload | No | Yes | Yes | No |
| Cancel own pending upload | No | Yes | Yes | No |
| Archive | Yes | Yes | No | No |
| Restore | Yes | Yes | No | No |
| Permanently delete accepted file | No | No | No | No |

An Owner who also has the Dentist role receives Dentist upload permission.
Role checks query active clinic memberships in PostgreSQL; user-editable JWT
metadata is never used for authorization.

## Security boundary

The `patient_files` table has RLS enabled. Only active Owners, Dentists, and
Assistants in the row's clinic may select available or archived metadata. A
Dentist or Assistant may also select only their own unexpired pending row so
the upload can be resumed or cancelled. Receptionists and cross-clinic users
receive no rows. Direct client inserts, updates, and deletes are denied.

All metadata mutations pass through the JWT-protected `patient-files` Edge
Function and service-role-only database commands. Every command revalidates the
actor, active membership, role, patient scope, links, current status, and exact
object path inside the database operation.

Storage has no public read access, list access, update, upsert, move, copy, or
delete access for application users. A narrowly scoped `storage.objects`
INSERT policy permits an authenticated Dentist or Assistant to create only the
exact object represented by their own unexpired `pending_upload` row. It checks
all path segments and active membership. Downloads use short-lived URLs created
by the Edge Function after a fresh database authorization check.

The service-role or secret key exists only in the Edge Runtime. It is never
included in Flutter, configuration committed for clients, logs, or responses.
Error responses do not reveal whether a file exists in another clinic.

Clinical filenames, descriptions, file contents, patient identifiers, signed
URLs, JWTs, and Storage paths are excluded from analytics, Crashlytics, audit
metadata, and server logs. Expected errors use stable codes. Unexpected logs
contain only the operation name and a generated request correlation ID.

## Protected API

RLS-protected metadata reads:

```text
list available files for patient, newest first, with limit and cursor
list archived files for patient when explicitly requested
read one accepted file record by ID
```

Edge Function actions:

```text
create_upload
complete_upload
cancel_upload
create_read_url
archive_file
restore_file
reconcile_pending_uploads
```

`reconcile_pending_uploads` handles a small bounded batch for the current
clinic when an authorized Files screen loads or a new upload begins. It marks
expired pending records rejected and removes an exact-path object if one was
uploaded but never completed. The operation is idempotent. A scheduled worker
may replace this opportunistic cleanup in production without changing Flutter.

Expected failures map to typed application outcomes:

```text
patient_file_forbidden
patient_file_unavailable
patient_unavailable
appointment_unavailable
clinical_session_unavailable
replacement_file_unavailable
patient_archived
patient_file_invalid_name
patient_file_type_not_allowed
patient_file_too_large
patient_file_empty
patient_file_upload_expired
patient_file_upload_missing
patient_file_signature_mismatch
patient_file_pending_only
patient_file_available_only
patient_file_archived_only
patient_file_storage_unavailable
invalid_patient_file_input
```

Validation failures use 400, authentication failures 401, authorization
failures 403, unavailable resources 404, lifecycle conflicts 409, unsupported
media 415, excessive size 413, and unexpected provider failures 503. Responses
contain no raw PostgreSQL or Storage messages.

## Failure recovery and consistency

PostgreSQL and object Storage do not share one transaction. The lifecycle is
therefore designed for safe partial failure:

- If metadata creation fails, no object path is authorized.
- If upload fails, the row remains pending and the same upload can resume or be
  cancelled.
- If upload succeeds but completion is interrupted, idempotent completion can
  be retried. Expiry reconciliation removes abandoned objects.
- If validation fails, cleanup removes the unaccepted object and records a safe
  rejection code.
- If invalid-upload cleanup temporarily fails, the row remains pending and the
  completion action can be retried. An expired row is already unreadable when
  cleanup begins; a rare cleanup failure is logged for operational removal.
- If archive or restore fails, the object is unchanged and the database state
  remains authoritative.
- If URL creation fails, no lifecycle data changes and the user can retry.

The list reads only accepted database rows. Direct Storage listing is never
used as the patient record, so orphaned or incomplete objects cannot appear in
the UI.

## Audit events

Phase 10 appends these events to the existing immutable `audit_events` table:

```text
patient_file_uploaded
patient_file_archived
patient_file_restored
```

Audit metadata contains the file ID, patient ID, clinic ID, category, actor ID,
and state transition. It does not contain the original filename, description,
archive reason, signed URL, path, MIME metadata, or file bytes. Rejected and
cancelled pending attempts are operational events and are not copied into the
clinical audit stream during MVP.

## Flutter experience

### Entry and list

The Patient Profile gains **Files** for active Owners, Dentists, and Assistants.
It opens `/patients/:patientId/files`. Receptionists do not see the action, and
direct navigation presents an unavailable screen without querying file data.

The screen includes:

- patient identity header and back navigation;
- newest-first file list;
- category, date, type, size, uploader, linked visit indicator, and archived
  status;
- category and active/archived filters;
- loading, empty, error, refresh, and load-more states;
- **Upload file** for Dentists and Assistants;
- preview/open, upload replacement, and role-appropriate archive/restore
  actions.

Metadata is paginated. File bytes and signed URLs are loaded only after a user
selects a file; the list never downloads previews in the background.

### Upload dialog

The upload flow displays:

- selected filename, type, and formatted size;
- required category;
- optional description;
- optional appointment or clinical-session link from the current patient;
- local validation message;
- progress percentage and transferred bytes;
- cancel and retry controls;
- a final server-validation state after transfer reaches 100 percent.

The action prevents duplicate taps. Leaving the screen during an active upload
requires confirmation because the browser may lose access to the selected
file. A failed validation message explains the supported types and 15 MiB limit
without exposing internal details.

### File detail and preview

The detail view shows protected metadata and lifecycle history. Images load
into an in-memory viewer with fit, zoom, and close controls. PDFs show **Open
PDF**, which requests a fresh 60-second URL immediately before opening. The UI
does not show or copy the signed URL.

Archived files have a clear banner and remain read-only. Owners and Dentists
see **Restore**. Available files show **Archive**, which opens a confirmation
dialog with a required reason. **Upload replacement** never implies that the
earlier object will be deleted.

## Responsive and localization behavior

On wide web layouts, filters and the file list occupy the main area while the
selected file details appear in a side panel. On tablets the detail panel opens
as a sheet or stacked section. On phones the list, upload form, and file detail
use separate full-width routes; progress and the primary action remain visible
without covering form fields.

File picking uses the platform picker on web, Android, iOS, macOS, Windows, and
Linux where supported. No camera or photo-library permission is requested in
this phase.

All new strings are added in English, Russian, and Arabic. Arabic uses the
existing right-to-left layout. Filenames remain in their original writing
direction inside direction-aware containers. Dates follow the selected locale
and active clinic time zone. File size formatting uses localized units. Status
and category meaning use text and icons as well as color.

## Flutter boundaries

```text
features/patient_file/
  domain/
    patient_file_models.dart
    patient_file_repository.dart
    file_transfer_client.dart
    patient_file_validator.dart
  data/
    patient_file_data_source.dart
    supabase_patient_file_data_source.dart
    supabase_patient_file_repository.dart
    supabase_tus_file_transfer_client.dart
  presentation/
    patient_file_cubit.dart
    pages/patient_file_pages.dart
```

The domain layer represents selected-file metadata and a byte stream without
importing Supabase types. The data source handles protected JSON APIs. The
transfer client alone knows the TUS endpoint, headers, offsets, and progress
events. The repository coordinates the metadata and transfer ports and maps
stable server codes into domain issues.

Widgets receive domain entities and call the Cubit. They do not construct
Storage paths, perform role authorization, hold service credentials, or parse
raw provider errors. The Cubit tracks list pagination separately from the
current upload so refreshes cannot erase transfer progress.

## Implemented files

Create:

```text
supabase/migrations/<timestamp>_add_patient_files.sql
supabase/tests/patient_files_rls.test.sql
supabase/functions/patient-files/index.ts
lib/features/patient_file/domain/patient_file_models.dart
lib/features/patient_file/domain/patient_file_repository.dart
lib/features/patient_file/domain/file_transfer_client.dart
lib/features/patient_file/data/patient_file_data_source.dart
lib/features/patient_file/data/supabase_patient_file_data_source.dart
lib/features/patient_file/data/supabase_patient_file_repository.dart
lib/features/patient_file/data/supabase_tus_file_transfer_client.dart
lib/features/patient_file/presentation/patient_file_cubit.dart
lib/features/patient_file/presentation/pages/patient_file_pages.dart
lib/features/patient_file/domain/patient_file_validator.dart
test/patient_file/patient_file_cubit_test.dart
test/patient_file/supabase_patient_file_data_source_test.dart
test/patient_file/patient_file_pages_test.dart
test/patient_file/patient_file_validator_test.dart
```

Change:

```text
pubspec.yaml
pubspec.lock
supabase/config.toml
lib/app/bootstrap/bootstrap.dart
lib/app/app.dart
lib/app/router/app_router.dart
lib/features/patient/presentation/pages/patient_pages.dart
lib/app/localization/arb/app_en.arb
lib/app/localization/arb/app_ru.arb
lib/app/localization/arb/app_ar.arb
generated dependency-injection and localization files
```

`file_picker` is added for cross-platform selection. Existing Dio networking is
used behind the transfer abstraction; an additional TUS dependency is added
only if the implementation spike proves that the small protocol adapter cannot
be made reliable and testable with Dio.

## Implementation sequence

1. Create the metadata types/table, constraints, indexes, grants, RLS policies,
   service-role-only commands, private local bucket declaration, Storage insert
   policy, and pgTAP coverage.
2. Add the JWT-protected Edge Function with strict request validation,
   idempotent lifecycle actions, bounded signature verification, private URL
   creation, safe error mapping, and cleanup.
3. Add domain and data ports, file-picker mapping, the Supabase TUS adapter,
   repository coordination, and focused unit tests.
4. Add the patient Files list, upload progress, detail/preview, archive/restore,
   replacement flow, responsive layouts, permission-aware navigation, and all
   three translations.
5. Generate dependency injection and localization, apply the migration without
   resetting existing fictional data, and complete the verification plan.

## Verification plan

Database tests cover tenant isolation, Owner/Dentist/Assistant reads,
Receptionist denial, upload roles, Owner-only upload denial, direct metadata
write denial, exact Storage path authorization, cross-patient path denial,
link integrity, allowed transitions, accepted-file immutability, archive and
restore roles, replacement lineage, pending expiry, and audit metadata safety.

Edge Function tests and smoke checks cover authentication, safe errors,
create/complete idempotency, missing objects, mismatched size/MIME/signature,
cleanup after rejection, 60-second URL creation, expired uploads, and calls that
attempt to use another clinic's identifiers.

Flutter tests cover file-picker mapping, extension/MIME/signature/size checks,
TUS creation/chunk/resume/cancel behavior, progress state, typed error mapping,
pagination, loading/empty/error states, role-specific actions, archive reason,
replacement behavior, image preview, PDF launch, narrow phone layout, and
Arabic right-to-left rendering.

Required completion commands:

```text
dart format .
flutter analyze
flutter test
supabase test db --local
supabase db lint --local --level warning --fail-on error
flutter build web --dart-define-from-file=config/local.json
```

The local bucket and `patient-files` Edge Function must also pass authenticated
upload, interrupted-transfer resume, validation, preview, archive, and
cross-role smoke tests using fictional files before Phase 10 is complete.

## Implementation and verification result

Phase 10 was approved and implemented on 2026-09-10. The implementation adds
the private bucket declaration, two forward-only migrations, protected Edge
Function actions, resumable direct-to-Storage transfer, local and server file
validation, the patient Files experience, archive/restore and replacement
workflows, dependency injection, routing, and English/Russian/Arabic strings.

Final verification completed successfully:

- `dart format .`: 151 Dart files formatted; no pending format changes after
  the final implementation edit.
- `flutter analyze`: no issues.
- `flutter test`: 89 passed; 3 existing environment-dependent tests skipped.
- `supabase test db --local`: 9 files and 207 pgTAP checks passed. The tests
  scope all assertions to their own fictional clinic fixtures, so retained
  smoke data cannot affect the result.
- `supabase db lint --local --level warning --fail-on error`: passed with no
  Phase 10 finding. Two pre-existing appointment/schedule functions retain
  four Phase 6 warnings documented outside this phase.
- `flutter build web --dart-define-from-file=config/local.json`: succeeded,
  including the WebAssembly dry run. Localization generation still reports 68
  older untranslated Arabic keys outside Phase 10; all Phase 10 strings are
  translated.
- Authenticated local smoke: a fictional Dentist created an upload, transferred
  a PDF through TUS, passed server signature validation, received a 60-second
  private read URL, verified the downloaded bytes, archived the file, and
  restored it successfully.

The local Supabase services and function runtime were used for validation. No
paid service or hosted production environment was created.

## Completion criteria

Phase 10 is complete when authorized clinical staff can upload an allowed file
with progress and retry, only server-validated objects appear in the patient
record, receptionists and other clinics cannot discover metadata or bytes,
accepted files cannot be overwritten or normally deleted, archive/restore and
replacement history remain auditable, image/PDF viewing uses private short-lived
access, every new screen works on phone/tablet/web in English/Russian/Arabic,
and every required verification check passes.

## Current Supabase references

- [Resumable uploads](https://supabase.com/docs/guides/storage/uploads/resumable-uploads)
- [Storage file limits](https://supabase.com/docs/guides/storage/uploads/file-limits)
- [Private buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals)
- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Serving private assets](https://supabase.com/docs/guides/storage/serving/downloads)
- [Storage schema guidance](https://supabase.com/docs/guides/storage/schema/design)
- [Edge Function limits](https://supabase.com/docs/guides/functions/limits)
