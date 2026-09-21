# Production readiness gate

**Current state: DEVELOPMENT / DEMO, USD 0 infrastructure, fictional patients only.** None of the following production gates is claimed complete. These do not block building/testing the demo MVP.

- [ ] Production provider and architecture selected.
- [ ] Russian data-location/legal/privacy review completed, including primary data, backups, cross-border processing, medical confidentiality, retention, access logging, consent/guardians, and third parties.
- [ ] RLS tenant isolation and role permissions tested on all access paths.
- [ ] Database backups configured and monitored.
- [ ] Patient-file backups configured and monitored independently.
- [ ] Restore tests completed, including data consistency and restored access permissions.
- [ ] Monitoring/alerts and named incident responsibility in place.
- [ ] Application audit logging operational and protected.
- [ ] Incident/recovery procedure documented and exercised.
- [ ] Owner re-authentication/MFA/security policy finalized.
- [ ] Production human-inactivity timeout finalized; the current three-day demo lease is not approved for real patient data.
- [ ] Primary-tooth visualization needs agreed with the pilot clinic.

Future recovery targets: **RPO 15 minutes, RTO 2 hours**. These are design targets, not measured current guarantees. Free Supabase does not satisfy this gate merely because the demo works.

Supporting deferred research: [hosting](docs/PRODUCTION_HOSTING_RESEARCH.md), [recovery](docs/RECOVERY_AND_ACCESS_SECURITY.md), [privacy questions](docs/RUSSIAN_PRIVACY_REVIEW.md). The master supersedes any conflicting older proposal. No paid plan, domain, monitoring, backup, CI, or production resource is authorized by Phase 0.
