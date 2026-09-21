# Phase 9 — Clinical Sessions Architecture

Status: implemented and locally verified.

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 14–16,
30, 40, 53–56, 76–77, 80–85, plus the product decisions approved on
2026-09-09.

## Approved product decisions

- A clinical session may be linked to one appointment or recorded as a walk-in
  visit without an appointment.
- Owners, Dentists, and Assistants may read clinical sessions. Receptionists
  cannot read clinical notes, recommendations, or amendments.
- Assistants may create and edit draft sessions. Dentists may also create and
  edit drafts.
- Only the session's assigned Dentist may finalize it.
- A finalized session is immutable. Any active Dentist may add a signed,
  append-only amendment with a required reason.
- A draft created for the wrong patient or appointment is marked
  `entered_in_error` with a required reason. It is preserved and cannot be
  edited or deleted afterward.
- Finalizing a session does not automatically change an appointment or a
  treatment-plan item. These remain separate, explicit clinical actions.

## Goal and scope

Phase 9 adds the patient **Visits** area and the clinical record for a completed
or ongoing visit. It supports draft preparation by an Assistant, clinical
review and finalization by the assigned Dentist, walk-in visits, immutable
final records, and signed corrections.

The phase does not upload patient files, create invoices, generate PDFs,
automatically update the odontogram, or automatically mark treatment-plan
procedures complete. Those actions belong to their existing modules or later
phases.

## Core workflow

For an appointment visit:

1. A Dentist or Assistant opens an eligible patient appointment and creates its
   session draft. The patient, dentist, and visit time are copied from the
   appointment and cannot be changed in the draft.
2. The Assistant or Dentist records clinical notes and recommendations and
   explicitly saves the draft.
3. The assigned Dentist reviews the content and finalizes it after the
   appointment is in progress or completed.
4. The original session becomes immutable.
5. If a correction is later necessary, any active Dentist adds an amendment
   containing the correction and its reason. The original text remains visible.

For a walk-in visit, a Dentist or Assistant selects the patient, assigned
Dentist, and actual session time. The remaining workflow is the same.

## Data model

### Status type

```text
clinical_session_status
  draft
  finalized
  entered_in_error
```

`entered_in_error` is an approved extension to the two Master Specification
statuses. It preserves an incorrect draft without treating it as a finalized
clinical record.

### Clinical sessions

```text
clinical_sessions
  id uuid primary key
  clinic_id uuid
  patient_id uuid
  appointment_id uuid nullable unique
  dentist_member_id uuid
  session_date timestamptz
  clinical_notes text nullable
  recommendations text nullable
  status clinical_session_status
  revision integer
  created_by uuid
  updated_by uuid
  finalized_by uuid nullable
  finalized_at timestamptz nullable
  error_reason text nullable
  marked_in_error_by uuid nullable
  marked_in_error_at timestamptz nullable
  created_at timestamptz
  updated_at timestamptz
```

`session_date` is stored as a UTC instant and displayed in the active clinic's
time zone. A linked session copies the appointment start time. A walk-in session
accepts the actual current or past visit time and rejects a future value.

Only one session may reference an appointment. Walk-in sessions have a null
`appointment_id`, so a patient may have multiple walk-in visits on the same day.

`revision` starts at 1 and increases on each draft update. Every update and
finalize request includes the revision the user loaded. If another staff member
saved first, the server rejects the stale request and asks the user to reload.
This prevents one person's draft from silently overwriting another person's
work.

Clinical notes allow up to 20,000 characters. Recommendations allow up to 5,000
characters. Draft fields may be empty, but finalization requires non-empty
clinical notes. All stored text is trimmed and validated by the server.

### Amendments

```text
clinical_session_amendments
  id uuid primary key
  clinic_id uuid
  clinical_session_id uuid
  amendment_text text
  reason text
  amended_by uuid
  amended_at timestamptz
```

Amendment text allows up to 10,000 characters and its reason up to 1,000.
Amendments are append-only: normal clients and protected commands cannot update
or delete them. The UI presents each amendment beside its author and timestamp.

## Database integrity

Foreign keys use `ON DELETE RESTRICT` so patient, appointment, membership, and
author records cannot be removed while clinical history references them.

A scope trigger verifies:

- the patient belongs to the session clinic;
- the assigned member belongs to the same clinic, is active, and has the
  Dentist role;
- a linked appointment belongs to the same clinic and patient;
- a linked appointment's Dentist matches the session Dentist;
- amendments always copy the clinic from their parent session.

The state constraint requires exactly the correct metadata:

```text
draft:
  no finalized or entered-in-error metadata

finalized:
  non-empty clinical notes and finalized_by/finalized_at
  no entered-in-error metadata

entered_in_error:
  required error reason, author, and time
  no finalized metadata
```

A database trigger blocks changes to identity, scope, authorship, and finalized
content. A draft may transition only to `finalized` or `entered_in_error`.
Finalized and entered-in-error sessions are terminal. Amendments are the only
way to correct finalized content.

Indexes support patient visit history by clinic, patient, session date, and ID;
appointment lookup; assigned-Dentist history; and amendment history by session
and time.

## Appointment relationship

A linked draft may be created for an appointment whose status is `scheduled`,
`confirmed`, `in_progress`, or `completed`. This lets an Assistant prepare a
draft before treatment while preventing notes for cancelled or no-show visits.

Finalization requires the linked appointment to be `in_progress` or
`completed`, and its start time cannot be in the future. The session command
does not transition the appointment. If the visit workflow requires it, the
Dentist separately marks the appointment complete through the existing
Appointments module.

Appointment cancellation remains independent. A draft linked to an appointment
that is later cancelled cannot be finalized; clinical staff either retain it as
a draft pending correction of the appointment or mark the draft entered in
error.

## Permissions

| Capability | Owner only | Dentist | Assistant | Receptionist |
| --- | ---: | ---: | ---: | ---: |
| Read session notes and recommendations | Yes | Yes | Yes | No |
| Read amendments | Yes | Yes | Yes | No |
| Create a draft | No | Yes | Yes | No |
| Edit any clinic draft | No | Yes | Yes | No |
| Mark a draft entered in error | No | Yes | Yes | No |
| Finalize assigned session | No | Assigned Dentist only | No | No |
| Add amendment to finalized session | No | Yes | No | No |

An account with both Owner and Dentist roles receives the Dentist capabilities.
Owner status by itself never grants clinical write permission.

Receptionists continue to see appointments and their administrative statuses.
The client does not query or expose a clinical-session row to Receptionists, so
no clinical content or existence details leak through the Visits screen.

## Security boundary

Row Level Security allows session and amendment reads only when the current user
has an active Owner, Dentist, or Assistant role in that clinic. Cross-clinic
queries return no rows. The browser receives no insert, update, or delete grants
for either clinical table.

All changes pass through an authenticated `clinical-sessions` Supabase Edge
Function. It validates the request shape and JWT, then invokes service-role-only
PostgreSQL commands. Each command independently verifies the actor, active
membership, role, clinic scope, target status, current revision, and linked
appointment rules inside the same transaction.

The service-role key stays inside the Edge Runtime. Raw PostgreSQL messages,
clinical text, and cross-clinic existence information never appear in API error
responses or logs.

## Protected API

RLS-protected reads:

```text
list sessions for patient, newest first, with limit and cursor
read one session by ID
list amendments for session, oldest first
list eligible appointments for the selected patient
```

Edge Function actions:

```text
create_session
update_draft_session
finalize_session
mark_draft_session_in_error
add_session_amendment
```

Expected failures map to typed application outcomes:

```text
clinical_session_forbidden
clinical_session_unavailable
patient_unavailable
appointment_unavailable
dentist_unavailable
appointment_already_has_session
appointment_not_eligible
assigned_dentist_required
assigned_dentist_mismatch
clinical_notes_required
clinical_session_draft_only
clinical_session_finalized_required
clinical_session_revision_conflict
invalid_clinical_session_input
```

HTTP responses use only safe codes and identifiers. Validation failures are
400, authentication failures 401, authorization failures 403, unavailable
resources 404, lifecycle or revision conflicts 409, and unexpected service
failures 503.

## Audit events

Phase 9 writes these events into the existing immutable `audit_events` table:

```text
clinical_session_finalized
clinical_session_marked_in_error
clinical_session_amendment_added
```

Audit metadata contains only safe identifiers and status information. Clinical
notes, recommendations, amendment text, and error reasons are never copied into
audit metadata or logs. Routine draft saves do not create audit events, which
avoids excessive volume. Phase 13 will provide the full audit UI.

## Flutter experience

### Patient Visits list

The Patient Profile gains an active **Visits** action for Owner, Dentist, and
Assistant roles. It opens `/patients/:patientId/visits`.

The screen shows the patient header, a newest-first paginated timeline, status,
session date in clinic time, assigned Dentist, linked appointment indicator,
and last update. It has loading, empty, error, refresh, and load-more states.
Receptionists do not see the action, and direct navigation shows an unavailable
screen without loading clinical data.

Dentists and Assistants see **New session**. They can select an eligible
appointment or choose **Walk-in visit**. Appointment-linked patient, Dentist,
and date fields are locked. A walk-in requires an active Dentist and visit time.

### Draft editor

The draft editor shows:

- patient and visit identity;
- linked appointment or walk-in badge;
- assigned Dentist;
- clinical notes;
- recommendations;
- author, last editor, and last-saved time;
- explicit **Save draft** action;
- revision-conflict banner with **Reload latest draft**;
- **Mark entered in error** with a required reason.

Only the assigned Dentist sees **Finalize session**. The finalization dialog
explains that the original text becomes permanent, displays a short content
review, and requires explicit confirmation. The button stays disabled until
clinical notes are present and appointment rules pass.

### Finalized visit

The finalized view renders the original notes and recommendations as read-only,
with finalizing Dentist and timestamp. Amendments appear chronologically below
the original content and remain visually distinct. Dentists see **Add
amendment**, which requires both amendment text and a reason.

An entered-in-error draft displays its original content, error reason, author,
and time as read-only. It is clearly labelled so it cannot be mistaken for a
finalized visit.

### Appointment entry point

Eligible appointment details gain **Open clinical session** for Dentists and
Assistants. If a session exists, the action opens it. Otherwise it opens the
new linked-session form. Appointment lists do not fetch clinical notes.

## Responsive and localization behavior

On wide web layouts, visit history occupies a left panel and the selected
session occupies a larger right panel. On tablets, the panels stack with the
selected session first. On phones, the list and editor use separate routes;
forms scroll above the keyboard and primary actions remain reachable at the
bottom.

All new user-facing strings are added to English, Russian, and Arabic
localization files. Arabic uses the application's existing right-to-left
layout. Dates and times follow the selected language while always using the
clinic time zone. Status meaning is communicated through text and icons as well
as color.

## Flutter boundaries

```text
features/clinical_session/
  domain/
    clinical_session_models.dart
    clinical_session_repository.dart
  data/
    clinical_session_data_source.dart
    supabase_clinical_session_data_source.dart
    supabase_clinical_session_repository.dart
  presentation/
    clinical_session_cubit.dart
    pages/clinical_session_pages.dart
    widgets/session_editor.dart
```

Widgets receive typed entities and call the Cubit. They do not call Supabase,
handle authorization, or interpret raw provider responses. The repository maps
provider rows and stable error codes into domain types.

## Files planned for implementation

Create:

```text
supabase/migrations/<timestamp>_add_clinical_sessions.sql
supabase/tests/clinical_sessions_rls.test.sql
supabase/functions/clinical-sessions/index.ts
lib/features/clinical_session/domain/clinical_session_models.dart
lib/features/clinical_session/domain/clinical_session_repository.dart
lib/features/clinical_session/data/clinical_session_data_source.dart
lib/features/clinical_session/data/supabase_clinical_session_data_source.dart
lib/features/clinical_session/data/supabase_clinical_session_repository.dart
lib/features/clinical_session/presentation/clinical_session_cubit.dart
lib/features/clinical_session/presentation/pages/clinical_session_pages.dart
lib/features/clinical_session/presentation/widgets/session_editor.dart
test/clinical_session/clinical_session_cubit_test.dart
test/clinical_session/supabase_clinical_session_data_source_test.dart
test/clinical_session/clinical_session_pages_test.dart
```

Change:

```text
supabase/config.toml
lib/app/bootstrap/bootstrap.dart
lib/app/app.dart
lib/app/router/app_router.dart
lib/features/patient/presentation/pages/patient_pages.dart
lib/features/appointment/presentation/pages/appointment_pages.dart
lib/app/localization/*.arb
generated dependency-injection and localization files
```

## Implementation sequence

1. Create the status type, tables, constraints, triggers, indexes, grants, RLS,
   protected commands, and pgTAP tests.
2. Add the JWT-protected Edge Function with strict request validation and safe
   error mapping.
3. Add typed Flutter domain, data, and state-management layers with focused
   unit tests.
4. Add the Visits list, draft editor, finalized view, amendment flow,
   appointment entry point, permissions, responsive layouts, and translations.
5. Generate dependencies and localization, then run the complete verification
   suite and fix every failure.

The pending migration will be applied with `supabase migration up --local`, not
a database reset, so existing local accounts and fictional demo records remain.

## Verification plan

Database tests cover tenant isolation, read roles, Receptionist denial, direct
browser-write denial, appointment scope, one-session-per-appointment,
Assistant draft writes, Owner write denial, assigned-Dentist finalization,
revision conflicts, terminal-state immutability, entered-in-error preservation,
append-only amendments, and safe audit events.

Flutter tests cover row mapping, authenticated Edge requests, typed error
mapping, pagination, loading/empty/error states, revision-conflict recovery,
role-specific actions, finalization confirmation, narrow phone layouts, and
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

The local `clinical-sessions` Edge Function must also load successfully and
respond correctly to authenticated smoke requests before Phase 9 is complete.

## Completion criteria

Phase 9 is complete when clinical staff can create and save drafts without
overwriting one another, only the assigned Dentist can finalize, finalized
history cannot be changed, corrections are signed append-only amendments,
Receptionists cannot access clinical content, all new screens work on phone,
tablet, and web in English, Russian, and Arabic, and every required check passes.

## Verification result

Completed on 2026-09-09 using fictional local development data only.

- `dart format .`: 136 files formatted; no changes required.
- `flutter analyze`: no issues found.
- `flutter test`: 75 tests passed and 3 environment-dependent tests skipped.
- `supabase test db --local`: 8 files and 181 pgTAP checks passed.
- `supabase db lint --local --level warning --fail-on error`: no errors and no
  warning introduced by Phase 9. Existing appointment and schedule warnings
  remain documented for their owning phases.
- The JWT-protected `clinical-sessions` Edge Function loaded locally and safely
  rejected a request without a user session with `401 authentication_required`.
- `flutter build web --dart-define-from-file=config/local.json`: completed and
  produced `build/web`.
- The focused Arabic phone-layout and Receptionist-denial widget tests passed.
  Every string introduced for Clinical Sessions has English, Russian, and
  Arabic text. The localization generator still reports 68 older untranslated
  Arabic keys outside Phase 9; those remain part of the later application-wide
  localization polish.

The migration was applied with `supabase migration up --local`; no local user,
clinic, or demo patient data was reset.
