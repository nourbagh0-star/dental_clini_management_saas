# Phase 8 — Treatment Plans Architecture

Status: implemented and locally verified.

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 37–39.

## Approved product decisions

- A patient may have one active treatment plan at a time. Older completed and
  cancelled plans remain available as history; a dentist must complete or
  cancel the current active plan before activating another one.
- Every item must reference an active procedure from the clinic's catalogue.
  This keeps procedure names, default prices, and duration estimates
  consistent.
- A dentist may adjust an individual item's estimated price from the catalogue
  default. The item preserves its own price snapshot, so later catalogue-price
  changes never rewrite an existing plan.
- Owners, assistants, and receptionists may view treatment plans. Only dentists
  make clinical plan decisions or change a plan. Owners alone manage the
  procedure catalogue and its default prices.

## Goal and scope

This phase adds the clinic procedure catalogue and patient treatment plans. An
Owner configures reusable procedures and their default prices. A Dentist creates
a draft plan for an active patient, adds clinically appropriate catalogue items,
sets tooth references and estimates, orders the work, activates the plan, and
tracks its progress.

The phase does not issue invoices, take payments, attach files, create clinical
session notes, automatically complete treatment from appointments, or generate
PDF documents. Those remain later phases.

## Data model

```text
procedures
  id uuid
  clinic_id uuid
  name text
  category text
  default_price numeric(12,2)
  duration_minutes smallint
  active boolean
  created_at / updated_at

treatment_plans
  id uuid
  clinic_id uuid
  patient_id uuid
  dentist_member_id uuid
  status treatment_plan_status       -- draft | active | completed | cancelled
  notes text nullable
  total_estimated_cost numeric(12,2) -- derived from items by server command
  created_at / updated_at

treatment_plan_items
  id uuid
  clinic_id uuid
  treatment_plan_id uuid
  procedure_id uuid
  tooth_number smallint nullable     -- FDI permanent or primary number
  description text nullable
  estimated_price numeric(12,2)      -- immutable catalogue-price snapshot or dentist estimate
  status treatment_plan_item_status  -- planned | approved | in_progress | completed | cancelled
  assigned_dentist_id uuid nullable
  sort_order integer
  created_at / updated_at
```

All money values are non-negative decimal amounts. Currency is read from the
clinic configuration and displayed alongside totals; an individual plan does
not convert currencies. `numeric(12,2)` prevents floating-point rounding
errors and supports the current RUB pilot plus future supported currencies.

Each table includes `clinic_id` and uses `ON DELETE RESTRICT` for historical
references. A database trigger confirms that a procedure belongs to its clinic,
an item belongs to the same clinic as its plan, and an assigned dentist belongs
to that plan's clinic with the Dentist role.

## Catalogue behaviour

An Owner may create, edit, activate, and deactivate procedures. Deactivating a
procedure preserves it and all historical plan items; it only prevents new plan
items from using it. Procedures cannot be hard-deleted once referenced by a
treatment plan.

Names are unique within a clinic after case-insensitive normalization. The
initial UI provides categories such as Consultation, Cleaning, Restoration,
Endodontics, Extraction, Crown, Implant, and Whitening. Category remains a
plain validated label in this phase so a clinic is not blocked by a fixed list.

## Plan and item rules

Only a Dentist may create, edit, activate, complete, cancel, or add and change
items in a plan. A plan must contain at least one non-cancelled item before the
Dentist can activate it.

Plan transitions are:

```text
draft  -> active | cancelled
active -> completed | cancelled
```

Completed and cancelled plans are historical and cannot be changed. A second
active plan for the same patient is blocked by a partial unique database index,
which also prevents concurrent requests from creating conflicting active plans.

Item transitions are:

```text
planned -> approved | in_progress | cancelled
approved -> in_progress | cancelled
in_progress -> completed | cancelled
```

Completed and cancelled items are terminal. In Phase 8, the Dentist records
these transitions manually. Phase 9 may later link completed treatment to a
finalized clinical session without weakening these server-side rules.

An item can optionally reference one validated FDI tooth number. The same
permanent and primary dentition values used by the Dental Chart are valid. A
procedure without a tooth reference, such as cleaning or consultation, remains
supported.

The plan total is calculated by the protected server command from non-cancelled
item estimates. Flutter never supplies or independently calculates the stored
total. This prevents a stale or manipulated browser value from becoming an
official estimate.

## Price snapshots and amendments

When a Dentist adds an item, the server copies the active procedure's current
default price into `estimated_price`. The Dentist may set a different
non-negative price for that item at creation or while the plan is a draft. That
price belongs to the plan item and is never modified when the Owner later
changes the catalogue price.

This phase keeps item content editable while its plan remains a draft. Once a
plan is active, its procedure, tooth, description, estimate, assignment, and
order become fixed. The Dentist may still progress item status or cancel an
item. A future plan amendment model can add a formal clinical change history if
the pilot requires changes to active plans.

## Access control and security boundary

| Role | Procedure catalogue | Treatment-plan read | Treatment-plan clinical changes |
| --- | --- | --- | --- |
| Owner | Manage | Yes | No |
| Dentist | Read | Yes | Yes |
| Assistant | Read | Yes | No |
| Receptionist | Read active procedures | Yes | No |

Row Level Security isolates all records by active clinic membership. Browser
clients receive RLS-protected reads only. They receive no direct insert, update,
or delete privileges for procedures, plans, or items.

An authenticated `treatment-plans` Supabase Edge Function validates requests
and uses service-role-only PostgreSQL commands. Every command verifies the
caller's current membership and role, the clinic relationship of every record,
patient availability, procedure activity, FDI values, status transitions, and
total recalculation inside a transaction. The service-role key remains only in
the Edge Runtime environment.

## API boundary

The RLS-protected reads are:

```text
procedures by clinic, including active filter
plans by patient, ordered by current and most recently updated
plan items by plan, ordered by sort_order
```

The protected Edge Function exposes:

```text
create_procedure
update_procedure
set_procedure_active

create_plan
update_draft_plan
transition_plan
add_plan_item
update_draft_plan_item
transition_plan_item
reorder_draft_plan_items
```

All expected failures map to safe typed outcomes: unavailable patient,
unavailable procedure, inactive procedure, invalid FDI tooth, duplicate active
plan, invalid state transition, draft-only edit, invalid price, and insufficient
role. Raw database details and cross-clinic record information never reach the
app.

## Flutter UX and navigation

The Patient Profile gains a **Treatment Plans** action. It opens a patient
scoped page with:

1. A current-plan card showing status, assigned dentist, item count, total, and
   direct clinical status updates for Dentists.
2. A draft-plan editor for Dentists: plan notes, catalogue procedure picker,
   optional FDI tooth picker, description, item estimate, assigned dentist, and
   item order controls.
3. An item timeline showing status, procedure, tooth, estimate, and assigned
   dentist. View-only staff see the same safe plan summary without edit
   controls.
4. A history section for completed and cancelled plans.

The clinic area gains a **Procedure Catalogue** page. Owners see create, edit,
price, duration, active/inactive controls, and a filtered table. Other clinic
staff see the active catalogue as read-only.

On tablet and web, the current plan, item list, and order/summary panel form a
two-column workspace. On phones, summary, item list, and item editor stack
vertically; item creation opens a full-screen sheet. Totals and status labels
always accompany colour so the interface remains accessible.

The Flutter feature follows the existing clean boundaries:

```text
features/treatment_plan/
  domain/         procedure and plan models, repository contracts, typed failures
  data/           Supabase RLS read source, Edge mutation source, repositories
  presentation/   catalogue and plan cubits, pages, sheets, widgets
```

## Performance and lifecycle

Database indexes support catalogue reads by clinic and active state, patient
plan history by clinic/patient/update time, active-plan lookup by patient, and
plan-item display by plan/sort order. Plan history is paginated. The patient
page loads only the current plan and its items before requesting older history.

## Implementation sequence

1. Add database types, tables, tenant checks, indexes, RLS, and protected
   PostgreSQL commands with pgTAP coverage.
2. Add the authenticated `treatment-plans` Edge Function and its request
   validation.
3. Add Flutter domain/data layers, dependency injection, and focused tests.
4. Add the Procedure Catalogue, Patient Profile treatment-plan navigation,
   plan editor, item states, totals, history, and responsive layouts.
5. Run formatting, analysis, Flutter tests, database tests, lint, security
   advisors, Edge smoke test, and Flutter web build. Fix every failure.

## Completion criteria

Phase 8 is complete when each clinic has an Owner-managed procedure catalogue,
Dentists can safely manage one active plan per patient, staff see only the
access allowed for their role, price snapshots and clinical history remain
meaningful, and the full verification suite passes.

## Verification result

Completed on 2026-09-09 with fictional local development data only.

- `dart format .`: 126 files formatted; no changes required.
- `flutter analyze`: no issues found.
- `flutter test`: 68 tests passed and 3 environment-dependent tests skipped.
- `supabase test db --local`: 7 files and 156 pgTAP checks passed.
- `supabase db lint --local --level warning --fail-on error`: no errors.
  The reported warnings belong to earlier appointment and schedule functions;
  Phase 8 introduced no database lint warning.
- The `treatment-plans` Edge Function loaded in the local Supabase Edge Runtime.
- `flutter build web --dart-define-from-file=config/local.json`: completed and
  produced `build/web`.

The completion migration was applied with `supabase migration up --local`, so
existing local accounts and demo patients were preserved.
