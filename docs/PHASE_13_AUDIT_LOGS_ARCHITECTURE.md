# Phase 13 — Security Audit Logs Architecture

Status: implemented and verified on 2026-09-13.

Authority: [Master Specification](MASTER_SPECIFICATION.md), especially sections
12, 53–56, 66–77, 80–83, plus the Phase 13 decisions approved on 2026-09-13.

## Approved product decisions

- Phase 13 includes the Owner audit viewer and the missing explicit
  sensitive-access events required by the Master Specification.
- The initial view covers the newest 30 clinic-local calendar days.
- Owners can filter by date range, employee, action category, event type, and
  entity type. Results use cursor pagination.
- The UI renders localized, typed summaries and an allowlisted detail view. It
  never prints arbitrary JSON or provider errors.
- Audit export is deferred. Existing authorized invoice PDF export auditing
  remains in place.
- Audit logs are clinic-scoped, append-only, and Owner-only to read.

## Purpose and boundaries

Phase 13 provides a security and accountability record for significant clinic
actions. It answers who performed an action, what class of record was affected,
when it happened in the clinic's time zone, and the approved non-clinical
context and reason.

Security Audit is distinct from Patient Activity. Phase 13 does not build the
role-filtered patient timeline described in section 54 of the Master
Specification. It also does not add reporting, analytics charts, alerting,
automated anomaly detection, SIEM integration, log drains, audit exports,
production retention rules, legal attestation, or a tamper-evident external
archive. Those require later production and legal decisions.

The current `public.audit_events` table remains the canonical application
ledger. It will be extended rather than replaced or renamed, preserving every
existing appointment, clinical-session, patient-file, and billing event.
Supabase platform and Auth audit logs describe provider administration and
authentication activity; they do not replace clinic business audit events.

## Roles and information boundaries

Only an active Owner of the requested clinic can list or inspect audit events.
Dentist, Assistant, Receptionist, anonymous, inactive, and cross-clinic users
receive no audit rows, actor directory, filter facets, counts, or existence
signals. Multiple roles grant access only when the same active membership has
the Owner role.

All active roles can cause approved access events through normal application
workflows. They cannot choose the stored actor, clinic, event category, event
name, timestamp, actor snapshot, or arbitrary metadata. The database derives
those values from the authenticated actor and the authorized target.

Flutter hides the Audit navigation item for non-Owners, but PostgreSQL and the
Edge Function enforce authorization. Route visibility is never treated as the
security boundary.

## Event model

Every event has:

- a UUID event ID;
- clinic ID;
- authenticated actor user ID;
- actor membership ID at the time of the event;
- verified actor email snapshot and role snapshot;
- stable event type and category;
- subject type and UUID;
- optional normalized reason;
- allowlisted safe metadata;
- optional idempotency/request UUID;
- server-generated occurrence time.

Actor snapshots prevent later role or email changes from rewriting historical
meaning. Existing events are backfilled from the best available clinic
membership values. If an old event cannot be matched, it retains its immutable
actor user ID and displays a localized “Former or unavailable staff member”
label rather than guessing.

### Categories

The stable categories are:

| Category | Examples |
| --- | --- |
| `access` | Patient profile opened, clinical record opened, patient search, file access authorized |
| `patient_administration` | Patient created, edited, archived, or restored |
| `scheduling` | Appointment changes, schedule changes, conflict override |
| `clinical` | Clinical finalization/amendment, odontogram and treatment changes |
| `financial` | Invoice, payment, credit, correction, refund, authorized invoice export |
| `staff_security` | Invitation, roles, activation, and other Owner security actions |

The database assigns a category from a controlled event taxonomy. Callers do
not supply it. Flutter localizes known event types and shows an “Other recorded
action” fallback for future server types, without exposing raw metadata.

### Required Phase 13 coverage

Phase 13 preserves existing events and fills these approved gaps:

- patient list/search access: one summary event per completed request with
  result count, page size, and whether a search term was present; never the
  search text or returned patient IDs;
- patient profile opened;
- medical, odontogram, treatment-plan, clinical-session, and patient-file
  areas opened;
- file preview/download authorization, recorded when short-lived access is
  issued because a browser cannot prove that the user completed the download;
- patient demographic creation/edit/archive/restore;
- appointment create, reschedule, and status changes, alongside the existing
  conflict-override, clinical-session, patient-file, and financial events;
- staff invitations, role changes, activation/deactivation, and other
  security-sensitive Owner actions;
- existing invoice PDF authorization, retained as an export event.

Opening the Audit screen itself uses the access command to record
`audit_log_opened` before the first page loads. One screen entry uses one
request UUID; an automatic retry reuses it, while pagination does not create
another open event. The list GET therefore remains read-only and safely
retryable.

No patient names, contact details, diagnoses, clinical note text, file names,
file paths, search terms, payment references, passwords, tokens, IP addresses,
user-agent strings, or raw request/response bodies enter `safe_metadata`.
Amounts already present in financial events remain canonical decimal strings
with currency codes. IDs are allowed only when they provide an authorized
record relationship needed for navigation or investigation.

## Database architecture

### Additive ledger changes

The implementation migration will add actor membership/email/role snapshots,
an event category, and an optional request ID to `audit_events`. It will add
constraints for normalized snapshots, recognized categories, bounded metadata,
and paired request semantics. The migration filename will be created with
`supabase migration new` after approval; no timestamp is invented here.

An insert trigger will derive actor snapshots and category, validate the event
against the taxonomy, reject disallowed metadata keys and value shapes, and
enforce a conservative serialized metadata-size ceiling. Existing writers can
continue inserting their current columns while the trigger supplies the new
values.

An immutability trigger rejects every normal `UPDATE` and `DELETE`, including
attempts made through service credentials. Schema-owner migrations remain the
only supported maintenance path. Direct insert/update/delete privileges are
revoked from `anon`, `authenticated`, and `service_role`; protected
security-definer commands owned by the migration owner append events.

This protects the ledger from normal application credentials. A PostgreSQL
administrator can still alter the database or disable a trigger. External
tamper evidence, signed hash chains, write-once storage, and final retention
policy are production governance decisions and are not claimed in MVP.

### Central event writer

A private central writer will be the only new insertion boundary. Existing
protected commands will be migrated to use it as they receive missing event
coverage. It accepts the already authenticated actor and authorized subject,
maps the event type to its category and metadata allowlist, captures snapshots,
uses database time, and applies request-ID idempotency where supplied.

The writer uses a fixed empty search path, schema-qualified objects, no dynamic
SQL, and no caller-provided identity snapshots. Execute is revoked from all
client roles. Feature commands remain responsible for their business
authorization; the audit writer does not grant access to the subject.

### Owner page query

A service-only page function returns at most 50 rows ordered by
`occurred_at DESC, id DESC`. Its cursor contains both values so events sharing
one timestamp remain stable and pages do not skip or duplicate rows. Optional
filters are equality predicates plus a bounded half-open date range.

The default range is the newest 30 clinic-local dates. A single request may
cover at most 90 days, while an Owner can move the range backward to inspect
older history. The server converts clinic-local date boundaries to instants;
the device time zone never decides inclusion.

The response includes `hasMore` and the next cursor. It omits a full result
count because counting an append-only ledger for every filter adds cost without
helping the investigation workflow. No `OFFSET`, JSON metadata search, fuzzy
actor search, or unbounded query is allowed.

The function checks active Owner membership inside the database even though
the Edge Function also authenticates the request. It returns safe response
fields and typed context keys only. Execute is explicitly revoked from
`PUBLIC`, `anon`, and `authenticated` and granted only to `service_role`.

### Index strategy

The existing clinic/time index will become a deterministic keyset index on
clinic, descending occurrence time, and descending event ID. Candidate
actor/time and category/time indexes will be retained only when representative
`EXPLAIN (ANALYZE, BUFFERS)` plans show they improve the approved filters.
There is no JSONB GIN index because metadata is not searchable.

At MVP volume, one append-only table is simpler and cheaper than partitions or
an archive database. Partitioning will be reconsidered only after production
retention is approved and measured table/index size justifies it.

## Access-auditing architecture

PostgreSQL cannot attach a normal table trigger to `SELECT`. Explicit access
must therefore be recorded at the application read boundary.

Phase 13 adds an authenticated access command to the audit Edge adapter. The
command accepts only a small access intent, target UUID when required, and a
client-generated request UUID. PostgreSQL independently derives the target
clinic, verifies the actor can access that record under the approved role
rules, maps the intent to a fixed event type, and appends idempotently. Flutter
must receive success before opening a sensitive detail area. If auditing is
unavailable, that new sensitive view fails closed with a localized retry state.

Patient list/search is treated differently because no patient IDs or query text
may be copied into metadata. The existing RLS-scoped bounded page is read first;
its adapter then records only result count, requested page size, and a
search-present flag before releasing the result to presentation. If recording
fails, the result is discarded and the workflow fails closed. Phase 14 must
move this into one server transaction before real patient data is permitted.

Patient-file open/download auditing is folded into the existing server-side
read authorization that issues short-lived access. The request includes a
validated `preview` or `download` intent; the database records the authorization
in the same operation. Existing invoice PDF export authorization already uses
this integrated pattern.

Other sensitive pages call the access command immediately before their first
detail query. A Cubit coalesces repeated build/load calls and reuses one request
UUID during a retry, preventing duplicate audit events. Pagination within an
already opened clinical area is not recorded as a separate “opened” event.

The current browser roles retain RLS-protected direct reads until Phase 14
completes the planned security hardening. Therefore Phase 13 guarantees audit
coverage for supported DentaFlow workflows, but it does not claim that a user
with a valid session cannot construct a separate direct Data API read. Phase
14 must inventory and close or formally accept each direct sensitive-read path
before production. This limitation is acceptable only because the current
environment contains fictional/demo data and is explicitly not production.

## Edge API

One `audit-events` Edge Function provides two authenticated operations:

- safe `GET` for Owner-only filtered pages;
- non-retryable `POST` for validated access intents.

The GET accepts clinic ID, local from/to dates, optional actor user ID,
category, event type, subject type, page limit, and the two-part cursor. Unknown
parameters, invalid UUIDs/dates/enums, reversed or oversized ranges, and limits
above 50 are rejected. The response carries the active clinic ID and time zone
so Flutter rejects a stale page after clinic switching.

The POST accepts clinic ID, access intent, optional subject ID, and request ID.
It never accepts actor ID, occurrence time, category, reason, actor label,
roles, or arbitrary metadata. It is a mutation and is never automatically
replayed by Dio; an explicit retry reuses the request UUID and is idempotent.

Both methods validate the bearer token with Supabase Auth, use the server key
only inside the Edge runtime, set `Cache-Control: no-store`, restrict CORS to
approved local/configured origins, and return stable safe error codes plus a
request ID. Logs contain event category, result status, and request ID only.
They exclude clinic, patient, employee, subject, filters, tokens, and bodies.

The Edge adapter does not call another Edge Function, so it does not consume
the hosted recursive function-call budget. Dependencies are version-pinned.

## Flutter architecture

The new `features/audit` module follows the existing boundaries:

```text
features/audit/
  domain/
    audit_models.dart
    audit_repository.dart
  data/
    audit_data_source.dart
    supabase_audit_data_source.dart
    supabase_audit_repository.dart
  presentation/
    audit_cubit.dart
    pages/audit_log_page.dart
    widgets/audit_filter_sheet.dart
    widgets/audit_event_details.dart
```

These paths are a proposed implementation structure, not frontend code.
Provider response objects stay in data. Domain models contain only validated
IDs, enums, instants, actor snapshots, reason, and typed safe context. Raw JSON
does not enter widgets.

`AuditCubit` owns the current filter, rows, next cursor, loading-more state,
refresh state, and typed failure. It resets on active-clinic change, privacy
lock, logout, or loss of Owner role. Every async response carries the requested
clinic/filter generation; a late response cannot overwrite newer state.
Duplicate initial loads and load-more calls are coalesced.

The repository treats unknown event types as forward-compatible “other”
events, but rejects malformed IDs, time zone, timestamps, categories, actor
snapshots, unsafe context keys, inconsistent cursors, or mismatched clinic
scope. The access-recording contract is separate from the Owner list contract
so other features do not gain audit-read capability.

The route is `/audit`. It is protected by the normal signed-in route guard and
an active-clinic Owner guard. A non-Owner deep link receives a neutral localized
unavailable page and triggers no audit query. Owners reach it from an Audit
action in the active-clinic workspace; later navigation-shell work can move the
same route without changing the feature.

## Audit Log screen specification

### Purpose and primary action

The screen lets an Owner investigate recent security and operational actions.
The primary action is narrowing the ledger with filters and opening one event
to understand its actor, subject, reason, and safe context.

### Desktop layout

- App bar: Audit log title, active clinic name, manual refresh, and clinic
  switch when more than one membership exists.
- Summary strip: visible local date range, clinic time zone, and a clear-filter
  action. It does not show misleading “total events” counts.
- Filter row: date range, employee, category, event type, and entity type.
  Applied filters appear as removable chips.
- Main table: local date/time, employee, category, localized action, entity,
  and reason indicator. Newest events appear first.
- Details: selecting a row opens a side panel on wide screens. The panel shows
  event ID, exact clinic-local timestamp with UTC offset, actor email and role
  snapshot, localized action/category, entity type/ID, reason, and typed safe
  context. IDs can be copied individually; arbitrary JSON is never rendered.
- Footer: a deliberate **Load more** button and progress state. There is no
  automatic infinite scroll, polling, or Realtime subscription.

### Tablet and mobile

At tablet width, filters wrap and event details use a modal sheet. On mobile,
the filter row becomes one **Filters** button with an applied-count badge and a
full-height bottom sheet. Results become cards showing time, actor, action, and
category; tapping a card opens the details sheet. Date/time remains formatted
in the clinic time zone. Layout supports 320 px width, 200% text scale, large
Russian strings, and Arabic RTL without horizontal page scrolling.

### States and interaction

- Skeleton rows on first load.
- A clear empty state distinguishes “no activity yet” from “no results for
  these filters.”
- First-load failure replaces the list with a safe retry action.
- Refresh and load-more failures retain existing rows and show a localized
  notice.
- Changing a filter cancels the logical generation, clears the cursor, and
  loads from the first page.
- Refresh retains the filter and returns to the first page.
- An event link appears only for a recognized subject/context combination and
  goes to an already authorized existing route. Unsupported or historical
  targets remain readable audit facts without broken navigation.

English, Russian, and Arabic strings include screen labels, categories, event
summaries, role names, empty/failure states, filter controls, dates, and
accessibility semantics. Colors use the existing healthcare theme; category is
communicated by icon and text as well as color.

## Proposed file changes after approval

```text
docs/PHASE_13_AUDIT_LOGS_ARCHITECTURE.md
supabase/migrations/<generated>_complete_audit_ledger.sql
supabase/functions/audit-events/index.ts
supabase/config.toml
supabase/tests/audit_events_rls.test.sql
lib/features/audit/domain/*
lib/features/audit/data/*
lib/features/audit/presentation/*
lib/features/patient/data/*
lib/features/patient_file/data/*
lib/features/clinical_session/presentation/*
lib/features/odontogram/presentation/*
lib/features/treatment_plan/presentation/*
lib/app/router/app_router.dart
lib/app/bootstrap/*
lib/app/localization/arb/app_en.arb
lib/app/localization/arb/app_ru.arb
lib/app/localization/arb/app_ar.arb
lib/app/localization/generated/*
test/audit/*
test/local/audit_integration_test.dart
README.md
ARCHITECTURE.md
DATABASE.md
PERMISSIONS.md
```

The implementation may touch existing protected database commands to route
their writes through the central ledger helper and add missing events. It will
not change their business outcomes or introduce Phase 14 work.

## Implementation sequence after approval

1. Use the installed Supabase CLI to generate the migration filename. Extend
   and backfill the ledger, add snapshot/taxonomy/immutability rules, central
   writer, Owner query, access commands, explicit grants, and measured indexes.
2. Add pgTAP coverage before exposing the API: tenant isolation, all roles,
   inactive users, direct grants, immutability, actor snapshots, metadata
   allowlists, request idempotency, filter boundaries, stable pagination, and
   existing-event preservation.
3. Add missing mutation and access events at the approved feature boundaries,
   including integrated patient search and file authorization paths.
4. Implement and test the authenticated `audit-events` Edge adapter with safe
   GET/POST contracts, no-store responses, method validation, and redacted
   logging.
5. Add Flutter domain/data/Cubit wiring, route/role guards, localized responsive
   UI, clinic/session clearing, filters, details, and subject navigation.
6. Run the full database, authenticated local, generation, formatting,
   analysis, Flutter test, and release Web build gates. Update status documents
   only after every required check passes.

## Verification plan

### Database and API

- Anonymous, non-Owner, inactive, and Clinic B users cannot infer Clinic A
  events or actor choices through rows, cursors, errors, or filter facets.
- `anon`, `authenticated`, and `service_role` cannot directly mutate existing
  events; update/delete triggers reject normal application paths.
- Only protected feature functions can append recognized event types and
  allowlisted metadata.
- Actor membership, verified email, and role snapshots remain unchanged after
  staff role or activation changes.
- Existing events survive migration and receive safe best-effort snapshots.
- Duplicate access retries with one request UUID return one event.
- Patient search stores result count and search-present flag without query text
  or returned patient IDs.
- Every sensitive access intent rechecks record clinic and role authorization.
- File preview/download and invoice export authorization append the expected
  event in the same protected operation.
- Local-date filters honor the clinic IANA time zone, half-open instants,
  daylight-saving boundaries, and the 90-day request limit.
- `(occurred_at, id)` cursor pagination remains stable for equal timestamps and
  concurrent inserts.
- Query plans use the clinic/keyset index at representative fictional volume.

### Flutter and end-to-end

- Repository parsing rejects malformed IDs, dates, roles, categories, context,
  cursors, and stale clinic responses.
- Cubit tests cover initial load, filters, refresh, load-more, duplicate calls,
  stale responses, clinic switching, role loss, lock/logout, and retained-data
  failures.
- Route and widget tests prove only Owner can discover the Audit area.
- UI tests cover desktop table, mobile cards and sheets, empty/loading/error
  states, long reasons, dark mode, 320 px width, 200% scale, Russian expansion,
  and Arabic RTL.
- An authenticated local integration test creates only fictional events,
  verifies Owner filtering/pagination/details, verifies non-Owner denial,
  records an access event, and proves an update/delete attempt fails.

Required completion commands:

```text
flutter gen-l10n
dart run build_runner build
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase db test
supabase db lint --level warning
flutter build web --dart-define-from-file=config/local.json
```

Phase 13 is complete only when every gate passes, the authenticated audit flow
is verified with fictional local data, documentation reflects the result, and
Phase 14 has not been implemented.

## Implemented result and verification

Phase 13 is implemented through the additive
`20260913145944_complete_audit_ledger.sql` migration, the authenticated
`audit-events` Edge Function, the provider-independent Flutter audit feature,
Owner routing/navigation, and fail-closed patient/file access gates. English,
Russian, and Arabic audit copy is included, with RTL mobile cards and a wider
desktop table.

Verification completed on 2026-09-13:

- all migrations replayed successfully from an empty local database;
- all 295 pgTAP database tests passed across 12 files;
- database lint returned no errors (four earlier schedule warnings remain);
- the authenticated local audit integration passed using fictional data and
  Mailpit;
- generated-code checks completed with no drift;
- `dart format` reported 188 files formatted and zero changes;
- `flutter analyze` reported no issues;
- all 116 Flutter tests passed, with six intentional opt-in skips in the normal
  suite;
- the configured Flutter Web build completed successfully, including its Wasm
  dry run.

Phase 14 was not implemented.

## Risks and trade-offs

- **Direct read paths:** Phase 13 records supported application workflows, but
  some existing RLS-authorized Data API reads remain constructible outside the
  Flutter UI. This is explicitly tracked for Phase 14 and prevents any claim of
  production-complete access auditing.
- **Database administrators:** Append-only controls protect against normal app
  credentials, not a database administrator. External immutable retention
  needs legal requirements and production infrastructure.
- **Event volume:** Search/access events grow faster than mutation events.
  Summary logging, bounded pages, keyset indexes, no per-row events, and no
  Realtime consumption keep MVP load predictable.
- **Metadata leakage:** Dynamic JSON is easy to misuse. A database allowlist,
  size cap, typed adapter, safe UI, and negative tests are mandatory.
- **Historical actor context:** Older rows lack snapshots. Backfill is the best
  available reconstruction and must be labeled unavailable when evidence is
  missing rather than fabricated.
- **Availability:** Failing closed can temporarily block a new sensitive page
  when audit recording is unavailable. This is preferable for an explicitly
  audited healthcare workflow and requires a clear retry state.
- **Retention:** Keeping all demo events is acceptable now. Production expiry,
  legal hold, backup, recovery, and residency remain undecided and must be
  resolved before real patient data.

## Current platform references

- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase database functions](https://supabase.com/docs/guides/database/functions)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Supabase platform audit logs](https://supabase.com/docs/guides/security/platform-audit-logs)
- [Supabase Data API explicit-grant change](https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically)

Supabase's 2026 Data API change reinforces this architecture's explicit
function/table grants. Platform audit logs cover project administration and
Auth audit logs cover authentication activity; neither is used as the clinic
business ledger. Phase 13 does not require paid log drains, external storage,
Realtime, scheduled jobs, or another service.
