# Phase 3 — Roles, staff, and invitations

Status: Steps 1–3 implemented and locally verified; Steps 4–5 await implementation. Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 10–19, 59–65, 76–77, and 80. Approved decisions: password confirmation for OWNER changes, one-time email links, and verified email only in the staff directory.

## Scope

Phase 3 introduces multi-role staff membership, staff lifecycle management, and invitations. It does not introduce patients, doctor schedules, appointments, clinical data, billing, a general audit-log UI, paid services, or real patient data.

## Approved behavior

- A staff member may have any combination of OWNER, DENTIST, ASSISTANT, and RECEPTIONIST roles in a clinic.
- Owners can invite staff, edit roles, revoke/resend invitations, and deactivate/reactivate staff. There is no normal hard deletion.
- A clinic must retain at least one active owner. Database triggers enforce this when an owner role is removed or an owner is deactivated/deleted.
- Adding, removing, or deactivating an OWNER requires the acting owner to re-enter their password. Step 2 performs that verification inside a protected Edge Function and completes the sensitive mutation in the same server request.
- Invitations expire after seven days, can be resent or revoked, and use a random one-time token. Only a hash is stored.
- A recipient must sign in or register with the exact invited verified email, then explicitly accept. Existing active staff cannot receive a duplicate invitation; an inactive membership is reactivated only through the accepted invitation workflow.
- Local development sends the business invitation link through Mailpit using a protected Edge Function. A production mail sender later implements the same server-side delivery interface.

## Data model

```text
clinics
  └─ clinic_members
       ├─ user_id, verified-email snapshot, active/deactivation state
       └─ clinic_member_roles
            └─ owner | dentist | assistant | receptionist

clinic_invitations
  ├─ clinic_id, normalized email, token digest, status, seven-day expiry
  ├─ created/resend/revoke/acceptance metadata
  └─ clinic_invitation_roles
```

The Phase 2 single `ownership` marker is migrated into `clinic_member_roles` and removed. Future clinic creation still creates the creator membership and assigns its OWNER role atomically.

## Authorization design

All public tables have RLS. Anonymous callers have no grants. An active staff member can read only their own membership and roles; an active owner can read the full staff directory and invitations for their active clinic. Neither Flutter nor ordinary authenticated clients can directly mutate memberships, roles, invitations, or invitation roles.

Private, fixed-search-path security-definer helpers support RLS without recursive policy queries. The last-owner guard is also a private fixed-search-path trigger, so it applies even to future server workflows with elevated access. Public clients receive no privileged function endpoint.

Step 2 uses an authenticated Edge Function for all staff mutations. The function validates the bearer token with Supabase Auth, rechecks current OWNER membership in the database command, verifies the owner password for sensitive OWNER changes, and then calls an atomic database operation. Server secrets remain in function configuration only. Its temporary password-verification session is revoked locally, preserving the caller's existing session.

The browser calls `POST /functions/v1/staff-invitations` with one of these actions: `create`, `resend`, `revoke`, `accept`, `replace_roles`, or `set_active`. For invitation links, the function accepts only a configured public app origin in hosted environments and local `localhost`/`127.0.0.1` origins during development. It returns stable, non-sensitive error codes and never returns an invitation secret.

The raw invitation token is created with `crypto.getRandomValues`, SHA-256 hashed before database storage, and delivered only in the email link fragment. The database command functions are executable only by `service_role`; ordinary browser clients retain no mutation route. The service role receives only the server-side reads needed for role confirmation and resend addressing.

Local delivery uses the existing Supabase Inbucket/Mailpit container over the internal Docker network (`inbucket:1025`). Hosted deployment must explicitly configure `DENTAFLOW_INVITATION_SMTP_HOST`, `DENTAFLOW_INVITATION_SMTP_PORT`, and `DENTAFLOW_PUBLIC_ORIGIN`; no production mail provider has been selected.

## Flutter data layer

Step 3 adds immutable `StaffMember`, `StaffInvitation`, and invitation-delivery domain models. `StaffRepository` owns local validation and translates data-source rows into those models. It validates UUIDs, normalized email addresses, non-empty role sets, one-time invitation token format, and a path-free public app origin before any network call.

`SupabaseStaffDataSource` reads the RLS-protected staff directory and invitation list through the regular Supabase client. It sends all mutations through the existing authenticated `DioClient`, which is restricted to the Supabase Edge Function origin and path. Safe server codes become typed staff outcomes: owner reauthentication required, invitation unavailable, and staff member unavailable. Provider error bodies, passwords, tokens, and invitation-link contents are not retained or logged.

The public app origin is an explicit `Uri` input for create and resend. The Step 4 routing layer will provide it from the active Web address; the Edge Function remains the final server-side allowlist check. This avoids guessing a route or accepting an arbitrary link destination in the repository.

## Link handling

The invitation email links to the Flutter acceptance route with the one-time secret in the URL fragment. The app reads it, removes the fragment from the address bar, holds it only in memory, and never consumes it until the matching signed-in user selects Accept. A mail scanner or accidental page visit therefore cannot accept an invitation. A refresh can use the original unconsumed email link again.

## Implementation steps

1. **Complete:** migrate Phase 2 owners to reusable roles; add staff/invitation schema, RLS read boundaries, last-owner database protection, and pgTAP authorization tests.
2. **Complete:** create the protected `staff-invitations` Edge Function for invitation creation, resend, revoke, acceptance, role changes, and activation changes; add the local Mailpit sender and full fictional-data lifecycle test.
3. **Complete:** add staff domain models, validation, repository interface, Supabase data adapter, typed outcomes, generated dependency registrations, and unit/local integration coverage.
4. Add invitation-aware routing plus localized, responsive staff and acceptance screens.
5. Add unit/widget/local Supabase-and-Mailpit integration tests; run Flutter and database validation plus a Web build.

## Verification through Step 2

- `supabase migration up`: passed locally.
- `supabase test db`: passed, 41 pgTAP tests across the existing clinic suite and the roles/invitations suite.
- `supabase db lint --local --fail-on error`: passed.
- `supabase db advisors --local --type security --fail-on error`: passed with no findings.
- `dart format .`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 57 tests with 3 opt-in local-service tests skipped by default.
- `flutter test test/local/staff_invitations_integration_test.dart --dart-define-from-file=config/local.json --dart-define=RUN_LOCAL_STAFF=true`: passed against local Supabase and Mailpit. It verifies delivery, resend rotation, revoke, mismatched-email rejection, one-time acceptance, role replacement, activation changes, and password confirmation without invalidating the owner's existing session.
- Staff repository and adapter unit tests: passed. They verify row mapping, local validation before network calls, protected Function request shape, and safe typed server outcomes.
- The local staff lifecycle test also reads the actual staff directory and invitation list through the new repository, validating its nested RLS query shape.

## Risks and limits

Mailpit delivers only to the local development environment. It cannot deliver invitations to a real remote employee; the future production sender remains a deliberate production-readiness decision. Password confirmation strengthens owner actions but is not MFA. The planned Phase 13 general audit-log UI remains outside this phase; Step 2 must preserve sufficient staff-operation metadata for the later audit feature.
