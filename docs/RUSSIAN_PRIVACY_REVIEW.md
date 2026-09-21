# DentaFlow — Russian legal/privacy review brief

Status: unanswered review checklist; not a legal opinion, compliance certification, or permission to enter real patient data. The clinic and qualified Russian legal/privacy/security reviewers must record decisions and evidence before production use. Research date: 2026-09-06.

Current-policy update: this review is deferred to future production planning. It does not block fictional-data development/MVP validation under the [free-only infrastructure policy](HOSTING_DECISION.md). No real patient medical data is authorized during that phase.

Provide reviewers with the data inventory, role matrix, architecture/data-flow diagram, selected provider contracts/subprocessors, proposed backup locations, incident runbook, and patient/guardian workflows. The geographic review must include primary data, replicas, backups, auth records, audit/logging, exports, email delivery, support access, monitoring, and recovery-test copies.

| Topic | Questions requiring review | Required output |
| --- | --- | --- |
| Primary location/localization | Where may Russian patient identity, personal, and medical data be collected, recorded, stored, updated, and processed? What localization duties apply to this clinic/service? | Approved locations and data-flow constraints |
| Backups and replicas | Where may backups, transaction logs, replicas, exported archives, and recovery copies reside? Does encryption change any applicable restriction? | Location rules for every copy, including keys |
| Cross-border activity | Is any foreign storage/processing, remote support, telemetry, SMTP, or subprocessor access permitted? What notices, assessments, or restrictions apply? | Approved transfers or explicit prohibition |
| Medical confidentiality | What handling/access restrictions apply to medical records and confidentiality? Is OWNER-only clinical oversight access permissible as designed? | Approved roles, purposes, safeguards, and any required revisions |
| Retention | What periods apply separately to clinical records, children’s records, invoices/payments, audit trails, files, and backups? | Retention schedule by record type |
| Archive/deletion | When must data be retained, archived, corrected, anonymized, or destroyed? How are requests, legal holds, backups, and tenant closure handled? | Approved procedure; no automatic hard-deletion policy assumed |
| Access logging | Which reads/writes/exports must be recorded, for how long, and with what integrity/access guarantees? Is the proposed explicit-access strategy sufficient? | Approved event and retention specification |
| Consent and documentation | Which lawful bases, consents/notices, agreements, and evidence are required? How are guardian authority, minors, unknown DOB, and changes in capacity handled? | Required forms, evidence, and workflow rules |
| Third parties | Which party is responsible for which processing obligations? What contracts and subprocessor disclosures are needed for cloud, backup, email, support, and monitoring providers? | Executed agreements and responsibility map |
| Security requirements | What system classification, threat assessment, encryption/certification, access controls, incident procedures, or independent assessments apply? | Approved security requirements and evidence plan |
| Regulator processes | Are registration/notification, cross-border notifications, incident reporting, or other regulator interactions required, and on what timelines? | Responsible person and documented process |
| Documents/exports | Can the invoice/receipt PDFs be used as intended? What fiscal/medical-document requirements remain outside the MVP, and what separate clinic systems are needed? | Approved document purpose and operational boundary |
| Shared-device fallback | How may minimal appointment references, printed receipts, temporary outage logs, and local downloads be stored, accessed, reconciled, and disposed of? | Approved staff procedure |

Review references to verify against current law: the official [publication entry for Federal Law No. 23-FZ of 28 February 2025](https://publication.pravo.gov.ru/document/0001202502280034), the [Government document listing](https://government.ru/docs/all/157906/), and [Roskomnadzor’s cross-border portal](https://pd.rkn.gov.ru/cross-border-transmission/). Automated retrieval of these official pages failed during this research; this brief does not derive a legal conclusion from inaccessible text. Reviewers must obtain current authoritative law and sector requirements, rather than treating this reference list as exhaustive.

Provider documentation supports technical comparison only. Supabase’s [DPA](https://supabase.com/legal/customer-resources/data-processing-addendum) requires review of processing locations and subprocessors; choosing a named database region alone does not resolve all data flows. A provider's compliance marketing or certifications do not establish DentaFlow's compliance.

For each row, record reviewer, decision, supporting authority/evidence, restrictions, date, and re-review trigger. Until the material questions are resolved and the pilot is approved, development/staging contain fictional patient data only.
