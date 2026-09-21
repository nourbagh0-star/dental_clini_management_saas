# DentaFlow — MVP Requirements

Status: requirements baseline APPROVED by the product owner in conversation, including Section 7's open items reserved for architecture/design resolution. Remaining conditional choices are not silently approved. Architecture, UI/UX, and implementation are not yet approved.

## 1. Authority and workflow

Source documents supplied by the product owner:

- Dental Clinic Management SaaS — Full Project Specification (66 sections).
- DentaFlow — Product Decisions & Clarifications (25 sections).
- DentaFlow — Additional Product Decisions (8 sections).
- Infrastructure, data location, recovery, and shared-device decisions (4 sections), supplied after baseline approval.
- Current infrastructure policy: free-tier-only development/MVP validation, fictional patient data, allowed Firebase auxiliary services, and deferred production decisions.

Precedence, highest first: Additional Product Decisions, Product Decisions & Clarifications, Full Project Specification. This document consolidates their requirements. Earlier assistant proposals are not approved merely because a later document does not mention them. The original specification remains applicable where not superseded.

The subsequent infrastructure decisions supplement the approved baseline and take precedence on their four topics. Architecture proposals implementing those requirements still require approval.

Historical note: this file is superseded by the [Master Specification](../MASTER_SPECIFICATION.md). The free-only policy supersedes earlier infrastructure spending/deployment proposals for development and MVP validation. See [current infrastructure policy](../HOSTING_DECISION.md). Production is a separate later stage; no paid service or real patient data is authorized now.

Work proceeds through requirements approval, architecture/API approval, UI/UX approval, and small implementation phases. Before each phase, resolve its outstanding requirements and present its scope. Do not write application code or migrations before the required approvals. Frontend implementation must follow approved screen designs.

## 2. Product and delivery scope

DentaFlow is a B2B, multi-tenant dental clinic management SaaS for owners, dentists, assistants, and receptionists. Patients are clinic-managed records and have no accounts in the MVP.

- Initial market: Russia; intended first release is a real clinic pilot.
- Development and early testing: fictional patients only.
- Real patient data: gated on review of security, access control, backups, audit logging, privacy, and applicable Russian legal requirements. This document asserts no regulatory compliance or hosting suitability.
- Pilot planning range: one clinic, 3–15 staff, 500–10,000 patients, 20–100 appointments daily.
- Future planning range: 100+ clinics, 20+ staff and 10,000+ patients per clinic, hundreds of thousands of patients overall. These are design targets, not verified capacity claims.
- One Flutter codebase; first release priority Web, followed by Android. Tablet workflows must be usable early. Maintain iOS support without making App Store release a pilot prerequisite.
- Planning target: approximately 8–12 weeks of consistent development; no fixed deadline or committed estimate yet.
- Current infrastructure budget: USD 0 for development and MVP validation. Supabase Free, Firebase no-cost/Spark services, free GitHub/Actions usage, local Flutter, and free Web hosting when needed. No paid plans/overages, backups, monitoring, domains, or CI/CD. The earlier USD 0–50 production target is historical; production budget and hosting will be decided later.
- No production infrastructure, provider, or region has been selected. Separate development, staging, and production from the beginning, with isolated projects/credentials where practical. Keep database and file-storage migration possible without a Flutter application rewrite.
- Pilot recovery targets: RPO 15 minutes (maximum target recent-data loss), RTO 2 hours (target time to restore core service). Require automated database backups, appropriately frequent recoverable changes/PITR, separate backup storage, monitoring, restore tests, and a recovery procedure. Patient files need separate recovery coverage. Establish a temporary manual appointment fallback.
- Staff use individual accounts even on shared computers; no generic reception, owner, or dentist account. Explicit logout and a 10-minute inactivity lock are required on Web/tablet/mobile. Unlock requires the current user's re-authentication; avoid unnecessary destruction of the underlying session.
- Sensitive owner actions require recent re-authentication: owner grants, staff removal, refunds/corrections, security changes, and large patient exports if implemented. Support MFA and strongly recommend it for owners before production. Clinic-network presence grants no trust.
- The recovery and real-data requirements above apply to a future production stage. Free MVP validation uses fictional data; paid recovery infrastructure and a production recovery guarantee are not current deliverables. Preserve logical environment separation without requiring a third hosted project or a paid plan.

## 3. Tenant and membership rules

- An account may belong to multiple clinics and have multiple roles independently within each clinic.
- Clinic data must be isolated in the backend, including files and realtime access. UI filtering alone is insufficient.
- Switching clinics refreshes feature data and removes access to stale data from the previously selected clinic.
- Roles are OWNER, DENTIST, ASSISTANT, and RECEPTIONIST. OWNER grants administrative authority; DENTIST grants clinical authority. Combined roles grant their respective capabilities within the same clinic.
- A clinic may have multiple owners. Existing owners may invite additional owners, including OWNER + DENTIST.
- Clinic creation is explicit. Its creator becomes OWNER and may also choose DENTIST.
- Invited staff sign up or log in and accept an invitation to join the existing clinic; they are not required to create a clinic.
- Owners invite staff, assign/remove roles, deactivate staff, and reactivate staff. Inactive membership must not grant clinic access.
- A clinic must never lose its last active owner through role removal, deactivation, departure, or another operation. Enforce this server-side, including concurrent operations.
- Invitations expire after seven days, are single-use, and may be revoked while pending. Resending an expired invitation creates a new invitation. Track pending/accepted/expired/revoked state and relevant author/timestamps. Prefer securely hashed tokens; never expose invitation secrets in logs or normal client reads.

## 4. Permission baseline

Each column describes a role alone. An additional role can add permissions. All permissions require active membership in the relevant clinic and backend enforcement.

| Capability | OWNER | DENTIST | ASSISTANT | RECEPTIONIST |
| --- | --- | --- | --- | --- |
| Read patient demographics | Yes | Yes | Yes | Yes |
| Create patients | Yes | Yes | Not explicitly granted | Yes |
| Edit demographic/contact information | Yes | Yes | Yes; basic/contact fields | Yes |
| Read clinical records and clinical files | Yes | Yes; all clinic patients | Yes | No |
| Make diagnoses or change tooth conditions | No | Yes | No | No |
| Author clinical treatment decisions | No | Yes | No | No |
| Prepare/edit draft session notes | No | Yes | Yes | No |
| Finalize clinical sessions, amend finalized notes, complete clinical procedures | No | Yes | No | No |
| Upload clinical files | Yes | Yes | Yes | No |
| Read appointment schedule | Yes | Yes | Yes | Yes |
| Create appointments | Yes | Yes; any clinic dentist, default to self | No | Yes |
| Confirm appointments | Yes | Not explicitly granted | No | Yes |
| Reschedule appointments | Yes | Own appointments | No | Yes |
| Cancel or mark no-show | Yes | Yes | No | Yes |
| Start appointments | Administrative boundary pending; no clinical finalization | Yes | Only under assigned dentist; enforcement design pending | No |
| Complete appointments | Administrative boundary pending; no clinical finalization | Yes | No | No |
| Add operational preparation notes | Administrative scope | Clinical scope | Yes | Administrative scope |
| Manage recurring working hours and breaks | Yes | No | No | No |
| Enter dentist leave/unavailability | Yes; manage staff entries | Own entries; audited, conflict rules apply | No | No |
| Override scheduling conflicts | Yes; warning, reason, audit required | No | No | No |
| See procedure prices and treatment estimates | Yes | Yes | No; relevant procedure names allowed | No clinical estimates; administrative financial totals only |
| Read invoices and balances; record payments | Yes | No automatic grant beyond estimates | No | Administrative financial view and payments |
| Export detailed invoice PDF | Yes | Optional, associated treatment only; decision pending | No | No |
| Provide simple payment receipt | Yes | Not explicitly granted | No | Yes |
| Manage procedure prices and financial settings | Yes | No | No | No |
| Apply discounts, refund or correct payments | Yes | No | No | No |
| Archive/restore patients | Yes | No | No | No |
| Manage staff and clinic settings | Yes | No | No | No |
| Read security audit logs | Yes | No | No | No |

A capability not explicitly granted must not be enabled by assumption. Conditional permissions require a concrete design and approval before implementation. Clinical restrictions also apply to medical history and any clinical information embedded in notes, appointment text, financial records, notifications, search results, or activity feeds.

Receptionists may see demographics, schedules, assigned dentists, appointment statuses, invoice totals, payments, balances, and limited administrative treatment indicators such as whether a plan is active. They must not read clinical treatment details, diagnoses, chart data, medical notes, session notes, X-rays, or clinical photos.

Assistants may add chairside observations, operational preparation notes, and non-diagnostic support information. They may help start an appointment only when working under its assigned dentist. Check-in is permitted if that optional workflow is implemented. They cannot independently diagnose, prescribe, alter tooth conditions, approve/finalize plans, complete appointments/procedures, or overwrite finalized records. Assistants may see relevant procedure names but not treatment estimates, balances, invoices, payments, revenue, or financial reports. A financial-ready indicator is optional, not an automatic grant of financial access.

## 5. Functional requirements

### Authentication and onboarding

- Register, login, logout, forgot password, reset password, and session restoration.
- Protected routes require authentication; clinic pages additionally require an active authorized clinic.
- Support explicit clinic creation, optional owner/dentist role selection, invitation acceptance, clinic selection, and restoration of the previously selected authorized clinic.
- Do not expose privileged backend credentials to the application.

### Patients

- Create, list, search, edit, view, archive, and restore according to role permissions.
- Required: first name, last name, and a usable contact method: patient phone/email or guardian phone/email. Address alone is insufficient. Any exception to the source's wording "normally" requires an explicit approved rule; no bypass is currently defined.
- Optional: middle name, birth date, gender, email, address, emergency contact name/phone, and notes.
- Support children from the beginning. For patients under 18, guardian details are normally required: full name, relationship (mother/father/legal_guardian/other), and phone or email. One primary guardian is sufficient for MVP; allow future multiple guardians. No exception workflow has been approved.
- Exact date of birth is nullable and must not block registration. Support an approximate-age representation, such as birth year with an estimated-age indicator; never fabricate a birth date. Calculate age/minor status from exact DOB when present. When only estimated information is available, allow staff to explicitly identify minor status. Exact DOB can replace estimates later. Selection of the representation and unknown-age validation belongs to design approval.
- Include allergies, current medications, chronic conditions, and important medical notes as protected clinical information. Clinical decisions require DENTIST; any assistant contribution must stay within approved draft/support boundaries.
- Generate a patient number unique within the clinic, such as PAT-00001.
- Search by name, phone, and patient number with debounce and pagination.
- Patient header: name, age when birth date is available, phone/contact, patient number, previous appointment, and next appointment.
- Patient workspace includes overview, appointments, dental chart, treatment plans, visits/clinical sessions, files, billing, and role-filtered activity. Final tab names/order belong to UI/UX approval; visits must remain accessible.
- Only owners archive and restore patients. Normal UI never permanently deletes patient records.

### Doctor schedules and appointments

- Basic working days/hours, recurring schedules, breaks, leave, and unavailable periods. Owners configure scheduling rules and may edit/remove staff schedule entries. Dentists may enter their own leave directly, with auditing; no leave approval workflow in MVP. Receptionists and assistants have read-only availability access.
- Dentists may create appointments for any dentist within the clinic, defaulting to themselves, and may reschedule their own appointments. Assistant operations remain limited as defined in the permission matrix.
- Calendar views: day, week, list. Month view is deferred.
- Appointments include patient, dentist, start/end, status, reason, and notes. Classification of free-text reason/notes must preserve clinical confidentiality.
- Statuses: scheduled, confirmed, in_progress, completed, cancelled, no_show. Exact permitted transitions require approval.
- Validate end after start, dentist conflicts, patient conflicts, working hours, and leave/unavailability.
- Conflicts are blocked by default. Only an owner may override dentist overlap, patient overlap, outside-hours booking, or dentist leave/unavailability. Require a strong warning, explicit confirmation, reason, actor, timestamp, conflict type, and audit event.
- Changes to working hours, breaks, or leave must show affected appointments and a blocking warning before saving. Offer cancel-change and review-appointments actions; never automatically move/delete bookings. Conflicting leave cannot be saved until affected appointments are manually resolved or an owner explicitly overrides. The same principle protects existing bookings during schedule edits.
- Owner override does not grant cross-clinic access or authority to perform clinical actions.
- Recheck conflicts during concurrent booking and rescheduling; simultaneous submissions must not silently bypass the rule.
- Appointment completion and clinical finalization are distinct. Completion does not require a procedure to have occurred.
- If a clinical session exists, completion requires finalization or an explicit valid empty/no-treatment state. Never manufacture clinical notes.
- Chairs/rooms and complex resource scheduling are deferred.

### Odontogram and clinical records

- Interactive FDI adult chart, tooth detail, history, and entry points for diagnosis and treatment.
- Adult chart teeth: 11–18, 21–28, 31–38, 41–48. Domain/database support for primary teeth 51–55, 61–65, 71–75, 81–85 is required from the beginning. Primary graphical chart deferral requires pilot-clinic agreement. Until then, primary-tooth information must be recordable in clinical notes or a simple structured tooth-number field as needed. If the clinic treats many children, include the primary graphical chart before production use.
- Support multiple simultaneous conditions per tooth; a single status enum for the tooth is insufficient.
- Conditions include healthy, caries, filling, crown, missing, implant, root canal, fracture, extraction required, and other. The newer rules also reference recurrent caries; the exact clinical terminology/mapping requires design review.
- Healthy cannot coexist with an active pathological condition. Adding a pathological condition automatically resolves the active healthy state while preserving its history. Marking a tooth healthy requires explicit resolution of incompatible active conditions first.
- Missing cannot coexist with active caries, fracture, filling, crown, or root-canal conditions on that absent natural tooth. Preserve historical records. Keep natural-tooth state distinguishable from implant/prosthetic replacement so later separation does not require a fundamental redesign. The complete compatibility matrix must be reviewed; do not invent further clinical rules.
- Approved compatible examples: caries + fracture, filling + recurrent caries, root canal + crown. Findings may differ by surface.
- Record tooth/surface, condition, notes, author/time, active/resolved/entered_in_error state, and resolution author/time.
- Supported initial surfaces: whole, mesial, distal, occlusal, buccal, lingual.
- Only dentists make clinical condition changes or explicitly resolve conditions, with the specified healthy-state transition above. Completing treatment must not delete conditions or their history.
- Only dentists may mark an erroneous entry entered_in_error, recording correction author, timestamp, and reason, then create a correct entry. Show the erroneous entry in history but exclude it from current odontogram state. Do not hard-delete it.
- Clinical edits remain attributable and historical clinical information remains auditable.
- Notes have draft/finalized states. Assistants may prepare drafts; dentists finalize.
- Finalized content is immutable through normal client operations. Corrections use amendments with original reference, text, reason, author, and timestamp.
- No medical AI or automated clinical decision-making.

### Procedures, treatments, and visits

- Clinic owners manage a customizable procedure catalog with category, price, duration, and active state.
- Dentists can view prices and discuss treatment estimates with patients.
- Treatment plans support draft, active, completed, cancelled states.
- Items support planned, approved, in_progress, completed, cancelled states and capture procedure, optional tooth, description, estimate, assigned dentist, and ordering.
- Dentists author clinical plans and mark procedures medically completed; administrative ownership alone cannot do so.
- Clinical sessions may optionally link to an appointment and attach completed treatment items.
- Assistants may prepare draft notes/support information; dentists retain clinical approval authority.

### Patient files

- Support JPG/JPEG, PNG, and PDF, with a 15 MB per-file target limit. Validate size, MIME type, and extension.
- Categories: X-ray, photo, document, other. Clinical access restrictions apply regardless of a user-selected category.
- Store files privately with clinic and patient association and randomized path elements.
- Secure access must protect both clinic boundaries and role restrictions within a clinic.
- Normally archive rather than permanently delete files. Archive/restore authority remains pending.
- DICOM and HEIC are deferred.

### Billing and payments

- Patient-facing internal clinic invoices; no claim of statutory accounting or fiscal-receipt compliance.
- Invoice number, patient, procedure line items, quantity, unit price, line totals, subtotal, fixed/percentage discount, total, paid amount, balance, and status.
- Invoice states: draft, unpaid, partially_paid, paid, cancelled.
- Owners control prices, discounts, financial settings, refunds, and corrections.
- Receptionists may see invoice number, patient identity, totals, paid/outstanding amounts, status, and payment method/history; record payments; and provide a simple payment receipt. Detailed clinical procedure descriptions and tooth identifiers must not be exposed. Use a non-clinical description such as "Treatment charge" where appropriate. They may not manipulate prices/totals, apply discounts, delete payments, or issue refunds.
- Owners see full invoice items and export detailed patient invoices. Dentist detailed-PDF access is optional and limited to associated treatment if approved; treatment estimate access does not grant general accounting access.
- Each clinic has one default currency, initially RUB for the Russian pilot. Store the currency on each invoice independently of later clinic-setting changes. No mixed currencies within one invoice.
- Discounts are invoice-level fixed amount or percentage, owner-only. Store discount type/value/reason and authorizing owner. Line-item discounts are deferred.
- Minimal tax support: invoice tax rate/amount and an optional clinic default. No full Russian fiscal/accounting implementation. Exact calculation and rounding rules must be approved in design.
- Payment methods: cash, card, bank transfer, other. Card entries are manual records; no payment-provider integration.
- Partial payments and outstanding balances must work correctly.
- Completed payments are not hard-deleted or silently edited. Refunds are separate transactions referencing the original payment, with amount, reason, author, and timestamp. The model must support partial refunds. Corrections use a reversal or correction transaction followed by the correct payment, with auditing.
- Preferred MVP behavior is to block payments exceeding the outstanding balance, including owner submissions until patient-credit functionality exists. Intentional owner-accepted overpayment and patient credits are deferred; never silently inflate invoice totals.
- Exact decimal money handling throughout the application and database; do not use floating-point financial calculations.
- Basic invoice PDF export is mandatory for the real pilot. Minimum: clinic name/contact, invoice number/date, patient name, items, quantities, unit prices, total, discount, paid amount, balance, and currency. Keep export design reusable; advanced branding and fiscal-document requirements are outside MVP pending review.

### Dashboard, activity, and administration

- Dashboard: today's/upcoming appointments, patient count, appointments this week, completed treatments, and outstanding payments, subject to the viewer's permissions.
- Owner dashboard must reflect the active clinic only. Aggregate information must not bypass role restrictions.
- Staff management displays independent role badges and supports invitation and membership administration.
- Patient Activity is role-filtered: owner full activity; dentist clinical/operational activity; assistant relevant clinical support; receptionist administrative activity only.
- Security Audit Logs are owner-only and append-only from normal clients. Audit explicit patient profile, clinical record, odontogram, file view/download, and export access; one profile-open event, not one event per displayed field.
- Do not emit an event per patient returned by ordinary lists/search. Summary search auditing is optional; do not store results or unnecessary sensitive search text in metadata.
- Every implemented export records actor, type, time, clinic, record count, relevant scope/filter, and success/failure without exported medical content. This audit rule does not itself add patient bulk export or patient PDF features to MVP.
- Audit file upload, meaningful view/access, download, archive, and replacement/correction. For temporary signed URLs, record access authorization/URL issuance rather than every browser network request.
- Always audit diagnosis changes, odontogram changes, clinical finalization/amendments, treatment-plan changes, condition resolution, and entries marked erroneous.
- Always audit invitations/revocations, role assignment/removal, staff deactivation, owner overrides, patient archive/restore, financial corrections/refunds, clinic-setting changes, and dentist-entered leave.
- Audit history must support high volume, relevant clinic/user/entity/time filtering, indexes, and pagination. Never load the entire history or permit ordinary-client update/delete.
- Audit metadata must not contain complete medical records or expose clinical details through administrative activity.

## 6. Experience and engineering constraints

- Flutter/Dart; feature-first Clean Architecture, repositories/data sources, separate DTOs and domain entities.
- Bloc/Cubit, Freezed/json_serializable, GoRouter, GetIt/Injectable, Dio, Supabase Flutter, secure storage when needed, localization support, and consistent error handling.
- Supabase/PostgreSQL, Auth, Storage, Realtime, and Edge Functions. Hosting topology and operational details are not yet selected.
- During free MVP validation, use Supabase Free for those backend services, including Edge Functions only within its allowance. Firebase FCM, Analytics, and Crashlytics are allowed auxiliary services; Remote Config only if needed. Integrate via replaceable adapters, with platform capability checks and non-sensitive payloads. Firebase does not replace Supabase business data/auth/storage. Concrete notification scope remains separately approved.
- No database access from widgets, business logic in widgets, client service-role keys, hardcoded tenant IDs, or disabled/weakened RLS.
- Tenant-owned data must have enforceable clinic association. Validate cross-record associations as well as direct access.
- Paginate large lists and index frequent filters/searches. Subscribe only to relevant active-clinic realtime data and clean subscriptions up.
- No unencrypted persistent medical-record caching or offline synchronization in MVP. Local preferences may include theme, locale, and active clinic ID.
- Typed failures and friendly errors; initial/loading/loaded/empty/error states as applicable, inline validation, duplicate-submission protection, and safe session recovery.
- Responsive Web/mobile/tablet layouts, desktop sidebar, mobile Dashboard/Patients/Appointments/More navigation, accessible controls, light/dark themes.
- English and Russian initially; prepare for later Arabic/RTL. Centralized theme and localized strings.
- UI/UX must specify every workflow, including auth/recovery, onboarding/clinic switching, dashboard, patient list/profile, calendar, appointment form/detail, doctor schedule, odontogram, treatments/sessions, files, staff/invitations, billing, activity/audit, and settings.
- Unit, widget, integration, and backend authorization tests; formatting, static analysis, and tests must pass. CI fails on failures.
- Small focused changes, conventional commits where appropriate, and the requested main/develop/feature branch workflow once repository setup is approved.
- Documentation must cover architecture, database, security, setup/environment configuration, demo-only credentials, screenshots, feature list, and portfolio narrative. Never commit production secrets.

## 7. Resolved decisions and remaining design review

The Additional Product Decisions resolves the eight previous question areas: principal staff permissions, financial confidentiality, schedule-change conflicts, contacts/guardians, billing scope, clinical history rules, ownership/invitations, and access-audit granularity. Their authoritative rules are incorporated above. The previous assistant proposals are superseded, not blanket-approved.

The requirements are ready for baseline review. Approval of this baseline does not silently choose the following conditional options or fill unspecified business rules. Resolve them with the product owner at the start of the relevant design step, then include the concrete result in architecture/UI approval before dependent implementation:

| Review item | Known requirement | Choice or evidence still needed |
| --- | --- | --- |
| Assistant supervision | Assistant may help start an appointment under its assigned dentist | How the assigned dentist authorizes that assistant and how long authorization lasts; no broad independent start permission |
| Optional capabilities | Check-in, assistant financial-ready indicator, and treatment-associated dentist invoice PDFs are optional | Explicit inclusion/exclusion; who qualifies as associated with treatment if PDF access is enabled |
| Unspecified permission edges | Least privilege and existing grants remain authoritative | File archive/restore roles, dentist appointment confirmation, OWNER-only start/complete boundaries, and any ungranted assistant patient-creation access |
| Patient registration exceptions | A contact and guardian for under-18s are normally required; exact DOB is optional | Whether exceptions exist, treatment of wholly unknown age/minor status, and contact-sharing/duplicate handling |
| Financial calculations/lifecycle | Decimal arithmetic, clinic/invoice currency, invoice discounts, minimal tax, separate refunds/corrections, no MVP overpayment | Tax inclusion/order, rounding/precision, quantity rules, refund limits and effect on debt, invoice issue/cancel/edit rules, and treatment-to-invoice creation workflow |
| Appointment/session transitions | Six appointment statuses; own-only dentist rescheduling; explicit no-treatment state when needed | Exact state transition/actor matrix, temporal slot boundaries, assigned-versus-covering dentist actions, and required no-treatment fields |
| Clinical compatibility | Healthy/pathology exclusion, specified missing exclusions, compatible examples, entered-in-error history | Review remaining condition combinations, implant representation, recurrent-caries terminology, and the workflow for marking a tooth missing with incompatible active findings; no invented medical rules |
| Primary graphical chart | Primary tooth numbers supported immediately; children have full other workflows | Pilot clinic agreement to defer visualization, or promote it into MVP when pediatric use requires it |
| Deployment and operations | Free-only fictional-data development/MVP validation; logical environment separation; 10-minute lock and sensitive-owner re-authentication remain; production deferred | Free project allocation, supported telemetry, free email delivery, and detailed session enforcement. Production hosting, legal/data-location review, backup/recovery, operations, and budget will be decided later. See current infrastructure policy. |

These items need not restart requirements discovery. They are explicit boundaries for the approved baseline and targeted questions for the next relevant phase. No dependent implementation should proceed with an unresolved rule disguised as a default.

## 8. Acceptance and release gates

The functional/security criteria below apply to fictional-data MVP validation. Production-specific criteria 12, 14's clinic graphical-chart decision, and 17 are deferred real-data launch gates, not claims about free-tier infrastructure. All must be addressed before a real-data pilot:

1. An owner registers, explicitly creates a clinic, chooses DENTIST as an additional role, and invites a receptionist who joins without creating another clinic.
2. Receptionist creates a patient, books within the dentist schedule, and records payment without gaining clinical access.
3. Dentist reviews medical information, records multiple tooth conditions, creates a treatment plan, records performed treatment, and finalizes a session; an assistant can prepare a draft but cannot finalize it.
4. Finalized clinical text remains intact after an amendment; resolved/corrected tooth records retain history. Entered-in-error entries do not affect the current chart. Healthy/pathological and missing-tooth exclusivity rules hold without deleting historical records.
5. Appointment and patient conflicts are enforced under concurrent requests; all four authorized owner override types require warning, confirmation, reason, actor, time, conflict type, and audit history. Schedule/leave changes identify affected appointments and block unresolved conflicts except through authorized override; no bookings silently move or disappear.
6. Partial payment balances are exact; duplicate submissions cannot create duplicate payments; corrections/refunds retain history and require owner authority. Overpayments are blocked for MVP. Historical invoice currency is preserved. Owners can export the required basic invoice PDF; receptionists can provide a simple receipt without clinical line-item access.
7. Clinic A users cannot read or modify Clinic B data, link records across clinic boundaries, retrieve files, or receive unauthorized realtime data, including through direct backend requests.
8. OWNER-only cannot write clinical decisions; DENTIST-only cannot administer staff; RECEPTIONIST cannot retrieve clinical records/files; ASSISTANT cannot finalize treatment. OWNER + DENTIST can exercise both approved role sets.
9. Deactivation, role changes, logout, and clinic switching remove inappropriate access, including stale screen data and subscriptions.
10. Record lists are paginated; relevant role-aware empty/error/loading states work; Russian/English, themes, and primary responsive workflows are verified.
11. Formatting, analysis, relevant automated tests, and RLS/security checks pass. Required documentation is available.
12. Hosting/privacy/legal review, backup restore verification, approved operational requirements, and readiness approval occur before real patient data is introduced.
13. No operation, including concurrent membership changes, can leave a clinic without an active owner. Revoked, expired, or already accepted invitations cannot be reused; expiration/resend behavior follows the seven-day single-use rule.
14. A child can be registered with approved guardian/contact information even without exact DOB; no fake DOB is generated. Primary tooth numbers are accepted by the domain and relevant recording workflow. Graphical-chart deferral has pilot-clinic agreement or the chart is included before production use.
15. Explicit sensitive opens, file authorizations, clinical/admin writes, and export outcomes produce the required audit events. Ordinary search/list results do not produce per-patient access events. Clients cannot edit/delete audit history or use its metadata to bypass clinical restrictions.
16. Dentist leave entry is audited; receptionists/assistants cannot manage availability. A dentist cannot reschedule another dentist's appointment through direct backend calls. Assistants cannot independently start or complete appointments or retrieve financial estimates hidden from their role.
17. Recovery exercises demonstrate at most 15 minutes of lost critical changes and core service restored within 2 hours for the agreed failure scenarios, with separate file recovery verified. A backup job's success status alone is insufficient evidence.
18. After 10 minutes without user activity, patient/clinical information is locked on all target device types; background refresh is not user activity. Unlock verifies the current user. Sensitive owner actions reject stale authentication, and staff changes remain attributable to individual accounts.

Security, validation, audit events, and relevant tests are required by each feature's acceptance criteria. The original phase list places additional hardening late; the architecture proposal must reconcile that ordering so acceptance requirements hold when each feature is delivered.

## 9. Deferred scope

Patient accounts/app/self-booking, AI diagnosis, insurance, branches, subscriptions, acquiring/payment-provider integrations, advanced accounting, prescriptions, inventory, video consultations, WhatsApp, complex offline synchronization, patient credits/overpayments, line-item discounts, leave approval workflows, DICOM/HEIC, month calendar, advanced reporting, and staff/patient notification features beyond required authentication and invitation delivery are outside the first MVP. Primary-teeth visualization is only conditionally deferred as described above; primary tooth-number support is required now.

## 10. Next review

The product owner has approved this consolidated requirements baseline with its explicit design-review items. Before the architecture phase, ask the targeted questions needed for the next design step. Then prepare the technical architecture and API design without implementation: component boundaries, data model, permission enforcement, concurrency and money rules, hosting/security/backup choices, testing strategy, delivery phases, and operational decisions. Submit the completed design for approval before code or migrations, followed by the required UI/UX approval before frontend implementation.

First architecture review step: hosting/data location, backups/recovery, and access-security constraints. Requirements approval does not authorize introducing real patient data or deploying infrastructure.

Update after free-only policy: current infrastructure scope is settled by the user. Continue architecture review for application boundaries, database/permissions/API, and free-compatible integrations; defer production procurement, legal decisions, and operational recovery selection. Do not re-request approval of the user's explicit no-spend policy.
