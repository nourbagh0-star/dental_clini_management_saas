# Email verification links — 2026-09-17

Approved flow: register, open the emailed verification link, then sign in.
Signup and hosted password recovery use email links, without code entry.
Recovery callbacks permit only a password change, retain credentials in memory,
and never open a clinic security lease. After reset, global logout is requested.

Hosted Auth uses Supabase's built-in sender for the owner's project-team email
only. Custom SMTP was disabled with a reviewed CLI config push; a subsequent
remote config preview confirmed the default signup and recovery link templates.
The Brevo sender implementation and deployed secrets were removed. No custom SMTP credentials are required for
this signup flow. Built-in delivery is restricted to project-team recipients
and its current two-email-per-hour allowance; arbitrary public registration
email delivery is not supported by this pilot configuration.

Supabase verifies the one-time link before redirecting to the configured site
URL. The Web bootstrap consumes and removes the callback fragment before the
router starts. An isolated Auth client validates the returned user and revokes
the temporary session with local scope. It never writes the callback token to
application storage or opens a clinic security lease. The user then signs in.
Expired/error callbacks show a safe message on the sign-in page. Recovery and
other callback types are rejected by this signup handler.

The local confirmation template uses the same ConfirmationURL placeholder,
with English, Russian, and Arabic wording. The hosted built-in template may
use Supabase's default wording instead of the local multilingual template.

Verification: regular Flutter tests cover the link-waiting screen and
signed-out success/error states. A loopback HTTP test validates the returned
user, confirms local-scope logout, and asserts no persisted login credentials.
The opt-in local Auth integration test follows the emailed confirmation URL
and checks that an explicit password sign-in is still required. That opt-in
test was not run for this change because the local Docker daemon was stopped.
Hosted inbox delivery and link opening remain to be confirmed by the user.
Local recovery integration still exercises the legacy code API and template.

Hosted staff invitation create/resend is unavailable because the built-in Auth
sender cannot deliver the application's custom staff invitation emails. These
actions now fail before database changes. Local Mailpit delivery remains available.

Supabase-only update validation: `dart format lib test`, `flutter analyze`
(no issues), `flutter test` (148 passed, 7 opt-in tests skipped), and the staging
release Web build passed. A subsequent isolated config check reported remote
Auth up to date with SMTP disabled; deployed secret names contain no Brevo key.

Do not push the full local Auth config over the hosted default-sender setup:
local custom templates and hosted built-in-provider restrictions differ.
