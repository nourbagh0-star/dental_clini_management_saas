# DentaFlow architecture

The [master specification](docs/MASTER_SPECIFICATION.md) governs this project.
The repository now implements the local MVP through Phase 15 responsive polish
and the complete authenticated integration workflow;
the phase architecture records under `docs/` describe each approved increment.

## Composition and startup

`main` initializes Flutter, validates `AppConfig`, creates an isolated GetIt container, restores non-sensitive appearance preferences, restores an Auth session when configured, constructs GoRouter, and renders `DentaFlowApp`. A localized startup-error page handles invalid configuration; preference failures keep the preview usable with a visible warning.

AppConfig is registered explicitly after validation. Injectable generates the rest of the graph. The container owns singleton disposal; `AppRuntime.dispose()` owns the router and appearance Cubit. Supabase's SDK client is created lazily only inside the data-layer connection. There is no global Supabase initialization, network health assertion, persisted auth, or placeholder sign-in during Phase 0.

## Authentication boundary

`features/auth` exposes safe identity/state types and an `AuthRepository` contract. The Supabase adapter owns provider objects, password calls, OTP verification, session mutation, and error translation. The UI receives no provider User/Session objects or raw exception text.

`SessionCoordinator` serializes restore/login/logout/refresh operations and controls the application token boundary. It starts a restored session locked, locks after ten minutes without pointer/keyboard/touch activity, masks on app background, and broadcasts only `lock`/`logout` messages between Web tabs. A password-recovery session is never persisted or supplied to Dio. Native storage uses the secure-storage adapter; Web uses tab session storage. This is a shared-device privacy control, not server-side clinical authorization.

## Feature boundaries

Business features use presentation → Bloc/Cubit → use case where useful → domain repository → data repository → data source. DTO mapping stays in data. Widgets and Cubits never become database clients. Phase 0 application appearance preferences are composition-level state, not a business feature or database DTO.

Implemented modules include auth, clinics, staff, schedules, patients,
appointments, odontogram history, treatment plans, clinical sessions, private
patient files, billing, the active-clinic dashboard, and security audit logs. Billing uses an exact `Money` domain value,
service-only mutation commands, an immutable financial ledger, private invoice
documents, and repository adapters that keep Supabase types out of Flutter's
domain and presentation layers. The Dashboard uses one authenticated safe GET
and a service-only database snapshot to calculate clinic-time-zone periods,
bounded appointment previews, active-patient counts, treatment completions,
and exact outstanding balances. Server-derived capabilities omit unauthorized
metric groups before they reach Flutter. The Audit feature records approved
sensitive opens before displaying content, reads bounded Owner-only keyset
pages, and keeps provider JSON out of presentation. Patient, appointment, and
staff commands add their business audit event in the same transaction.
The adaptive workspace shell provides role-aware desktop, tablet, and mobile
navigation. Settings uses existing client-side appearance, language, clinic
switch, privacy lock, and sign-out boundaries. Reporting, notifications, and
production settings remain later phases.

The public route `/` is a demo shell. Configured builds provide auth routes for
login, registration, email verification, recovery, lock, and account-ready.
Router redirects deny direct access to protected routes while signed out or
locked. Unknown paths render a neutral unavailable page without echoing route
parameters. Signed-in clinic routes share the adaptive workspace shell;
role-filtered navigation complements existing route guards and authoritative
server permissions.

## Data and transport

Supabase is the development business/auth source of truth. `SupabaseConnection` contains the SDK; `SessionTokenProvider` is the narrow interface needed by Dio. Feature data sources inject the connection while presentation remains provider-independent. Versioned PostgreSQL migrations, RLS, explicit grants, protected commands, and private Storage policies implement the boundaries summarized in [DATABASE.md](DATABASE.md) and [PERMISSIONS.md](PERMISSIONS.md).

`DioClient` is specifically an Edge Functions transport. It refuses unconfigured/foreign-origin/non-function requests before dispatch, strips caller-supplied credential headers, attaches the configured public key, and attaches a session bearer only when the data source marks authentication required. Redirects are disabled. Parallel expired-token read requests share a refresh; safe reads retry once. Mutations never auto-retry. Billing commands use client command UUIDs and database receipts so an explicit retry cannot create a second financial effect.

ErrorInterceptor maps transport/status errors to typed safe failures. Presentation uses the localized failure mapper and never raw Dio/Supabase error bodies. Cancellation and unknown errors currently map to UnknownFailure; features may refine cancellation UX later. Debug HTTP logs contain only response status. Firebase telemetry must be separately scrubbed and must never replace clinic audit events.

## Local state, appearance, and portability

Only theme/language JSON is persisted, behind PreferencesStore. Freezed produces immutable appearance state and JSON serialization; it is not a medical cache. Preferences use system settings by default with explicit English/Russian/Arabic and light/dark options. Material themes centralize colors/spacing; layout uses bounded widths, scrolling, and directional alignment, including right-to-left Arabic.

Config uses development/staging with optional public Supabase settings. Production remains blocked. Firebase/data/files/realtime services must remain replaceable adapters; stable domain IDs and logical object keys preserve feature code when infrastructure migrates. Provider replacement still entails backend/auth migration and adapter tests.

Generated source is included alongside handwritten source and must be committed when this workspace is placed under Git. The CI workflow regenerates it and checks for drift. Direct dependencies and Flutter version are pinned. No paid service or backend project is provisioned by this phase.
