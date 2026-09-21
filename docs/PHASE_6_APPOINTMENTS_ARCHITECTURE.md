# Phase 6 — Appointment Architecture

Status: implemented and locally verified.

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 21–24 and 29–30.

## Approved product decisions

- The staff member creating an appointment chooses its duration. The form starts at 30 minutes and provides 15-minute increments. A dentist may adjust appointment timing only through the permissions defined below.
- An archived patient cannot receive a new appointment. An Owner restores the patient first, preserving the existing patient history and making reactivation deliberate.
- A small, reusable audit-event foundation is introduced now for security-sensitive appointment overrides. It records who acted, when, which appointment was affected, and the required reason. It never stores clinical content.

## Goal and scope

This phase creates the clinic appointment calendar and its safe booking workflow. It supports creation, confirmation, rescheduling, start, completion, cancellation, no-show, Owner conflict overrides, and Assistant operational preparation notes.

It does not create clinical sessions, treatment plans, billing, dental charts, chair/room booking, or patient reminders. Those remain later phases.

## Calendar and time model

All appointment instants are stored as UTC `timestamptz` values. The calendar, appointment form, and conflict messages display the clinic's configured time zone, not the device's time zone. A booking uses a start time and a duration; the server derives the end time.

The calendar initially provides day and week views, filters by dentist and status, and a clear "New appointment" action. Patient search reuses the existing paginated patient search. Calendar reads are limited to a visible date range so a clinic with many years of history is never downloaded at once.

## Data model

```text
appointments
  id
  clinic_id
  patient_id
  dentist_member_id
  starts_at / ends_at
  status
  purpose
  cancellation_reason
  created_by / created_at / updated_at
  status_changed_by / status_changed_at
  override_reason / overridden_by / overridden_at

appointment_conflict_flags
  id
  appointment_id
  kind                     -- working_hours | leave | unavailable
  detected_at
  detected_by
  resolved_at / resolved_by / resolution_note

appointment_preparation_notes
  id
  appointment_id
  note
  created_by / created_at / updated_at

audit_events
  id
  clinic_id
  actor_user_id
  event_type
  subject_type / subject_id
  reason
  occurred_at
  safe_metadata
```

`appointments` keeps only operational booking data. `purpose` is a short, optional, non-clinical booking label. Medical details belong to later clinical modules. The nullable future `chair_id` is intentionally omitted now; no current constraint prevents adding a chair/room reference later.

Patient, dentist, and clinic references use `ON DELETE RESTRICT` so historical appointments cannot be silently orphaned. Appointment records are never hard-deleted.

The database will index clinic/date-range calendar reads, dentist/date-range reads, patient/date-range reads, and unresolved conflict flags.

## Statuses and permissions

| Role | Allowed appointment actions |
| --- | --- |
| Owner | All administrative actions, including every override and restoring an archived patient before booking. |
| Receptionist | Create, confirm, reschedule, cancel, and mark no-show. |
| Dentist | Create, start, complete, cancel when necessary, and mark no-show. |
| Assistant | Read appointments and add/edit operational preparation notes only. |

The server, not Flutter, enforces all permissions. UI controls reflect the role for clarity but are never the security boundary.

Valid status flow is: `scheduled` → `confirmed` → `in_progress` → `completed`, with `cancelled` and `no_show` available as terminal outcomes where the role permits them. A completed, cancelled, or no-show appointment is retained as history and cannot be rescheduled; staff create a new appointment instead.

## Conflict rules

The server validates every create and reschedule inside one database transaction:

1. The patient must be active and belong to the selected clinic.
2. The dentist membership must be active, have the Dentist role, and belong to the same clinic.
3. The patient may not overlap another active appointment. This is a hard database constraint; no role can override it.
4. A dentist overlap, appointment outside working hours, break overlap, leave, or unavailable-period overlap is blocked by default.
5. Only an Owner may proceed through rules 4 with an explicit confirmation and non-empty reason. The override fields and an audit event are written in the same transaction.

The overlap interval is `[start, end)`: an appointment ending at 10:30 and another starting at 10:30 do not conflict. Cancelled, no-show, and completed appointments do not reserve future calendar time.

Doctor availability is calculated from the schedule version effective on the appointment's clinic-local date. If no working schedule exists for that dentist/date, booking is treated as outside working hours and is blocked unless an Owner supplies an override reason.

Because Owner dentist-overlap overrides are allowed, dentist conflicts are checked by the protected command under a transaction lock rather than a database exclusion constraint. Patient overlap uses a PostgreSQL exclusion constraint, which makes it impossible for concurrent requests to create two physically overlapping appointments for one patient.

## Schedule changes affecting appointments

The current Doctor Schedule workflow will be extended in this phase.

Before a weekly schedule or leave/unavailable change is saved, the server calculates the future active appointments that it would affect. It returns the count and a limited review list.

- A dentist who is not an Owner cannot save a schedule change that affects future appointments.
- An Owner can cancel the schedule change, review the affected appointments, or confirm it with a reason.
- On Owner confirmation, the schedule is saved and each affected appointment receives an unresolved conflict flag. The patient is never moved, cancelled, or notified automatically.

The final save repeats the check rather than trusting the earlier preview, preventing a race where a new appointment is created between review and confirmation.

## API and security boundary

Flutter reads calendar records through RLS-protected, clinic-scoped queries. Browser clients receive no direct appointment writes.

The authenticated `appointments` Edge Function exposes these actions:

```text
list_range
create
update_timing
confirm
start
complete
cancel
mark_no_show
save_preparation_note
resolve_conflict_flag
```

Each mutation validates its request shape and invokes a service-role-only PostgreSQL command. That command locks the relevant rows, confirms the caller's present role and clinic membership, validates status transitions and conflicts, performs the mutation, and returns only the safe result needed by the app.

All public tables use RLS. Users may read only records belonging to an active clinic membership. The service-role key remains in the Edge Runtime environment and is never included in Flutter configuration or logs.

## Flutter design

The feature follows the existing clean boundaries:

```text
features/appointment/
  domain/       models, repository contract, validation types
  data/         Supabase data source and repository implementation
  presentation/ calendar cubit, appointment-detail cubit, pages
```

The calendar requests only its current date range and refreshes after a successful mutation. The form has patient search, dentist selection, clinic-local date/time, duration, purpose, and any required override confirmation. Clear messages distinguish a hard patient conflict from an Owner-overridable availability conflict.

Patient Profile gains an Appointments tab once this feature exists. The existing schedule page gains an affected-appointment review flow for schedule changes.

## Error handling

Safe typed errors are returned for: unavailable patient, inactive dentist, patient overlap, dentist overlap, outside working hours, leave/unavailable period, invalid status transition, insufficient role, and schedule-change affected appointments. The app displays a useful action message without exposing database details or patient information from another clinic.

## Verification plan

Before Phase 6 is complete, verification must include:

- pgTAP tests for tenant isolation, each role, patient hard-conflict behavior, Owner overrides, schedule-change flags, and audit events.
- Flutter unit/widget tests for typed error mapping, duration selection, status controls, and role-specific UI.
- `dart format .`, `flutter analyze`, `flutter test`, `supabase test db --local`, public-schema lint, and Supabase security advisors.
- A local Edge Runtime smoke test for the `appointments` function.

## Implementation sequence

1. Create and test the migration, RLS, indexes, conflict commands, and limited audit-event foundation.
2. Extend protected schedule commands with appointment-impact preview and Owner confirmation.
3. Add the `appointments` Edge Function and its request validation.
4. Add Flutter domain/data layers and tests.
5. Build calendar, booking form, status actions, conflict review, and Patient Profile appointment tab.
6. Run the full verification plan and fix every failure.

## Verification result

- `dart format .` and `flutter analyze`: passed with no issues.
- `flutter test`: 58 passed, with 3 opt-in local-service tests skipped by default.
- `supabase test db --local`: 110 pgTAP checks passed, including appointment conflicts and both schedule-impact flows.
- Public-schema lint and Supabase security advisors: passed with no findings.
- `flutter build web --dart-define-from-file=config/local.json`: compiled successfully.
