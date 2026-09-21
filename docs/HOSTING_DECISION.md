# DentaFlow — Current infrastructure policy

Status: free-development policy retained under the authoritative [Master Specification](MASTER_SPECIFICATION.md). The master authorizes Phase 0 implementation; earlier approval restrictions below do not block that phase. Deployment and production remain deferred. Sources checked 2026-09-06.

## Binding constraints

- USD 0 service spend during development and MVP validation. Supabase Free only; Firebase Spark/no-cost services only. No paid plans, hosting, backups, monitoring, domains, CI/CD, paid runners, or paid overages. A paid plan with trial credits or free allowances does not satisfy this rule.
- Use fictional/demo patient data exclusively. A validated demo is not approval for a real-data pilot.
- Production hosting, budget, data residency, legal review, backups, and recovery are deferred. Earlier research is retained in [production hosting research](PRODUCTION_HOSTING_RESEARCH.md), not an active recommendation.
- Preserve production-oriented architecture, tenant isolation/RLS, independent staff accounts, clinical/financial permissions, validation, auditing, tests, and secret handling. Free infrastructure does not relax these requirements.
- Phase 0 implementation is authorized by the master. This policy does not independently approve later phases or deployment.

## Service responsibilities

| Area | Current allowed service and scope |
| --- | --- |
| Primary backend | Supabase Free PostgreSQL, Auth, Storage, Realtime; Edge Functions within free limits |
| Push transport | Firebase Cloud Messaging; concrete notification workflows remain subject to MVP scope approval |
| Usage analytics | Firebase Analytics with a reviewed, non-sensitive event schema |
| Crash reporting | Firebase Crashlytics on supported platforms, with redacted payloads |
| Remote configuration | Only if a concrete need is approved; never an authority for roles, tenant access, financial rules, or clinical decisions |
| Source and CI | GitHub and GitHub Actions within included free usage; local Flutter validation |
| Web validation hosting | A free static host when needed; proposed candidate: classic Firebase Hosting on Spark with its provided domain, not Firebase App Hosting |
| Development recovery | Reproducible migrations and fictional seeds; optional local DB exports and demo-file copies. No paid backup product or production recovery promise |

Supabase remains the business database/auth/file authority. Firebase telemetry and push are auxiliary services; this policy does not add Firebase Auth, Firestore, Firebase Storage, or Cloud Functions to the architecture. FCM availability does not approve patient accounts or patient notifications, or promote the previously deferred staff-notification feature by itself.

## Free-tier constraints relevant to design

Supabase currently advertises two active free projects, 500 MB database capacity, 1 GB files, 5 GB egress plus 5 GB cached egress, 200 peak realtime connections, two million monthly realtime messages, and 500,000 Edge Function invocations. Projects may pause after a week without activity. Automatic backups, PITR, and managed session-timeout controls are excluded; basic MFA is included. These are vendor allowances, not DentaFlow performance guarantees. Confirm quota scope in the account before provisioning. [Supabase pricing](https://supabase.com/pricing).

Proposed arrangement: separate Free projects for shared development and staging if the account allowance is available; local Supabase for isolated tests/seed resets. Keep production configuration logically separate but unprovisioned. Do not create extra accounts to evade quotas. If resources are unavailable, use local validation until an authorized free arrangement is available.

Maintain small demo datasets and synthetic image/PDF fixtures. Preserve the 15 MB application upload rule, while keeping routine fixtures much smaller. Audit tables, indexes, and fixtures count toward available capacity. Use scoped realtime subscriptions, debounced search, pagination, bounded retries, and on-demand file access. No artificial keep-alive jobs to prevent project pausing. Reaching a limit means reducing workload, local testing, waiting for reset, or transparently reporting restricted functionality—not upgrading or weakening controls.

Firebase lists Analytics, FCM, and Crashlytics as no-cost services. Remote Config remains optional and quota-limited. Keep the project on Spark; do not enable Blaze or a billing-dependent service to access its advertised free allowance. [Firebase pricing](https://firebase.google.com/pricing).

The official Flutter Crashlytics plugin supports Android/iOS/macOS, not Web. Define a crash-reporting interface with native Crashlytics and sanitized local diagnostics on Web initially; do not promise a Web Crashlytics dashboard or silently introduce a paid replacement. [Official Crashlytics plugin](https://pub.dev/packages/firebase_crashlytics).

Classic Firebase Hosting provides no-cost storage/transfer subject to limits and may block deployments or suspend serving when exhausted on Spark. Its current Hosting guide and general pricing table express transfer allowances differently; recheck the effective console quota before deployment instead of promising capacity. Use the supplied domain and local Flutter Web while hosted validation is unnecessary. [Hosting quotas](https://firebase.google.com/docs/hosting/usage-quotas-pricing), [Firebase pricing](https://firebase.google.com/pricing).

GitHub Free currently includes 2,000 monthly Actions minutes and 500 MB artifact storage for private repositories; standard runners in public repositories have different free treatment. Larger runners are paid. Prefer standard Linux jobs, short artifact retention, cancellation of superseded runs, and local checks. Keep paid overage spending blocked; a budget alert alone is not a spending cap. Repository visibility is a separate user decision. [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

## Authentication, email, and telemetry boundaries

- The ten-minute application inactivity lock and sensitive-owner re-authentication remain requirements. Design their application/backend enforcement using available primitives; do not depend on a paid Supabase session-timeout setting. Provider automatic token refresh is not user activity. Exact proof and session design still need architecture approval.
- Supabase's default email sender currently limits delivery to authorized project-team addresses and roughly two messages per hour. Use local email capture for automated auth/invitation tests. External demo invitations/reset emails require a verified free sender setup or an explicitly approved alternative delivery workflow. Do not give clinic testers infrastructure-admin membership to work around email restrictions, disable verification, or claim arbitrary external email delivery works before testing. No paid sender/domain is assumed. [Supabase email restrictions](https://supabase.com/docs/guides/auth/auth-smtp).
- Keep patient names, contacts, notes, diagnoses, file URLs, invoice details, tokens, and free-text inputs out of Analytics, Crashlytics, and push payloads. Scrub errors/breadcrumbs and parameterized routes. Even with demo patients, employee accounts and device identifiers need careful handling. Collection controls, event schema, and FCM token lifecycle are later design items.
- Telemetry is not the immutable clinic audit trail; required domain audit records remain in the authorized backend. Core clinical workflows must not depend on Analytics or Remote Config availability. Remote Config must have safe local defaults if introduced.

## Portability and deferred production work

Keep repository interfaces and domain types independent of provider SDKs. Encapsulate Supabase auth/data/files/realtime and Firebase notifications/analytics/crash/config behind data/service adapters. Use environment-specific endpoints, stable UUIDs and object keys, versioned migrations, and exportable configuration. Do not persist expiring file URLs as record identity.

Changing a compatible deployment may need configuration only; replacing backend/auth/storage services can require new adapters, backend integration, and migration tests. The goal is preserving Flutter screens and domain workflows, not promising a zero-work provider switch.

RPO 15 minutes/RTO 2 hours remain earlier production targets for later review; they are neither guaranteed nor a free-demo acceptance gate. Retain the [recovery/security proposal](RECOVERY_AND_ACCESS_SECURITY.md) and [legal review questions](RUSSIAN_PRIVACY_REVIEW.md) for that stage. No real patient data until the future production decisions and readiness review are complete.
