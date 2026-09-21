import {
  authenticate,
  commandDigest,
  corsHeaders,
  fail,
  isolatedAuthClient,
  record,
  reply,
  securityFailure,
  serviceClient,
  proofToken,
  uuid,
} from "../_shared/security.ts";

type LeaseResponse = { unlockedUntil: string; revision: number };
const ownerActions = new Set([
  "owner_invitation_create", "owner_invitation_resend",
  "owner_invitation_revoke", "staff_roles_replace", "staff_deactivate",
  "billing_settings_update", "financial_entry_reverse",
]);

function lease(value: unknown): LeaseResponse | null {
  const item = record(value);
  return typeof item?.unlockedUntil === "string" &&
      Number.isInteger(item.revision) && (item.revision as number) > 0
    ? {
      unlockedUntil: item.unlockedUntil,
      revision: item.revision as number,
    }
    : null;
}

export default {
  fetch: async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(request) });
    }
    if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
    if (!(request.headers.get("content-type") ?? "").toLowerCase().startsWith("application/json")) {
      return fail(request, 415, "invalid_request");
    }
    const rawBody = await request.text();
    if (new TextEncoder().encode(rawBody).byteLength > 16_384) {
      return fail(request, 413, "invalid_request");
    }
    const body = record((() => {
      try {
        return JSON.parse(rawBody);
      } catch (_) {
        return null;
      }
    })());
    if (!body || !["complete_password_setup", "unlock", "restore", "renew", "lock", "prove_owner_action"].includes(String(body.action))) {
      return fail(request, 400, "invalid_request");
    }
    const context = await authenticate(request, false).catch(() => null);
    if (!context) return fail(request, 401, "authentication_required");
    const service = serviceClient();
    try {
      if (body.action === "complete_password_setup") {
        const { error } = await service.rpc("staff_password_setup_complete", {
          actor_user_id: context.userId, target_session_id: context.sessionId,
        });
        return error ? fail(request, 403, "password_change_required") : reply(request, { ok: true });
      }
      if (body.action !== "lock") {
        const { data: pending, error } = await service.rpc("staff_password_setup_pending", {
          actor_user_id: context.userId, target_session_id: context.sessionId,
        });
        if (error) return securityFailure(request, new Error(error.message));
        if (pending === true) return fail(request, 403, "password_change_required");
      }
      if (body.action === "restore") {
        const { data, error } = await service.rpc("security_session_assert", {
          actor_user_id: context.userId,
          target_session_id: context.sessionId,
        });
        const result = lease(data);
        return error || !result
          ? securityFailure(request, new Error(error?.message ?? "invalid_response"))
          : reply(request, result);
      }
      if (body.action === "unlock") {
        if (typeof body.password !== "string" || body.password.length === 0 ||
            body.password.length > 1024) {
          return fail(request, 400, "invalid_request");
        }
        const verifier = isolatedAuthClient();
        try {
          const { data, error } = await verifier.auth.signInWithPassword({
            email: context.email,
            password: body.password,
          });
          if (error || data.user?.id !== context.userId) {
            return fail(request, 403, "credentials_invalid");
          }
        } finally {
          await verifier.auth.signOut({ scope: "local" }).catch(() => undefined);
        }
        const { data, error } = await service.rpc("security_session_open", {
          actor_user_id: context.userId,
          target_session_id: context.sessionId,
        });
        const result = lease(data);
        return error || !result
          ? securityFailure(request, new Error(error?.message ?? "invalid_response"))
          : reply(request, result);
      }
      if (body.action === "renew") {
        if (!Number.isInteger(body.revision) || (body.revision as number) < 1) {
          return fail(request, 400, "invalid_request");
        }
        const { data, error } = await service.rpc("security_session_renew", {
          actor_user_id: context.userId,
          target_session_id: context.sessionId,
          expected_revision: body.revision,
        });
        const result = lease(data);
        return error || !result
          ? securityFailure(request, new Error(error?.message ?? "invalid_response"))
          : reply(request, result);
      }
      if (body.action === "prove_owner_action") {
        const clinicId = uuid(body.clinicId);
        const targetId = body.targetId === null || body.targetId === undefined
          ? null
          : uuid(body.targetId);
        const actionCode = typeof body.actionCode === "string" &&
            ownerActions.has(body.actionCode)
          ? body.actionCode
          : null;
        const command = record(body.command);
        if (!clinicId || !actionCode || !command ||
            (body.targetId !== null && body.targetId !== undefined && !targetId) ||
            typeof body.password !== "string" || body.password.length === 0 ||
            body.password.length > 1024) {
          return fail(request, 400, "invalid_request");
        }
        const verifier = isolatedAuthClient();
        try {
          const { data, error } = await verifier.auth.signInWithPassword({
            email: context.email,
            password: body.password,
          });
          if (error || data.user?.id !== context.userId) {
            return fail(request, 403, "credentials_invalid");
          }
        } finally {
          await verifier.auth.signOut({ scope: "local" }).catch(() => undefined);
        }
        const token = await proofToken();
        const { data, error } = await service.rpc("security_owner_proof_issue", {
          actor_user_id: context.userId,
          target_session_id: context.sessionId,
          target_clinic_id: clinicId,
          target_action: actionCode,
          target_id: targetId,
          target_input_digest: await commandDigest(command),
          target_proof_digest: token.digest,
        });
        if (error || typeof data !== "string") {
          return securityFailure(request, new Error(error?.message ?? "invalid_response"));
        }
        return reply(request, { proof: token.raw, expiresAt: data });
      }
      const { error } = await service.rpc("security_session_lock", {
        actor_user_id: context.userId,
        target_session_id: context.sessionId,
      });
      return error ? securityFailure(request, new Error(error.message)) : reply(request, { ok: true });
    } catch (error) {
      return securityFailure(request, error);
    }
  },
};
