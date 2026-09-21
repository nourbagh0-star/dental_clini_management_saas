# Owner-created staff accounts

Approved workflow: an owner supplies email, roles, and a temporary password;
staff must replace it before clinic access. No email is sent. This is owner
attestation of the account, not proof that the employee controls the mailbox.

Only the backend calls Supabase Auth admin createUser. It never updates an
existing account. The owner must re-enter their own password. An Auth insert/update
trigger handles Supabase's admin-metadata write and atomically creates membership, roles, an audit entry, and private setup
state; failure rolls back account creation. The setup state is not client-writable.
Passwords are absent from application logs, events, and persisted Flutter state.

Server session gates reject all clinic access while setup is pending. After a
Supabase password update, a service-only completion command verifies that the
stored password hash changed, records completion, and invalidates all sessions
created before completion through the existing live-session check. Staff sign
in again. A refresh or direct API call cannot bypass this gate. Setup completion
does not need SMTP. Existing signup and recovery email limits remain unchanged.

UI: Staff → Create staff account → email, temporary password, roles → owner's
password confirmation → success notice. First sign-in → mandatory new password
and confirmation → sign-in. English, Russian, and Arabic are required.

The user intends real use in Syria. This feature is not a production readiness
approval; provider eligibility, privacy/legal requirements, backup and recovery,
credential rotation, and production acceptance remain unresolved.

Validation: local PostgreSQL setup/authorization checks and all 32 existing
security-session assertions pass. Real local Auth integration verifies owner
reauthentication, duplicate-account rejection, role assignment, no clinic access
before password replacement, rejection of the old password, and fresh-session
access after completion. Both local staff integration tests passed. Final checks:
`dart format` unchanged, `flutter analyze` clean, `flutter test` 151 passed
(8 opt-in tests skipped in the default run), release Web build successful,
and local Supabase security advisor reported no issues.

Hosted deployment was explicitly approved and completed on 2026-09-17 UTC.
Direct database connections failed, so the tested migration and its history
entry were applied atomically through the CLI query API. Hosted verification
confirmed the migration entry, enabled provisioning trigger, private table RLS,
and no authenticated execute grant on the setup-completion function. Both
`security-session` and `staff-invitations` were deployed before the Web release.
No existing account password is changed by the migration. Provisioned accounts must complete setup even if
they use an old app version or call protected APIs directly.

Hosted security advisor returned two warnings outside this migration: the
existing `doctor_schedule_readable_dentists` SECURITY DEFINER function is
callable by authenticated users, and leaked-password protection is disabled.
These remain part of the production-readiness review; this release does not
approve use with real patient records.
