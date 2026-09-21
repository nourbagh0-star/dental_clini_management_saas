# Current permissions

| Actor | Clinics | Memberships |
| --- | --- | --- |
| Anonymous visitor | No read or write access | No read or write access |
| Authenticated creator | Can create a clinic owned by their verified identity; can read their created or actively joined clinics | Can read only their own membership and roles; cannot create, edit, or delete memberships or roles |
| Active owner | Can read every staff membership, role, and invitation in their clinic | Can use the authenticated server workflow to invite, resend, revoke, change roles, and activate/deactivate staff. OWNER additions, removals, and deactivation require password confirmation; direct client writes remain prohibited. |
| Active non-owner | Can read only their own membership and roles | Cannot read invitations or other staff records; direct writes remain prohibited |

Flutter route guards and the privacy lock improve the user experience, but PostgreSQL row-level security is the tenant boundary. Phase 3 Step 2 exposes a protected server API, never a direct client table mutation. Flutter staff and invitation screens remain scheduled for the later Phase 3 steps.
