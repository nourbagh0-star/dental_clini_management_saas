import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { enforceLease, securityFailure } from "../_shared/security.ts";

type JsonObject = Record<string, unknown>;
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const datePattern = /^\d{4}-\d{2}-\d{2}$/;
const categories = new Set([
  "access", "patient_administration", "scheduling", "clinical",
  "financial", "staff_security",
]);
const intents = new Set([
  "audit_log", "patient_search", "patient_profile", "medical_record",
  "odontogram", "treatment_plan", "clinical_sessions", "patient_files",
  "file_preview", "file_download",
]);

function record(value: unknown): JsonObject | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as JsonObject
    : null;
}
function uuid(value: unknown): string | null {
  return typeof value === "string" && uuidPattern.test(value) ? value : null;
}
function optionalUuid(value: unknown): string | null | undefined {
  if (value === null || value === undefined || value === "") return null;
  return uuid(value) ?? undefined;
}
function boundedText(value: unknown, max: number): string | null | undefined {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value !== "string") return undefined;
  const next = value.trim();
  return next.length >= 1 && next.length <= max ? next : undefined;
}
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
function responseHeaders(request: Request, requestId: string): HeadersInit {
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
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Vary": "Origin",
      }
      : {}),
  };
}
function reply(
  request: Request,
  requestId: string,
  body: JsonObject,
  status = 200,
) {
  return Response.json(body, {
    status,
    headers: responseHeaders(request, requestId),
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
function client(keyName: "public" | "service") {
  const url = Deno.env.get("SUPABASE_URL");
  const key = keyName === "service"
    ? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
      Deno.env.get("SUPABASE_SECRET_KEY")
    : Deno.env.get("SUPABASE_ANON_KEY") ??
      Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) throw new Error("server_configuration");
  return createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
async function authenticatedUser(request: Request) {
  const token = request.headers.get("authorization")
    ?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return null;
  const { data, error } = await client("public").auth.getUser(token);
  return error === null ? data.user : null;
}
function databaseFailure(
  request: Request,
  requestId: string,
  message: string,
) {
  const forbidden = message === "audit_read_forbidden" ||
    message === "audit_access_forbidden";
  const invalid = message === "invalid_audit_query" ||
    message === "invalid_audit_access";
  console.error(JSON.stringify({
    event: "audit_operation_failed",
    requestId,
    category: forbidden ? "forbidden" : invalid ? "invalid" : "database",
  }));
  return fail(
    request,
    requestId,
    forbidden ? 403 : invalid ? 400 : 503,
    forbidden ? "audit_forbidden" : invalid ? "invalid_audit_request" :
      "audit_unavailable",
  );
}

async function listEvents(
  request: Request,
  requestId: string,
  actorUserId: string,
) {
  const query = new URL(request.url).searchParams;
  const clinicId = uuid(query.get("clinicId"));
  const from = query.get("from");
  const to = query.get("to");
  const actor = optionalUuid(query.get("actorUserId"));
  const category = boundedText(query.get("category"), 40);
  const eventType = boundedText(query.get("eventType"), 100);
  const subjectType = boundedText(query.get("subjectType"), 100);
  const cursorAt = boundedText(query.get("cursorAt"), 40);
  const cursorId = optionalUuid(query.get("cursorId"));
  const rawLimit = query.get("limit") ?? "50";
  const limit = /^\d{1,2}$/.test(rawLimit) ? Number(rawLimit) : 0;
  const known = new Set([
    "clinicId", "from", "to", "actorUserId", "category", "eventType",
    "subjectType", "cursorAt", "cursorId", "limit",
  ]);
  const unknown = [...query.keys()].some((key) => !known.has(key));
  if (!clinicId || !from || !datePattern.test(from) || !to ||
    !datePattern.test(to) || actor === undefined || category === undefined ||
    (category !== null && !categories.has(category)) ||
    eventType === undefined || subjectType === undefined ||
    cursorAt === undefined || cursorId === undefined || limit < 1 ||
    limit > 50 || ((cursorAt === null) !== (cursorId === null)) || unknown) {
    return fail(request, requestId, 400, "invalid_audit_request");
  }
  const { data, error } = await client("service").rpc("audit_event_page", {
    actor_user_id: actorUserId,
    target_clinic_id: clinicId,
    range_from: from,
    range_to_exclusive: to,
    filter_actor_user_id: actor,
    filter_category: category,
    filter_event_type: eventType,
    filter_subject_type: subjectType,
    page_limit: limit,
    cursor_occurred_at: cursorAt,
    cursor_id: cursorId,
  });
  if (error) return databaseFailure(request, requestId, error.message);
  if (!record(data)) return fail(request, requestId, 503, "audit_unavailable");
  return reply(request, requestId, data as JsonObject);
}

async function recordAccess(
  request: Request,
  requestId: string,
  actorUserId: string,
) {
  let body: JsonObject | null = null;
  try {
    body = record(await request.json());
  } catch (_) {
    return fail(request, requestId, 400, "invalid_audit_request");
  }
  const clinicId = uuid(body?.clinicId);
  const intent = boundedText(body?.intent, 40);
  const subjectId = uuid(body?.subjectId);
  const commandId = uuid(body?.requestId);
  const resultCount = body?.resultCount;
  const pageSize = body?.pageSize;
  const searchPresent = body?.searchPresent;
  if (!clinicId || !intent || !intents.has(intent) || !subjectId ||
    !commandId || (resultCount !== undefined &&
      (!Number.isInteger(resultCount) || (resultCount as number) < 0 ||
        (resultCount as number) > 50)) ||
    (pageSize !== undefined &&
      (!Number.isInteger(pageSize) || (pageSize as number) < 1 ||
        (pageSize as number) > 50)) ||
    (searchPresent !== undefined && typeof searchPresent !== "boolean")) {
    return fail(request, requestId, 400, "invalid_audit_request");
  }
  const { data, error } = await client("service").rpc("audit_record_access", {
    actor_user_id: actorUserId,
    target_clinic_id: clinicId,
    access_intent: intent,
    target_subject_id: subjectId,
    target_request_id: commandId,
    result_count: resultCount ?? null,
    requested_page_size: pageSize ?? null,
    search_present: searchPresent ?? null,
  });
  if (error) return databaseFailure(request, requestId, error.message);
  return reply(request, requestId, { eventId: data }, 201);
}

export default {
  fetch: async (request: Request) => {
    const requestId = crypto.randomUUID();
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: responseHeaders(request, requestId),
      });
    }
    if (request.method !== "GET" && request.method !== "POST") {
      return fail(request, requestId, 405, "method_not_allowed");
    }
    const user = await authenticatedUser(request).catch(() => null);
    if (!user) return fail(request, requestId, 401, "authentication_required");
    try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
    try {
      return request.method === "GET"
        ? await listEvents(request, requestId, user.id)
        : await recordAccess(request, requestId, user.id);
    } catch (_) {
      console.error(JSON.stringify({
        event: "audit_operation_failed",
        requestId,
        category: "unexpected",
      }));
      return fail(request, requestId, 503, "audit_unavailable");
    }
  },
};
