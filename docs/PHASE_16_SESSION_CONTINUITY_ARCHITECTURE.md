# Phase 16 — Three-Day Demo Session Continuity Architecture

Status: approved, implemented, and locally verified on 2026-09-17.

Authority: [Master Specification](MASTER_SPECIFICATION.md), the completed
[Phase 14 security architecture](PHASE_14_SECURITY_HARDENING_ARCHITECTURE.md),
and the user's approved fictional-demo convenience decision on 2026-09-15.

## Product decision

For the fictional-data demo:

- the workspace locks after three days without human activity;
- a Web page refresh restores an authenticated session without another
  password when its server lease is still valid;
- switching tabs or minimizing masks the workspace but does not immediately
  lock it;
- resume rechecks both the client inactivity deadline and authoritative server
  lease before protected data can be requested;
- explicit Lock and Sign out remain immediate;
- normal Web tab closure continues to discard the refresh token because Web
  authentication remains in `sessionStorage`;
- the three-day policy must be reviewed and shortened before real patient data
  is authorized.

Initial sign-in and an expired, explicitly locked, revoked, or unavailable
lease still require authentication. No password, password-derived value, or
client-controlled unlocked flag is persisted.

## Security model

The PostgreSQL lease remains authoritative. Web refresh restoration uses the
authenticated Supabase session ID already verified by the Edge Function. The
client asks for the current lease and receives only its expiry and revision.
It cannot create or extend a lease through this restoration request.

Human pointer, keyboard, touch, or scroll activity may renew a live lease at
most once per minute. Each accepted renewal moves `unlocked_until` to three
days after the server timestamp. Token refreshes, background network traffic,
timers, analytics, and Realtime events do not count as activity.

A hidden application exposes no session token to feature transports and masks
the widget tree. On resume, a local deadline check runs before the mask is
removed. A later protected response with `session_locked`/HTTP 423 invokes the
existing global lock callback and redirects to `/locked` without replaying the
request.

Explicit lock updates the server lease, clears its in-memory revision, and
broadcasts the lock to other same-origin tabs. Sign out clears the Auth session
and lease state. Owner-action password proofs retain their existing short
expiry and are not extended to three days.

Native builds retain the safer existing cold-start behavior: secure Auth
credentials may restore, but reopening the native application starts locked.
Only Web refresh receives valid-lease restoration. Browser crash/session
restoration behavior is controlled partly by the browser, so the application
does not claim tab closure as a guaranteed remote revocation event; explicit
Lock or Sign out remains the reliable action.

## Backend changes

Add one forward-only migration. It will replace the lease open and renewal
functions so their server-computed expiry is `statement_timestamp() + interval
'3 days'`. Existing rows are not silently extended; they gain the new duration
only after a successful password unlock or live renewal.

Expose an authenticated `restore` action in the existing `security-session`
Edge Function. It calls the service-only `security_session_assert` function and
returns the existing bounded `{unlockedUntil, revision}` response. A missing,
expired, locked, revoked, or mismatched session returns the existing safe lock
or authentication response. No table grant, direct Data API path, new secret,
or password bypass is added.

## Flutter changes

Extend `ServerSession` with a restore operation that loads a valid lease into
memory. `SessionCoordinator` receives an explicit Web restoration policy from
composition:

1. restore the Auth session;
2. on Web, assert the server lease;
3. enter `signedIn` only when both succeed;
4. otherwise enter `locked` and expose no application token.

The coordinator uses one shared three-day inactivity constant for its local
deadline. Backgrounding sets `hidden` without changing `signedIn`; resuming
checks inactivity before clearing `hidden`. Native restoration continues to
enter `locked` without calling lease restore.

This remains provider-portable: presentation and feature repositories do not
change. Only the provider-neutral session interfaces, coordinator, Supabase
session adapter, and composition policy know about continuity.

## Files to create or change

```text
supabase/migrations/<timestamp>_extend_demo_security_session_lease.sql
supabase/functions/security-session/index.ts
supabase/tests/security_hardening_rls.test.sql
lib/core/auth/server_session.dart
lib/core/auth/session_coordinator.dart
lib/app/bootstrap/backend_module.dart
test/auth/auth_fakes.dart
test/auth/session_coordinator_test.dart
test/local/auth_integration_test.dart
README.md
SECURITY.md
PRODUCTION_READINESS.md
docs/PHASE_16_SESSION_CONTINUITY_ARCHITECTURE.md
```

Generated dependency files change only if dependency injection generation
requires it. No feature, clinical, billing, or navigation contract changes.

## Test plan

- 72 hours minus one second remains signed in; 72 hours locks before late
  activity can reset the deadline.
- Human activity renews a live lease; token refresh does not.
- Background masks content and withholds feature tokens without locking.
- Resume before expiry restores visibility; resume after expiry locks.
- Web Auth restoration plus a valid server lease enters `signedIn` without a
  password.
- Missing, expired, revoked, mismatched, malformed, and unavailable lease
  responses fail closed.
- Native restoration still requires unlock.
- Explicit lock remains immediate and cross-tab.
- HTTP 423 continues to lock globally and mutations remain unreplayed.
- Local integration verifies unlock, refresh-style reconstruction, restoration,
  renewal, explicit lock, and denial after lock using fictional identities.
- pgTAP verifies the three-day bounds using server time and proves clients
  still have no direct lease-table or command access.

## Completion gates

```text
flutter gen-l10n
dart run build_runner build
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase test db --local
authenticated local Auth integration test
authenticated local MVP integration test
flutter build web --dart-define-from-file=config/local.json
```

Phase 16 is complete only when refresh continuity works through the real local
Edge Function and PostgreSQL lease, hidden content remains masked, all expired
and explicit-lock paths fail closed, the full MVP regression workflow passes,
and documentation clearly limits the policy to fictional demo use.

## Verification result

Phase 16 completed locally on 2026-09-17:

- the forward-only three-day lease migration applied successfully;
- all 327 pgTAP database tests passed across 13 suites;
- 17 focused coordinator tests passed, including exact expiry, Web restore,
  background masking, authoritative resume, and fail-closed behavior;
- the real local Auth workflow passed registration, verification, password
  unlock, refresh-style reconstruction, lease restoration, renewal, explicit
  lock denial, recovery, and revocation;
- the full Flutter suite passed with 140 active tests and 7 intentionally
  opt-in local tests skipped;
- Flutter analysis reported no issues and all 203 Dart files were formatted;
- the authenticated local MVP workflow passed with fictional role-separated
  clinic data;
- localization and generated dependency output completed successfully; and
- the configured Flutter Web release build completed, including its Wasm dry
  run.

No hosted migration or function deployment was performed as part of Phase 16.

## Risks and trade-offs

- Three days is a long exposure window for an unattended clinic workstation.
  Explicit lock training and the fictional-data restriction reduce current
  demo risk but do not make this suitable for production.
- A valid Auth token and live server lease may survive a browser crash that
  restores the same tab session. The server deadline and explicit lock remain
  authoritative.
- Longer leases increase the value of a stolen live session. RLS, clinic roles,
  short Owner proofs, cross-tab lock, and server revocation still limit scope,
  but the production timeout must be substantially shorter.
- Network loss during refresh cannot be treated as successful restoration. The
  app stays locked until it can verify the lease or the user authenticates.
