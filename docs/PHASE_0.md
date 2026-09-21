# Phase 0 — Project foundation

Authority: [Master Specification](MASTER_SPECIFICATION.md), sections 80 and 85. Status: Phase 0 implemented and required local checks passed; ready for review. Scope is bootstrap only. Phase 1 authentication has not started.

## Inspection and implementation plan

The initial workspace contained a Flutter starter with Android, iOS, and Web targets, a counter screen, a starter widget test, and earlier planning documents. No Git repository or production infrastructure was configured. Flutter 3.44.8 / Dart 3.12.2 is the validation toolchain.

The implementation steps were:

1. Preserve the master and mark conflicting earlier requirements as superseded.
2. Configure dependencies, strict analysis, localization, code generation, and environment examples.
3. Build application composition, routing, themes, a localized demo shell, and safe startup errors.
4. Add replaceable preferences/session interfaces, a lazy Supabase connection, and guarded Dio transport.
5. Add meaningful foundation tests and a free-usage GitHub Actions workflow.
6. Format, analyze, test, and compile for Web; document results and limitations.

## File structure

```text
lib/
  main.dart
  app/
    app.dart
    bootstrap/       # Initialization, generated DI, preview, startup failures
    router/          # Public preview and unavailable-route handling
    theme/           # Material themes, immutable preferences, appearance Cubit
    localization/    # English/Russian ARBs and generated strings
  core/
    config/          # Validated environment and public backend settings
    error/           # Typed failures and localized messages
    network/         # Supabase adapter, token interface, Dio/interceptors
    storage/         # Non-sensitive preferences interface and adapter
    widgets/         # Shared responsive message page
test/
  app/               # DI, preferences, responsive/localized widget behavior
  core/              # Configuration and HTTP security/retry behavior
  support/           # In-memory stores, tokens, and HTTP adapter
integration_test/    # Opt-in native bootstrap smoke test
config/              # Development/staging public-setting examples
.github/workflows/   # Locked dependencies, generation, format, analyze, tests
docs/                # Master, current requirements, phase status, earlier research
```

Root documentation includes README.md, ARCHITECTURE.md, DATABASE.md, PERMISSIONS.md, SECURITY.md, and PRODUCTION_READINESS.md. Platform metadata identifies the Web/Android application as DentaFlow. Business features will receive their own data/domain/presentation folders in later phases; no medical models or database migrations were invented for bootstrap.

## Validation — 2026-09-07

- `dart format .`: passed, 35 Dart files, final run required no changes.
- `flutter analyze`: passed, no issues found after the final code change.
- `flutter test`: passed, all 27 unit/widget tests.
- `flutter build web`: passed; output is `build/web`. The initial missing Cupertino font warning was fixed by explicitly including the icon-font package. The final build has no missing-font warning. The Wasm compatibility dry run also succeeded; a separate Wasm deployment was not tested.

Validation found and fixed a generated singleton disposal registration error and eager preference-plugin initialization. The latter now occurs within guarded storage operations, allowing the shell to remain accessible with a visible preferences warning if storage is unavailable.

Tests cover unsafe configuration and privileged-key rejection, credential destination restrictions, authenticated request requirements, single-flight refresh, bounded read retry, no mutation replay, sanitized HTTP logs, preference persistence failures, generated dependency resolution, English/Russian theme controls, and layouts at widths 320/800/1440 with enlarged Russian text.

The native integration smoke test is included but has not run on a native device/emulator. Android/iOS release builds and remote GitHub Actions execution have not been verified. No live Supabase service was provisioned or contacted by the test suite; HTTP behavior uses an in-memory adapter. The Web build verifies compilation, not an end-to-end hosted deployment.

## Handoff boundary

Run the credential-free preview using `flutter run -d chrome`. It exposes theme/language settings and demo notices only. Backend authentication, tenant access, appointments, clinical screens, billing, Firebase integration, and production readiness remain later work. No paid service, hosting deployment, real patient data, or production credential was introduced.

Next is the Phase 0 review. Phase 1 needs its own repository review, implementation plan, and file list before work begins.
