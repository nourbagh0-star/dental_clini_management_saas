# Database and tenant boundary

Phases 2–3 introduce the first business data. All development records remain fictional.

| Table | Purpose | Client permissions |
| --- | --- | --- |
| `public.clinics` | A clinic tenant: name, currency, time zone, creator, and timestamps | Authenticated users may select their own/active-member clinics and insert a clinic for themselves. No update or delete yet. |
| `public.clinic_members` | An individual clinic/user membership with a verified-email snapshot and activation state | A staff member can select only their own row; owners can read their clinic's directory. Direct writes are prohibited. |
| `public.clinic_member_roles` | Reusable roles for a clinic membership | A staff member can read only their own roles; owners can read roles in their clinic. Direct writes are prohibited. |
| `public.clinic_invitations` | Pending, accepted, revoked, or expired staff invitations | Only owners can read invitations for their clinic. Direct writes are prohibited. |
| `public.clinic_invitation_roles` | Roles proposed by an invitation | Only owners can read invitation roles for their clinic. Direct writes are prohibited. |

`created_by` defaults to `auth.uid()` inside PostgreSQL. The clinic insert policy checks that same value, so the Flutter client never submits an owner identity. An `AFTER INSERT` private trigger creates the first active membership and its OWNER role as part of the transaction.

An invitation stores a normalized email and a one-way token digest, never the raw acceptance token. Last-owner guard triggers block deletion of the final OWNER role and deactivation/deletion of its membership. Every future clinic-owned table must include `clinic_id`, indexes for its tenant query patterns, RLS, explicit grants, and pgTAP coverage before it is exposed to Flutter.

The `staff_create_invitation`, `staff_resend_invitation`, `staff_revoke_invitation`, `staff_accept_invitation`, `staff_replace_member_roles`, and `staff_set_member_active` commands are fixed-search-path security-definer functions. They are executable only by `service_role` inside the authenticated Edge Function, and each rechecks the supplied actor's active OWNER role. The server role has the smallest supporting reads: staff roles, invitation roles, and an invitation's `id` and `email` for a resend. Browser roles have no direct execute permission.
