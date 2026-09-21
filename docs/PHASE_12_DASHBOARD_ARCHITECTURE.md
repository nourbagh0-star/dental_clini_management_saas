# Phase 12 — Active Clinic Dashboard Architecture

Status: implemented and verified on 2026-09-13.

Authority: [Master Specification](MASTER_SPECIFICATION.md), especially sections
10–15, 52, 66–77, 80–83, and the Phase 12 product decisions approved on
2026-09-13.

## Approved product decisions

- The Dashboard is available to every active clinic member, but it never grants
  a role access to information that role cannot already read elsewhere.
- An Owner sees all six MVP dashboard areas. A Dentist sees appointments,
  active-patient totals, completed treatments, and invoice balance information
  already allowed by Phase 11. A Receptionist sees appointments,
  active-patient totals, and outstanding payments. An Assistant sees
  appointments and the active-patient total, without treatment-completion or
  financial information.
- All calendar boundaries use the active clinic's stored IANA time zone rather
  than the device time zone.
- A week is Monday through Sunday. Upcoming appointments cover the next seven
  clinic-local calendar days after today, so they do not duplicate the Today
  list.
- Total patients means patients in the active clinic whose record is not
  archived.
- Completed treatments means treatment-plan items whose completion time falls
  in the current clinic-local calendar month.
- Outstanding payments means the exact sum of `outstanding_balance` for
  finalized, non-cancelled invoices in the active clinic.
- Data loads when the Dashboard is entered and when the active clinic changes.
  The user can refresh explicitly. Phase 12 does not consume Supabase Realtime
  or poll continuously.

## Scope and exclusions

Phase 12 delivers one read-only operational Dashboard for the active clinic:

1. today's appointment count and bounded appointment preview;
2. upcoming appointment count and bounded seven-day preview;
3. active-patient count;
4. non-cancelled appointment count for the current Monday–Sunday week;
5. treatment-plan item completions for the current month, where authorized;
6. exact outstanding invoice balance and invoice count, where authorized.

The page also provides links to the existing Patients, Appointments, Treatment
Plans, and Billing areas when the user's roles allow them.

Phase 12 does not add monthly revenue, patient-growth trends, per-dentist
metrics, procedure statistics, charts, exports, targets, comparisons with an
earlier period, notifications, a full audit browser, or a materialized
analytics warehouse. Those belong to later phases. It also does not introduce
Firebase Analytics, Supabase Analytics Buckets, Realtime subscriptions, paid
services, or production monitoring.

## Metric definitions

The server calculates one `generatedAt` instant and derives all boundaries from
the clinic time zone. Ranges are half-open: start is included and end is
excluded. This avoids double counting at midnight and around month/week
changes.

### Clinic-local boundaries

```text
todayStart       = local midnight at the start of the clinic's current date
tomorrowStart    = todayStart + one local calendar day
upcomingEnd      = tomorrowStart + seven local calendar days
weekStart        = Monday 00:00 containing the clinic's current date
weekEnd          = weekStart + seven local calendar days
monthStart       = first day of the clinic's current month at 00:00
nextMonthStart   = first day of the next clinic-local month at 00:00
```

PostgreSQL converts each local boundary to `timestamptz` using the clinic's
stored time zone before comparing it with UTC instants. It must not approximate
a day as 24 elapsed hours because daylight-saving transitions can produce
shorter or longer local days.

### Appointment rules

- **Today's appointments:** `starts_at` is in `[todayStart, tomorrowStart)`.
  The preview includes scheduled, confirmed, in-progress, completed, and
  no-show appointments. Cancelled appointments are excluded from the Dashboard
  but remain visible in the full Appointment Calendar.
- **Upcoming appointments:** `starts_at` is in
  `[tomorrowStart, upcomingEnd)` and status is scheduled or confirmed.
- **Appointments this week:** `starts_at` is in `[weekStart, weekEnd)` and the
  status is not cancelled. Completed and no-show appointments still count as
  appointments that occurred during the week.
- Appointments are ordered by `starts_at`, then UUID for deterministic output.
- Today returns at most 12 preview records. Upcoming returns at most 10. Each
  section also returns its full count and `hasMore`; **View all** opens the
  Appointment Calendar with a validated initial date range.
- Preview rows contain appointment ID, patient ID, safe patient display name
  and number, dentist member ID and display label, start/end instants, and
  status. They exclude purpose, preparation notes, clinical-session content,
  diagnoses, contact details, and override/cancellation reasons.

### Patient rule

`totalPatients` counts `patients` rows for the active clinic where
`archived_at is null`. Archived patients remain in historical appointment and
billing records but do not contribute to this operational total.

### Completed-treatment rule

`completedTreatmentsThisMonth` counts treatment-plan items with
`status = completed` and `completed_at` in `[monthStart, nextMonthStart)`.
Only Owner and Dentist capabilities receive this field.

Phase 8 currently records `updated_at` but no dedicated completion instant.
Phase 12 therefore proposes additive `completed_at` and `completed_by` columns:

```text
treatment_plan_items.completed_at timestamptz nullable
treatment_plan_items.completed_by uuid nullable
```

The status invariant requires both values when status is completed and neither
for all other statuses. The protected item-transition command sets them when a
Dentist completes an item. Existing completed fictional items are backfilled
from `updated_at`; this is the best available historical approximation and is
documented as such. Completed items are terminal under the existing workflow,
so later updates cannot silently move their completion month.

### Outstanding-payment rule

The Dashboard returns:

```text
outstandingInvoiceCount = count of finalized, non-cancelled invoices
                          where outstanding_balance > 0
outstandingPayments     = exact sum of their outstanding_balance
currencyCode            = active clinic currency snapshot for display
```

Cancelled and draft invoices are excluded. Unpaid and partially paid finalized
invoices are included. Values stay PostgreSQL `numeric`, cross the API as
canonical decimal strings, and map to the existing Dart `Money` value. Owner,
Dentist, and Receptionist capabilities receive these fields. Assistant
responses omit the entire financial object rather than returning a hidden
zero.

## Role and information boundaries

| Dashboard capability | Owner | Dentist | Assistant | Receptionist |
| --- | ---: | ---: | ---: | ---: |
| Today's and upcoming appointments | Yes | Yes | Yes | Yes |
| Active-patient total | Yes | Yes | Yes | Yes |
| Appointments-this-week total | Yes | Yes | Yes | Yes |
| Completed treatments this month | Yes | Yes | No | No |
| Outstanding invoice count and amount | Yes | Yes | No | Yes |
| Patient and appointment links | Yes | Yes | Yes | Yes |
| Treatment link | Yes | Yes | Read path only when already authorized | No |
| Billing link | Yes | Yes | No | Yes |

The backend derives these capabilities from active database membership and the
union of the user's roles for the requested clinic. Flutter uses the returned
capabilities to render the page, but that rendering is convenience rather than
authorization. A stale client role can never make the server return a denied
field.

The Dashboard does not return clinical notes, diagnoses, odontogram data,
procedure descriptions, file metadata, payment references, ledger entries,
patient phone/email/address, or audit reasons.

## Backend architecture

### Why live indexed aggregation

MVP data volume and refresh frequency do not justify a materialized view,
scheduled aggregation job, Analytics Bucket, or extra cache service. One
bounded PostgreSQL snapshot uses source-of-truth tables and existing tenant
keys. This avoids stale counters, invalidation logic, paid infrastructure, and
another provider dependency.

The implementation should reconsider pre-aggregation only after measured query
plans show a real problem at production-like volume. Flutter's repository
contract does not change if the server later replaces live queries with a
summary table or another provider.

### Protected snapshot function

One service-only PostgreSQL function is the calculation authority:

```text
public.dashboard_snapshot(
  actor_user_id uuid,
  target_clinic_id uuid
) returns jsonb
```

The function is `security definer` only because the result combines tables
whose RLS visibility differs by role. It uses `set search_path = ''`, schema-
qualified names, an active-membership check, database-derived role checks,
bounded subqueries, and no dynamic SQL. Execution is revoked from `PUBLIC`,
`anon`, and `authenticated` and granted only to `service_role` for the Edge
adapter. Its JSON contains only the approved safe fields.

The function computes every count, list, permission flag, date boundary, and
`generatedAt` value inside one database request. The response includes the
clinic ID and time zone used so Flutter can reject a stale response received
after the user switches clinics.

Proposed response contract:

```text
clinicId
clinicTimeZone
generatedAt
periods
  todayStart / tomorrowStart
  upcomingEnd
  weekStart / weekEnd
  monthStart / nextMonthStart
capabilities
  canViewCompletedTreatments
  canViewFinancialSummary
metrics
  totalPatients
  appointmentsThisWeek
  completedTreatmentsThisMonth?  (omitted when denied)
  financial?                      (omitted when denied)
    outstandingInvoiceCount
    outstandingAmount            canonical decimal string
    currencyCode
todayAppointments
  totalCount / hasMore / items
upcomingAppointments
  totalCount / hasMore / items
```

Unknown keys are ignored by the adapter for forward compatibility. Missing,
malformed, out-of-range, denied-but-present, cross-clinic, or non-canonical
money values fail closed as a typed invalid-response failure.

### Edge Function

A JWT-protected `dashboard` Edge Function exposes one safe read endpoint:

```text
GET /functions/v1/dashboard?clinicId=<uuid>
```

It accepts no body. It validates the method, clinic UUID, JWT, and authenticated
user using the existing server-auth pattern, invokes `dashboard_snapshot` with
the service credential, and returns the bounded JSON. A GET allows the existing
transport's single safe retry after token refresh or a transient read failure.

Responses use:

- `200` for a snapshot;
- `400` for a malformed clinic ID;
- `401` for an absent or invalid session;
- `403` for inactive or cross-clinic membership;
- `405` for other methods;
- `500` with a generic dashboard-unavailable code for unexpected failures.

Logs contain action, safe error category, HTTP status, and request correlation
ID. They exclude user/clinic/patient/appointment identifiers, response data,
tokens, names, balances, and raw provider/database messages. The response uses
`Cache-Control: no-store` because it contains clinic operational data.

### Grants and RLS

No direct client mutation is introduced. Existing source tables retain their
RLS and grants. Any new public object receives an explicit grant because current
Supabase Data API behavior is moving away from automatic public-schema
exposure. The function itself revalidates membership and capabilities even
though only the Edge service adapter can execute it.

No dashboard table, public aggregate view, browser-callable privileged
function, or Storage policy is needed. The service-role key remains exclusively
inside the Edge runtime and never enters Flutter, generated assets, logs, or
configuration committed to the repository.

## Index plan

Existing indexes already support active-patient and clinic appointment ranges:

```text
patients (clinic_id, last_name, first_name, id)
  where archived_at is null
appointments (clinic_id, starts_at)
```

Phase 12 proposes only measured, query-shaped additions:

```text
treatment_plan_items (clinic_id, completed_at)
  where status = 'completed'
invoices (clinic_id, outstanding_balance)
  where document_status = 'finalized' and outstanding_balance > 0
```

The invoice partial index is accepted only if `EXPLAIN (ANALYZE, BUFFERS)` on
representative fictional volume shows it improves the dashboard query without
duplicating a sufficient Phase 11 index. Index review includes foreign-key and
RLS helper access paths. Phase 12 does not add indexes speculatively after the
query plan is already efficient.

## Flutter architecture

### Domain

The `dashboard` feature owns provider-independent immutable values:

```text
DashboardSnapshot
DashboardCapabilities
DashboardMetrics
DashboardFinancialSummary
DashboardAppointmentPreview
DashboardPeriod
DashboardRepository
```

Appointments use existing domain status semantics, but the Dashboard keeps a
small read model rather than depending on an appointment DTO or Cubit. The
financial summary uses the existing `Money` type. Domain objects contain no
Supabase client, JSON map, HTTP response, or Storage type.

### Data

`DashboardDataSource` owns the authenticated GET and provider response.
`SupabaseDashboardRepository` validates and maps every field into the domain
snapshot. The repository accepts the active clinic ID explicitly; it does not
read global widget state. This keeps the adapter replaceable and makes clinic
scope testable.

### State

`DashboardCubit` has these states:

```text
initial
loading
ready
refreshing while retaining the last in-memory snapshot
failure with no snapshot
ready with non-blocking refresh failure
```

`load(clinicId)` clears any earlier clinic snapshot immediately, prevents an
older request from overwriting a newer clinic selection, and coalesces duplicate
loads for the same clinic. `refresh()` keeps the last snapshot visible and
updates `generatedAt` only after success. Data is held in memory only and is
cleared on logout, privacy lock, clinic removal, or clinic switch.

Typed failures distinguish authentication, permission, connectivity,
temporarily unavailable, invalid response, and unknown. The user sees localized
safe messages and a retry action; raw SQL, HTTP bodies, or identifiers never
reach presentation.

### Routing and active-clinic flow

- `/dashboard` is an authenticated route.
- Once clinic loading has selected an active clinic, `/clinic-gate` sends the
  user to `/dashboard` as the normal workspace landing page.
- A direct `/dashboard` visit with no active clinic goes to `/clinic-gate`.
- Selecting or creating a clinic finishes at `/dashboard`.
- Switching clinics clears the previous Dashboard before the new load begins.
- **View all appointments** opens `/appointments` with validated `from` and
  `to` date query parameters. The Appointment page may use them only to choose
  its initial visible range; its repository still scopes by the active clinic.

Phase 12 adds a Dashboard entry to the current clinic workspace navigation and
quick links from Dashboard cards. Converting every existing feature to the
complete desktop sidebar/mobile bottom-navigation shell remains Phase 15 work;
Phase 12 must not perform that broad navigation refactor.

## UI and UX specification

### Purpose and primary action

The Dashboard answers: “What needs attention in this clinic today?” Its primary
action is opening an appointment from Today or Upcoming. Secondary actions open
the complete Patients, Appointments, Treatments, or Billing workspaces.

### Desktop layout above 1024 px

- A page header shows **Dashboard**, active clinic name, clinic-local date and
  time-zone label, last-updated time, clinic switch action when applicable, and
  an icon-and-text Refresh button.
- A responsive metric grid uses up to three columns. Cards appear only when
  authorized: Active patients, Appointments this week, Completed treatments
  this month, and Outstanding payments. The financial card shows exact amount,
  currency code, and outstanding invoice count.
- Below the metrics, two equal-width panels show Today's appointments and the
  next seven days. Each has count, bounded rows, empty state, and **View all**.
- Appointment rows show local time, patient name and number, dentist label, and
  a text/icon status chip. Selecting a row opens the existing appointment
  workflow or patient context supported by the Appointment page.
- Financial and treatment cards link only when the role has the corresponding
  destination permission.

### Tablet 600–1024 px

- Header controls wrap without truncating the clinic name.
- Metric cards use two columns.
- Today and Upcoming stack vertically at full width.
- Appointment rows retain patient, time, dentist, and status. Long labels wrap
  to two lines; no horizontal scrolling is required.

### Mobile below 600 px

- Header is a compact app bar with Dashboard title, clinic selector, and Refresh
  icon with an accessible tooltip.
- Metrics use one or two columns depending on available width and text scale;
  exact money never shrinks below the readable body style.
- Appointment panels become vertical cards. Each record shows time first,
  followed by patient, dentist, and status.
- Today appears before Upcoming. **View all** is a full-width text action.
- Layout must fit 320 logical pixels with 200% text scaling and preserve Arabic
  right-to-left order without clipping.

### Loading, empty, and error behavior

- First load uses semantic skeleton blocks with no invented numbers.
- A clinic with no data shows zero metric values and separate friendly empty
  messages for Today and Upcoming.
- Refresh keeps the last result visible, disables duplicate refresh taps, and
  shows a small progress indicator.
- A failed first load replaces content with a localized safe message and Retry.
- A failed refresh retains the earlier snapshot, labels its last-updated time,
  and displays a dismissible non-sensitive banner.
- Permission changes that remove access cause a full reload; denied sections
  disappear rather than showing an error card that reveals their existence.

### Visual system and accessibility

Phase 12 reuses the approved Material 3 theme, spacing tokens, typography, and
light/dark modes. It does not introduce a separate dashboard palette. Accent
color supports hierarchy; appointment status always uses text and icon in
addition to color. Metric cards use semantic icons with hidden decorative
duplicates, logical focus order, minimum 48×48 tap targets, high-contrast text,
and screen-reader labels that include the metric period and currency code.

All user-facing text is generated for English, Russian, and Arabic. Dates and
times use the selected application locale while their boundaries remain based
on clinic time. Numbers and monetary values preserve readable digit direction
inside Arabic layouts. No English fallback is hardcoded in widgets.

## Proposed file changes after approval

Create:

```text
docs/PHASE_12_DASHBOARD_ARCHITECTURE.md
supabase/migrations/<generated_timestamp>_add_dashboard_snapshot.sql
supabase/tests/dashboard_rls.test.sql
supabase/functions/dashboard/index.ts
lib/features/dashboard/domain/dashboard_models.dart
lib/features/dashboard/domain/dashboard_repository.dart
lib/features/dashboard/data/dashboard_data_source.dart
lib/features/dashboard/data/supabase_dashboard_data_source.dart
lib/features/dashboard/data/supabase_dashboard_repository.dart
lib/features/dashboard/presentation/dashboard_cubit.dart
lib/features/dashboard/presentation/pages/dashboard_page.dart
test/dashboard/supabase_dashboard_data_source_test.dart
test/dashboard/dashboard_repository_test.dart
test/dashboard/dashboard_cubit_test.dart
test/dashboard/dashboard_page_test.dart
test/local/dashboard_integration_test.dart
```

Change:

```text
lib/app/app.dart
lib/app/bootstrap/bootstrap.dart
lib/app/bootstrap/dependencies.config.dart (generated)
lib/app/router/app_router.dart
lib/features/clinic/presentation/pages/clinic_pages.dart
lib/features/appointment/presentation/pages/appointment_pages.dart
lib/app/localization/arb/app_en.arb
lib/app/localization/arb/app_ru.arb
lib/app/localization/arb/app_ar.arb
lib/app/localization/generated/* (generated)
README.md
ARCHITECTURE.md
DATABASE.md
PERMISSIONS.md
```

The migration filename must be created by `supabase migration new`; the
timestamp above is intentionally not invented in this architecture document.

## Implementation sequence after approval

1. Generate the migration file with the installed Supabase CLI. Add completion
   metadata and invariants, backfill fictional completed items, implement the
   protected snapshot, and add only query-plan-justified indexes.
2. Add pgTAP coverage for tenant isolation, roles, time boundaries, archived
   patients, appointment statuses, treatment completion, exact outstanding
   balances, grants, and denied-field omission.
3. Implement the authenticated read-only Dashboard Edge Function with bounded
   validation, safe errors/logs, explicit no-store response caching, and Edge
   tests.
4. Add the Flutter domain, data adapter, repository, Cubit, dependency wiring,
   clinic-change cancellation, route, and generated localization.
5. Build the responsive role-aware screen and validated links to existing
   workspaces. Do not add later analytics or Phase 13 audit UI.
6. Run generated-code and localization checks, authenticated role smoke tests,
   database tests/lint, Flutter format/analyze/test, and the Web release build.

## Verification plan

### Database and authorization

- Clinic A cannot obtain Clinic B counts, previews, time zone, or balances.
- Inactive members and unknown users are denied.
- `anon` and `authenticated` cannot execute the protected snapshot directly.
- Owner, Dentist, Assistant, Receptionist, and combined roles receive exactly
  the approved fields.
- Appointment status filters and half-open boundaries are correct at midnight,
  Monday/Sunday, month change, leap day, and a representative daylight-saving
  transition.
- Archived patients are excluded from the active total.
- Completion metadata remains paired and only the protected Dentist transition
  can establish it.
- Outstanding balance includes only finalized non-cancelled positive balances
  and remains an exact decimal string.
- Preview limits, ordering, counts, and `hasMore` remain correct.
- `EXPLAIN (ANALYZE, BUFFERS)` confirms range and partial-index use at
  representative fictional volume.

### Edge and Flutter

- GET succeeds with a valid local session; malformed clinic, wrong method,
  missing JWT, cross-clinic request, and unexpected database failure return
  safe stable outcomes.
- Repository mapping rejects malformed dates, negative counts, bad UUIDs,
  unsupported appointment statuses, and non-canonical money.
- Cubit prevents stale clinic responses, coalesces duplicate load/refresh,
  preserves the current snapshot after a refresh error, and clears data on
  clinic switch or session privacy changes.
- Widget tests cover every role combination, empty/loading/error/refresh states,
  navigation, 320 px mobile width, tablet and desktop, 200% text scale, dark
  mode, Russian expansion, and Arabic RTL.
- An opt-in authenticated local test creates fictional appointments, patients,
  completed treatment items, and invoices, then verifies all six Owner metrics
  plus Assistant and Receptionist field omission.

Required completion commands:

```text
flutter gen-l10n
dart run build_runner build
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase test db --local
supabase db lint --local --level warning --fail-on error
flutter build web --dart-define-from-file=config/local.json
```

Phase 12 is complete only when every gate passes, the authenticated active-
clinic workflow is verified with fictional data, and Phase 13 has not been
implemented.

## Implementation and verification

Phase 12 is implemented in migration
`20260913102927_add_dashboard_snapshot.sql`, the protected `dashboard` Edge
Function, and the Flutter `features/dashboard` module. It also routes clinic
selection and clinic creation to `/dashboard`, while session lock, logout, and
clinic changes clear or replace the in-memory snapshot.

Verification completed with fictional local data:

- 264 pgTAP assertions passed across all 11 database test files; the 25
  dashboard assertions cover grants, tenant isolation, active membership,
  every role, clinic-local boundaries, status filters, archived patients,
  exact balances, completion metadata, and terminal treatment state.
- Database lint reported no Phase 12 findings. Its remaining warnings are the
  pre-existing appointment enum-return casts and unused schedule impact
  parameters.
- Dashboard data-source, repository, Cubit, and widget tests passed, including
  strict money and clinic-scope mapping, stale-response protection, refresh
  behavior, denied-group rendering, Arabic RTL, and narrow large-text layout.
- The opt-in authenticated local integration test created a fictional owner
  and clinic through public application paths and received the full
  clinic-scoped owner snapshot from the real Edge Function.
- Localization generation, dependency generation, formatting, static
  analysis, the full Flutter suite, and release Web compilation passed.

The role and nonzero metric combinations are exercised deterministically in
pgTAP; the authenticated integration check separately proves Auth, gateway,
Edge Function, service-role RPC, and response wiring end to end.

## Risks and trade-offs

- **Historical completion time:** Phase 8 did not store `completed_at`.
  Backfilled fictional history uses `updated_at`, so older completion-month
  placement is approximate. All future completions become exact.
- **Live aggregate cost:** Counts become slower as a clinic grows. Bounded lists,
  tenant-first predicates, query-shaped indexes, and measured plans are enough
  for MVP; a summary table can replace the server adapter later.
- **Freshness:** Manual refresh can show an older in-memory snapshot until the
  user refreshes or re-enters. The visible last-updated time makes this clear
  without consuming ongoing free-tier Realtime resources.
- **Role changes during a session:** Flutter may briefly render its last safe
  snapshot, but every new server request derives permissions from current
  database membership. Privacy lock/logout/clinic switch clears the snapshot.
- **Time zones:** Clinic-local periods are business-correct but require explicit
  DST boundary tests. Device time never decides metric membership.
- **Financial meaning:** Outstanding payments are operational receivables, not
  recognized revenue, cash flow, tax reporting, or certified accounting.

## Current platform references

- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase PostgreSQL indexes](https://supabase.com/docs/guides/database/postgres/indexes)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Supabase changelog](https://supabase.com/changelog)

The 2026 changelog notes that new public-schema objects are moving away from
automatic Data API exposure, which reinforces this project's existing practice
of explicit grants and RLS. It also documents automatic transient retries for
safe PostgREST reads; Phase 12 still keeps mutation retry rules unchanged and
uses an explicitly safe GET for the Dashboard snapshot.
