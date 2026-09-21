# Phase 1 — Authentication design proposal

Status: implemented and locally verified; ready for review. Authority: MASTER_SPECIFICATION.md, sections 57–65, 80, and 85. Approval and verification date: 2026-09-07.

## Repository findings

Phase 0 provides an isolated GetIt composition root, GoRouter preview, English/Russian localization, Material themes, typed errors, a lazy in-memory Supabase connection, and guarded Dio transport. There is no authentication feature, session persistence, auth callback handling, or privacy-lock implementation. Appearance preferences contain no tokens. The workspace is not currently a Git repository.

The existing token-provider contract is reusable. Session refresh must move under a shared authentication coordinator so SDK refresh, startup restoration, and Dio retries cannot rotate the same refresh token independently. Existing Phase 0 behavior and tests remain regression coverage.

## Required scope and phase boundary

Implement individual email/password registration, email verification, login, logout, forgot/reset password, session restoration, and the ten-minute privacy lock. Supabase Auth is the only identity provider. No shared employee accounts.

Registration creates an identity only in this phase. A signed-in user reaches a neutral account-ready page, with manual lock and logout. It must not invent a clinic, membership, role, or dashboard. Clinic creation and automatic OWNER assignment belong to Phase 2. Staff invitations and role assignment belong to Phase 3. Preserve future navigation intent without treating an invitation URL as permission.

MFA enrollment and sensitive-owner action proofs are later work. Their requirements are retained; a login timestamp or refreshed token must never be presented as sufficient proof for those actions.

## Product decisions

1. APPROVED: browser persistence across refresh only, with password unlock after restoration. Session storage may be restored by browser session-recovery features, so tab closure is not a security boundary; the lock remains mandatory.
2. APPROVED and implemented: local Supabase with Mailpit local inbox. Free Colima/Docker CLI and Supabase CLI are installed locally, and the repository contains reproducible Auth settings and code-email templates. No paid sender, domain, external email, or verification bypass is used.
3. APPROVED: after password reset, revoke all sessions, including the recovery session, and require a fresh login. If password update succeeds but revocation fails, report the partial outcome and never claim all sessions were revoked. Existing access tokens may remain usable until expiry; immediate denial requires later protected-API session checks.

All recommendations below are design proposals for approval, not silently accepted product requirements.

## Authentication architecture

Presentation calls AuthBloc, which coordinates workflows through an AuthRepository interface. Domain models expose identity and safe authentication state, never raw Supabase User/Session objects or tokens. A SupabaseAuthDataSource and repository implementation handle provider calls, error mapping, verification, and session events.

An application SessionCoordinator owns restoration, refresh synchronization, privacy lock, lifecycle handling, and logout. An AuthSessionStore interface isolates platform storage. Native adapters use flutter_secure_storage; the proposed Web adapter uses tab session storage. Neither Web storage choice protects against injected same-origin scripts. Native keystore guarantees must not be claimed for Web. SharedPreferences remains limited to non-sensitive UI preferences.

Keep passwords out of persistent state, serialized Bloc events, diagnostics, analytics, URLs, and storage. Clear password fields after successful actions and disposal. Credential-bearing commands and SDK exceptions must be redacted from any Bloc observer. Do not store medical drafts as part of session restoration.

Startup remains behind a neutral loading screen until restoration and lock evaluation finish. A locally stored identity alone is insufficient to open protected routes: validate/refresh through Auth, then enter a locked restoration state. Network failures retain a blocked retry state; invalid/revoked credentials clear the local session. No offline access to protected screens is introduced.

Use explicit states for restoring, signed out, awaiting email confirmation, signed in, locked, recovery pending, recovery authorized, and recoverable failure. Recovery authorization must not accidentally open ordinary account routes. Preserve the current account if a mismatched recovery flow is encountered; require explicit account switching before replacing it.

## Identity operations and API boundaries

| Operation | Provider responsibility | Application responsibility |
| --- | --- | --- |
| Register | Create identity; send confirmation | Validate form; show generic confirmation; never assign roles |
| Verify email | Validate single-use confirmation | Consume approved flow only; clear secret-bearing callback state |
| Login | Verify email/password | Map safe errors; establish app session; clear form |
| Restore/refresh | Validate/rotate session | Serialize refresh; block until status is known |
| Forgot password | Issue recovery email | Generic acknowledgement without confirming account existence |
| Reset password | Verify recovery and update password | Gate reset route; apply approved session-revocation policy |
| Unlock | Verify same account credentials | Compare verified user ID before revealing protected content |
| Logout | Revoke selected session scope | Clear local credentials/state immediately; handle remote failure explicitly |

Use the installed Supabase Dart SDK inside the adapter; Dio remains for Edge Functions. No custom password hashing or client use of admin/service-role APIs. No business-table migration is needed for this phase as proposed. Provider settings and email templates must be reproducible and documented; hosted dashboard-only changes need an explicit setup checklist.

Proposed email design: verification/recovery email codes entered into an application form, using Supabase-issued OTPs and matching verification type. This avoids requiring an email link to return to the same browser's PKCE verifier. Configure templates to include the code; no automatic account creation through a login OTP operation. Code lifetime and server rate limits follow explicitly recorded provider configuration. If clickable links are requested instead, finalize the callback/PKCE and cross-device behavior before implementation. Do not implement both flows speculatively.

Proposed password policy: minimum 15 characters for new passwords, passphrases and password-manager paste supported; no arbitrary rotation schedule. Set matching server enforcement. Document the deployed provider's actual maximum/Unicode handling before finalizing field limits. Never silently trim or alter passwords. Login accepts existing credentials without applying new-password rules. Confirmation must match exactly. Leaked-password blocking is not promised on the Free plan.

Proposed logout scope: current session/device. Clear the client immediately even if offline; report that server revocation could not be confirmed. A previously issued access token can remain valid until expiry. Future sensitive APIs must check revocation where immediate denial is required.

## Privacy lock and later backend enforcement

Ten minutes without meaningful keyboard, pointer, or touch activity locks protected presentation. Background refresh, network traffic, and realtime events do not count as user activity. Recompute the deadline on visibility/resume instead of relying solely on throttled browser timers. Mask content immediately in background; check the lock before revealing it again.

On lock, hide protected routes, stop protected requests/subscriptions, and prevent the token provider from authorizing application requests. Keep the server session rather than automatically signing out. Unlock requires an online password check of the same identity; wrong credentials or unavailable Auth leave the screen locked. A successful check may create a replacement provider session: retire the previous session where supported and test this explicitly. A different employee must choose Switch account, clearing prior user state.

Broadcast lock/logout across same-origin tabs without sending credentials. A restored or duplicated tab starts locked. Treat these controls as shared-device privacy protection, not as a defense against a malicious client or stolen token.

Before any clinic/patient endpoints are introduced, finalize backend session-access enforcement covering RLS, RPCs, files, and realtime. A client lock alone cannot enforce those boundaries. Any server access lease must be bound to a validated session and re-authentication, with ordinary token refresh unable to unlock it. This is a prerequisite for sensitive data phases, not a completed Phase 1 security claim.

## Screen and navigation proposal

Common layout: DentaFlow header with language/theme controls, centered form card up to 440 logical pixels wide, visible demo notice, no clinic sidebar. Below 600 pixels use full-width padded forms and a scrolling keyboard-safe layout; tablet/desktop center the same card. Retain existing light/dark themes, teal primary #006D77, readable system typography, 16px form text, visible focus, semantic error announcements, and at least 48px touch targets. Every state is translated into Russian and English.

| Route/screen | Contents and main action | Destination and failure behavior |
| --- | --- | --- |
| /login | Email, password, visibility toggle, Sign in; Register and Forgot password links | Account-ready after verified login; inline generic credential error; retry on network failure |
| /register | Email, password, confirmation, visible password guidance, Create account | Email verification screen; no clinic form or role selector |
| /verify-email | Email context, verification code, Verify, Resend, Change email | Account-ready after verification; expired/invalid code stays on form; resend respects server throttling |
| /forgot-password | Email and Send recovery code | Neutral recovery instructions whether or not an account exists |
| /reset-password | Email/code verification step, then new password and confirmation | Only verified recovery can update password; successful completion follows the selected revocation policy |
| /locked | Neutral account context, password, Unlock, Switch account | Return to an allowlisted pending internal destination only after same-account verification |
| /account-ready | Account confirmation, demo/phase notice, Lock and Sign out | Lock or login; no fake clinic navigation |

Submission buttons show progress and prevent duplicates. Provider throttling is authoritative; client cooldowns are only feedback. Expired/reused codes offer a fresh request. Unknown routes retain the safe existing unavailable page. Never echo tokens, unrestricted redirect destinations, or provider exception bodies. Web history cannot expose protected pages after logout or lock.

## Proposed files

Create `lib/features/auth/domain/` for identity, safe auth state, repository contract, and workflow use cases; `data/` for Supabase source, repository, and provider-to-domain mapping; `presentation/bloc/` for AuthBloc/events/state; `presentation/pages/` for the seven screens above; and `presentation/widgets/` for shared form components.

Create `lib/core/auth/` for session coordinator, lock/activity policy, and clock/lifecycle interfaces; `lib/core/storage/auth_session_store.dart` plus conditional Web/native adapters. Do not export provider SDK types through these interfaces.

Change composition/DI, router guards, app lifecycle wiring, the token provider/Supabase connection, typed auth failures, both ARBs, and native configuration only as required. Add auth/domain, adapter, Bloc, router, persistence, and lock tests under `test/`; add real local-auth flows under `integration_test/`. Add local Supabase configuration/email templates only after the email-testing decision. Update README, ARCHITECTURE, SECURITY, and this phase document.

## Reviewable implementation steps after approval

1. Record product decisions and exact provider settings; establish the selected free test environment and verify email delivery there.
2. Implement domain contracts and safe provider adapters, then test verification, provider errors, and credential handling.
3. Implement session storage/coordinator and routing; test restoration, invalid sessions, refresh races, logout failure, and privacy lock.
4. Implement approved localized forms and responsive navigation; verify validation, keyboard/accessibility behavior, and pending states.
5. Exercise real registration → verification → login → refresh → lock/unlock → recovery → logout against the selected test backend. Never substitute mock results for provider integration evidence.
6. Run generation, `dart format`, `flutter analyze`, `flutter test`, and Web build. Run available native smoke/build checks and disclose unverified targets. Fix all required-check failures before Phase 1 completion.

Each step ends with a short result and next-step update. No Phase 2 implementation is authorized by approving this phase.

## Verification priorities

Cover unconfirmed accounts, duplicate registration without account enumeration, incorrect credentials, expired/reused/wrong-type codes, recovery attempted without proof, account mismatch, refresh racing logout, corrupted/unavailable storage, timer boundaries, background/resume, duplicated tabs, back/deep-link guard bypass, offline logout, revocation limits, Russian large-text/mobile forms, and sanitized diagnostics. Use controlled clocks and adapters for failure tests; use actual Supabase Auth for integration checks.

## Sources and unresolved verification

- [Supabase sessions](https://supabase.com/docs/guides/auth/sessions): paid managed limits, refresh behavior, and access-token revocation limits.
- [SMTP restrictions](https://supabase.com/docs/guides/auth/auth-smtp): default sender restrictions; custom sender configuration.
- [Password authentication](https://supabase.com/docs/guides/auth/passwords): registration, sign-in, and recovery.
- [Email templates](https://supabase.com/docs/guides/auth/auth-email-templates): confirmation/recovery templates and OTP fields.
- [Password security](https://supabase.com/docs/guides/auth/password-security): provider policies and paid leaked-password protection.

Documentation and the installed gotrue 2.27.2 source were reviewed for the proposal. The SDK supports email/code `verifyOTP` with a recovery type and emits a passwordRecovery event; `resetPasswordForEmail` requests recovery; `signOut` accepts explicit local/global/others scopes. `recoverSession` can accept a still-valid stored session without network validation, so it is insufficient by itself for the proposed startup verification. Provider integration tests must confirm the complete flow against the selected local Auth version.

The current changelog was reviewed before implementation. The relevant hosted Free-tier restriction is that new hosted Free projects cannot customize Auth email templates with the default SMTP sender; self-hosted/local CLI projects are unaffected. The local environment therefore supplies the approved verification/recovery code templates. No hosted configuration was provisioned.

## Implementation and verification

Implemented files follow the proposed `features/auth/domain`, `data`, and `presentation` boundaries, plus `core/auth` and conditional native/Web token stores. The supplied local Supabase config enables email confirmation, requires 15-character passwords, disables public auto-exposure of new tables, and contains no clinical schema or migration.

Validation completed on 2026-09-07:

- `dart format .`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 44 tests; the real local test is skipped by default because it needs containers.
- `flutter test test/local/auth_integration_test.dart --dart-define=RUN_LOCAL_AUTH=true --dart-define-from-file=config/local.json`: passed against local Supabase and Mailpit. It exercised registration, confirmation code, unconfirmed-login rejection, restore, same-account unlock, refresh, logout, recovery code, reset, global session revocation, and old-password rejection.
- `flutter build web --dart-define-from-file=config/local.json`: passed.

The Browser testing surface was unavailable in this environment, so no interactive browser screenshot was captured. Android/iOS builds, a native device smoke test, external email delivery, hosted Supabase, GitHub Actions execution, MFA, and production infrastructure remain unverified or out of scope.

Phase 2 remains unimplemented.
