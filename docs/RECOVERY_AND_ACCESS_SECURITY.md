# DentaFlow — Recovery and access-security proposal

Status: architecture step 1 proposal, awaiting approval. Requirements already supplied: RPO 15 minutes, RTO 2 hours, three environments, individual accounts, 10-minute inactivity lock, and recent authentication for sensitive owner actions. Parameters explicitly described as proposed below are not approved defaults.

Current-policy update: [free-only development/MVP validation](HOSTING_DECISION.md) takes precedence. The recovery design below is retained for deferred production review, not a free-tier commitment or authorization for paid backups/monitoring. Session locking, individual accounts, authorization, and owner re-authentication remain current requirements and must use free-compatible designs. Paid managed session controls cannot be implementation dependencies. Architecture proposals here remain subject to approval.

## Recovery design

Use automated base database backups plus continuous archived transaction logs/PITR. A nightly dump alone cannot meet the required loss window. PostgreSQL documents recovery from a base backup and subsequent WAL; host configuration files require separate coverage. [PostgreSQL PITR](https://www.postgresql.org/docs/current/continuous-archiving.html).

Proposed operational thresholds: aim for recoverable DB/object changes within five minutes, warn at ten minutes of unprotected changes, and declare an RPO breach at fifteen. Measure the latest successfully recoverable change, not just the backup job start time. Low activity, upload queues, WAL gaps, failed jobs, storage capacity, and unavailable keys need monitoring. Provider PITR availability alone is not evidence that this application meets its target.

| Asset | Recovery coverage |
| --- | --- |
| Business DB | Patients, appointments, clinical data/history, invoices, payments, memberships, permissions, audit, configuration; base backup plus complete transaction-log chain |
| Auth | User identities, credential/factor records supported by the chosen deployment, auth schema/config, signing-key recovery/rotation procedure; validate current access after restore |
| Patient files | Independent copies of immutable/versioned object content and a manifest linking file IDs, keys/versions, checksums, sizes, and metadata |
| Runtime | Versioned application/functions/migrations and deployment configuration; encrypted secret/key recovery outside Git; DNS/certificates/email callbacks |
| Operational evidence | Backup/replication monitoring, recovery reports, runbook, incident contacts, key access instructions; available during primary-provider outage |

Proposed file target: the same 15-minute RPO as critical records, subject to explicit approval because the user requested file recovery but did not separately assign its numerical target. Copy newly accepted objects to independent storage promptly; monitor protection lag and expose failures operationally. Do not overwrite prior file versions on correction or propagate normal archive actions as backup deletion.

A database/object backup is not automatically atomic. Restore DB to a chosen time; reconcile every referenced file against the manifest and its available versions. Keep later unreferenced objects quarantined instead of deleting them during recovery. If required file data cannot be recovered within the agreed window, report the gap and do not claim the drill passed.

For RTO, propose the following drill budget measured from service interruption: detect/triage 15 minutes; provision/recover DB, auth, and runtime 60 minutes; validate data/access/files 30 minutes; switch traffic and verify users 15 minutes. Recover files in parallel from a ready-to-serve secondary copy where feasible. These are planning allocations, not observed timings. Large object sets may require pre-positioned recovery storage to fit two hours.

Before a real pilot, rehearse machine loss, database corruption/PITR, lost primary file access, and revoked credentials. Explicitly scope a complete provider/region outage: meeting two hours may require alternate infrastructure, quota, and budget. Prevent simultaneous writable old/new systems during recovery. Do not return traffic to the old DB after accepting new writes without reconciliation.

Validate invoice balances, clinical finalization/amendments, tenant isolation, current staff permissions, file checksums, and audit writes. A restored backup can resurrect removed memberships or sessions; reconcile access changes since the restore point using independently retained security evidence, revoke sessions as needed, and require fresh login before reopening. Never blindly restore old authorization state into public service.

Propose a full pre-pilot restore test, monthly drills during the pilot, and a new drill after material infrastructure/backup changes. Record actual loss window, elapsed time, missing files, failures, and corrective actions. Retention periods and the named person responding to alerts remain approval items. Copies used for production restore drills stay in an approved isolated recovery environment, never routine staging.

Clinic fallback: agree on a minimal, securely handled daily appointment reference and an outage log. Staff record changes manually during a short outage and reconcile them after recovery, checking duplicates/conflicts and attribution. No uncontrolled medical exports or credentials in the fallback sheet. Its access and disposal procedure needs clinic/privacy approval.

## Session and shared-device design

Each staff member uses an individual account. Being on the clinic network grants no extra permission. A device/browser session has a distinct server-recognized identity; multiple clinic memberships do not merge roles across clinics.

After ten minutes without human interaction, conceal patient/clinical content, block feature actions, stop sensitive subscriptions/background requests, and show a neutral unlock screen. Token refresh, polling, and realtime traffic must not reset the timer. On resume/refresh, check lock state before rendering sensitive data. Coordinate browser tabs so opening a tab cannot bypass the lock; mask mobile content when backgrounded. Manual lock/logout remain available.

Unlock verifies the same account through the auth service; do not invent a reusable local PIN or let another employee unlock as the previous user. Switching staff signs out the prior user and clears patient state before a new login. Revalidate roles and active clinic on unlock. Safe in-memory draft preservation needs a UI decision; do not persist unencrypted medical drafts to browser storage.

Supabase's session inactivity timeout tracks refresh activity and applies at refresh time. It is not a ten-minute human-inactivity lock. Session identity is available for backend checks. Therefore use separate application lock enforcement and an explicit session-lifetime policy. [Supabase sessions](https://supabase.com/docs/guides/auth/sessions).

Proposed backend boundary: maintain a server-controlled lock/unlock lease tied to the authenticated session, checked for sensitive data access. Only verified re-authentication can reopen a locked lease; ordinary background requests cannot. The later API/RLS design must cover direct data endpoints, file authorization, and subscriptions, so a lock screen is not the sole control. Client activity is a usability signal, not independent proof of human presence or protection against a stolen credential. Document these limits and test bypass attempts.

Use private, short-lived file authorization; signed URLs may remain usable until expiry and already downloaded data cannot be recalled. Prefer neutral realtime change notifications followed by authorized fetches for sensitive features. Web token persistence, cross-tab refresh coordination, lease behavior, and native secure storage require a concrete threat-reviewed design before implementation; do not assume browser storage has native keystore guarantees.

## Sensitive owner actions

Require successful recent re-authentication for owner-role grants, staff removal, refunds/corrections, security-setting changes, and bulk patient export if that feature exists. Proposed proof: short-lived, server-issued, single-use authorization bound to user, clinic, session, action, and target; suggested maximum lifetime five minutes, pending approval. A refreshed access token or a client-supplied timestamp is not proof of re-authentication.

Verify the credential/factor through the auth service, record the successful verification server-side, recheck current OWNER membership at execution, consume the authorization atomically, and audit the result. Preserve each action's own idempotency and business checks. Failed verification must not perform the action. Exact password/MFA challenge and recovery flows will be specified before coding; Supabase's password-change reauthentication nonce is not assumed to be a general business-action authorization mechanism. [Reauthentication API](https://supabase.com/docs/reference/javascript/auth-reauthenticate), [auth implementation reference](https://github.com/supabase/auth/blob/master/README.md).

Support owner MFA enrollment/challenge and recovery; strongly recommend an authenticator factor before production. Supabase exposes authenticator MFA and assurance levels for authorization. MFA enrollment/assurance does not by itself establish recent approval for a particular refund or staff removal. Define lost-factor recovery without shared accounts or a silent bypass. [Supabase MFA](https://supabase.com/docs/guides/auth/auth-mfa).

## Required later verification

- Recovery: measured database/file loss within the approved target and service usable within two hours; missing keys, object lag, and stale restored permissions are exercised.
- Lock: background token refresh does not prevent locking; stale tabs, deep links, app resume, and direct sensitive API requests cannot bypass the designed control.
- Re-authentication: stale/replayed/wrong-user/wrong-clinic/wrong-action proof is rejected; role revocation invalidates authority; a network retry does not repeat a refund.
- Privacy: no clinical information in auth/error logs, signed-URL logs, notifications, shared-device previews, or persistent draft caches.
- Environment separation: staging credentials cannot read production DB/files/backups, and production restore drills do not populate staging.

These are proposed checks, not tests already executed. This step changes documentation only.
