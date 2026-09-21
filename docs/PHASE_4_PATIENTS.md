# Phase 4 — Patients

Status: implemented. Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 25–30.

## Delivered behavior

- Active clinic staff can search patient records by name, phone, email, or clinic-scoped patient number. The query is submitted deliberately, and results are paginated by the data layer.
- Owners, dentists, and receptionists can create a patient. Each creation receives a clinic-scoped `PAT-00001`-style number from an atomic counter.
- A patient must have a first name, last name, and at least one usable patient or guardian contact method. The application supports exact, approximate, and unknown birth-date information.
- A known or declared minor requires a guardian name and at least one guardian contact method. The database applies the clinic time zone when it calculates age from an exact date of birth.
- Medical information is separate from demographic data. Owners, dentists, and assistants can read it; only dentists can change it.
- Only owners can archive or restore a patient. The interface asks for confirmation, and the protected server command repeats the owner check.

## Security and data design

- Patient data is isolated by clinic through row-level security. Browser clients have read-only table access; protected Edge Function commands perform all writes.
- The Flutter application never receives a Supabase service-role key. The `patients` Edge Function authenticates the caller and delegates authorization to service-role-only database commands.
- Patient demographics, contacts, and medical profile are stored separately. No sensitive field values are written to application logs.
- Development data remains fictional/demo data only, as required by the master specification.

## Current UI scope

- Patient list and search, new-patient form, overview profile, medical-profile access, and owner archive/restore are available.
- Later phases will fill the profile's Appointments, Dental Chart, Treatment Plans, Visits, Files, Billing, and Activity areas as those modules are delivered.

## Verification

- `dart format .`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 58 tests with 3 opt-in local-service tests skipped by default.
- `supabase test db --local`: passed, including 83 pgTAP checks across clinic, staff, schedule, and patient security suites.
- `supabase db lint --local --schema public --fail-on error`: passed with no application-schema errors. The unscoped linter includes pgTAP's bundled test-extension functions and reports compatibility errors from that external `extensions` schema, so it is intentionally excluded from application linting.
- `supabase db advisors --local --type security --fail-on error`: passed with no findings.
