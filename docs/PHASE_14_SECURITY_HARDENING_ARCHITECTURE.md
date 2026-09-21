# Phase 14 — Security Hardening and RLS Test Architecture

Status: approved and implemented on 2026-09-14.

Authority: [Master Specification](MASTER_SPECIFICATION.md), especially sections
7, 10–18, 45–47, 55–57, 59–65, 69, 75–80, and 83, plus the Phase 14 decisions
approved on 2026-09-14.

## Approved product decisions

- Every clinic business-data read moves behind authenticated Edge APIs.
- Direct Flutter/Data API reads of public business tables and views are removed.
- The ten-minute shared-device privacy lock gains a server-side, session-bound
  lease for business reads and writes.
- Sensitive Owner actions use a five-minute, single-use proof bound to the
  user, clinic, Auth session, action, target, and exact command input.
- Phase 14 includes a complete RLS, grant, Storage, session, proof, and Edge
  attack-test matrix.

## Goal

Phase 14 closes bypasses around the controls already implemented through Phase
13. A modified client holding a public key and user token must not be able to:

- query business tables or views directly;
- continue using clinic APIs after its Auth session is revoked;
- use clinic APIs after the server lock lease expires;
- renew an expired lock lease without verifying the same account password;
- reuse an Owner approval or apply it to another clinic, action, target, input,
  account, or session;
- reach another clinic, inactive membership, or unauthorized role;
- use Storage paths or signed-file authorization outside the approved scope;
- receive protected data when its required audit write fails.

This phase strengthens the development/demo system. It does not authorize real
patient data and does not claim production compliance.

## Threat model

### Protected assets

- patient demographics and medical information;
- odontogram, treatment, clinical-session, and file history;
- appointment and schedule information;
- staff identities, invitations, roles, and activation state;
- invoice, payment, credit, and financial-ledger information;
- clinic settings and audit history;
- short-lived file URLs and Owner action authority.

### Adversaries covered

- an anonymous caller with the project URL and publishable key;
- an authenticated user with no clinic membership;
- an inactive or removed clinic member with an unexpired access token;
- a member of Clinic A probing Clinic B identifiers;
- a valid member using a modified Flutter client or raw HTTP/Data API request;
- a role attempting an operation unavailable to that role;
- a person returning to an unattended, locked clinic workstation;
- replay, substitution, and race attempts against an Owner proof;
- malformed, oversized, stale, or duplicated requests.

### Boundaries not claimed

A stolen service/secret key, database administrator, compromised device while
it is actively unlocked, malicious browser extension, or compromised Supabase
platform is outside this application-layer boundary. A client activity signal
can be forged by code already controlling a valid unlocked session; the lease
protects unattended use and direct API bypass, not device compromise. Signed
URLs remain usable until their short expiry and downloaded files cannot be
recalled.

## Current findings

The current schema has strong tenant and role policies, protected mutation
functions, immutable clinical/financial/audit history, and 295 passing pgTAP
tests. However, the `authenticated` database role still has `SELECT` on 35
business tables/views, while Flutter directly reads patients, medical profiles,
appointments, schedules, staff, odontogram, treatment plans, clinical sessions,
files, and billing views.

Those reads are tenant-filtered by RLS, but a raw Data API client can avoid the
Phase 13 access-recording sequence and the Flutter privacy lock. Current Edge
Functions independently call Auth `getUser`, but they do not consistently
verify that the JWT `session_id` still exists in `auth.sessions`. Supabase
access tokens can remain valid until expiry after sign-out unless that database
session check is added.

Sensitive staff actions currently verify a password inside the same Edge
request when Owner authority is involved. Financial reversals and other future
security settings do not yet share an action-bound, single-use approval model.
Authentication, CORS, safe errors, and request validation are repeated across
functions, increasing drift risk.

## Target security boundary

```text
Flutter feature
  -> repository interface
  -> authenticated Dio Edge request
  -> shared Edge security gateway
       1. platform JWT verification
       2. verified user + session_id extraction
       3. live auth.sessions check
       4. active server lock-lease check
       5. strict origin/method/input limits
  -> service-only PostgreSQL command/query
       6. active membership + role + clinic checks
       7. query or mutation
       8. required audit/proof consumption in the same transaction
  -> typed bounded response
  -> strict data mapper
  -> Cubit/UI
```

Authentication proves the account. The live-session check proves that the
specific login has not been revoked. The lock lease protects an unattended
session. Clinic membership and roles authorize the business action. Owner
proofs authorize narrowly defined high-risk commands. Each layer has one job.

## Server session and lock lease

### Data model

Add a private `security_session_leases` table with:

- `session_id uuid primary key` matching the JWT `session_id`;
- `user_id uuid not null`;
- `unlocked_until timestamptz not null`;
- `last_renewed_at timestamptz not null`;
- `locked_at timestamptz`;
- `created_at` and `updated_at`;
- a bounded monotonically increasing revision for concurrent renew/lock calls.

The table is kept in the unexposed `private` schema. No `anon`, `authenticated`,
or `service_role` table privilege is granted. Only fixed-search-path security
functions owned by the migration owner can inspect or change it.

Every lease operation verifies that `(session_id, user_id)` still exists in
`auth.sessions`. A missing row means the session was signed out or revoked and
must fail as `authentication_required`. No client-supplied user or session ID
is accepted until the Edge gateway has cryptographically validated the JWT
claims.

### Unlock

A new authenticated `security-session` Edge Function accepts an `unlock`
operation and the same account password over POST. It verifies the password
through an isolated Supabase Auth client, confirms that the returned user ID is
the JWT user, signs out the temporary verification session locally, and opens
the original session lease for ten minutes. Passwords never enter PostgreSQL,
logs, state objects, URLs, analytics, or persistent storage.

A fresh interactive login may call unlock using the password already held by
the login form, then discard it. Restored sessions remain locked, matching the
approved refresh-only Web behavior. Registration/recovery sessions do not gain
a lease automatically.

### Renewal and expiry

Flutter sends a throttled `renew` request at most once per minute after real
pointer, keyboard, touch, or foreground interaction. Network traffic, token
refresh, timers, Realtime, polling, and background tasks never count as
activity. Renewal succeeds only while the current lease is still open; it
extends `unlocked_until` to database time plus ten minutes. Once expired, only
password unlock can reopen it.

Manual lock, app backgrounding, account switching, and logout immediately hide
and clear feature state, stop sensitive work, and best-effort close the server
lease. Failure to send the close request does not extend the existing expiry.
All business endpoints check the lease, so a deep link or raw request cannot
bypass the Flutter lock screen.

If renewal cannot reach the server and the lease expires, business operations
fail closed and the UI returns to the neutral unlock screen. Unsaved medical
data remains memory-only and is cleared under the existing privacy rules.

### Shared Edge gateway

Create a version-pinned module under `supabase/functions/_shared/` for:

- allowed-origin CORS and preflight handling;
- method and media-type validation;
- bearer extraction and verified JWT claims;
- UUID `sub` and `session_id` parsing;
- live-session and lease authorization;
- request IDs, `Cache-Control: no-store`, and security response headers;
- stable error mapping and redacted logging;
- bounded JSON parsing and common validation helpers.

All clinic Edge Functions adopt it. Supabase platform JWT verification remains
enabled in `config.toml`; the handler still validates identity and current
session explicitly. The public/publishable key authenticates the application,
never the user. The service/secret key remains Edge-only.

Auth endpoints needed to register, verify, recover, login, and unlock are not
blocked by the clinic lease. Every clinic data endpoint is blocked.

## Single-use Owner action proof

### Protected actions

Phase 14 requires a proof for:

- inviting or resending an invitation that grants Owner;
- revoking a pending Owner invitation;
- adding or removing the Owner role;
- deactivating an Owner membership or other staff removal equivalent;
- changing billing settings;
- issuing a refund or financial correction;
- future security- or security-setting changes when those commands exist;
- bulk patient export if it is implemented in a later phase.

Routine invitation/staff actions that do not affect Owner authority continue to
require current Owner membership but do not require a password proof. No bulk
export or new settings feature is introduced in Phase 14.

### Proof issue

The `security-session` function accepts a `prove_owner_action` POST containing
the password plus a fixed action code, clinic UUID, optional target UUID, and a
canonical command-input hash. It:

1. passes the shared live-session and lease checks;
2. checks active Owner membership in PostgreSQL;
3. verifies the same account password using an isolated Auth client;
4. generates 32 cryptographically random bytes;
5. stores only a SHA-256 digest in a private table;
6. returns the raw URL-safe proof once.

The private record stores digest, user, session, clinic, action, target, command
hash, creation time, five-minute expiry, and consumption time. No password,
email, token, patient content, or raw command body is stored.

### Proof consumption

The final protected PostgreSQL command receives the digest and atomically:

- locks the proof row;
- confirms it is unused and unexpired;
- matches user, live session, clinic, action, target, and canonical input hash;
- rechecks active Owner membership;
- marks it consumed;
- performs the business mutation and audit insert in the same transaction.

Any mismatch rolls back everything. A network retry with the same proof cannot
repeat the action. Existing financial command UUID idempotency remains in
addition to proof single-use. Flutter holds the raw proof only in memory for
the immediate action and clears it on success, failure, lock, clinic switch, or
logout.

MFA is not introduced in this phase, but the proof issuer uses a provider-
independent verifier interface so an authenticator challenge can replace or
supplement password verification before production.

## Business read migration

### API shape

Existing feature Edge Functions gain bounded read operations, or a dedicated
workspace bootstrap function is added where no feature endpoint exists. Reads
remain grouped by business capability rather than exposed as a generic table
proxy:

| Boundary | Read responsibilities |
| --- | --- |
| `workspace` | Clinic creation, memberships, roles, active-clinic bootstrap |
| `staff-invitations` | Owner directory and invitation pages; own membership summary |
| `doctor-schedules` | Readable dentists, schedule versions/hours/breaks/exceptions |
| `patients` | Bounded list/search, demographics, medical profile |
| `appointments` | Bounded calendar range, conflict flags, preparation note |
| `odontogram` | Current and historical tooth-condition pages |
| `treatment-plans` | Procedures, plan/item lists, role-filtered money fields |
| `clinical-sessions` | Session and amendment pages |
| `patient-files` | File metadata plus existing short-lived content authorization |
| `billing` | Role-filtered invoice, item, payment, credit, and ledger pages |
| `dashboard` | Existing capability-filtered snapshot |
| `audit-events` | Existing Owner-only cursor page |

Each Edge read calls a service-only PostgreSQL query that rechecks clinic and
role scope and returns an explicit DTO. It does not accept column lists,
relation names, SQL fragments, arbitrary ordering, arbitrary JSON filters, or
unbounded limits. IDs and clinic scope are server-validated.

All list operations have an enforced maximum page/range. Existing UI contracts
are preserved where safe; offset queries are migrated to deterministic cursors
when concurrent inserts could otherwise skip or duplicate records. Date ranges
use clinic time where business-day meaning matters. Responses include clinic
identity so repositories reject stale results after clinic switching.

### Atomic access auditing

Patient search/list, patient profile, medical profile, odontogram, treatment
plan, clinical session, and patient-file metadata reads record the approved
summary access event inside the same PostgreSQL transaction that builds the
response. The result is returned only if audit insertion succeeds. Search
events contain count, page size, and search-present state, never search text or
returned patient IDs.

This replaces the Phase 13 two-request gate for those reads and closes its
documented raw Data API bypass. File preview/download stays coupled to signed
URL authorization. Appointment, schedule, staff, billing, dashboard, and audit
reads retain their explicitly approved event policy; Phase 14 does not create a
per-row audit flood.

### Flutter migration

Repositories and domain entities remain provider-independent. Supabase data
sources replace direct `.from(...)` reads with authenticated Dio calls and
strict response mapping. Widgets and Cubits keep their current contracts where
possible. A response containing the wrong clinic, role-visible fields, invalid
IDs, unbounded collections, malformed money, or unsafe metadata is rejected.

On lock, logout, inactive membership, or clinic switch, all feature Cubits clear
patient, clinical, financial, staff, schedule, dashboard, and audit state.
Pending requests are cancelled or ignored by generation/clinic guards.

### Grant closure

After every Flutter read adapter has moved and passed integration tests, a
final migration revokes `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`,
`REFERENCES`, and `TRIGGER` on application tables/views from `anon` and
`authenticated`. Clinic creation also moves behind `workspace`, eliminating
the current narrow direct clinic insert/read exception.

All public business functions are audited by signature. `anon` and
`authenticated` receive no execute privilege unless a function is deliberately
designed as a user-JWT/RLS boundary and documented; Phase 14's normal design is
service-only execution behind Edge. Default privileges are changed so future
public tables and functions are not accidentally exposed.

RLS remains enabled even after browser grants are revoked. This provides
defense in depth and protects any explicitly reintroduced narrow client access.
Views are either ungranted or marked `security_invoker`; no creator-rights view
is exposed to browser roles.

Storage keeps only the minimum authenticated object privileges needed for the
approved resumable upload protocol. Listing and content reads remain denied;
exact pending-file identity, uploader, clinic path, MIME, size, and lifecycle
rules stay enforced. Storage grants/policies are tested separately from public
schema grants.

## Database design

One additive Phase 14 migration will contain:

- private session-lease and Owner-proof tables;
- expiry, ownership, digest, and input-hash constraints;
- indexes only for session/proof lookup and bounded cleanup;
- fixed-search-path private verification helpers;
- service-only lease/proof/read functions;
- secured replacements for high-risk Owner commands;
- default-privilege hardening;
- final browser grant revocation and view hardening.

Time comes only from PostgreSQL. Equality comparisons use fixed-size digests;
raw proofs are never stored. Cleanup may be opportunistic and bounded during
proof issuance because free-tier Cron is not required. Expired records grant
no authority even before deletion.

All security-definer functions use an empty fixed search path and
schema-qualified objects. Execute is revoked from `PUBLIC` before narrow grants
are applied. No dynamic SQL is used. Service-only functions still perform
membership, role, session, lease, target-clinic, state-transition, and input
validation instead of trusting the Edge caller.

## Error and privacy behavior

The shared gateway exposes stable localized categories:

- `authentication_required` for invalid, expired, or revoked sessions;
- `session_locked` for a missing/expired/closed lease;
- `owner_proof_required` for missing/invalid/expired/consumed proof;
- `authorization_denied` for role or clinic denial;
- `validation_failed`, `conflict`, `not_found`, and `service_unavailable`.

Responses do not reveal whether a foreign-clinic record exists. Logs include
request ID, operation code, status class, and duration bucket only. They omit
tokens, proof values/digests, passwords, emails, clinic/patient/member/file IDs,
query text, clinical content, financial references, bodies, and raw provider
errors.

All business responses use `Cache-Control: no-store`. CORS permits only local
development origins and the configured public origin. CORS is treated as a
browser control, not authentication. Deployment-level CSP/HSTS is documented
for production hosting but cannot be claimed before a host is selected.

## Verification architecture

### Catalog invariants

A new pgTAP catalog suite enumerates every public table, view, sequence, and
function. It fails if:

- RLS is missing on an exposed table;
- `anon` has application-schema privileges;
- `authenticated` retains a business table/view read or mutation grant;
- a protected function is executable by browser roles or `PUBLIC`;
- a security-definer function lacks an approved fixed search path;
- an exposed view can bypass RLS;
- default privileges can expose a future object;
- required tenant/filter columns lack their reviewed indexes.

Tests use allowlists for the few intentional Auth/Storage/public entry points,
so adding a new object forces an explicit security decision.

### Role and tenant matrix

For every resource and command, table-driven pgTAP tests cover:

- anonymous, authenticated outsider, inactive member, and active member;
- Owner, Dentist, Assistant, Receptionist, and approved combined roles;
- same-clinic and cross-clinic IDs;
- self versus another staff member where relevant;
- active, archived, finalized, cancelled, and entered-in-error states;
- direct table CRUD and direct function execution denial;
- final-Owner concurrency protection and existing business invariants.

No test assumes UI hiding is authorization.

### Session and proof tests

Database and Edge tests cover:

- valid session/unlocked lease success;
- missing, malformed, wrong-user, and deleted `auth.sessions` row denial;
- expired lease, explicit lock, stale revision, and renewal-after-expiry denial;
- background/network calls not renewing the lease;
- unlock for the wrong account or wrong password;
- proof expiry, replay, wrong user/session/clinic/action/target/input hash;
- role revocation between proof issue and consumption;
- concurrent double consumption, with exactly one winner;
- financial idempotency combined with proof single-use;
- no mutation or audit event when proof consumption fails.

### Edge and Flutter tests

- Every Edge Function uses the shared gateway and rejects unknown methods,
  origins, media types, parameters, oversized bodies, and malformed IDs.
- Raw REST/GraphQL requests with real local user tokens cannot read business
  tables/views or execute protected functions.
- Authenticated integration tests exercise every role against same- and
  cross-clinic endpoints, including revoked session and expired lock cases.
- Storage integration tests attempt path spoofing, listing, foreign object
  reads, invalid upload state, MIME/signature mismatch, and signed-URL misuse.
- Repository tests reject malformed or stale responses and forbidden fields.
- Bloc/widget tests prove lock clears data, renewal follows only user activity,
  expired leases route to unlock, and Owner-proof UI never retains passwords or
  proof tokens.
- Existing end-to-end fictional workflow continues through invoice payment and
  audit inspection after direct reads are removed.

## Implementation sequence

Each step must compile and pass its focused tests before the next begins.

1. **Baseline inventory and shared gateway** — freeze the catalog allowlist,
   centralize Edge auth/CORS/errors, and prove behavior matches existing APIs.
2. **Live session and lease** — add private lease storage, unlock/renew/lock,
   Flutter coordination, state clearing, and bypass tests.
3. **Owner proof** — add issue/consume lifecycle and migrate staff, billing,
   and existing security-sensitive commands.
4. **Read commands** — add bounded database/Edge reads feature by feature,
   starting with clinical data and atomic access auditing.
5. **Flutter adapters** — replace every direct business `.from(...)` read and
   verify current screens and role visibility.
6. **Grant closure** — revoke browser business-table/view privileges, harden
   defaults/views/functions, and run raw Data API bypass tests.
7. **Complete attack matrix** — run all database, Edge, Storage, Flutter, and
   fictional end-to-end tests; update security and operations documentation.

No intermediate migration may leave a released Flutter build unable to read
its required data. In local development, read commands and adapters land before
the final grant revocation. The completed phase has one supported boundary.

## Completion gates

Phase 14 is complete only when:

- no Flutter business data source performs a direct table/view read;
- raw user-token REST/GraphQL access to business data is denied;
- all clinic Edge requests verify a live Auth session and open lease;
- all approved sensitive Owner actions consume a matching proof atomically;
- all RLS/grant/Storage/role/tenant/session/proof tests pass;
- all previous feature and fictional integration workflows pass;
- no secrets or sensitive values appear in source, generated artifacts, test
  output, or logs;
- documentation states the remaining production limitations accurately;
- Phase 15 responsive polish is not implemented.

Required final commands:

```text
flutter gen-l10n
dart run build_runner build
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase db reset --local
supabase db test
supabase db lint --local --level warning
authenticated local security integration tests
flutter build web --dart-define-from-file=config/local.json
```

Database lint must have no errors. Existing warnings outside changed functions
must be listed; new Phase 14 warnings are not accepted.

## Implementation and verification

Phase 14 now routes Flutter business reads through authenticated, bounded Edge
commands. Browser roles no longer have direct `select` access to public
business tables or views. Every clinic Edge command checks both the live
Supabase Auth session and its ten-minute server lease. Owner invitations, role
changes, staff deactivation, billing settings, and financial reversals use
five-minute proofs that bind the exact action input and are consumed once by
the database command.

The clean local migration history includes
`20260913214148_harden_security_sessions_and_reads.sql`. Verification completed
with 189 Dart files formatted, zero Flutter analyzer findings, all 116 active
Flutter tests passing, and all 325 pgTAP database tests passing. Authenticated
local flows passed for clinic isolation and lock/unlock/renew behavior, staff
invitations and owner proofs, dashboard reads, audit access, and the complete
billing workflow including an Arabic PDF. Every changed Edge handler compiled
through the local runtime, and the Flutter Web build and Wasm dry run passed.

Database lint has no errors and no Phase 14 warning. It retains four previously
documented Phase 6 warnings in two appointment/schedule helpers: two enum return
casts and two unused parameters. Localization generation also retains 68
previously untranslated Arabic messages; generated fallback strings keep the
application functional, but completing those translations remains product
localization work outside this security phase.

## Risks and trade-offs

- **Scope:** Moving 35 table/view reads is intentionally substantial. Doing it
  feature by feature with contract tests prevents a single high-risk rewrite.
- **Availability:** Live-session and lease checks add a database dependency to
  every clinic request. This is the approved trade-off for immediate revocation
  and shared-device enforcement; failures close access and show a retry/unlock
  state.
- **Latency/free limits:** One shared authorization RPC adds work per request.
  Bounded pages, indexed primary-key checks, no recursive Edge calls, and no
  per-row audit writes keep local/free-tier load controlled.
- **Activity authenticity:** The server can validate session and lease state,
  but cannot prove a physical person generated an activity event. The control
  addresses an unattended official client, not a compromised device.
- **Password verification:** The temporary Auth sign-in creates a short-lived
  verification session which is immediately signed out locally. Password rate
  limits remain with Supabase Auth; no password hash is copied into the app DB.
- **Service key:** Edge service credentials bypass RLS. Least-privilege
  service-only functions, restricted direct grants, redacted logs, and secret
  handling reduce mistakes, but production secret rotation and monitoring are
  still required.
- **Compatibility:** Revoking direct grants before all adapters migrate would
  break the app. The final revocation is deliberately last and tested against
  the complete workflow.
- **Production:** Free development lacks approved hosting, recovery,
  monitoring, legal/data-residency review, and MFA policy. Phase 14 does not
  satisfy the Production Readiness Gate by itself.

## Current platform references

- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase user sessions](https://supabase.com/docs/guides/auth/sessions)
- [Supabase sign-out semantics](https://supabase.com/docs/guides/auth/signout)
- [Supabase Edge Function authentication](https://supabase.com/docs/guides/functions/auth)
- [Supabase Edge Function authorization headers](https://supabase.com/docs/guides/functions/auth-headers)
- [Supabase Edge Function CORS](https://supabase.com/docs/guides/functions/cors)
- [Supabase database functions](https://supabase.com/docs/guides/database/functions)

Current Supabase documentation confirms that grants and RLS are separate,
views need explicit invoker/privilege treatment, access tokens can survive
sign-out until expiry, and the JWT `session_id` can be checked against
`auth.sessions`. The design uses those documented properties without paid Auth
session-timeout features.
