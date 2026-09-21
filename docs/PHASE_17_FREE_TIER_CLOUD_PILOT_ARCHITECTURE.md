# Phase 17 — Free-Tier Cloud Pilot Architecture

Status: approved and deployed on 2026-09-17; hosted email and complete pilot
workflow verification remain open.

Email decision superseding the SMTP signup plan below: the user approved
Supabase's built-in sender for their project-team email and signup verification
links followed by sign-in. See `EMAIL_VERIFICATION_LINKS.md`. Earlier Brevo
configuration is historical evidence, not the current signup delivery policy.

Authority: `MASTER_SPECIFICATION.md`, the current free-tier infrastructure and
fictional-data policy, the completed Phase 15 MVP, and the proposed Phase 16
three-day demo session continuity architecture.

## Goal

Publish a reviewable DentaFlow staging pilot on the linked Supabase Free Tier
project while preserving the existing provider-independent Flutter boundaries.
The pilot is for fictional/demo patient data only. It is not production hosting
and does not satisfy production legal, backup, recovery, monitoring, or data
residency requirements.

## Current evidence

- The remote Supabase project is linked and reports healthy.
- All 36 ordered migrations are present in matching local and remote migration
  history. No development seed was applied.
- All 14 Edge Functions are deployed. An unauthenticated invitation request is
  rejected with HTTP 401 before function data is exposed.
- Supabase Auth uses the Firebase Hosting origin, the reviewed redirect list,
  verified-email registration, six-digit codes, the 15-character password
  minimum, secure password changes, and English/Russian/Arabic templates.
- Brevo custom SMTP is configured for Supabase Auth. The staff invitation
  function has server-side Brevo credentials and multilingual invitation
  content; actual hosted delivery still needs an end-to-end inbox check.
- The Flutter Web release is deployed on Firebase Hosting Spark at
  `https://dentaflow-demo-nour.web.app` with HTTPS and the reviewed security
  headers.
- The deployed client contains only the public Supabase URL and publishable key.
- Formatter, analyzer, and the complete ordinary Flutter suite pass after the
  cloud configuration: 140 tests passed and 7 opt-in integration tests skipped.
- The database password and an earlier secret API key were shared in chat. Both
  must still be rotated before this pilot can be accepted as complete. Neither
  value is stored in the repository or Flutter configuration.

## Remaining acceptance checks

- Rotate the exposed Supabase database password and secret API key.
- Register one fictional Owner through the hosted app and confirm the real
  verification email and code flow.
- Run the fictional hosted workflow for clinic setup, staff invitation and
  acceptance, role permissions, patient and appointment operations, clinical
  records, files, billing, dashboard, audit, and sign-out.
- Confirm English, Russian, and Arabic layout and email behavior on the hosted
  origin.
- Record remote database tests/lint and authenticated Edge Function smoke-test
  results. Local database and end-to-end coverage remain supporting evidence,
  not a substitute for the hosted checks.

## Deployment boundary

The hosted pilot contains:

- Supabase Auth for verified-email accounts;
- PostgreSQL schema, commands, RLS, grants, audit ledger, and security sessions;
- private `patient-files` and `invoice-pdfs` Storage buckets;
- the 14 repository Edge Functions;
- a Flutter Web build configured with only the project URL and publishable key;
- fictional clinic, staff, patient, appointment, clinical, file, and billing data.

The pilot excludes real patient data, a custom domain, paid infrastructure,
production backups, production recovery guarantees, production monitoring,
legal approval, and production data-residency approval.

## Required sequence

### Step 1 — Finish Phase 16 locally

Implement and approve the three-day inactivity lease, browser-refresh restore,
background privacy mask, explicit lock/sign-out behavior, and regression tests
described in `PHASE_16_SESSION_CONTINUITY_ARCHITECTURE.md`. This must happen
before the cloud schema is applied so the first hosted version has one coherent
session contract.

### Step 2 — Rotate exposed credentials

Reset the database password and replace/delete the exposed secret API key in the
Supabase dashboard. The Flutter app receives only the publishable key. Hosted
Edge Functions use Supabase-provided server secrets and never expose them to the
client.

### Step 3 — Prepare hosted email and URL settings

Choose a free-tier-compatible email delivery path for Auth verification,
password recovery, and staff invitation links. The current staff invitation
function defaults to the local `inbucket:1025` server and is therefore not
host-ready as written. Before deployment, adapt it to the approved hosted mail
path and verify that one-time invitation links work for verified email
addresses.

The approved free pilot path uses Brevo Free for transactional delivery and
Firebase Hosting Spark for the Flutter Web site. Brevo credentials remain
server-side. Firebase serves the static release at its free `web.app` origin;
the project must not be linked to a billing account for this pilot.

All user-facing account emails must support English, Russian, and Arabic. The
verification and password-recovery templates must add clear Arabic text, and
staff invitation messages must no longer be English-only. Arabic email sections
use right-to-left direction and keep codes and URLs readable. Because an invited
staff member may not have saved a language preference yet, the first hosted
invitation email contains concise sections in all three supported languages.

Configure the Auth site URL, exact redirect allow-list, and
`DENTAFLOW_PUBLIC_ORIGIN` from the selected free Flutter Web URL. Until that URL
exists, cloud authentication callbacks and browser CORS cannot be considered
verified.

### Step 4 — Apply and verify the database

Apply all 35 migrations in timestamp order through the linked project pooler.
Do not run a destructive reset and do not load local development seeds. Then
verify migration history, database lint, RLS/grants, private Storage buckets,
and cross-clinic isolation with fictional data.

### Step 5 — Deploy and verify Edge Functions

Deploy all 14 functions from the repository. Configure only the required hosted
secrets and public origin. Run authenticated smoke checks for Owner, Dentist,
Assistant, and Receptionist roles, including explicit denied operations.

### Step 6 — Configure and publish Flutter Web

Create ignored `config/staging.json` with `APP_ENV`, the base Supabase project
URL, and the publishable key. Build Flutter Web from that configuration and
publish it on the selected free host. No secret or service-role credential may
be compiled into the app.

### Step 7 — Pilot verification

Using fictional data only, verify registration, email verification, sign-in,
three-day session continuity, clinic creation, staff invitation, role
permissions, patients, schedules, appointments, odontogram, treatment plans,
clinical sessions, private files, billing, invoice PDF, dashboard, audit log,
Arabic/Russian/English behavior, right-to-left layout, multilingual account and
invitation emails, Arabic invoice PDF output, responsive layouts, and sign-out.

Run the repository quality gates after implementation:

- `dart format`
- `flutter analyze`
- `flutter test`
- database tests and lint
- Edge Function smoke tests
- configured Flutter Web release build

## Failure and rollback policy

Every schema change remains forward-only and versioned. If a deployment step
fails, stop before the next layer, record the failure, and fix it with a new
migration or function revision. Do not erase migration history or reset the
hosted database. Because the pilot contains only fictional data, the project can
be abandoned and recreated if the free-tier environment becomes irrecoverable,
but this is a pilot contingency rather than a production recovery strategy.

## Approval gate

Approval authorizes implementation of Phase 16 followed by this cloud-pilot
sequence. Applying migrations, deploying functions, or publishing the web build
must not begin until this architecture is approved. Credential rotation remains
a mandatory checkpoint before the first hosted mutation.
