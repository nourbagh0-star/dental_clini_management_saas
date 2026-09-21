# Phase 7 — Odontogram Architecture

Status: implemented and locally verified.

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 30–36.

## Approved product decisions

- The MVP includes both permanent and primary dentition. This supports clinics
  that treat children without a later clinical-data redesign.
- The initial condition catalogue is: caries, filling, crown, root canal,
  fracture, missing, extraction required, and implant.
- A clinical condition applies to one tooth and one surface. `whole` represents
  the entire tooth. A clinician records a separate condition for every
  additional affected surface.

## Goal and scope

This phase adds a safe, interactive Dental Chart to a patient's profile. A
dentist can view the current chart, add a condition, resolve a condition, and
correct an erroneous entry without removing its history. Owners and assistants
can view the chart according to their clinic role. Receptionists have no access
to clinical Dental Chart data.

This phase does not create treatment plans, procedure pricing, clinical-session
notes, patient files, billing items, or appointment-linked clinical records.
Those remain separate later phases.

## Clinical model

The chart uses FDI tooth numbers.

| Dentition | Supported teeth |
| --- | --- |
| Permanent | 11–18, 21–28, 31–38, 41–48 |
| Primary | 51–55, 61–65, 71–75, 81–85 |

The interface exposes both dentitions deliberately. It does not infer a single
dentition from a patient's age because children can have mixed dentition and a
clinical user must be able to inspect either chart.

Supported surfaces are `whole`, `mesial`, `distal`, `occlusal`, `buccal`, and
`lingual`. The database values are designed as controlled types so a later
migration can add a surface without changing existing history.

`healthy` is never stored. The app derives a healthy presentation when a valid
tooth has no active condition requiring display.

## Data model

The implementation will add a single append-only clinical table, with database
types for controlled values:

```text
tooth_conditions
  id uuid
  clinic_id uuid
  patient_id uuid
  tooth_number smallint             -- validated FDI permanent or primary value
  surface tooth_surface
  condition_type tooth_condition_type
  status tooth_condition_status     -- active | resolved | entered_in_error
  notes text nullable
  created_by uuid
  created_at timestamptz
  resolved_by uuid nullable
  resolved_at timestamptz nullable
  error_reason text nullable
  marked_in_error_by uuid nullable
  marked_in_error_at timestamptz nullable
```

`clinic_id`, `patient_id`, `created_by`, and all actor references use
`ON DELETE RESTRICT`. Clinical history therefore cannot be detached or silently
deleted by removing a patient, clinic member, or user.

The record's tooth, surface, condition type, notes, and creator are immutable
after creation. A dentist resolves an entry or marks it as entered in error;
they do not overwrite clinical history. To correct a factual mistake, the
dentist marks the original entry `entered_in_error` with a non-empty reason and
creates a new accurate condition.

The status metadata is mutually exclusive:

- `active` has no resolution or error metadata;
- `resolved` requires `resolved_by` and `resolved_at`, and has no error
  metadata;
- `entered_in_error` requires `error_reason`, `marked_in_error_by`, and
  `marked_in_error_at`, and has no resolution metadata.

The initial database types are:

```text
tooth_surface: whole | mesial | distal | occlusal | buccal | lingual

tooth_condition_type:
  caries | filling | crown | root_canal | fracture | missing |
  extraction_required | implant

tooth_condition_status: active | resolved | entered_in_error
```

For a condition that applies to the entire tooth, `whole` is required. The
protected command will require `whole` for `missing`, `root_canal`,
`extraction_required`, and `implant`; the remaining condition types may use a
specific surface or `whole` when clinically appropriate.

## Missing-tooth integrity rule

`missing` means the natural tooth is absent. An active missing record for a
tooth cannot coexist with an active `caries`, `filling`, `crown`,
`root_canal`, `fracture`, or `extraction_required` record for that same
patient and tooth. An active `implant` may coexist with `missing` because it
represents a replacement, not the natural tooth.

The server command will lock the affected patient's tooth-condition rows before
it checks this rule and inserts a record. This makes concurrent requests safe.
Resolved and entered-in-error rows remain history and do not block a later
clinically valid record.

The UI presents this as a clear conflict message. It never automatically
resolves, errors, or removes a clinical entry to make a new entry fit.

## Access control and security boundary

| Role | Read chart and history | Add / resolve / correct condition |
| --- | --- | --- |
| Owner | Yes | No |
| Dentist | Yes | Yes |
| Assistant | Yes | No |
| Receptionist | No | No |

All database access is tenant-isolated by `clinic_id` and an active
membership. Row Level Security permits only the reads in this table; it grants
no browser-side inserts, updates, or deletes. In particular, receptionists
receive no chart rows even if they know a patient identifier.

Flutter sends mutations only to an authenticated `odontogram` Supabase Edge
Function. It validates the request shape, identifies the calling user from the
JWT, and invokes service-role-only PostgreSQL commands. Those commands repeat
the live clinic-role, patient-ownership, FDI-number, status-transition, and
missing-tooth validations inside a transaction. The Supabase service-role key
stays in the Edge Function environment and is never included in the Flutter
application or logs.

## Read and write API

The Flutter app reads only RLS-protected data for the selected patient. The
active chart read returns all active conditions for that patient, grouped by
tooth in the application. History loads in fixed-size pages ordered by
`created_at DESC, id DESC`; a large history is never fetched in one request.

The Edge Function exposes only these clinical mutations:

```text
create_condition
resolve_condition
mark_condition_in_error
```

`create_condition` accepts a patient ID, FDI tooth number, surface, condition
type, and optional concise note. It returns a safe typed error for invalid
input, unavailable patient, insufficient role, invalid tooth/surface pairing,
or a missing-tooth conflict.

`resolve_condition` accepts a condition ID. It may transition only an active
record to resolved. `mark_condition_in_error` accepts a condition ID and a
required correction reason. It may transition only an active record to
entered-in-error. Neither endpoint has a delete action.

## Flutter design and navigation

The Patient Profile's Dental Chart tab opens the patient-scoped Dental Chart
page. The page header keeps the existing patient identity visible and includes
a back path to that patient profile.

The main screen contains:

1. A permanent/primary dentition switcher. Both choices remain available for
   every patient.
2. A two-arch interactive FDI chart. Each tooth shows its number and the
   highest-priority active visual state. A tooth with multiple active
   conditions shows a count indicator and a details panel lists every record.
3. A selected-tooth panel showing active conditions by surface and the
   condition history for that tooth. The patient-wide history remains available
   in a separate paginated History section.
4. Dentist-only actions to add a condition, resolve an active condition, or
   mark an active condition as entered in error. The correction action requires
   a reason before it can be submitted.

The add-condition sheet selects the tooth, condition type, surface, and an
optional note. It prevents an impossible surface choice in the interface, but
the server remains the authoritative validator. A condition's visual icon and
colour are a display aid only; text labels and surface details remain available
for accessibility and for colour-blind users.

On small phone screens, the two arches scroll vertically, the selected-tooth
details open as a bottom sheet, and the condition form uses a full-screen
sheet. Tablet and web layouts keep the selected-tooth panel beside the chart.

The Flutter feature follows the project's clean boundaries:

```text
features/odontogram/
  domain/         tooth-condition models, repository contract, typed failures
  data/           Supabase read source, Edge-function mutation source, repository
  presentation/   chart cubit, chart/history pages, sheets and widgets
```

## Database performance and lifecycle

The migration will index active-chart lookups by `(clinic_id, patient_id,
tooth_number)` with a partial index for active rows, and history paging by
`(clinic_id, patient_id, created_at DESC, id DESC)`. A patient-scoped chart is
small, while the history index retains predictable query time as records grow.

No clinical condition is hard-deleted. Future modules may reference the stable
condition ID for treatment plans or clinical sessions without needing to copy
or reinterpret a condition record.

## Error handling

The app maps expected failures to clear messages: no permission, patient is not
available in this clinic, invalid tooth number, invalid surface, missing-tooth
conflict, condition is already closed, and an offline or unexpected service
failure. It does not expose raw SQL, JWT, clinic-membership, or another
patient's data.

## Implementation sequence

1. Add and test the controlled database types, table, indexes, integrity
   checks, RLS policies, grants, and protected PostgreSQL commands.
2. Add the `odontogram` Edge Function with request validation and safe typed
   errors.
3. Add Flutter domain/data/presentation boundaries and dependency injection.
4. Add the Patient Profile Dental Chart navigation, chart, detail view, history,
   and role-aware condition actions.
5. Run the full verification plan and correct every failure.

## Verification plan

- pgTAP tests for clinic isolation; each role's read/write boundaries;
  receptionist denial; immutable history; error and resolution transitions;
  FDI validation; concurrent-safe missing-tooth rules; and implant coexistence.
- Flutter tests for condition mapping, derived healthy state, form validation,
  typed error display, navigation, and role-based controls.
- `dart format .`, `flutter analyze`, `flutter test`, `supabase test db --local`,
  public-schema lint, Supabase security advisors, and a local Edge Runtime
  smoke test.

## Completion criteria

Phase 7 is complete only when the chart works for permanent and primary teeth,
clinical access rules are enforced by RLS and protected server commands, all
condition history is preserved, and every verification command above passes.

## Verification result

- `dart format .` and `flutter analyze`: passed with no issues.
- `flutter test`: 64 passed, with 3 opt-in local-service tests skipped by
  default.
- `supabase test db --local`: 137 pgTAP checks passed, including all
  odontogram role, history, primary-dentition, and missing-tooth checks.
- Public-schema lint and Supabase security advisors: passed with no findings.
- The local Edge Runtime loaded the authenticated `odontogram` function
  successfully.
- `flutter build web --dart-define-from-file=config/local.json`: compiled the
  web pilot build successfully.
