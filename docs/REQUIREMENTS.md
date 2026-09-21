# DentaFlow — Current requirements index

The [MASTER PRODUCT & ENGINEERING SPECIFICATION](MASTER_SPECIFICATION.md) is the authoritative product and engineering specification. It is copied verbatim from the user-provided document. Conflicting older instructions and derived summaries are superseded.

Current authorization: implement **Phase 0 only**, then stop. The master's explicit start instruction supersedes the older pre-implementation approval gate for this phase. It does not authorize Phase 1, paid infrastructure, or real patient data.

## Scope and policy

- Development/demo mode, USD 0 services, fictional patients exclusively.
- Flutter Web first; Android/iOS/tablet architecture retained.
- Supabase Free is the business backend and sole auth authority. Firebase is supplementary; no Firestore business data or parallel Firebase Auth.
- Production hosting, location/legal review, backups, and recovery are deferred. RPO 15 minutes/RTO 2 hours are future targets, not current guarantees.
- Phase 0: app/bootstrap, configuration, generated DI, routing, themes/localization, Supabase abstraction, Dio/error handling, lints/tests, GitHub Actions, documentation.
- Phase 1 login/session workflows, clinic tables, RLS policies, and business features are not Phase 0 deliverables. No connected backend or demo credentials are fabricated.

## Important changes from older decisions

| Topic | Master rule |
| --- | --- |
| Dentist schedule | Dentist may edit own working hours and leave; owner manages all schedules |
| Patient appointment overlap | Hard block, including for owners |
| Owner scheduling override | Dentist overlap, working hours, leave/unavailability only; explicit confirmation/reason/audit |
| Schedule changes | Owner may confirm affected future bookings remain flagged for manual resolution; no automatic moves/cancellations |
| Assistant appointments | Read-only plus operational/preparation notes; no major status changes or supervised start exception |
| Clinic selection | One clinic opens automatically; multiple clinics show selector |
| Unknown DOB | Nullable DOB plus exact/approximate/unknown precision; optional approximate age; guardian mandatory for known/explicit minors |
| Patient search | Include email alongside name, phone, and clinic patient number |
| Healthy tooth | Derived display state; never stored as an ordinary active condition |
| Missing tooth | Incompatible with active natural-tooth conditions including extraction required; an implant replacement can be represented separately |
| Incorrect clinical entry | Preserve entered_in_error record with error_reason, marked_in_error_by, marked_in_error_at |
| Invoice access | OWNER/DENTIST see clinical item detail; receptionist can print/export an already finalized authorized invoice without editing clinical contents |
| Overpayment | Preserve excess as patient/unapplied credit with audit history; do not block all overpayments as in the older proposal |
| Audit | Explicit sensitive access; appropriate summary list/search event includes count; exports include identifier; no per-result patient events |
| Navigation | Desktop explicitly includes Schedule |
| Delivery sequence | Master phases 0–15 are the current phase numbering |

Ambiguous medical/financial behavior must become a documented TODO for its relevant phase, not an invented rule. For example, invoice clinical-content approval versus financial status, overpayment allocation/refund behavior, and the full clinical compatibility matrix require review before their implementation.

## Supporting documents

- [Architecture](../ARCHITECTURE.md): implemented foundation and future feature boundaries.
- [Database](../DATABASE.md): no business migrations yet; future invariants.
- [Permissions](../PERMISSIONS.md): master-derived future permission rules, not deployed authorization.
- [Security](../SECURITY.md): current controls and limitations.
- [Production readiness](../PRODUCTION_READINESS.md): deferred real-data gate.
- [Infrastructure policy](HOSTING_DECISION.md): free-only policy, subject to the master's precedence.

The prior summary remains in [archive/REQUIREMENTS_PRE_MASTER.md](archive/REQUIREMENTS_PRE_MASTER.md) for history only. Its old business rules and approval instructions must not guide implementation.
