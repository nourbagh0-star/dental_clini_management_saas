# Phase 2 — Clinic creation and multi-tenancy plan

Status: implemented and locally verified. Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 10, 17, 19, 44, 62, 76, 80, and 85. Phase 3 roles, staff management, and invitations are explicitly excluded.

## Repository review

Phase 1 provides authenticated identities, a locked session boundary, GoRouter guards, safe storage, a local Supabase project, and real local Auth integration tests. There are no business tables, migrations, demo clinics, roles, staff records, or tenant-aware Flutter features. Local Supabase uses `api.auto_expose_new_tables = false`, which supports an explicit-grant RLS model.

## Scope

An authenticated user may create a clinic deliberately. Creation atomically gives that user the clinic's sole initial active owner membership. The application then selects that clinic automatically. A user with more than one active clinic sees a selector and may change the non-sensitive active-clinic preference. A clinic with no active membership leads to a neutral no-access page.

Phase 2 does not implement employee invitations, staff-management screens, role assignment, clinic settings editing, patient data, or mock dashboards. Existing owners, dentists, assistants, and receptionists cannot be created through the UI in this phase. The owner membership is the minimal bootstrap ownership fact required by the master; generalized role relations are Phase 3.

## Data design

```text
auth.users
   │ creator / member
   ├─────────────── public.clinics
   │                   id UUID
   │                   name
   │                   currency_code
   │                   time_zone
   │                   created_by, created_at, updated_at
   │
   └─────────────── public.clinic_members
                       clinic_id + user_id (unique membership)
                       ownership = owner
                       is_active
                       created_at, updated_at
```

`clinics` uses a UUID primary key. `clinic_members` has a surrogate UUID primary key and a unique `(clinic_id, user_id)` constraint, which permits future invitations, deactivation history, and role relations without using email as identity. The initial `ownership` enum has only `owner`; Phase 3 replaces it with the multi-role relation required by the master and migrates this fact without changing clinic IDs or memberships.

The minimal proposed create form stores a clinic name, ISO 4217 currency, and IANA time zone. It deliberately excludes address, phone, legal entity, tax, and branding details because their requirements have not been defined and belong to clinic settings later.

## Server enforcement

The implemented migrations:

1. Create the two tables, timestamp trigger, constraints, indexes, and a private trigger function.
2. Create an `AFTER INSERT` trigger on `clinics` that inserts exactly one owner membership for `created_by`. The trigger function lives outside exposed schemas, uses a fixed search path, and has no `PUBLIC` execute grant.
3. Enable RLS and revoke all client grants before granting only needed operations to `authenticated`.
4. Permit a signed-in user to insert a clinic only where `created_by = auth.uid()`.
5. Permit a member to select only their own membership and an active-member clinic; the verified creator can also read its own created clinic so the immediate create response is available.
6. Prohibit direct client insert/update/delete on `clinic_members`; Phase 3 adds privileged invitation/role workflows with explicit server checks.
7. Prohibit anonymous access and direct clinic deletion in this phase.

The trigger and insert policy make clinic creation transactional: either both clinic and initial owner membership commit, or neither does. No Flutter code can manufacture a membership for another user. RLS tests use separate authenticated JWT claims to prove that a second user cannot read, create memberships in, modify, or select another clinic.

## Flutter architecture and screens

`features/clinic/domain` contains `Clinic`, `ClinicMembership`, a clinic state, and repository contract. `data` maps Supabase rows to those entities. `presentation` contains a Cubit for loading/creating/selecting clinics and three small screens:

| Screen | Primary action | Result |
| --- | --- | --- |
| Create clinic | Submit name, currency, and time zone | Atomic clinic + owner membership, active clinic selected |
| Clinic selector | Select an active clinic | Active ID changes and future feature data is invalidated |
| No clinic access | Create a new clinic or sign out | No protected clinic route is shown without membership |

After authenticated startup and after unlock, a clinic gate loads memberships. One clinic routes to its neutral clinic-ready page; more than one routes to the selector; zero routes to create/no-access as appropriate. The active-clinic preference is scoped to the current user ID, held in memory during the session, and cleared on logout or account switching. It holds only a UUID, never medical records or roles.

## Implemented files

Create:

- `supabase/migrations/20260907145805_create_clinics_and_memberships.sql`, plus two follow-up migrations for server-derived creator and create responses.
- `supabase/tests/clinics_rls.test_test.sql`
- `lib/features/clinic/domain/{clinic_models,clinic_repository}.dart`
- `lib/features/clinic/data/{supabase_clinic_data_source,supabase_clinic_repository}.dart`
- `lib/features/clinic/presentation/{clinic_cubit,device_time_zone,pages/clinic_pages}.dart`
- `test/clinic/clinic_cubit_test.dart`
- `test/local/clinic_integration_test.dart` for the real local database flow.

Change:

- composition/DI, session lifecycle, router gate, app shell, localization ARBs, the active-clinic preference adapter, generated dependency wiring, `DATABASE.md`, and `PERMISSIONS.md`.

## Reviewable implementation sequence

1. Confirm the unresolved clinic-creation decisions below.
2. Generate the migration using Supabase CLI, implement the schema/RLS/trigger, and add pgTAP RLS tests.
3. Apply locally, run `supabase db lint`, `supabase db advisors`, `supabase test db`, and direct real-user isolation checks.
4. Implement domain/data boundaries and test DTO/error mapping.
5. Implement the clinic gate, active-clinic storage, selector, create form, routes, and responsive/localized UI.
6. Run local integration tests, generation, formatting, analysis, Flutter tests, and Web build. Fix every failure before calling Phase 2 complete.

## Approved decisions

1. **Time zone:** prefill the IANA time zone detected from the device, like the owner's phone; the owner may change it before submitting. The stored value is a clinic decision, not a live device setting.
2. **Clinic creation fields:** name, owner-selected currency with RUB preselected, and time zone are approved. Address, phone, legal entity, and branding wait for clinic settings.
3. **Multiple owner-created clinics:** approved. A user may create additional clinics from the selector in Phase 2.

## Risks and limits

The initial owner marker is deliberately limited to bootstrap ownership. Phase 3 must migrate to reusable multi-role membership records before any employee role UI exists. The privacy lock does not replace RLS. Application-level clinic filtering is usability only; all real isolation claims depend on the included policy tests. No production legal/data-residency conclusion follows from local demo validation.

## Implementation and verification

Implemented on 2026-09-07:

- Three ordered migrations create `clinics` and `clinic_members`, derive the creator from `auth.uid()`, and permit the creator to receive the immediate `INSERT ... RETURNING` response before the membership trigger is visible to a select policy.
- Every client-facing table has RLS enabled. Anonymous users receive no grants. Authenticated users can create only clinics whose server-derived creator is themselves, read only their own memberships, and read clinics that they created or actively belong to. Client mutation of memberships and clinic updates/deletes are not granted.
- The owner membership trigger uses a private, fixed-search-path security-definer function. It creates the first active owner in the same transaction as the clinic.
- Flutter now has separated clinic domain, data, and presentation layers. The gate loads RLS-filtered memberships; one clinic auto-selects, multiple clinics require selection, and no membership provides only creation or sign-out. The remembered clinic UUID is scoped to the signed-in user and is cleared on logout/account switch. A privacy lock keeps the same in-memory choice for the same user after unlock.
- The creation form uses the OS/browser IANA zone as an editable default through `flutter_timezone` 5.1.0. Currency is owner-selected with RUB preselected and USD/EUR available. Clinic name, currency, and time zone are database-validated.

Validation completed:

- `supabase migration up`: passed against the local development stack.
- `supabase test db`: passed, 18 pgTAP tests covering RLS, tenant isolation, direct mutation denial, anonymous denial, validation, atomic owner creation, and the client create-response path.
- `supabase db lint --local --fail-on error`: passed.
- `supabase db advisors --local --type security --fail-on error`: passed with no findings.
- `flutter test test/local/clinic_integration_test.dart --dart-define=RUN_LOCAL_CLINIC=true --dart-define-from-file=config/local.json`: passed using only fictional users, local Supabase, and Mailpit. It created two independent clinics and proved each user receives only its own membership-backed clinic list.
- Unit coverage exercises automatic selection, multi-clinic selection, creation, logout clearing, and safe failures.
- `dart format .`: passed with no pending changes.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 49 tests with 2 local-service tests skipped by default.
- `flutter build web --dart-define-from-file=config/local.json`: passed; the generated Web artifact is in `build/web`.
