# Phase 15 — Responsive Polish and Integration Test Architecture

Status: complete on 2026-09-14.

Authority: [Master Specification](MASTER_SPECIFICATION.md), especially sections
66–68, 79–85, and the approved Phase 0–14 architecture and behavior.

## Product decisions used for this proposal

These choices follow the recommendation preference already approved for this
project:

- use an adaptive signed-in workspace shell: labeled sidebar on desktop,
  compact navigation rail on tablet, and bottom navigation plus More on mobile;
- retain the approved teal healthcare identity and apply consistent visual
  polish instead of redesigning the product;
- translate all 68 remaining Arabic keys and remove all user-facing hardcoded
  strings from existing Flutter widgets;
- validate English, Russian, and Arabic, including right-to-left Arabic, at
  mobile, tablet, and desktop widths;
- use fictional data and local free-tier services only.

## Goal and boundaries

Phase 15 completes the MVP client experience. It creates one predictable
navigation system, makes every existing screen usable across the approved
breakpoints, completes Arabic localization, improves keyboard and assistive
technology behavior, and verifies the complete fictional clinic workflow.

Phase 15 does not add clinical or financial capabilities, change permissions,
add database tables, deploy to a paid service, introduce real patient data, or
claim production readiness. Existing server authorization remains authoritative.

## Current-state findings

- Feature screens are implemented through Phase 14 and the current 116 Flutter
  tests pass.
- Individual newer screens already contain responsive layouts, but signed-in
  routes do not share a persistent workspace shell.
- The Master Specification requires desktop sidebar navigation, adaptive tablet
  navigation, and Dashboard/Patients/Appointments/More mobile navigation.
- English and Russian each contain 294 translated keys. Arabic contains 226 and
  is missing 68 older keys.
- At least 185 user-facing English string occurrences remain directly in eight
  feature page files. They prevent complete Russian/Arabic behavior and must be
  moved to ARB resources.
- The project has no Git repository, so local review artifacts and validation
  can be produced, but commits and pull requests cannot be created.

## Implementation progress

Step 1 is complete. English, Russian, and Arabic now contain the same 576
message keys. The 68 older Arabic gaps are translated, and appointment,
patient, staff, schedule, odontogram, procedure-catalogue, treatment-plan, and
billing validation copy now uses generated localization instead of direct
English widget strings. Enum names shown to users are mapped to localized role,
status, tooth-surface, and clinical-condition labels. A regression test checks
catalog parity, empty translations, and direct English presentation literals.

Step 2 is complete. Shared mobile, tablet, and desktop breakpoints, spacing and
size tokens, a consistent `WorkspacePage`, responsive record switching, and
reusable loading/empty/error panels now provide the layout foundation for every
feature. The theme enforces 48-pixel control targets and consistent card/input
surfaces. Focused responsive tests cover breakpoint boundaries, local-width
adaptation, and a 320-pixel Arabic RTL screen at 200% text scale. Static analysis
is clean and the complete suite passes with 121 active tests and 6 intentionally
skipped local-service tests.

Step 3 is complete. All signed-in clinic routes now share an adaptive shell:
a 256-pixel labeled desktop sidebar, a compact tablet rail, and a four-item
mobile navigation bar with a safe-area More sheet. Destination visibility comes
from the active membership while feature and server authorization remain in
place. Contextual patient and appointment routes retain the correct selection.
The new Settings screen controls the existing persisted theme and language,
clinic switching, privacy lock, and sign-out flows. English, Russian, and Arabic
catalogs each contain 587 matching keys. Static analysis is clean and the full
suite passes with 125 active tests and 6 intentionally skipped local-service
tests.

Step 4 is complete. The patient directory now switches from mobile cards to a
desktop data table, the patient profile uses an adaptive action grid, and the
new-patient form uses spaced one/two-column field groups instead of edge-to-edge
controls. The appointment calendar now loads one clinic-time day on mobile and
one week on wider screens, correctly reloads when its period changes, and adds
a Today action. Appointment creation uses bounded content and adaptive date,
time, and duration controls. Clinic entry no longer advertises the doctor
schedule to roles that cannot open it. Existing authentication and dashboard
responsive coverage remains clean. All three catalogs contain 593 matching
keys; static analysis is clean and the full suite passes with 128 active tests
and 6 intentionally skipped local-service tests.

Step 5 is complete. Schedule and procedure-catalogue pages now use the shared
responsive page insets, and all clinical selectors expand safely for long
Russian and Arabic values. The dental chart replaces its segmented dentition
control with a full-width selector on phones while retaining the faster control
on tablet and desktop. Treatment-plan, visit, and patient-file dialogs received
the same overflow-safe selector behavior. Existing clinical-session and
patient-file mobile/RTL permission tests remain green, with a new 320-pixel,
200%-text Arabic dental-chart test. All three catalogs contain 594 matching
keys; static analysis is clean and the full suite passes with 129 active tests
and 6 intentionally skipped local-service tests.

Step 6 is complete. Billing and audit selectors now use the full available
width for long localized values. Invoice item totals moved into the readable
item description so narrow screens retain the action menu without crowding.
Billing and staff confirmation forms are scrollable at large text sizes,
including financial, payment, credit, correction, invitation, role, and owner
reauthentication dialogs. Existing monetary precision, owner safeguards, role
filtering, and audit chronology are unchanged. Static analysis is clean and the
full suite passes with 129 active tests and 6 intentionally skipped
local-service tests.

Step 7 is complete. The responsive test matrix now exercises the exact 599,
600, 1024, and 1025-pixel shell transitions, contextual route selection, and
Owner, Dentist, Assistant, and Receptionist destination visibility. Settings is
tested in Arabic at 320 pixels and 200% text while persisting a theme change and
dispatching the privacy lock. Existing authentication, dashboard, patient,
appointment, clinical-session, patient-file, dental-chart, and audit RTL tests
remain green. Static analysis is clean and the full suite passes with 134
active tests and 6 intentionally skipped local-service tests.

Step 8 is complete. The opt-in local MVP workflow uses the production Auth,
session, clinic, staff, and protected Edge Function boundaries against local
Supabase and Mailpit. A fictional Owner verifies and unlocks an account, creates
a clinic, gains Dentist capability, and sends a one-time Receptionist
invitation. The accepted Receptionist creates a fictional patient and
appointment and records payment; the Dentist maintains the schedule, medical
profile, odontogram, treatment plan, clinical session, and clinical invoice
content; the Owner finalizes the invoice and reads the dashboard and audit log.
The same test proves invitation reuse, Receptionist medical editing, and
Receptionist audit access are denied. The complete workflow passes locally.

Step 9 is complete. Localization and generated dependency output reproduce
without drift, all 203 Dart files are formatted, static analysis reports no
issues, and the Flutter suite passes with 134 active tests plus 7 intentionally
opt-in local-service tests. The authenticated fictional MVP workflow passes
against local Supabase and Mailpit. All 13 database suites pass with 325 pgTAP
checks. Three older SQL fixtures were scoped to their fixed clinic and patient
IDs so the suites remain deterministic when the local database already holds
legitimate demo records. The configured Flutter Web build and its Wasm
compatibility dry run both succeed; the reviewable artifact is in `build/web`.

## Information architecture

### Primary destinations

The shell derives visible destinations from the active clinic membership. This
is a presentation convenience only; route guards and server authorization still
protect every operation.

| Destination | Route | Visibility |
| --- | --- | --- |
| Dashboard | `/dashboard` | Every active member; metrics remain role-filtered |
| Patients | `/patients` | Every active member; clinical links remain permission-aware |
| Appointments | `/appointments` | Every active member with existing action restrictions |
| Schedule | `/schedule` | Roles already allowed by the schedule feature |
| Treatments | `/procedures` | Roles already allowed by the treatment feature |
| Billing | `/billing` | Roles already allowed by the billing feature |
| Staff | `/staff` | Owner only |
| Audit | `/audit` | Owner only |
| Settings | `/settings` | Every active member |

Patient medical, odontogram, treatment-plan, visit, file, and patient-billing
routes are contextual child screens. The shell highlights Patients while these
screens are open. Appointment creation highlights Appointments.

### Responsive navigation

- **Mobile, below 600:** a four-item bottom bar contains Dashboard, Patients,
  Appointments, and More. More opens a full-height modal sheet with the allowed
  secondary destinations, current clinic, clinic switch, settings, privacy
  lock, and sign out. Detail and form routes keep the bar visible unless the
  keyboard would make it unsafe; dialogs and sheets use safe-area insets.
- **Tablet, 600–1024:** a compact `NavigationRail` shows icons and tooltips.
  Secondary destinations remain in the rail and scroll when height is limited.
  The current clinic and account actions appear in a rail footer/menu.
- **Desktop, above 1024:** a 256-pixel labeled sidebar groups Workspace,
  Clinical Operations, and Administration destinations. It shows the clinic
  name, active role summary, theme/language access, lock, and account menu.
  Content is centered with a screen-specific maximum width.

Navigation order mirrors reading direction automatically. Arabic keeps logical
leading/trailing placement; icons that communicate direction are mirrored.

## Shell architecture

`GoRouter` gains a signed-in `ShellRoute` for clinic workspace routes. Clinic
gate, clinic creation/selection, authentication, account recovery, and invitation
acceptance stay outside the shell. `WorkspaceShell` receives the routed child
and renders the correct navigation for the current width.

The shell reads roles from `ClinicCubit.state.activeMembership`; it does not
load staff data or duplicate permission rules. A small immutable destination
catalog maps routes, localization keys, icons, and existing role capabilities.
Unknown or forbidden destinations remain hidden and direct URLs retain their
existing safe server/feature denial.

Existing pages keep their Cubits and business behavior. Their root scaffolds are
adapted to cooperate with the shell through a shared `WorkspacePage` container,
which provides title, leading action, page actions, scrolling policy, maximum
width, loading/empty/error state placement, and optional bottom action area.

## Settings screen

The new Settings screen is client-only and uses existing services:

- appearance: System/Light/Dark;
- language: System/English/Russian/Arabic;
- active clinic summary and switch-clinic action;
- privacy: Lock now;
- account: verified email display and Sign out;
- application information: local MVP status and version without internal
  endpoints, keys, identifiers, or diagnostic content.

Settings stores only the existing non-sensitive appearance and active-clinic
preferences. It does not expose medical data, session tokens, password changes,
staff permissions, or new backend settings.

## Visual system

The current Material 3 teal identity remains the base:

- primary teal `#006D77`;
- supporting cyan `#0E7C86`;
- light background `#F6FAFA` and surface `#FFFFFF`;
- dark background `#0D191B` and surface `#142326`;
- success `#2E7D5B`, warning `#A56700`, error `#BA1A1A`;
- text and container colors are generated as semantic light/dark color roles,
  never used as raw status meaning without a label or icon.

Typography uses the platform-safe Material text scale with a clear hierarchy:
32/40 display, 24/32 page title, 20/28 section title, 16/24 body, and 14/20
supporting text. The implementation does not bundle a new font during this
free-tier phase. Layout tokens standardize 4, 8, 12, 16, 24, 32, and 40-pixel
spacing, 12-pixel control radii, and 16-pixel card radii.

Cards, filters, dialogs, forms, badges, tables, date/time controls, and action
bars use shared tokens. Destructive actions require clear labels and the
existing confirmation rules. Clinical and financial statuses always combine
text, icon, and color.

## Screen behavior

### Authentication and clinic gate

Authentication remains a focused single-column card, capped near 480 pixels.
On wide screens it sits beside a quiet brand panel with no patient data. On
mobile it becomes one safe-area column. Clinic selection uses cards on mobile
and a compact list/grid on wider screens. All restoration, verification,
recovery, privacy-lock, loading, and failure states receive complete Arabic
copy.

### Dashboard

Desktop uses a responsive metric grid and two-column appointment sections.
Tablet uses two columns; mobile uses one. Quick actions become horizontally
wrapping buttons and then full-width actions at narrow sizes. Restricted metric
groups remain absent rather than disabled.

### Patients and patient profile

Desktop/tablet show a sortable data table or wide list with fixed search/filter
controls. Mobile uses accessible patient cards with the same information and
actions. The new-patient form uses two columns only when each field retains a
usable width; otherwise it is one column. The patient profile uses a stable
summary header and responsive feature cards for Medical, Appointments,
Odontogram, Treatment Plans, Visits, Files, and Billing.

### Appointment calendar and form

Desktop keeps the week calendar with sticky day/time context. Tablet uses a
compressed week or day switch when cells become too narrow. Mobile defaults to
an agenda/day list with previous/today/next controls. The appointment form uses
one column on mobile and grouped two-column date/time fields on wider screens.
Conflict and Owner-override messages remain visible near the affected fields.

### Doctor schedule

Desktop displays schedule versions, weekly hours, exceptions, and appointment
impact review side by side where safe. Tablet stacks related panels in two
columns. Mobile uses cards and bottom sheets for editing. Time ranges never
depend on color alone and remain in clinic timezone.

### Dental chart, treatment plans, and clinical sessions

The odontogram may scroll within its own labeled region on narrow screens; the
whole page must not overflow horizontally. Primary/permanent switches and tooth
actions remain reachable with large text. Treatment-plan master/detail panels
become stacked cards on mobile. Clinical session sections use a step-like
vertical flow on mobile while preserving draft/finalized/amendment rules.

### Patient files

Desktop/tablet retain list/detail presentation. Mobile shows metadata cards and
a full-width preview/action flow. Upload progress, signature failures, archive
state, and permission denial remain explicit. No filename or patient detail is
placed in global navigation or analytics.

### Billing and invoices

Desktop uses invoice list/detail columns. Tablet collapses the detail column
when needed. Mobile uses invoice cards followed by a dedicated detail route or
panel. Monetary columns preserve decimal alignment in left-to-right and Arabic
layouts. Owner password confirmation for reversals stays a focused modal.

### Staff, audit, and settings

Staff tables become member and invitation cards below 600 pixels. Audit filters
use a collapsible mobile panel while results remain chronological cards.
Settings uses grouped cards and platform-native selection controls. Owner-only
destinations are not discoverable in navigation for other roles.

## Localization and RTL

- Add Arabic values for all 68 missing keys.
- Add localization keys for every remaining user-facing literal found in
  appointment, patient, schedule, staff, odontogram, procedure, treatment-plan,
  and related page widgets.
- Keep technical values such as UUIDs, currency codes, FDI tooth numbers, and
  clinic timezone identifiers in directionally isolated spans.
- Use locale-aware dates, times, plurals, and money labels while retaining the
  server's exact decimal values.
- Add an automated ARB parity test so English, Russian, and Arabic cannot lose a
  key without failing CI.

## Accessibility and interaction

- Support 320 logical pixels and 200% text scaling without page-level horizontal
  overflow.
- Maintain at least 48-by-48 logical-pixel touch targets.
- Preserve visible keyboard focus, logical tab order, Escape/back behavior,
  tooltips, and semantic labels for icon-only controls.
- Meet WCAG AA contrast for normal text and controls in light and dark themes.
- Announce loading, success, validation, and failure states without exposing
  provider errors or patient content.
- Keep primary actions reachable above the software keyboard and safe areas.

## Testing strategy

### Static and widget tests

- ARB key parity and no user-facing hardcoded-string regression checks;
- workspace destination selection and route highlighting;
- role-aware navigation for Owner, Dentist, Assistant, and Receptionist;
- 320, 599, 600, 1024, and 1440-pixel layouts at normal and 200% text scale;
- English, long Russian text, and Arabic RTL for every top-level screen;
- light/dark contrast-sensitive components, keyboard traversal, semantics, and
  no uncaught layout exceptions;
- table-to-card, calendar-to-agenda, master/detail-to-stack behavior;
- settings language/theme persistence, clinic switch, privacy lock, and signout.

### Local integration tests

One fictional end-to-end workflow covers the Master Specification success path:

1. Owner registers, verifies email, unlocks, and creates a clinic.
2. Owner gains Dentist capability using the protected existing workflow.
3. Owner invites a Receptionist; the invitation is accepted once.
4. Receptionist creates a fictional patient and appointment.
5. Dentist opens the schedule and patient medical information, updates the
   odontogram, creates a treatment plan, and finalizes a clinical session.
6. Receptionist records payment and reads the approved invoice.
7. Owner reads the dashboard and audit log.
8. Cross-clinic, hidden-navigation, expired proof, locked session, and raw Data
   API bypass attempts remain denied.

The test uses local Supabase and Mailpit only. It never commits credentials,
logs clinical content, or writes real patient information.

## Planned file structure

```text
lib/
  app/
    router/app_router.dart
    shell/
      workspace_destination.dart
      workspace_shell.dart
    theme/
      app_theme.dart
      app_tokens.dart
    localization/arb/app_en.arb
    localization/arb/app_ru.arb
    localization/arb/app_ar.arb
  core/widgets/
    workspace_page.dart
    responsive_record_view.dart
    responsive_state_panel.dart
  features/
    settings/presentation/pages/settings_page.dart
    */presentation/pages/*.dart
test/
  app/workspace_shell_test.dart
  app/localization_parity_test.dart
  app/responsive_workspace_test.dart
  settings/settings_page_test.dart
  */*_page_test.dart
test/local/
  mvp_workflow_integration_test.dart
docs/
  PHASE_15_RESPONSIVE_POLISH_ARCHITECTURE.md
  README/architecture/security/readiness documents as applicable
```

Files are split when page modules become too large; business Cubits,
repositories, Edge Functions, and database migrations are unchanged unless a
test exposes an actual defect in approved behavior.

## Reviewable implementation steps

1. Add localization parity tests, translate missing Arabic keys, and migrate
   all remaining user-facing literals to generated localization.
2. Add shared breakpoints, layout tokens, workspace page primitives, and
   accessibility foundations.
3. Implement the role-aware adaptive shell and Settings screen, then update
   routing without changing authorization behavior.
4. Polish authentication, clinic, dashboard, patient, and appointment flows.
5. Polish schedule, odontogram, treatment plans, clinical sessions, and files.
6. Polish billing, staff, audit, empty/loading/error states, and dialogs.
7. Add breakpoint, text-scale, RTL, keyboard, semantics, and role-navigation
   widget tests.
8. Add and run the fictional local MVP integration workflow.
9. Update project documentation and run every completion gate.

After each step, implementation results and the next step will be reported for
review.

## Completion gates

```text
flutter gen-l10n
dart run build_runner build
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase test db
authenticated local MVP integration test
flutter build web --dart-define-from-file=config/local.json
```

Phase 15 is complete only when all three ARB catalogs have matching message
keys, no known user-facing strings are hardcoded in widgets, every top-level
screen passes representative responsive/RTL tests, the fictional MVP workflow
passes, the web build succeeds, and no Phase 16 or production deployment work
has begun.

## Risks and trade-offs

- Converting independent pages to one shell touches many presentation files.
  Small shared primitives and route-focused tests reduce regression risk.
- A week calendar cannot remain readable at phone width. The mobile agenda view
  preserves the same appointments and actions with a different presentation.
- Full Arabic translation requires domain terminology review by a fluent dental
  professional before real clinical use. Phase 15 provides complete functional
  Arabic copy, but does not replace that later legal/clinical language review.
- A single full UI integration test can be slower and more fragile than focused
  tests. Domain and widget tests remain the primary diagnostics; the full flow
  verifies wiring and boundaries.
- The absent Git repository limits change history and review. Initializing Git
  is operational work and requires a separate explicit decision.
