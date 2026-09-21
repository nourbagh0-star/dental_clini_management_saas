# Database design status

**Current status: migrations and RLS through Phase 14 are implemented and the
Phase 15 local MVP workflow is verified against them.** The
local Supabase Free/PostgreSQL schema covers clinics and roles, schedules,
patients, appointments, odontogram history, treatment plans, clinical
sessions, immutable audit events, private patient-file metadata, invoices,
invoice items, payments, patient credit, immutable financial ledger entries,
idempotency receipts, and private invoice-document metadata. The authoritative
details live in the versioned migrations and phase architecture records.

Phase 13 extends `audit_events` with immutable actor membership, verified-email
and role snapshots, a server-derived event category, and optional request UUID.
Browser and service credentials have no direct table access. An insert trigger
accepts only recognized event types and allowlisted bounded metadata; another
trigger rejects every update and delete. A service-only function records
idempotent sensitive access, and an active-Owner-only function returns at most
50 rows using the `(occurred_at, id)` cursor and a clinic-local date range of at
most 90 days. Patient administration, appointment, and staff security wrappers
write their audit event in the same transaction as the protected mutation.

Phase 12 adds paired `completed_at` and `completed_by` metadata to treatment
plan items and maintains it inside the protected item-status workflow. The
service-only `dashboard_snapshot` function checks active membership, derives
role capabilities in PostgreSQL, applies clinic-local day/week/month
boundaries, and returns bounded safe appointment previews plus authorized
aggregates. Browser roles cannot execute it directly.

Implemented invariants from the [master](docs/MASTER_SPECIFICATION.md) include:

- UUID identifiers and clinic_id on clinic-owned records, with tenant-consistent foreign references and timestamps.
- Independent membership/role relations; one account may have several roles in several clinics. Never remove the last active owner, including under concurrent requests.
- Separate demographic and clinical access boundaries so receptionist reads cannot expose clinical fields. RLS and server constraints protect all paths, not just UI requests.
- Patient number unique per clinic. Email/phone/name/number search with pagination and indexed filters.
- Hard patient-overlap prevention. Only the master-authorized dentist/working-hours/leave conflicts support audited owner override. Recheck concurrent appointments/schedule changes.
- Tooth conditions support active/resolved/entered_in_error; healthy is derived. Clinical amendments preserve finalized history.
- Decimal money end to end; itemized invoices, payment/refund/correction records, excess as patient credit, immutable financial history. Snapshot invoice currency and item pricing.
- Private object identities and metadata with clinic/role authorization. Archive rather than hard-delete clinical/financial records through normal UI.
- Append-only normal-client audit events; no per-returned-row search logging. Appropriate summary events and explicit sensitive access/export events.

Invoice document lifecycle is separate from payment state. Finalization assigns
a clinic-scoped permanent number, and protected database commands calculate all
totals, serialize concurrent financial changes, and preserve reversals instead
of updating ledger history. Money reaches Flutter as canonical decimal text.
The `invoice-pdfs` Storage bucket is private and has no direct client upload,
list, update, or delete path.

Migration scripts, policy tests, and indexes are reviewed together. Never
disable RLS or grant universal authenticated access to resolve implementation
failures. Production backup/recovery selection remains deferred.
