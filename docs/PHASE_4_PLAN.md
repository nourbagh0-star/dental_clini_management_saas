# Doctor Schedule — implemented early (official Phase 5)

Status: implemented and locally verified ahead of the official Phase 5 sequence. Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 20–22.

## Delivered behavior

- An active dentist can manage their own weekly hours, breaks, leave, and unavailable periods.
- An active owner can manage the same records for any active dentist in their clinic.
- Active clinic staff can view schedules and use a narrow dentist directory to choose whose calendar to view. The directory exposes only active dentist member IDs and email addresses; it does not grant staff-management access.
- Weekly schedules are versioned by a clinic-local effective date. The server rejects a date before the next clinic day, preserving existing availability rules.
- Weekly hours cannot overlap. Breaks must be inside their working period and cannot overlap. Leave and unavailable periods are UTC intervals, with the Flutter interface displaying them in the viewer's local time and identifying the clinic time zone.
- Browser clients have read-only database access. Every write goes through `doctor-schedules`, which validates the signed-in user and calls database commands that recheck the current clinic role.

## Data model

```text
doctor_schedule_versions
  └─ doctor_working_hours
       └─ doctor_schedule_breaks

doctor_schedule_exceptions
  └─ leave | unavailable
```

Each schedule version links to an active dentist membership and clinic. A database trigger blocks schedules for inactive or non-dentist members. The server receives local weekly times and converts exception instants to UTC before persistence.

## Security design

- All four public tables use RLS and explicit grants.
- Signed-in clinic members may read only schedule data from their active clinic. Anonymous callers receive no table or directory-function access.
- The four mutation commands are executable only by `service_role` inside the protected Edge Function. Their database logic enforces dentist-self or owner authority again, so a forged client payload cannot change another clinic's schedule.
- The schedule dentist directory is a fixed-search-path security-definer function with an explicit active-clinic-membership check. It is read-only and has no anonymous grant.

## Verification

- `supabase migration up --local --yes`: passed.
- `supabase test db --local`: passed, 64 pgTAP checks across clinic, staff, and schedule security suites.
- `supabase db lint --local --fail-on error`: passed.
- `supabase db advisors --local --type security --fail-on error`: passed with no findings.
- The local Edge Runtime loaded `doctor-schedules` successfully.
- `dart format .`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 58 tests with 3 opt-in local-service tests skipped by default.
- `flutter build web --dart-define-from-file=config/local.json`: passed.

## Deliberate Phase 6 dependency

No appointments exist yet, so a schedule change cannot detect affected future appointments. Phase 6 must invoke the existing schedule rules before creating or editing an appointment, and must add the required warning, owner override reason, and manual-resolution flag for future appointments affected by a later schedule change. No appointment is automatically moved or cancelled.
