import {
  authenticate,
  corsHeaders,
  fail,
  record,
  reply,
  securityFailure,
  serviceClient,
  uuid,
} from "../_shared/security.ts";

function idList(value: unknown): string[] | null {
  if (!Array.isArray(value) || value.length > 100) return null;
  const values = value.map(uuid);
  return values.every((item) => item !== null) ? values as string[] : null;
}

export default {
  fetch: async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, {status: 204, headers: corsHeaders(request)});
    }
    if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
    const body = record(await request.json().catch(() => null));
    if (!body || typeof body.action !== "string") return fail(request, 400, "invalid_request");
    let context;
    try {
      context = await authenticate(request);
    } catch (error) {
      return securityFailure(request, error);
    }
    if (!context) return fail(request, 401, "authentication_required");
    const client = serviceClient();
    try {
      if (body.action === "memberships") {
        const {data, error} = await client.from("clinic_members")
          .select("id, clinic_id").eq("user_id", context.userId).eq("is_active", true)
          .limit(100);
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (body.action === "roles") {
        const ids = idList(body.membershipIds);
        if (!ids) return fail(request, 400, "invalid_request");
        const {data: owned, error: ownedError} = await client.from("clinic_members")
          .select("id").eq("user_id", context.userId).eq("is_active", true).in("id", ids);
        if (ownedError || (owned?.length ?? 0) !== ids.length) return fail(request, 403, "workspace_forbidden");
        const {data, error} = await client.from("clinic_member_roles")
          .select("clinic_member_id, role").in("clinic_member_id", ids).limit(400);
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (body.action === "clinics") {
        const ids = idList(body.clinicIds);
        if (!ids) return fail(request, 400, "invalid_request");
        const {data: memberships, error: membershipError} = await client.from("clinic_members")
          .select("clinic_id").eq("user_id", context.userId).eq("is_active", true).in("clinic_id", ids);
        if (membershipError || (memberships?.length ?? 0) !== ids.length) {
          return fail(request, 403, "workspace_forbidden");
        }
        const {data, error} = await client.from("clinics")
          .select("id, name, currency_code, time_zone").in("id", ids).limit(100);
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (body.action === "create") {
        if (typeof body.name !== "string" || typeof body.ownerDisplayName !== "string" ||
            typeof body.currencyCode !== "string" || typeof body.timeZone !== "string") {
          return fail(request, 400, "invalid_request");
        }
        const {data, error} = await client.rpc("security_workspace_create_clinic", {
          actor_user_id: context.userId,
          supplied_name: body.name,
          supplied_owner_display_name: body.ownerDisplayName,
          supplied_currency_code: body.currencyCode,
          supplied_time_zone: body.timeZone,
        });
        return error || !record(data)
          ? fail(request, 422, "invalid_workspace_input")
          : reply(request, data as Record<string, unknown>, 201);
      }
      return fail(request, 400, "invalid_request");
    } catch (error) {
      console.error(
        "workspace_failed",
        error instanceof Error ? error.message : "unexpected",
      );
      return fail(request, 503, "service_unavailable");
    }
  },
};
