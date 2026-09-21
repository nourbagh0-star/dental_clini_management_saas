# DentaFlow — MASTER PRODUCT & ENGINEERING SPECIFICATION

Treat this document as the authoritative specification for the project.

If an older instruction conflicts with this document, follow this document.

Do NOT implement the whole system at once.

Work phase by phase and keep the project compiling, analyzed and tested after every phase.

==================================================
1. PRODUCT OVERVIEW
==================================================

Project name:

DentaFlow

Product:

B2B Dental Clinic Management SaaS.

The application is for:

- Clinic Owners
- Dentists
- Assistants
- Receptionists

Patients DO NOT have user accounts in the MVP.

Patients exist only as records managed by clinic staff.

The product is intended to eventually become a real commercial SaaS.

A real dental clinic is potentially available as the first pilot clinic.

However, the CURRENT development phase must use fictional/demo patient data only.

No real patient medical data should be entered until the Production Readiness Gate described later is completed.

==================================================
2. CURRENT DEVELOPMENT MODE
==================================================

CURRENT MODE:

DEVELOPMENT / DEMO

Infrastructure budget:

$0

Use only free-tier services and free development tools.

Do NOT provision:

- paid Supabase
- paid Firebase
- paid hosting
- paid backups
- paid monitoring
- paid domains
- paid CI/CD
- any paid infrastructure

Current goal:

Build and validate the complete MVP architecture and clinic workflow using fictional data.

Production infrastructure will be selected later.

==================================================
3. FUTURE PRODUCTION INTENT
==================================================

The first real market is expected to be Russia.

Future pilot assumptions:

- 1 clinic initially
- approximately 3–15 staff members
- approximately 500–10,000 patients
- approximately 20–100 appointments per day

Architecture should later scale toward:

- 100+ clinics
- 20+ staff per clinic
- 10,000+ patients per clinic
- hundreds of thousands of patient records overall

Use:

- pagination
- proper PostgreSQL indexes
- tenant isolation
- efficient filtering
- scalable queries

Do not make architectural choices that require rewriting the entire application when additional clinics are added.

==================================================
4. TARGET PLATFORMS
==================================================

Use a single Flutter codebase.

Target architecture:

- Flutter Web
- Android
- iOS
- Tablets

Release priority:

1. Flutter Web
2. Android
3. iOS

Flutter Web is the primary pilot platform.

Reasons:

Receptionists and administrators usually need:

- larger screens
- schedules
- patient lists
- billing
- staff management

Android should work early for dentists using tablets or phones.

iOS must remain supported by the architecture but App Store release should not block the first pilot.

==================================================
5. MAIN TECHNOLOGY STACK
==================================================

Frontend:

- Flutter
- Dart

State management:

- flutter_bloc
- Cubit
- Bloc

Architecture:

- Feature-First Clean Architecture
- Repository Pattern
- Dependency Injection
- Data / Domain / Presentation separation

Code generation:

- Freezed
- json_serializable
- build_runner

Dependency injection:

- GetIt
- Injectable

Navigation:

- GoRouter

Backend:

- Supabase Free Tier

Supabase responsibilities:

- Supabase Auth
- PostgreSQL
- Row Level Security
- Realtime
- Storage
- Edge Functions where appropriate

Firebase responsibilities:

- Firebase Cloud Messaging
- Firebase Analytics
- Firebase Crashlytics
- Remote Config later if needed

IMPORTANT:

Supabase is the main backend and source of truth.

Do NOT use:

Firebase Auth in parallel with Supabase Auth.

Do NOT use:

Firestore for clinic business data.

==================================================
6. FLUTTER PACKAGES
==================================================

Use these packages unless there is a strong technical reason not to.

State management:

flutter_bloc

Models / code generation:

freezed
freezed_annotation
json_serializable
json_annotation
build_runner

Dependency Injection:

get_it
injectable
injectable_generator

Navigation:

go_router

Backend:

supabase_flutter

Networking:

dio

Local security:

flutter_secure_storage

Preferences:

shared_preferences

Firebase:

firebase_core
firebase_messaging
firebase_analytics
firebase_crashlytics

Localization / formatting:

intl

Files:

file_picker
image_picker if needed

Images:

cached_network_image

External actions:

url_launcher

Testing:

flutter_test
bloc_test
mocktail
integration_test

Optional:

equatable only where Freezed is not used.

==================================================
7. ARCHITECTURE
==================================================

Use:

Feature-First Clean Architecture.

Preferred flow:

UI
↓
Cubit / Bloc
↓
Use Case where useful
↓
Repository Interface
↓
Repository Implementation
↓
Data Source
↓
Supabase / API / External Service

Never call Supabase directly from Flutter Widgets.

Avoid calling Supabase directly from Cubits if a repository abstraction is appropriate.

Database DTOs must not be exposed directly to presentation.

Data layer DTO
↓
Mapper
↓
Domain Entity
↓
Presentation

==================================================
8. FOLDER STRUCTURE
==================================================

Use approximately:

lib/

  app/
    app.dart
    bootstrap/
    router/
    theme/
    localization/

  core/
    config/
    error/
    network/
      dio_client.dart
      interceptors/
    security/
    storage/
    permissions/
    utils/
    widgets/

  features/

    auth/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/

    clinic/
    staff/
    patients/
    schedule/
    appointments/
    odontogram/
    treatments/
    clinical_sessions/
    files/
    billing/
    dashboard/
    settings/
    audit/

Do not create giant files.

Prefer small reusable widgets.

==================================================
9. STATE MANAGEMENT
==================================================

flutter_bloc is the primary state management solution.

Use Cubit for:

- CRUD screens
- patient list
- patient filters
- staff
- dashboard
- billing
- settings
- simple feature state

Use Bloc for complex event-driven workflows such as:

- authentication
- invitation workflow
- appointment lifecycle
- clinical session lifecycle
- workflows with explicit events/state transitions

Do not mix GetX, Provider, Riverpod, etc. as competing state-management systems.

Use Freezed for immutable states.

Every important feature must support:

- initial
- loading
- loaded
- empty
- error

Do not assume successful requests.

==================================================
10. MULTI-TENANCY
==================================================

The application is MULTI-TENANT from the beginning.

One user may belong to one or multiple clinics.

Every clinic-owned record must contain:

clinic_id

Clinic A must NEVER access Clinic B data.

This includes:

- patients
- appointments
- medical records
- files
- invoices
- payments
- staff
- treatment plans

Tenant isolation must be enforced using Supabase/PostgreSQL RLS.

Do NOT rely only on Flutter filtering.

==================================================
11. ROLES
==================================================

Initial roles:

OWNER
DENTIST
ASSISTANT
RECEPTIONIST

A user may have MULTIPLE roles.

Example:

Dr. Nour:

OWNER
DENTIST

OWNER is an administrative role.

DENTIST is a clinical role.

Do not model Owner as a profession.

==================================================
12. OWNER PERMISSIONS
==================================================

OWNER manages the clinic administratively.

OWNER MAY:

- manage clinic settings
- manage staff
- invite employees
- assign roles
- deactivate/reactivate staff
- manage schedules
- manage procedure pricing
- view finances
- perform financial corrections
- view reports
- view audit logs
- archive/restore patients
- view all clinic information

OWNER without DENTIST MAY read clinical information for oversight.

OWNER-only MAY read:

- patient profiles
- appointments
- clinical history
- odontogram history
- treatment plans
- X-rays/files
- clinical notes
- billing information

OWNER without DENTIST MUST NOT:

- create diagnoses
- change diagnoses
- modify odontogram medical conditions
- prescribe treatment
- finalize clinical notes
- mark clinical procedures as medically completed

Clinical write permissions require DENTIST.

OWNER + DENTIST receives both administrative and clinical permissions.

==================================================
13. DENTIST PERMISSIONS
==================================================

For MVP:

Dentists may read ALL patients within their clinic.

Do not restrict them only to assigned patients initially.

This allows another dentist to cover a patient if necessary.

DENTIST MAY:

- create patients
- edit basic patient information
- create appointments
- view clinic patients
- view appointments
- read medical history
- read X-rays/files
- create diagnoses
- manage odontogram
- create treatment plans
- create clinical sessions
- finalize clinical notes
- complete treatment procedures
- see procedure prices
- see treatment estimates

Dentists MUST NOT manage:

- staff roles
- owners
- clinic-wide security settings
- financial refunds unless also Owner

Later, clinics may optionally restrict dentists to assigned patients.

Not required for MVP.

==================================================
14. RECEPTIONIST PERMISSIONS
==================================================

Receptionists follow least-privilege access.

RECEPTIONIST MAY:

- create patients
- edit demographic information
- edit contact details
- create appointments
- confirm appointments
- reschedule appointments
- cancel appointments
- mark no-show
- view appointment schedule
- view assigned dentist
- view invoice totals
- view paid amount
- view outstanding balance
- record payments

RECEPTIONIST MUST NOT access:

- diagnoses
- odontogram clinical details
- clinical notes
- treatment session notes
- X-rays
- clinical photos
- detailed clinical history

Receptionists may see administrative treatment indicators such as:

Active treatment plan: Yes

but not detailed clinical treatment content.

==================================================
15. ASSISTANT PERMISSIONS
==================================================

ASSISTANT MAY read:

- patient profile
- appointments
- odontogram
- treatment plans
- clinical history
- X-rays
- clinical files

ASSISTANT MAY:

- upload X-rays
- upload clinical images/files
- add chairside observations
- prepare draft clinical notes
- edit draft notes
- update limited non-diagnostic support information
- update basic contact information if needed

ASSISTANT MUST NOT:

- independently diagnose
- change tooth medical conditions
- approve treatment plans
- prescribe treatment
- finalize treatment plans
- medically complete procedures
- overwrite finalized dentist notes

Assistants do NOT need financial treatment estimates by default.

Hide treatment prices from Assistants unless this becomes configurable later.

For MVP, Assistants should not change major appointment statuses.

They may:

- view schedule
- view appointment details
- add operational/preparation notes

They should NOT:

- cancel
- mark no-show
- complete appointment
- override scheduling conflicts

==================================================
16. CLINICAL NOTES
==================================================

Clinical notes have:

draft
finalized

Assistant may create/edit draft notes.

Dentist finalizes notes.

Once finalized:

the original note becomes immutable through normal UI.

Corrections must be added as amendments.

Store:

created_by
updated_by
finalized_by
finalized_at
status

Amendments:

original_note_id
amendment_text
reason
amended_by
amended_at

Never silently overwrite finalized medical history.

==================================================
17. CLINIC OWNERSHIP
==================================================

A clinic may have multiple Owners.

Existing Owners may invite additional Owners.

Prevent removal/deactivation of the LAST active Owner.

There must always be at least one active Owner.

Owner invitation must be revocable.

Default invitation expiration:

7 days.

Invitation can be resent.

==================================================
18. STAFF INVITATIONS
==================================================

Flow:

1. Owner enters employee email.
2. Owner selects role(s).
3. Invitation is created.
4. User opens invitation.
5. User signs up or logs in.
6. User accepts.
7. User joins existing clinic.
8. clinic_members is created.
9. roles are assigned.

Invited employees MUST NOT be forced to create their own clinic.

Creating a clinic only occurs when user explicitly chooses:

Create New Clinic

Never expose Supabase service-role credentials to Flutter.

Use Edge Functions for privileged operations where necessary.

==================================================
19. CLINIC SWITCHING
==================================================

A user may work in multiple clinics.

After login:

If user has one clinic:
open it automatically.

If multiple:
show clinic selector.

Store selected clinic ID as a non-sensitive preference.

Changing active clinic must refresh all feature data.

Never hardcode clinic IDs.

==================================================
20. DOCTOR WORK SCHEDULE
==================================================

MVP includes Doctor Schedule.

Support:

- working days
- working hours
- breaks
- leave
- unavailable periods

OWNER may manage schedules for all dentists.

DENTIST may manage/request changes to their own working hours and leave.

For MVP:

Dentist may edit their own schedule.

Owner has final administrative authority and may modify all clinic schedules.

Audit significant schedule changes.

==================================================
21. APPOINTMENT CONFLICTS
==================================================

Appointment validation checks:

1. dentist overlap
2. patient overlap
3. outside dentist working hours
4. dentist leave/unavailable period

Default:

block conflicts.

OWNER may explicitly override:

- dentist overlap
- working-hours conflict
- leave/unavailability conflict

Override requires:

- warning
- explicit confirmation
- reason
- audit entry

Patient overlap should remain HARD BLOCKED for MVP.

Do not allow one patient to have physically overlapping appointments.

Dental-chair/resource scheduling is deferred.

Design schema so chairs/rooms can be added later.

==================================================
22. SCHEDULE CHANGES WITH EXISTING APPOINTMENTS
==================================================

Changing dentist working hours or adding leave must NOT automatically move or cancel existing appointments.

Before saving a schedule change:

detect affected future appointments.

Show:

"This change conflicts with X existing appointments."

Then provide:

- cancel schedule change
- review affected appointments

OWNER may confirm the schedule change while leaving existing appointments flagged as conflicts.

Do not silently reschedule patients.

Existing affected appointments should receive a conflict flag requiring manual resolution.

==================================================
23. APPOINTMENT STATUSES
==================================================

Use:

scheduled
confirmed
in_progress
completed
cancelled
no_show

RECEPTIONIST:

create
confirm
reschedule
cancel
mark no-show

DENTIST:

create
start
complete
cancel if necessary
mark no-show

OWNER:

all administrative appointment actions.

ASSISTANT:

read only + operational preparation notes for MVP.

==================================================
24. APPOINTMENT VS CLINICAL SESSION
==================================================

Appointment completion and clinical session finalization are related but separate.

Appointment may be completed without treatment.

Examples:

- consultation
- examination
- patient declined treatment
- administrative visit

If a clinical session exists:

it should be finalized or explicitly marked as no-treatment/empty before final completion.

Never generate fake clinical notes automatically.

==================================================
25. PATIENT REQUIRED INFORMATION
==================================================

Required:

first_name
last_name

And at least ONE usable contact method.

Valid contact methods:

- patient phone
- patient email
- guardian phone
- guardian email

Do not require patient phone specifically if another valid contact exists.

Optional:

middle_name
date_of_birth
gender
address
emergency_contact
notes

==================================================
26. CHILD PATIENTS
==================================================

Children are supported.

If date of birth shows patient is under 18:

guardian information becomes mandatory.

Required guardian data:

guardian_name

and at least one:

guardian_phone
guardian_email

If date of birth is unknown:

allow date_of_birth = null.

Add:

birth_date_precision:

exact
approximate
unknown

Optionally support:

approximate_age_years

If patient is explicitly marked as minor:

guardian details are mandatory even when birth date is unknown.

==================================================
27. MEDICAL INFORMATION
==================================================

Include basic medical information:

- allergies
- current medications
- chronic conditions
- important medical notes

Keep MVP focused.

Do not build a full hospital EHR.

==================================================
28. PATIENT NUMBER
==================================================

Every patient gets a clinic-specific patient number.

Example:

PAT-00001

Unique within clinic.

Do not require global uniqueness across all clinics.

==================================================
29. PATIENT SEARCH
==================================================

Search by:

- name
- phone
- email
- patient number

Use debounce.

Do not perform backend request for every keystroke.

Use pagination.

Handle:

loading
empty
error
results

==================================================
30. PATIENT PROFILE
==================================================

Tabs:

Overview
Appointments
Dental Chart
Treatment Plans
Visits
Files
Billing
Activity

Header:

Name
Age
Patient number
Phone/contact
Last appointment
Next appointment

==================================================
31. ODONTOGRAM
==================================================

Interactive dental chart is a core feature.

Use FDI numbering.

Permanent teeth:

11–18
21–28
31–38
41–48

Primary teeth:

51–55
61–65
71–75
81–85

Primary tooth visualization may be deferred ONLY if the pilot clinic confirms pediatric odontogram support is not required initially.

If the clinic treats children clinically and requires primary-tooth charting, move primary dentition into MVP before real patient usage.

==================================================
32. TOOTH CONDITIONS
==================================================

Do NOT model a tooth with one single condition field.

A tooth may have multiple conditions.

Examples:

existing filling
recurrent caries
fracture

Each condition is its own record.

Fields:

id
clinic_id
patient_id
tooth_number
surface
condition_type
status
notes
created_by
created_at
resolved_by
resolved_at

Status:

active
resolved
entered_in_error

==================================================
33. HEALTHY CONDITION RULE
==================================================

Do NOT store "healthy" as a normal active condition.

Healthy should normally be DERIVED:

If a tooth exists and has no active pathological/restorative condition requiring display, UI may display it as healthy.

This avoids contradictions such as:

healthy + caries

==================================================
34. MISSING TOOTH RULE
==================================================

"missing" represents absence of the natural tooth.

Missing cannot coexist with active natural-tooth conditions such as:

- caries
- filling on natural tooth
- crown on natural tooth
- root canal on natural tooth
- fracture
- extraction_required

However:

missing may coexist conceptually with an implant replacement record.

Model implant/restoration carefully so history remains meaningful.

==================================================
35. ERRONEOUS CLINICAL ENTRIES
==================================================

Do NOT hard-delete erroneous medical entries.

Use:

status = entered_in_error

Store:

error_reason
marked_in_error_by
marked_in_error_at

Keep original history.

==================================================
36. TOOTH SURFACES
==================================================

Support:

whole
mesial
distal
occlusal
buccal
lingual

Design so additional surfaces can be added if needed.

==================================================
37. PROCEDURE CATALOG
==================================================

procedures:

id
clinic_id
name
category
default_price
duration_minutes
active
created_at
updated_at

Example procedures:

Consultation
Cleaning
Composite Filling
Root Canal
Extraction
Crown
Implant
Whitening

OWNER manages pricing.

DENTIST sees pricing.

==================================================
38. TREATMENT PLANS
==================================================

treatment_plans:

id
clinic_id
patient_id
dentist_member_id
status
notes
total_estimated_cost
created_at
updated_at

Statuses:

draft
active
completed
cancelled

==================================================
39. TREATMENT PLAN ITEMS
==================================================

Fields:

id
clinic_id
treatment_plan_id
procedure_id
tooth_number
description
estimated_price
status
assigned_dentist_id
sort_order
created_at
updated_at

Statuses:

planned
approved
in_progress
completed
cancelled

Only Dentist may make clinical treatment decisions.

==================================================
40. CLINICAL SESSIONS
==================================================

Fields:

id
clinic_id
patient_id
appointment_id
dentist_member_id
session_date
clinical_notes
recommendations
status
created_at
updated_at

Status:

draft
finalized

Finalized records are immutable.

Corrections use amendments.

==================================================
41. PATIENT FILES
==================================================

Allow:

JPG
JPEG
PNG
PDF

Later:

DICOM
HEIC

Maximum initial size:

15 MB per file

Validate:

- extension
- MIME type
- size

Use Supabase Storage.

Path:

clinic_id/patient_id/random_uuid/filename

Clinic isolation applies to files.

==================================================
42. FILE ACCESS
==================================================

DENTIST:

clinical files allowed.

ASSISTANT:

clinical files allowed as required for treatment support.

RECEPTIONIST:

must not open X-rays or clinical images.

OWNER:

may read for clinic oversight.

==================================================
43. BILLING
==================================================

Invoices should be real internal clinic billing records.

Support:

invoice_number
patient
items
quantity
unit_price
line_total
subtotal
discount
tax
total
paid_amount
outstanding_balance
status

Statuses:

draft
unpaid
partially_paid
paid
cancelled

==================================================
44. CURRENCY
==================================================

Clinic has configurable currency.

Initial default for Russian pilot:

RUB

Architecture supports:

RUB
USD
EUR
other ISO currencies later

Use PostgreSQL numeric/decimal.

Never use binary floating-point for money.

==================================================
45. DISCOUNTS
==================================================

Support:

fixed discount
percentage discount

OWNER may apply/manage discounts for MVP.

Future configurable permission may allow additional staff.

==================================================
46. TAX
==================================================

Support a simple configurable tax field.

Default can be:

0

Do NOT implement full Russian accounting/tax compliance logic in the MVP.

==================================================
47. PAYMENTS
==================================================

Payment methods:

cash
card
bank_transfer
other

Card payments are manually recorded.

No payment-provider integration initially.

RECEPTIONIST may:

- record payment
- view total
- view paid
- view outstanding

RECEPTIONIST cannot:

- change prices
- delete payments
- issue refunds
- change financial settings

==================================================
48. INVOICE CONFIDENTIALITY
==================================================

Detailed procedure descriptions may reveal clinical information.

Therefore:

RECEPTIONIST should not freely browse detailed clinical treatment data.

Receptionist may see:

- invoice number
- total amount
- paid amount
- balance
- payment status
- general billing status

Detailed itemized clinical invoice content is primarily visible to:

OWNER
DENTIST

However:

Receptionist MAY print/export an already finalized patient invoice prepared/approved by authorized staff without gaining permission to edit clinical procedure contents.

==================================================
49. INVOICE PDF
==================================================

Basic invoice PDF export IS mandatory for the real pilot.

It does not need advanced branding initially.

Must include:

- clinic name
- invoice number
- patient
- date
- authorized itemized procedures
- amounts
- payments
- outstanding balance

PDF generation should be separated behind a service abstraction.

==================================================
50. REFUNDS AND CORRECTIONS
==================================================

Do not delete completed payments.

Refund/correction creates a separate financial record.

OWNER only for MVP.

Store reason and audit information.

==================================================
51. OVERPAYMENTS
==================================================

If payment exceeds current invoice balance:

do not silently discard the difference.

Create patient credit / unapplied credit.

This credit may later be applied to another invoice.

Keep a full audit trail.

==================================================
52. DASHBOARD
==================================================

Show:

- today's appointments
- upcoming appointments
- total patients
- appointments this week
- completed treatments
- outstanding payments

Later:

- monthly revenue
- patient growth
- dentist metrics
- procedure statistics

Dashboard always reflects ACTIVE clinic only.

==================================================
53. DELETION AND ARCHIVING
==================================================

Do not hard-delete patients through normal UI.

Use:

archived_at
archived_by

OWNER may:

archive
restore

Files should normally be archived rather than permanently deleted.

Never hard-delete through normal UI:

- finalized clinical notes
- diagnoses
- odontogram history
- treatments
- payments
- invoices
- audit logs

==================================================
54. PATIENT ACTIVITY
==================================================

Patient Activity is different from security audit logs.

OWNER:

full patient activity.

DENTIST:

clinical + operational activity.

ASSISTANT:

relevant clinical-support activity.

RECEPTIONIST:

administrative activity only.

Examples receptionist may see:

- appointment created
- appointment moved
- phone updated
- payment recorded

==================================================
55. AUDIT LOGS
==================================================

audit_logs:

id
clinic_id
user_id
action
entity_type
entity_id
metadata
created_at

Audit logs should be immutable from normal clients.

OWNER-only security audit UI initially.

==================================================
56. ACCESS AUDITING
==================================================

Do NOT create one audit event for every patient row returned in a search/list because this creates unnecessary volume.

Log explicit sensitive access events.

Audit:

- patient profile opened
- clinical record opened
- file/X-ray opened
- file downloaded
- patient data exported
- bulk export
- clinical record modified
- financial record modified
- permissions changed
- schedule override
- security-sensitive owner action

For patient list/search:

record a search/list access event when appropriate, including:

- user
- clinic
- timestamp
- search/list action
- result count

Do NOT store every returned patient ID unless legally/security-wise required later.

For exports:

record:

- exporting user
- clinic
- export type
- number of records
- timestamp
- export identifier

==================================================
57. AUTHENTICATION
==================================================

Implement:

Register
Login
Logout
Forgot password
Reset password
Session restoration

Supabase Auth is the ONLY primary authentication provider.

==================================================
58. OWNER REGISTRATION
==================================================

Registration flow:

1. User registers.
2. User creates clinic.
3. User automatically becomes OWNER.
4. Ask:

"Are you also a dentist?"

If yes:

OWNER + DENTIST

If no:

OWNER only

==================================================
59. SHARED DEVICES
==================================================

Reception computers may be physically shared.

Application accounts must NOT be shared.

Every employee has an individual login.

Do not create:

reception@example...
shared dentist...
generic owner...

Audit logs must identify the real employee.

==================================================
60. INACTIVITY LOCK
==================================================

Implement privacy lock after:

10 minutes inactivity.

This privacy lock is separate from authentication session expiration.

After privacy lock:

hide patient/clinical data and require re-authentication/unlock.

Do not unnecessarily destroy the entire server session.

Later make timeout configurable.

==================================================
61. OWNER RE-AUTHENTICATION
==================================================

Sensitive Owner actions require recent server-verified re-authentication.

Examples:

- assigning another Owner
- removing staff
- changing critical permissions
- financial refund/correction
- bulk patient export
- security setting changes

Architecture should support MFA/2FA later.

MFA should be strongly recommended before real production use.

==================================================
62. RLS / RBAC
==================================================

Supabase RLS is the REAL authorization layer.

Flutter permission checks are UX only.

Create reusable PostgreSQL helper functions where useful:

is_clinic_member(clinic_id)

has_clinic_role(clinic_id, role_name)

Every sensitive operation must be protected server-side.

Never disable RLS to make development easier.

==================================================
63. DIO
==================================================

Create centralized:

DioClient

AuthInterceptor
ErrorInterceptor
LoggingInterceptor in debug only

Dio will be used for:

- Supabase Edge Functions over HTTP
- future external APIs
- notifications integrations
- future payment services

AuthInterceptor should:

- attach token where needed
- handle 401
- safely refresh session if appropriate
- retry request at most once when safe
- prevent infinite retry loops

==================================================
64. ERROR HANDLING
==================================================

Create typed failures:

NetworkFailure
AuthenticationFailure
AuthorizationFailure
ValidationFailure
ServerFailure
NotFoundFailure
UnknownFailure

Do not expose stack traces to normal users.

Show user-friendly messages.

==================================================
65. LOCAL STORAGE
==================================================

SharedPreferences:

ONLY non-sensitive values.

Examples:

theme
locale
active clinic ID
UI preferences

flutter_secure_storage:

sensitive local values when needed.

Do not store full medical records locally during MVP.

Offline medical-data synchronization is not required initially.

==================================================
66. LOCALIZATION
==================================================

Prepare localization from the beginning.

Initial languages:

Russian
English

Later:

Arabic

Ensure architecture supports RTL.

Do not hardcode strings directly into widgets.

==================================================
67. RESPONSIVE UI
==================================================

Suggested breakpoints:

mobile < 600
tablet 600–1024
desktop > 1024

Desktop:

sidebar navigation.

Mobile:

bottom navigation / drawer.

Tablet:

adaptive layout.

==================================================
68. MAIN NAVIGATION
==================================================

Desktop:

Dashboard
Patients
Appointments
Schedule
Treatments
Staff
Billing
Settings

Mobile:

Dashboard
Patients
Appointments
More

==================================================
69. SECURITY RULES
==================================================

Never:

- expose service-role keys to Flutter
- hardcode secrets
- disable RLS
- trust client role checks alone
- store sensitive patient data in SharedPreferences
- log clinical content in Crashlytics
- log passwords/tokens
- silently delete medical history

==================================================
70. FIREBASE
==================================================

Firebase is supplemental only.

Use:

Firebase Cloud Messaging
Firebase Analytics
Firebase Crashlytics

Do NOT use:

Firebase Auth
Firestore for business data

Be careful not to send sensitive medical information into analytics/crash reporting.

==================================================
71. CURRENT FREE INFRASTRUCTURE POLICY
==================================================

Use only free-tier infrastructure.

Allowed:

Supabase Free Tier
Firebase free features where applicable
GitHub
GitHub Actions free allowance
free Flutter Web hosting if necessary
local Android/iOS development

Do not enable paid PITR or paid backup products.

Do not block MVP development because paid production backup is unavailable.

==================================================
72. DEVELOPMENT DATA
==================================================

During DEVELOPMENT / DEMO:

use ONLY fictional/demo patients.

No real medical data.

==================================================
73. FUTURE PRODUCTION READINESS
==================================================

Production requirements are documented but not currently required to be operational.

Desired future targets:

RPO:

15 minutes

RTO:

2 hours

These are TARGETS, not current guarantees.

Do not claim these targets are achieved until infrastructure is selected and recovery is tested.

==================================================
74. DATA LOCATION
==================================================

Production data location for Russian patient data is NOT decided.

Do not assume foreign Supabase hosting is legally acceptable.

Before real patient usage:

research and review:

- Russian personal-data requirements
- medical-data requirements
- primary-data location
- backup-data location
- cross-border processing
- third-party processors
- retention requirements
- access logging
- consent/document requirements

Legal review is outside application code.

==================================================
75. PRODUCTION READINESS GATE
==================================================

Real patient data may only be introduced after:

- production hosting selected
- data-location/legal review completed
- RLS security tested
- role permissions tested
- database backups configured
- file backups configured
- restore test completed
- monitoring enabled
- audit logging operational
- incident/recovery procedure documented
- owner security policy finalized

Until then:

DEMO DATA ONLY.

==================================================
76. TESTING
==================================================

Testing is mandatory.

Unit tests:

- repositories
- use cases
- Cubits
- Blocs
- validation
- billing calculations
- role permissions
- schedule conflict logic

Widget tests:

- login
- patient list
- patient form
- appointment form
- odontogram interactions
- role-aware UI

Integration tests:

register
create clinic
invite staff
create patient
create appointment
update odontogram
create treatment plan
finalize clinical session
record payment

==================================================
77. RLS TESTS
==================================================

Explicitly test:

Clinic A cannot read Clinic B patients.

Clinic A cannot open Clinic B files.

Receptionist cannot read clinical notes.

Receptionist cannot update odontogram.

Assistant cannot finalize diagnosis.

Dentist cannot change staff roles.

Owner without Dentist cannot modify diagnosis.

Owner + Dentist can perform administrative + clinical operations.

Last Owner cannot be removed.

==================================================
78. CI/CD
==================================================

Use GitHub Actions.

On Pull Request run:

flutter pub get

dart format --set-exit-if-changed .

flutter analyze

flutter test

Later add:

Flutter Web build

Android build

Do not merge failing code.

==================================================
79. DOCUMENTATION
==================================================

Repository should include:

README.md
ARCHITECTURE.md
DATABASE.md
SECURITY.md
PERMISSIONS.md
PRODUCTION_READINESS.md

README should explain:

Problem
Solution
Architecture
Features
Setup
Demo account
Screenshots
Technology stack

Never commit secrets.

==================================================
80. DEVELOPMENT PHASES
==================================================

Do NOT implement all features at once.

PHASE 0

Project bootstrap.

Configure:

Flutter project
architecture
DI
GoRouter
themes
localization
Supabase client abstraction
Dio
error handling
linting
testing
GitHub Actions

PHASE 1

Authentication.

PHASE 2

Clinic creation + multi-tenancy.

PHASE 3

Roles + staff + invitations.

PHASE 4

Patients.

PHASE 5

Doctor schedule.

PHASE 6

Appointments.

PHASE 7

Odontogram.

PHASE 8

Treatment plans.

PHASE 9

Clinical sessions.

PHASE 10

Patient files.

PHASE 11

Billing + payments + PDF.

PHASE 12

Dashboard.

PHASE 13

Audit logs.

PHASE 14

Security hardening + RLS tests.

PHASE 15

Responsive polish + integration tests.

==================================================
81. MVP COMPLETE WORKFLOW
==================================================

MVP is successful when:

Owner registers.

Owner creates clinic.

Owner chooses:

"I am also a dentist."

System assigns:

OWNER + DENTIST.

Owner invites Receptionist.

Receptionist joins clinic.

Receptionist creates patient.

Receptionist schedules appointment.

Dentist opens schedule.

Dentist opens patient.

Dentist reviews medical information.

Dentist updates odontogram.

Dentist creates treatment plan.

Assistant may prepare draft session notes.

Dentist finalizes clinical session.

Receptionist records payment.

Receptionist prints approved invoice if needed.

Owner views dashboard.

All data remains isolated to clinic.

==================================================
82. NOT REQUIRED FOR FIRST MVP
==================================================

Do not prioritize:

Patient accounts
Patient mobile app
Online patient booking
AI diagnosis
Medical AI
Insurance integrations
Advanced accounting
Inventory
WhatsApp integration
Video consultations
Multiple branches
Subscription billing
Payment gateway
Dental-chair scheduling
Complex offline medical synchronization

==================================================
83. CODE QUALITY RULES
==================================================

Never:

- put business logic inside Widgets
- call Supabase directly from UI
- expose raw Supabase maps to presentation
- create giant service classes
- disable authorization
- hardcode clinic IDs
- silently catch exceptions
- create fake clinical records automatically
- mutate finalized medical history
- hard-delete financial history

Prefer:

- small testable classes
- typed entities
- typed failures
- repositories
- explicit permissions
- reusable widgets
- immutable states
- code generation
- clear feature boundaries

==================================================
84. DEFINITION OF DONE
==================================================

A feature is complete only when:

- UI exists
- loading state exists
- empty state exists
- error state exists
- validation exists
- permission checks exist
- server-side authorization exists
- responsive behavior exists
- tests exist
- analyzer passes
- no secrets are committed
- relevant docs are updated

==================================================
85. CODEX WORKING INSTRUCTIONS
==================================================

Do NOT start by implementing the entire specification.

Start with:

PHASE 0 ONLY.

Before each phase:

1. Review current repository.
2. Explain the implementation plan briefly.
3. List files to create/change.
4. Create database migration when necessary.
5. Implement domain layer.
6. Implement data layer.
7. Implement presentation layer.
8. Add tests.
9. Run formatting.
10. Run flutter analyze.
11. Run flutter test.

Do not proceed to the next phase if tests or analyzer fail.

Do not rewrite unrelated working features.

Do not weaken security rules to make implementation easier.

If a medical/business requirement is unclear:

document a TODO rather than inventing unsafe clinical behavior.

For now:

START PHASE 0 ONLY.

Do not implement Phase 1 until Phase 0 is complete, formatted, analyzed and tested.