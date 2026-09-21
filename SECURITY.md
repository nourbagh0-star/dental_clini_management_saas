# Security status and boundaries

Phase 16 is a fictional-data development build. It is not ready for real
patient data. The [master](docs/MASTER_SPECIFICATION.md) and
[production gate](PRODUCTION_READINESS.md) control later rollout.

## Present controls

- Production configuration is blocked; incomplete/unsafe backend config fails visibly.
- Only public client keys are accepted by configuration checks; legacy anon JWT parsing is a mistake-prevention check, not signature verification or authorization.
- Supabase Auth is the sole identity provider. Passwords are never serialized, logged, stored in Bloc state, URL parameters, analytics, or SharedPreferences.
- Native refresh tokens use secure storage; Web uses browser tab session storage. A Web refresh may restore a valid server lease without another password; native cold starts remain locked. Missing, expired, revoked, malformed, or unavailable leases fail closed.
- Three days with no human pointer/keyboard/touch/scroll activity locks the fictional-data demo. Background network activity and token refresh do not count. Backgrounding masks content, and resume asserts the server lease before revealing it. Lock/logout messages cross tabs without credentials.
- Recovery sessions are never persisted or exposed to Dio. Password reset requests global sign-out; a failed server revocation is shown as a partial result, while the current client is cleared.
- Dio permits only the configured Edge Functions origin/path, disables redirects, removes supplied credential headers, and attaches bearer tokens only for requests explicitly marked authenticated.
- Read-only 401 replay is single-flight and limited to one; mutation retries are not automatic.
- Typed failures have no provider response text. Localized UI errors do not show stack traces. HTTP debug logging omits URLs, identifiers, headers, payloads, and exception messages.
- Appearance preferences are the only local records stored. No patient cache, tokens in SharedPreferences, or logging of medical content is implemented.
- CI has read-only repository permission, pinned action revisions, no production secrets, and standard free-allowance runner usage.
- Clinic membership, combined roles, RLS, explicit grants, protected database
  commands, private Storage, and immutable clinical/financial/audit histories
  enforce server-side authorization independently of hidden UI actions.
- Sensitive Owner staff commands require a server-verified unlocked lease and
  recent password proof. Locking and revocation invalidate the server lease.
- The Phase 15 local workflow verifies one-time invitations, role separation,
  protected clinical and billing operations, and representative denials using
  fictional data only.

## Production gaps

Production hosting and data residency, legal and clinical review, managed
backup and recovery drills, monitoring and incident response, MFA policy,
external email delivery, Firebase notification/telemetry integration, and real
patient-data approval remain unresolved. Web tab storage is not a native
keystore, and the client privacy lock remains a shared-device privacy control;
server authorization and the server lease provide the security boundary.
Supabase Free lacks the complete managed operational controls required for a
production healthcare deployment.

The three-day inactivity period is a demo convenience accepted only while all
patient data is fictional. It increases unattended-workstation exposure and
must be shortened through the production security review before real patient
data is authorized.

No raw Supabase/service-role keys, FCM service credentials, or privileged tokens belong in Flutter, Git, diagnostics, or CI output. Firebase initialization is deferred to its actual integration; analytics/crash/push adapters must exclude patient content and not depend on Firebase Auth.

Development dependencies and generated files are pinned for reproducibility. Do not upgrade around failing tests or add analyzer suppressions for security issues. Backend changes must include their RLS tests as they are introduced, even though the master also has later hardening phases.
