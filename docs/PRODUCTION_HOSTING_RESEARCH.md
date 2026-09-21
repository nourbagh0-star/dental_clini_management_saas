# DentaFlow — Deferred production hosting research

Research date: 2026-09-06. Status: historical research, deferred by the user's subsequent free-only policy. These paid-service comparisons and recommendations are not the active development/MVP infrastructure plan and authorize no purchase. See [current infrastructure policy](HOSTING_DECISION.md). No production provider, budget, or recovery solution is selected. Read with [recovery and access security](RECOVERY_AND_ACCESS_SECURITY.md) and [Russian legal/privacy review questions](RUSSIAN_PRIVACY_REVIEW.md). Reverify all pricing and product details when production planning resumes.

## Earlier proposal — deferred, not approved

Use local Supabase for development and a separate fictional-data staging environment. Keep managed Supabase staging available if useful. Evaluate self-hosted Supabase in an approved Russian location as the leading production candidate because it preserves the requested service stack. Yandex Cloud and Selectel are infrastructure candidates, not approved vendors. A named infrastructure operator, legal review, actual resource quote, migration rehearsal, and recovery test must precede selection.

Retain managed PostgreSQL plus an application service layer as an alternative if the team cannot operate self-hosted database recovery. That option requires integration work and architecture approval. No production option is presently proven to meet both USD 0–50/month and RPO 15 minutes/RTO 2 hours. Do not reduce recovery requirements silently to fit the budget.

## Comparison

| Option | Location and recovery evidence | Operational work and migration | Cost assessment |
| --- | --- | --- | --- |
| Managed Supabase | Published regions do not include Russia. Pro includes daily DB backups; PITR is an add-on. Objects need separate backup. | Lowest Supabase operations burden. Export DB, files, functions, and configuration separately. Full data-location/subprocessor review remains necessary. | Approx. USD 130/month for one Small project with seven-day PITR, before additional services/usage. Exceeds target. |
| Self-hosted Supabase on Russian-region infrastructure | We select compute, DB, objects, and backup locations, subject to review. We must configure continuous DB recovery and independent object backup. | Closest fit to requested stack; team owns patches, monitoring, keys, recovery, and incident response. One VM is a single failure point. | No verified all-in quote. Need compute, disk, object copies, traffic, monitoring, email, and operational support costs. Do not interpret inexpensive entry VM advertising as an adequate production configuration. |
| Yandex Managed PostgreSQL + application services + Object Storage | Russia is an available region. PostgreSQL supports PITR; actual recoverable lag depends on WAL archiving/upload. | Managed DB reduces DB maintenance. Auth/API/files/realtime integration remains our responsibility. Supabase compatibility must be tested rather than assumed. | Published three-host example is about USD 147.59/30 days for DB alone; illustrative, not the pilot's quote or a minimum price. Smaller configuration needs pricing. |
| Selectel Managed PostgreSQL + application services + S3 | PostgreSQL documentation describes seven-day backup retention and WAL creation every ten minutes or by volume. Actual recoverable lag still needs measurement. | Managed DB, but no customer superuser role: check required privileges/extensions before proposing Supabase components against it. Logical export/replication options exist. | Resource-based pricing; no verified sized monthly quote obtained. Need a configuration-specific total. |

Sources: [Supabase regions](https://supabase.com/docs/guides/platform/regions), [Supabase pricing](https://supabase.com/pricing), [Supabase backups](https://supabase.com/docs/guides/platform/backups), [Yandex regions](https://yandex.cloud/en/docs/overview/concepts/region), [Yandex PostgreSQL recovery](https://yandex.cloud/en/docs/managed-postgresql/concepts/backup), [Yandex PostgreSQL pricing](https://yandex.cloud/en/docs/managed-postgresql/pricing), [Selectel PostgreSQL backups](https://docs.selectel.ru/managed-databases/postgresql/backups/), [Selectel PostgreSQL service and limitations](https://selectel.ru/services/cloud/managed-databases/postgresql/).

The Supabase estimate is arithmetic from published rates: Pro 25 + Small compute 15 − compute credit 10 + approximately 100 for seven-day PITR = approximately USD 130/month. One Small production project plus one Micro staging project would be approximately USD 140 before other costs. Daily-only backup does not satisfy a 15-minute loss target. These estimates exclude tax, overages, independent backups, email, and operations; verify rates before purchase. [Pricing](https://supabase.com/pricing), [PITR requirements/pricing](https://supabase.com/docs/guides/platform/backups).

The Yandex example uses three 2-vCPU/8-GB hosts and 100 GB HDD per host. It is useful only as a comparison point; it is not a recommended disk choice or measured DentaFlow sizing. Contracting entity determines billing currency and tax treatment. [Yandex pricing](https://yandex.cloud/en/docs/managed-postgresql/pricing).

## Files, encryption, and independent backups

| Storage choice | Verified capabilities and decision implications |
| --- | --- |
| Managed Supabase Storage | Database backup does not back up object contents. Maintain an independent object inventory/copy and restore process. [Backup limitations](https://supabase.com/docs/guides/platform/backups). |
| Self-hosted Supabase Storage | An S3-compatible backend is configurable; retain Supabase authorization in front of private buckets. Test the selected backend's API behavior and encryption. [S3 configuration](https://supabase.com/docs/guides/self-hosting/self-hosted-s3). |
| Yandex Object Storage | Supports KMS-backed server-side encryption. Key recovery must be part of disaster recovery; deleting the key can make objects unreadable. Confirm the chosen bucket/backup location and enable the intended controls explicitly. [Encryption](https://yandex.cloud/en/docs/storage/concepts/encryption). |
| Selectel S3 | Supports object versioning. Its S3 API compatibility table lists Bucket Encryption as unsupported; do not assume AWS encryption configuration transfers unchanged. Obtain written encryption-at-rest details or evaluate application-side encryption/key management. [Versioning](https://docs.selectel.ru/en/s3/buckets/versioning/), [API compatibility](https://docs.selectel.ru/en/api/object-storage-s3/). |

Proposed baseline: verified TLS for external/service/database connections; encryption for DB disks, files, backups, and secret storage; keys recoverable through separately controlled access. Yandex documents encrypted PostgreSQL backups. Supabase's DPA describes transport and disk encryption controls, but does not settle Russian legal suitability or every processing location. [Yandex backups](https://yandex.cloud/en/docs/managed-postgresql/concepts/backup), [Supabase DPA](https://supabase.com/legal/customer-resources/data-processing-addendum).

Store independent backups in a separate security boundary with separate credentials and retention protection; a second bucket under the same unrestricted application key is insufficient. A second provider/location is conditional on legal approval. Versioning and replicas do not replace independently restorable backups. Keep operational backup retention separate from medical-record retention; no duration is selected yet.

## Portability and environment boundaries

- Flutter domain entities, use cases, and screens depend on repository interfaces. Supabase types and SDK calls stay in replaceable data/auth/file/realtime adapters.
- Keep API endpoints, environment IDs, callbacks, storage configuration, and credentials environment-specific. Development/staging never read production data, backup copies, or secrets.
- Use stable record IDs and logical object keys; do not persist signed URLs as file identity. Keep private file access through an authorized service boundary.
- Preserve SQL schema, grants/RLS, functions, migrations, and seed definitions in version control. Provider administrative configuration, secrets, auth keys, and object manifests need separate export/recovery procedures.
- Supabase-to-self-hosted migration still needs DB/auth review, separate object transfer, function redeployment, callback changes, session/key strategy, and reconciliation. Generic PostgreSQL alone does not replace Supabase Auth, Storage, APIs, or Realtime. This separation is intended to avoid rewriting Flutter features; backend adapters and deployment work remain real costs. [Database migration guide](https://supabase.com/docs/guides/self-hosting/restore-from-platform), [separate object transfer guide](https://supabase.com/docs/guides/self-hosting/copy-from-platform-s3).

For an initial self-hosted sizing quote, assess the documented 4-GB/2-core/40-GB minimum against the 8-GB+/4-core/80-GB+ recommendation, then load-test. Neither specification proves DentaFlow capacity. Avoid adding Kubernetes for this pilot. Pin versions and rehearse upgrades; recent Supabase changes include the self-hosted API gateway and PostgreSQL major version. [Sizing](https://supabase.com/docs/guides/self-hosting/docker), [gateway change](https://supabase.com/changelog/48048-self-hosted-supabase-envoy-becomes-the-default-api-gateway-b), [PostgreSQL change](https://supabase.com/changelog/46080-self-hosted-supabase-upgrading-from-pg-15-to-17-breaking-change).

## Procurement and approval boundary

Obtain a like-for-like quote covering runtime/DB resources, primary and independent storage, WAL volume, object growth, egress/restore traffic, KMS, monitoring, SMTP, staging, and incident support. Current file volume/growth and the responsible operator are not yet known. Prices from dynamic calculators were not sufficient to verify a Russian-provider pilot total; no vendor has been contacted.

Approve the design direction independently of the final vendor. Keep real patient data blocked until location/contracts, the all-in budget, operating responsibility, and measured recovery pass review. The detailed legal checklist is a review brief, not a legal opinion.
