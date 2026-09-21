# Phase 11 — Billing, Payments, Credit, and Invoice PDF Architecture

Status: approved, implemented, and verified on 2026-09-12.

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 10–15,
30, 37–39, 43–51, 53–56, 66–69, and 76–85, plus the product decisions
approved on 2026-09-11.

## Approved product decisions

- A Dentist prepares and clinically approves invoice items. An Owner controls
  unit prices, discount, tax, document language, and finalizes the invoice. A
  user with both roles can perform both responsibilities.
- Document lifecycle and payment state are separate. Documents are `draft`,
  `finalized`, or `cancelled`; payment state is `unpaid`, `partially_paid`, or
  `paid`. The UI may combine them into the Master Specification's familiar
  status labels.
- Invoice items come from the clinic procedure catalogue or an existing
  treatment-plan item. The finalized invoice stores immutable snapshots. The
  system does not accept unrestricted free-text clinical line items.
- A draft supports one invoice-level fixed or percentage discount. Discount is
  applied before percentage tax. Clinic billing settings supply a default tax
  rate of zero, which is copied into the draft and may be changed by an Owner.
- Owners and Receptionists may record payments and apply existing patient
  credit. An overpayment creates unapplied patient credit automatically. Only
  an Owner may refund or correct a financial entry, with a required reason.
- Draft invoices can be cancelled. Only an Owner can cancel a finalized
  invoice, and only after its net paid amount has returned to zero through
  preserved refunds or corrections.
- A permanent clinic-specific number such as `INV-00001` is allocated when an
  invoice is finalized. Numbers are never reused.
- Invoice PDFs are generated from immutable finalized content, stored in a
  private bucket, and accessed through short-lived links. English, Russian,
  and Arabic are supported. Owners, Dentists, and Receptionists may export;
  Assistants cannot access billing.
- Existing billing history remains accessible for archived patients, but a
  new invoice cannot be created for an archived patient.
- Flutter financial values use an exact Money model. Existing Phase 8
  treatment price mappings that use binary floating point are corrected as
  part of this phase without changing their database values.

## Scope

Phase 11 adds a clinic Billing workspace and a patient Billing area. It covers
invoice drafting, clinical-content approval, financial finalization, manual
cash/card/bank/other payments, overpayment credit, later credit application,
Owner-only refunds and corrections, and basic private invoice PDFs.

The phase has no payment gateway, card processing, fiscal receipt integration,
electronic signature, insurance claim, recurring invoice, subscription,
installment schedule, multi-currency conversion, advanced accounting, or
Russian tax/fiscal compliance. Every development record remains fictional.
Before real use, the clinic must obtain legal and accounting review of the
document wording, numbering, tax treatment, retention, and whether a separate
fiscal receipt is required.

## Roles and information boundaries

| Capability | Owner | Dentist | Assistant | Receptionist |
| --- | ---: | ---: | ---: | ---: |
| Read invoice summaries and balances | Yes | Yes | No | Yes |
| Read itemized clinical content | Yes | Yes | No | No |
| Create draft and select clinical items | Only with Dentist role | Yes | No | No |
| Approve clinical content | Only with Dentist role | Yes | No | No |
| Change unit prices, discount, and tax | Yes | No | No | No |
| Finalize an approved invoice | Yes | No | No | No |
| Record a payment | Yes | No | No | Yes |
| Apply patient credit | Yes | No | No | Yes |
| Refund or correct a financial entry | Yes | No | No | No |
| Cancel a finalized invoice | Yes | No | No | No |
| Export finalized PDF | Yes | Yes | No | Yes |

Receptionists never receive structured invoice-item rows through the Data API.
Their export permission is a narrow server operation that returns a private PDF
for a finalized invoice and records the export. As stated in the Master
Specification, a person printing the document can see its contents; the rule
prevents general clinical browsing and editing rather than pretending the PDF
is unreadable to its operator.

## Invoice workflow

### Prepare and clinically approve

1. A Dentist opens an active patient's Billing area and creates a draft.
2. The Dentist adds no more than 100 items. An item either selects an active
   catalogue procedure or an eligible treatment-plan item for the same patient.
3. The server snapshots the procedure name, category, tooth reference, and any
   approved treatment description. Quantity defaults to `1.00`. The initial
   unit price is copied from the treatment estimate or catalogue price.
4. The Dentist can change source and quantity while the draft is unapproved.
   Only an Owner can change the copied unit price.
5. The Dentist approves the clinical content. Approval records the actor and
   time. Any later clinical-item change clears that approval and requires a new
   approval.

A treatment-plan item may appear on only one non-cancelled invoice in MVP. This
prevents accidental duplicate billing. Split billing for one treatment item is
future work. A catalogue procedure can be selected directly for a service that
does not have a treatment plan, including a walk-in consultation.

### Apply financial values and finalize

1. An Owner reviews the approved content, copied unit prices, discount, tax,
   currency, patient, and totals.
2. The database calculates every line and invoice total. Flutter-provided
   totals are ignored.
3. Finalization locks the draft row, revalidates the patient, item sources,
   clinical approval, and exact arithmetic, and allocates the next clinic
   invoice number in the same short transaction.
4. The server snapshots patient name/number, clinic name, item content,
   currency, discount, tax, and totals. These values become immutable.
5. The initial payment state is `unpaid`. PDF creation can begin after the
   transaction commits; an unavailable PDF never rolls back or corrupts the
   finalized invoice.

Finalization is idempotent. A client-generated command UUID is unique for the
clinic and operation. Repeating the same request returns the existing result.

### Cancel

- A Dentist who created a draft or an Owner may cancel a draft. It receives no
  invoice number and remains historical.
- Only an Owner may cancel a finalized invoice, with a required reason.
- A finalized invoice can be cancelled only when `paid_amount = 0`. Recorded
  payments must first be refunded or corrected through the ledger. The invoice
  and every financial event remain stored.
- A cancelled treatment-plan item can be invoiced again only when its earlier
  invoice is cancelled; finalized invoice snapshots are never changed.

## Money and calculation rules

PostgreSQL is the sole calculation authority. Monetary columns use
`numeric(14,2)`. Rates and quantities also use decimal types with explicit
limits. No database, Edge Function, or Flutter command performs financial
arithmetic with binary floating point.

For each item:

```text
line_total = round(quantity × unit_price, 2)
```

For the invoice:

```text
subtotal = sum(line_total)
fixed discount amount = min(configured fixed value, subtotal)
percentage discount amount = round(subtotal × rate / 100, 2)
taxable_base = subtotal - discount_amount
tax_amount = round(taxable_base × tax_rate / 100, 2)
total = taxable_base + tax_amount
paid_amount = sum(invoice effects in the immutable financial ledger)
outstanding_balance = max(total - paid_amount, 0)
```

Percentage discount and tax rates are between 0 and 100. A fixed discount
cannot reduce the taxable base below zero. Quantity is greater than zero and no
more than 999.99. Unit price and all resulting totals must remain within the
chosen `numeric(14,2)` range.

The finalized invoice stores the clinic's three-letter uppercase currency as a
snapshot. Phase 11 supports the configured RUB, USD, or EUR codes with two
fraction digits. Currency conversion and ISO currencies with other fraction
scales remain a future migration rather than an unsafe formatting assumption.

### Flutter Money boundary

`Money` stores integer minor units and a currency code. API requests and
responses use canonical decimal strings such as `"1250.00"`; Edge validation
uses a strict decimal-string pattern and passes values to PostgreSQL as
`numeric`. PostgREST projections cast money to text before it reaches Dart.

Phase 8 `defaultPrice`, `estimatedPrice`, and `totalEstimatedCost` domain fields
move from `double` to this exact type. Existing PostgreSQL `numeric(12,2)` data
does not need conversion. Formatting may convert a value for display only, but
all validation, comparison, storage, and server calculations stay exact.

## Data model

### Types

```text
invoice_document_status: draft | finalized | cancelled
invoice_payment_status: unpaid | partially_paid | paid
invoice_discount_type: none | fixed | percentage
invoice_item_source: catalogue | treatment_plan_item
payment_method: cash | card | bank_transfer | other
financial_entry_kind:
  payment_applied | credit_created | credit_applied |
  refund_invoice | refund_credit |
  correction_invoice | correction_credit
invoice_document_generation_status: pending | available | failed
invoice_document_locale: en | ru | ar
```

### Billing settings and number counter

```text
clinic_billing_settings
  clinic_id uuid primary key
  default_tax_rate numeric(5,2) default 0
  invoice_prefix text default 'INV'
  updated_by uuid
  updated_at timestamptz

clinic_invoice_counters
  clinic_id uuid primary key
  next_number bigint
```

Only Owners read or update billing settings. Counters are not exposed through
the Data API. The finalization command locks one clinic counter row with
`FOR UPDATE`, increments it, and formats a unique number. A failed transaction
does not consume a number; a cancelled finalized invoice never releases one.

### Invoices and items

```text
invoices
  id uuid primary key
  clinic_id uuid
  patient_id uuid
  invoice_number text nullable
  sequence_number bigint nullable
  document_status invoice_document_status
  payment_status invoice_payment_status
  currency_code char(3)
  discount_type invoice_discount_type
  discount_value numeric(14,2)
  discount_amount numeric(14,2)
  tax_rate numeric(5,2)
  subtotal numeric(14,2)
  tax_amount numeric(14,2)
  total numeric(14,2)
  paid_amount numeric(14,2)
  outstanding_balance numeric(14,2)
  clinical_approved_by uuid nullable
  clinical_approved_at timestamptz nullable
  prepared_by uuid
  finalized_by uuid nullable
  finalized_at timestamptz nullable
  cancelled_by uuid nullable
  cancelled_at timestamptz nullable
  cancellation_reason text nullable
  patient_name_snapshot text nullable
  patient_number_snapshot text nullable
  clinic_name_snapshot text nullable
  revision integer
  financial_revision bigint
  created_at / updated_at timestamptz

invoice_items
  id uuid primary key
  clinic_id uuid
  invoice_id uuid
  source invoice_item_source
  procedure_id uuid
  treatment_plan_item_id uuid nullable
  procedure_name_snapshot text
  category_snapshot text
  description_snapshot text nullable
  tooth_number_snapshot smallint nullable
  quantity numeric(8,2)
  unit_price numeric(14,2)
  line_total numeric(14,2)
  sort_order integer
  created_at timestamptz
```

Draft totals are stored caches maintained only by protected commands. Every
mutation recalculates them in PostgreSQL. Finalized fields and items are
immutable. Foreign keys use `ON DELETE RESTRICT`.

`revision` provides optimistic concurrency for draft changes. Every update
includes the revision loaded by the user. `financial_revision` increments only
when a payment, credit, refund, or correction changes the financial snapshot.

### Payments, credit account, and append-only ledger

```text
payments
  id uuid primary key
  clinic_id uuid
  patient_id uuid
  received_for_invoice_id uuid
  amount_received numeric(14,2)
  method payment_method
  reference text nullable
  received_at timestamptz
  recorded_by uuid
  command_id uuid unique within clinic
  created_at timestamptz

patient_credit_accounts
  clinic_id uuid
  patient_id uuid
  currency_code char(3)
  balance numeric(14,2)
  revision bigint
  updated_at timestamptz
  primary key (clinic_id, patient_id, currency_code)

financial_ledger_entries
  id uuid primary key
  clinic_id uuid
  patient_id uuid
  invoice_id uuid nullable
  payment_id uuid nullable
  reverses_entry_id uuid nullable
  command_id uuid
  kind financial_entry_kind
  amount numeric(14,2) positive
  invoice_delta numeric(14,2)
  credit_delta numeric(14,2)
  reason text nullable
  created_by uuid
  created_at timestamptz
```

Payments and ledger entries are append-only. There is no normal update or
delete command. `patient_credit_accounts.balance` and invoice paid/balance
fields are lockable caches whose values must equal the ledger; database tests
assert that invariant.

Recording a payment of `P` locks the patient credit account and invoice in a
consistent order, rechecks the balance, applies `min(P, outstanding)` to the
invoice, and creates credit for the excess. Applying credit posts one atomic
entry with a positive invoice effect and equal negative credit effect. A refund
or correction references the affected earlier entry, cannot exceed its
remaining unreversed amount, and posts the opposite effect. Refund means money
was returned; correction means an earlier record was entered incorrectly. Both
require an Owner and a reason.

Commands acquire locks in this order: patient credit account, invoice by UUID,
then referenced ledger entries by UUID. Transactions contain only database
work and never wait for PDF generation or another network call. This prevents
negative credit, duplicate allocation, over-refund, and common deadlocks.

### Idempotency receipts

```text
billing_command_receipts
  clinic_id uuid
  command_id uuid
  action text
  actor_user_id uuid
  response jsonb
  created_at timestamptz
  primary key (clinic_id, command_id)
```

Every financial mutation requires a fresh client UUID and stores a safe result
in the same transaction. A retry with the same actor/action returns the stored
result; reuse for different input is rejected. Receipt payloads contain IDs and
statuses, not clinical descriptions, filenames, or printable content.

## PDF architecture

### Immutable versions

A finalized invoice's clinical and pricing snapshot never changes, but the PDF
must show payments and current outstanding balance. Therefore a document is
versioned by `invoice.financial_revision` and locale:

```text
invoice_documents
  id uuid primary key
  clinic_id uuid
  patient_id uuid
  invoice_id uuid
  financial_revision bigint
  locale invoice_document_locale
  template_version smallint
  status invoice_document_generation_status
  storage_bucket text fixed to 'invoice-pdfs'
  storage_object_path text unique
  content_sha256 text nullable
  size_bytes bigint nullable
  generated_by uuid
  generated_at timestamptz nullable
  failure_code text nullable
  created_at timestamptz

unique (invoice_id, financial_revision, locale, template_version)
```

Older documents remain private and auditable. An export always resolves or
generates the current financial revision. This means a PDF printed after a
payment contains the updated payment and balance without rewriting a PDF that
was previously issued.

### Rendering and storage

The dedicated JWT-protected `invoice-pdf` Edge Function:

1. authorizes Owner, Dentist, or Receptionist access to one finalized invoice;
2. claims the unique document version idempotently;
3. loads a bounded snapshot of at most 100 items and its financial entries;
4. renders a basic PDF with pinned, redistributable Latin/Cyrillic and Arabic
   fonts, correct right-to-left shaping, no external resource fetches, and no
   hidden clinical notes;
5. calculates SHA-256 and uploads create-only to a private `invoice-pdfs`
   bucket;
6. marks metadata available and returns a signed URL valid for 60 seconds.

The PDF contains clinic name, invoice number/date, patient name/number,
authorized itemized procedures, quantity, unit price, line totals, subtotal,
discount, tax, total, payments as of the document revision, credit applied,
and outstanding balance. It contains no clinical-session notes, diagnoses,
odontogram data, patient contact information, file links, or internal audit
reasons.

The renderer lives behind an `InvoiceDocumentService` port. Flutter knows only
how to request an export and open the returned URL. The initial server adapter
uses a pinned lightweight PDF library and bundled fonts. Rendering stays under
the current Supabase Free Edge limits by bounding item count and fonts. A
provider change replaces the server renderer/storage adapter without changing
the Flutter billing domain.

The bucket is private, PDF-only, and capped at 2 MiB per object. Paths contain
IDs rather than names:

```text
clinic_id/invoice_id/document_id/invoice.pdf
```

Clients receive no Storage insert, list, update, or delete policies. The Edge
Function uploads with its server credential after database authorization and
returns only a short-lived signed URL. Signed URLs are never logged or stored
in Flutter preferences.

If generation fails after invoice finalization, the invoice remains valid and
the UI shows a retryable document error. A stale `pending` claim can be retried;
an available version is never overwritten.

## Database authorization and RLS

Every Phase 11 table in `public` has RLS enabled and explicit grants. Browser
clients receive only the SELECT grants they need and no direct INSERT, UPDATE,
or DELETE privileges.

- `invoices`: active Owner, Dentist, or Receptionist in the same clinic may
  read summary columns. Clinical snapshots are not stored in this table.
- `invoice_items`: only active Owner or Dentist in the same clinic may select.
- `payments`: Owner and Receptionist may select operational payment history.
  Dentists receive only invoice aggregate paid/balance fields.
- `patient_credit_accounts`: Owner and Receptionist may read the balance.
- `financial_ledger_entries`: Owner may read full financial entries;
  Receptionist receives a restricted server/read projection needed for payment
  operations. Dentist and Assistant receive no ledger rows.
- `invoice_documents`: Owner, Dentist, and Receptionist may read safe document
  metadata for finalized invoices. No role directly reads Storage objects.
- billing settings are Owner-only; counters and command receipts are server-only.

Complex RLS checks use existing indexed private membership helpers, wrap
`auth.uid()` in `select`, and always include clinic filters. Security-definer
helpers remain in the unexposed `private` schema with an empty search path and
revoked execution. Public mutation functions are revoked from `public`,
`anon`, and `authenticated`, then granted explicitly to `service_role` only.
The Edge Function passes the authenticated user ID, and every database command
revalidates identity, active membership, role, target clinic, lifecycle, and
cross-table scope inside the transaction.

## Protected API

RLS-protected reads are paginated and select explicit columns:

```text
invoice summaries by active clinic, patient, state, date, and search
patient invoice history
one invoice summary
invoice items for Owner/Dentist only
payment history for Owner/Receptionist only
patient credit balance for Owner/Receptionist only
safe PDF version metadata
```

The JWT-protected `billing` Edge Function exposes:

```text
update_billing_settings
create_invoice_draft
add_invoice_item
update_invoice_item
remove_invoice_item
approve_invoice_content
reopen_invoice_content
set_invoice_financials
finalize_invoice
cancel_invoice
record_payment
apply_patient_credit
refund_financial_entry
correct_financial_entry
```

The separate `invoice-pdf` function exposes:

```text
export_current_invoice_pdf
```

Financial mutations are never automatically replayed by Dio. The UI disables
duplicate submission and offers an explicit retry with the same command UUID
after an uncertain response. The database receipt guarantees exactly one
financial effect.

Expected errors use stable codes and safe HTTP mappings, including forbidden,
unavailable clinic/patient/invoice/source, archived patient, stale revision,
clinical approval required, empty invoice, duplicate treatment item, invalid
money/rate/quantity, finalized-only or draft-only action, insufficient credit,
over-refund, payment command conflict, nonzero paid balance, PDF pending, and
PDF generation unavailable. Raw SQL, item descriptions, payment references,
patient identifiers from another clinic, and Storage paths never appear in an
error response or log.

## Audit events

Phase 11 writes these immutable events:

```text
invoice_draft_created
invoice_content_approved
invoice_finalized
invoice_cancelled
payment_recorded
patient_credit_created
patient_credit_applied
payment_refunded
payment_corrected
invoice_pdf_exported
```

Safe audit metadata includes clinic, patient, invoice/payment/document IDs,
currency, amount where needed for financial accountability, state transition,
actor, and command ID. It excludes procedure descriptions, patient name,
payment reference, refund reason text, PDF URL/path/hash, and clinical notes.
The reason remains protected in the financial record and is available to the
Owner in Phase 11; the full audit browser arrives in Phase 13.

## Flutter UI and navigation

### Clinic Billing workspace

The desktop sidebar **Billing** destination opens `/billing`. Owner, Dentist,
and Receptionist see it; Assistant does not. The page provides:

- summary cards for unpaid total, partially paid count, paid count, and
  unapplied credit for the active clinic;
- paginated invoice table with invoice number, patient, issue date, total,
  paid, balance, document/payment status, and actions;
- patient, invoice number, status, and date filters with debounced search;
- loading, empty, permission, error, refresh, and load-more states;
- role-specific actions: item detail for Owner/Dentist, payment for
  Owner/Receptionist, and finalized PDF export for all three roles.

Phase 12 may reuse these aggregates on the Dashboard. Phase 11 does not build
the main dashboard or revenue analytics.

### Patient Billing

The Patient Profile **Billing** action opens `/patients/:patientId/billing`.
It shows invoice history and, for Owner/Receptionist, available patient credit.
Archived patients show history and financial actions on existing invoices but
no **New invoice** action.

### Draft editor

The editor shows the patient, currency, clinical approval state, item source,
quantity, unit price, line total, subtotal, discount, tax, and total.

- Dentist controls item source and quantity and approves clinical content.
- Owner controls unit prices, discount, tax, language, and finalization.
- Values are server-returned after each save; the client preview is never the
  authoritative total.
- Revision conflicts stop the save and require reload rather than overwriting
  another user's work.
- A combined Owner+Dentist sees both action groups in sequence.

### Invoice detail and payment

Owner/Dentist detail contains the immutable itemized snapshot. Receptionist
detail contains only summary totals, payment state, credit, **Record payment**,
and **Export PDF**.

The payment dialog requires positive exact amount, method, received date/time,
and optional short reference. Before submission it explains how much will pay
the invoice and how much will become credit. This preview is informative; the
locked database transaction determines the final allocation. A result shows
the applied amount, new balance, and credit created.

Owner-only refund/correction dialogs show the selected protected ledger entry,
remaining reversible amount, exact amount, and required reason. The UI never
offers deletion or editing of a completed payment.

### Responsive and localization behavior

- Desktop uses a list/detail split view and keeps totals visible beside the
  draft items.
- Tablet uses a full-width table or cards with a side sheet for detail.
- Mobile uses invoice cards and separate full-screen editor/detail/payment
  routes; the total and primary action remain visible without covering fields.
- English, Russian, and Arabic strings are generated. Arabic uses RTL item and
  PDF layouts while invoice numbers and decimal amounts preserve readable
  direction.
- Status always uses text and icon as well as color. Money includes the currency
  code; no symbol alone is used where it could be ambiguous.

## Performance and indexes

Indexes match actual access patterns and RLS joins:

```text
invoices (clinic_id, finalized_at desc, id desc)
invoices (clinic_id, patient_id, created_at desc, id desc)
invoices (clinic_id, document_status, payment_status, finalized_at desc)
unique invoices (clinic_id, invoice_number) where invoice_number is not null
unique invoice_items (treatment_plan_item_id)
  where treatment_plan_item_id is not null and parent invoice is non-cancelled
invoice_items (invoice_id, sort_order)
payments (clinic_id, patient_id, received_at desc, id desc)
payments (received_for_invoice_id, received_at desc)
financial_ledger_entries (invoice_id, created_at, id)
financial_ledger_entries (clinic_id, patient_id, created_at, id)
financial_ledger_entries (reverses_entry_id)
invoice_documents (invoice_id, financial_revision, locale, template_version)
```

Because a partial index cannot use another table's status directly, duplicate
treatment-item billing is enforced with a dedicated claim table or a trigger
maintained in the same protected invoice commands. The implementation spike
will choose the simpler constraint-backed form and test cancellation/reuse.
Every foreign key used for joins or restriction checks receives an appropriate
index. Lists use keyset pagination after the first page rather than large
offset scans.

## Portability

Flutter depends on `BillingRepository`, `InvoiceDocumentService`, and exact
domain values, never Supabase maps, Storage paths, or PDF library types.
Supabase adapters own RLS reads, Edge commands, and signed URLs. PostgreSQL
owns calculation and ledger invariants. A future backend can replace the
repository/data-source and document adapters while retaining billing screens
and workflows.

## Files proposed for implementation

Create:

```text
docs/PHASE_11_BILLING_ARCHITECTURE.md
supabase/migrations/<timestamp>_add_billing_ledger.sql
supabase/migrations/<timestamp>_add_billing_commands.sql
supabase/tests/billing_rls.test.sql
supabase/functions/billing/index.ts
supabase/functions/invoice-pdf/index.ts
supabase/functions/invoice-pdf/fonts/<licensed-font-files>
lib/core/value/money.dart
lib/features/billing/domain/billing_models.dart
lib/features/billing/domain/billing_repository.dart
lib/features/billing/domain/invoice_document_service.dart
lib/features/billing/data/billing_data_source.dart
lib/features/billing/data/supabase_billing_data_source.dart
lib/features/billing/data/supabase_billing_repository.dart
lib/features/billing/data/supabase_invoice_document_service.dart
lib/features/billing/presentation/billing_cubit.dart
lib/features/billing/presentation/invoice_editor_cubit.dart
lib/features/billing/presentation/pages/billing_pages.dart
test/core/value/money_test.dart
test/billing/billing_cubit_test.dart
test/billing/invoice_editor_cubit_test.dart
test/billing/supabase_billing_data_source_test.dart
test/billing/billing_pages_test.dart
```

Change:

```text
supabase/config.toml
pubspec.yaml / pubspec.lock only if the PDF renderer needs a pinned dependency
lib/features/treatment_plan/domain/treatment_plan_models.dart
lib/features/treatment_plan/data/supabase_treatment_plan_repository.dart
supabase/functions/treatment-plans/index.ts
lib/app/bootstrap/bootstrap.dart and generated DI
lib/app/app.dart
lib/app/router/app_router.dart
lib/features/patient/presentation/pages/patient_pages.dart
lib/app/localization/arb/app_en.arb
lib/app/localization/arb/app_ru.arb
lib/app/localization/arb/app_ar.arb
README.md, ARCHITECTURE.md, DATABASE.md, PERMISSIONS.md
```

## Implementation sequence after approval

1. Spike exact-money serialization and the bounded multilingual PDF renderer
   with fictional data. Pin dependencies/fonts and record their licenses.
2. Create migrations using the Supabase CLI, then add types, tables,
   constraints, indexes, explicit grants, RLS, immutable-ledger guards, and
   service-only commands.
3. Add pgTAP tests and concurrent integration checks for numbering, payment
   idempotency, overpayment, credit application, refund/correction limits,
   cross-clinic isolation, and receptionist clinical-content denial.
4. Add the protected billing and invoice-PDF Edge Functions with strict decimal
   strings, bounded inputs, safe errors, private Storage, and idempotency.
5. Introduce the exact Money value and refactor Phase 8 price mappings. Add the
   Phase 11 domain/data repositories and focused tests.
6. Build the Billing workspace, patient Billing area, draft editor, approvals,
   payments, credit, refunds/corrections, and PDF export in all three languages
   and responsive layouts.
7. Generate code/localizations, apply migrations without resetting fictional
   local data, run authenticated role/PDF smoke tests, and complete every
   verification command. Do not implement Phase 12.

## Verification and completion record

The implemented slice includes the exact `Money` boundary, RLS-protected
billing reads, service-only and idempotent database commands, immutable ledger
and reversal records, responsive English/Russian/Arabic Flutter billing UI,
and server-generated multilingual PDFs in private Storage. Phase 8 treatment
price mappings were moved from binary floating point to canonical decimal
strings, and the shared patient Edge Function's UUID and optional-email
validation defects discovered during the authenticated workflow were fixed.

Completion evidence:

- `dart format .`: 162 files checked, no changes required.
- `flutter analyze`: no issues.
- `flutter test`: 94 passed; four opt-in local suites skipped by design.
- `supabase test db --local`: 239 tests passed across ten suites, including
  all 32 Phase 11 billing tests, while existing fictional demo data remained.
- `supabase db lint --local --level warning`: no Phase 11 warnings. Four
  pre-existing Phase 6 schedule-function warnings remain documented.
- The authenticated local billing smoke passed patient creation, combined
  Owner/Dentist roles, procedure and invoice preparation, clinical approval,
  exact fixed-discount-then-tax totals, permanent numbering, overpayment
  credit, Arabic PDF generation, private upload, signed download, and PDF
  signature validation.
- The Flutter Web release build completed successfully, including its Wasm
  dry run.

The broader cases below remain the architecture's test strategy for future
hardening and production readiness. The completion evidence above states the
checks actually executed in Phase 11.

## Verification plan

Required automated checks:

```text
dart format .
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
supabase test db --local
supabase db lint --local --level warning --fail-on error
flutter build web --dart-define-from-file=config/local.json
```

Database coverage includes exact rounding boundaries, maximum values, invoice
state constraints, immutable snapshots, number uniqueness, same-command retry,
different-input command conflict, double-submit concurrency, cross-clinic
isolation, role combinations, Assistant denial, Receptionist item denial,
archived-patient creation denial, duplicate treatment item prevention,
overpayment credit, concurrent credit application, negative-credit prevention,
partial/full refund, over-refund rejection, correction reversal, nonzero-paid
cancellation denial, and safe audit metadata.

Edge smoke tests use fictional accounts for all four roles. They cover JWT
validation, safe errors, draft/approval/finalization, uncertain payment retry,
credit creation/application, Owner refund, and Receptionist restrictions. PDF
checks generate English, Russian, and Arabic current-revision documents,
extract text, render pages to images for visual review, verify RTL text and
totals, confirm the private 60-second URL, and prove that another clinic and an
Assistant cannot retrieve it.

Flutter tests cover exact Money parsing/formatting, typed failures, pagination,
revision conflict, role-specific actions, payment allocation display,
duplicate-tap prevention, PDF launch, loading/empty/error states, narrow mobile
layouts, large text, and Arabic RTL.

Phase 11 is complete only when every gate passes and financial invariants still
hold after deliberate retry and concurrency tests.

## Implemented result and verification

Phase 11 was approved and implemented on 2026-09-12. The implementation adds
the billing schema and protected commands, exact Dart money handling, Billing
workspace and patient Billing routes, role-aware invoice workflows, manual
payments and overpayment credit, immutable financial reversals, and private
English/Russian/Arabic invoice PDF generation. It also corrects the existing
patient Edge Function's UUID and optional-email validation, which had caused
valid patient creation to return a generic unavailable message.

Final verification completed with 162 Dart files formatted, zero Flutter
analysis findings, 94 active Flutter tests passing with four opt-in local
suites skipped by default, all 239 pgTAP database tests passing, all 32 focused
billing pgTAP tests passing against a database containing existing demo data,
and a successful Flutter Web build including its Wasm dry run. An authenticated
local billing smoke test also completed the full fictional workflow, proved
that two simultaneous retries produce one payment and one credit allocation,
and generated an Arabic private PDF whose signed download began with a valid
PDF signature.

Database lint has no Phase 11 findings. It retains four earlier Phase 6
warnings in two appointment/schedule helper functions: two enum return casts
and two unused parameters. Those warnings do not fail the configured error
gate and remain recorded for appointment maintenance rather than being changed
inside the billing phase.

## Risks and trade-offs

- **Legal status:** The PDF is an internal clinic invoice, not a certified
  fiscal receipt. Real-patient or real-money use is blocked by the production
  legal/readiness gate.
- **Ledger complexity:** Append-only entries require more tables and tests than
  editing a payment balance, but they preserve the history required by the
  Master Specification and prevent silent financial changes.
- **PDF runtime:** Multilingual font embedding and Arabic shaping consume Edge
  CPU and bundle space. Item count, font assets, and output size are bounded;
  the renderer spike must pass on the Free local runtime before schema/UI work.
- **Historical documents:** Keeping every issued PDF revision consumes more
  Storage, but preserves what was actually exported. MVP demo data stays small,
  and retention for production is part of the later legal review.
- **Phase 8 exact-money correction:** This is a cross-feature refactor, so the
  full treatment-plan suite must pass before billing work continues.

## Current technical references

- [Supabase breaking-change changelog](https://supabase.com/changelog?types=breaking-change)
- [Supabase Edge Function limits](https://supabase.com/docs/guides/functions/limits)
- [Supabase private Storage buckets](https://supabase.com/docs/guides/storage/buckets/fundamentals)
- [Serving private Storage assets](https://supabase.com/docs/guides/storage/serving/downloads)
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [PostgreSQL explicit locking and deadlocks](https://www.postgresql.org/docs/current/explicit-locking.html)
- [PostgreSQL numeric types](https://www.postgresql.org/docs/current/datatype-numeric.html)

The 2026 Data API auto-exposure change is handled by explicit grants and RLS.
The current hosted Edge limits are 256 MB memory, 2 seconds CPU per request,
and 150 seconds wall time on Free. The design keeps PDF inputs and dependencies
bounded and performs all database locks in short transactions before rendering.
