# Permission design baseline

Source: [master specification](docs/MASTER_SPECIFICATION.md). **Business
authorization policies through Phase 14 are implemented and directly tested;
Phase 15 verifies their complete role-separated local MVP workflow.**
Every grant requires active membership in the same clinic. Multiple roles
combine only inside that clinic.

| Capability | OWNER only | DENTIST | ASSISTANT | RECEPTIONIST |
| --- | --- | --- | --- | --- |
| Read clinical information | Oversight | All clinic patients | Treatment support | No |
| Create diagnoses/change tooth state | No | Yes | No | No |
| Draft session notes | No clinical authority | Yes | Yes | No |
| Finalize notes/treatments | No | Yes | No | No |
| Patient demographics | Administrative management | Create/edit | Limited contact updates | Create/edit |
| Schedules | Manage all | Edit own | Read | Read |
| Appointment actions | Administrative | Create/start/complete/cancel/no-show; prior own-rescheduling rule where not superseded | Read/preparation notes only | Create/confirm/reschedule/cancel/no-show |
| Override patient overlap | Never | Never | Never | Never |
| Other specified scheduling overrides | Warning + confirmation + reason + audit | No | No | No |
| Clinical files | Oversight | Yes | Support | No |
| Treatment estimates | Yes | Yes | No prices | Administrative totals only |
| Detailed invoice content | Yes | Yes | No | Restricted finalized approved export only |
| Record payment | Yes | No automatic grant | No | Yes |
| Prices/discounts/refunds/corrections | Yes | No unless also OWNER | No | No |
| Staff/roles/security/audit | Yes | No unless also OWNER | No | No |
| Patient archive/restore | Yes | No | No | No |

Receptionist printing/exporting an authorized finalized invoice is an explicit narrow exception to detailed-invoice browsing restrictions. Printed/exported contents can be seen by the person handling the document; do not describe this as preventing them from reading the PDF. It grants neither clinical editing nor unrestricted invoice-detail browsing. The server authorizes each finalized document export and records an immutable audit event.

Patient files use the approved Phase 10 rule: Dentist and Assistant upload;
Owner, Dentist, and Assistant view; Owner and Dentist archive/restore;
Receptionist receives no file metadata or content. Billing summaries are
available to Owner, Dentist, and Receptionist; item rows to Owner and Dentist;
payments and credit to Owner and Receptionist; price/finalization/refund and
correction commands to Owner; clinical item preparation and approval to
Dentist. Assistants receive no billing access. Multiple roles combine.

Dashboard snapshots are available to every active member through the
authenticated Edge Function. Owner receives all dashboard groups; Dentist
receives appointments, patients, completed treatments, and outstanding
balances; Receptionist receives appointments, patients, and outstanding
balances; Assistant receives appointments and patients. Denied groups are
omitted by PostgreSQL rather than masked only in the interface. Anonymous,
inactive, and cross-clinic callers are denied.

Audit pages and actor filter data are available only to an active Owner in the
same clinic. Direct audit-table reads and every normal update/delete are
denied, including to service credentials. Authorized roles can create a fixed,
safe access event only through the authenticated Edge workflow; record scope
and role checks are repeated in PostgreSQL. Patient clinical areas and file
access fail closed when their required audit event cannot be recorded.

Security acceptance will include direct backend access tests for cross-clinic reads/writes/files, receptionist clinical isolation, assistant finalization restrictions, owner-only clinical write denial, combined roles, and last-owner protection.
