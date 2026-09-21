import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { enforceLease, securityFailure } from "../_shared/security.ts";

type Json = Record<string, unknown>;

function validOrigin(value: string | null): string | null {
  if (!value) return null;
  try {
    const url = new URL(value);
    const configured = Deno.env.get("DENTAFLOW_PUBLIC_ORIGIN");
    const local = url.protocol === "http:" &&
      (url.hostname === "localhost" || url.hostname === "127.0.0.1");
    return (local || url.origin === configured) && url.pathname === "/" &&
        !url.search && !url.hash
      ? url.origin
      : null;
  } catch (_) {
    return null;
  }
}

function headers(request: Request, requestId: string): HeadersInit {
  const origin = validOrigin(request.headers.get("origin"));
  return {
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
    "X-Request-Id": requestId,
    ...(origin
      ? {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Vary": "Origin",
      }
      : {}),
  };
}

function reply(
  request: Request,
  requestId: string,
  body: Json,
  status = 200,
) {
  return Response.json(body, {
    status,
    headers: headers(request, requestId),
  });
}

function fail(
  request: Request,
  requestId: string,
  status: number,
  error: string,
) {
  return reply(request, requestId, { error }, status);
}

function serverClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) throw new Error("server_configuration");
  return createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

function publicAuthClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) throw new Error("public_auth_configuration");
  return createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function authenticatedUser(request: Request) {
  const token = request.headers.get("authorization")
    ?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return null;
  const { data, error } = await publicAuthClient().auth.getUser(token);
  return error === null ? data.user : null;
}

function uuid(value: string | null): string | null {
  return value &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        .test(value)
    ? value
    : null;
}

export default {
  fetch: async (request: Request) => {
    const requestId = crypto.randomUUID();
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: headers(request, requestId),
      });
    }
    if (request.method !== "GET") {
      console.error(JSON.stringify({
        event: "dashboard_method_not_allowed",
        requestId,
        method: request.method,
      }));
      return fail(request, requestId, 405, "method_not_allowed");
    }
    const clinicId = uuid(new URL(request.url).searchParams.get("clinicId"));
    if (!clinicId) {
      return fail(request, requestId, 400, "invalid_dashboard_request");
    }
    const user = await authenticatedUser(request).catch(() => null);
    if (!user) {
      return fail(request, requestId, 401, "authentication_required");
    }
    try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
    try {
      const { data, error } = await serverClient().rpc("dashboard_snapshot", {
        actor_user_id: user.id,
        target_clinic_id: clinicId,
      });
      if (error) {
        const forbidden = error.message === "dashboard_forbidden";
        console.error(JSON.stringify({
          event: "dashboard_snapshot_failed",
          requestId,
          category: forbidden ? "forbidden" : "database",
        }));
        return fail(
          request,
          requestId,
          forbidden ? 403 : 503,
          forbidden ? "dashboard_forbidden" : "dashboard_unavailable",
        );
      }
      if (!data || typeof data !== "object" || Array.isArray(data)) {
        console.error(JSON.stringify({
          event: "dashboard_snapshot_failed",
          requestId,
          category: "invalid_response",
        }));
        return fail(
          request,
          requestId,
          503,
          "dashboard_unavailable",
        );
      }
      return reply(request, requestId, data as Json);
    } catch (_) {
      console.error(JSON.stringify({
        event: "dashboard_snapshot_failed",
        requestId,
        category: "unexpected",
      }));
      return fail(request, requestId, 503, "dashboard_unavailable");
    }
  },
};
