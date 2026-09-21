import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { enforceLease, patientReadScope, securityFailure } from "../_shared/security.ts";

type Action = "create_condition" | "resolve_condition" | "mark_condition_in_error" | "read_active" | "read_history";
type Surface = "whole" | "mesial" | "distal" | "occlusal" | "buccal" | "lingual";
type ConditionType =
  | "caries"
  | "filling"
  | "crown"
  | "root_canal"
  | "fracture"
  | "missing"
  | "extraction_required"
  | "implant";

const jsonHeaders = {"Content-Type": "application/json"};
const surfaces = new Set<Surface>(["whole", "mesial", "distal", "occlusal", "buccal", "lingual"]);
const conditionTypes = new Set<ConditionType>([
  "caries",
  "filling",
  "crown",
  "root_canal",
  "fracture",
  "missing",
  "extraction_required",
  "implant",
]);

function record(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function uuid(value: unknown): string | null {
  return typeof value === "string" &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
    ? value
    : null;
}

function nullableText(value: unknown, maximum: number): string | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed.length <= maximum ? trimmed : undefined;
}

function requiredText(value: unknown, maximum: number): string | null {
  const result = nullableText(value, maximum);
  return typeof result === "string" ? result : null;
}

function validFdiNumber(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isInteger(value)) return null;
  const valid = (value >= 11 && value <= 18) || (value >= 21 && value <= 28) ||
    (value >= 31 && value <= 38) || (value >= 41 && value <= 48) ||
    (value >= 51 && value <= 55) || (value >= 61 && value <= 65) ||
    (value >= 71 && value <= 75) || (value >= 81 && value <= 85);
  return valid ? value : null;
}

function conditionInput(value: unknown): Record<string, unknown> | null {
  const input = record(value);
  const toothNumber = validFdiNumber(input?.toothNumber);
  const surface = input?.surface;
  const conditionType = input?.conditionType;
  const notes = nullableText(input?.notes, 2000);
  if (!input || toothNumber === null || typeof surface !== "string" || !surfaces.has(surface as Surface) ||
      typeof conditionType !== "string" || !conditionTypes.has(conditionType as ConditionType) ||
      notes === undefined) return null;
  const wholeToothOnly = conditionType === "missing" || conditionType === "root_canal" ||
    conditionType === "extraction_required" || conditionType === "implant";
  if (wholeToothOnly && surface !== "whole") return null;
  return {toothNumber, surface, conditionType, notes};
}

function validOrigin(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value);
    const local = url.protocol === "http:" &&
      (url.hostname === "localhost" || url.hostname === "127.0.0.1");
    const configured = Deno.env.get("DENTAFLOW_PUBLIC_ORIGIN");
    return (local || url.origin === configured) && url.pathname === "/" && !url.search && !url.hash
      ? url.origin
      : null;
  } catch (_) {
    return null;
  }
}

function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get("origin");
  if (!origin || !validOrigin(origin)) return jsonHeaders;
  return {
    ...jsonHeaders,
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function reply(request: Request, body: Record<string, unknown>, status = 200) {
  return Response.json(body, {status, headers: corsHeaders(request)});
}

function fail(request: Request, status: number, code: string) {
  return reply(request, {error: code}, status);
}

function server() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) throw new Error("server_configuration");
  return createClient(url, key, {auth: {autoRefreshToken: false, persistSession: false}});
}

function publicAuthClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) throw new Error("public_auth_configuration");
  return createClient(url, key, {auth: {autoRefreshToken: false, persistSession: false}});
}

async function authenticatedUser(request: Request) {
  const token = request.headers.get("authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return null;
  const {data, error} = await publicAuthClient().auth.getUser(token);
  return error === null ? data.user : null;
}

function databaseFailure(request: Request, code: string | undefined) {
  if (code === "patient_unavailable" || code === "tooth_condition_unavailable") {
    return fail(request, 404, code);
  }
  if (code === "tooth_condition_edit_forbidden") return fail(request, 403, code);
  if (code === "missing_tooth_conflict" || code === "duplicate_active_tooth_condition" ||
      code === "tooth_condition_not_active") return fail(request, 409, code);
  return fail(request, 422, "invalid_tooth_condition_input");
}

export default {fetch: async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, {status: 204, headers: corsHeaders(request)});
  }
  if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
  const body = record(await request.json().catch(() => null));
  const user = await authenticatedUser(request).catch(() => null);
  const action = body?.action as Action | undefined;
  if (!body || !user || !action) return fail(request, 401, "authentication_required");
  try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }

  try {
    const client = server();
    if (action === "read_active" || action === "read_history") {
      const patientId = uuid(body.patientId);
      const offset = action === "read_history" && Number.isInteger(body.offset)
        ? body.offset as number : 0;
      const limit = action === "read_history" && Number.isInteger(body.limit)
        ? body.limit as number : 100;
      if (!patientId || offset < 0 || offset > 10000 || limit < 1 || limit > 100) {
        return fail(request, 400, "invalid_request");
      }
      const clinicId = await patientReadScope(client, user.id, patientId, true);
      let query = client.from("tooth_conditions").select(
        "id, patient_id, tooth_number, surface, condition_type, status, notes, created_at, resolved_at, error_reason, marked_in_error_at",
      ).eq("patient_id", patientId);
      query = action === "read_active"
        ? query.eq("status", "active").order("tooth_number").order("surface").order("created_at").limit(100)
        : query.order("created_at", {ascending: false}).order("id", {ascending: false})
          .range(offset, offset + limit - 1);
      const {data, error} = await query;
      const {error: auditError} = await client.rpc("audit_record_access", {
        actor_user_id: user.id, target_clinic_id: clinicId,
        access_intent: "odontogram", target_subject_id: patientId,
        target_request_id: crypto.randomUUID(),
      });
      return error || auditError ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
    }
    if (action === "create_condition") {
      const patientId = uuid(body.patientId);
      const input = conditionInput(body.condition);
      if (!patientId || !input) return fail(request, 400, "invalid_request");
      const {data, error} = await client.rpc("tooth_condition_create", {
        actor_user_id: user.id,
        target_patient_id: patientId,
        condition_input: input,
      });
      return error || !uuid(data)
        ? databaseFailure(request, error?.message)
        : reply(request, {conditionId: data}, 201);
    }

    const conditionId = uuid(body.conditionId);
    if (!conditionId) return fail(request, 400, "invalid_request");
    if (action === "resolve_condition") {
      const {error} = await client.rpc("tooth_condition_resolve", {
        actor_user_id: user.id,
        target_condition_id: conditionId,
      });
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "mark_condition_in_error") {
      const reason = requiredText(body.reason, 1000);
      if (!reason) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("tooth_condition_mark_in_error", {
        actor_user_id: user.id,
        target_condition_id: conditionId,
        correction_reason: reason,
      });
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    return fail(request, 400, "invalid_request");
  } catch (_) {
    console.error("odontogram_workflow_failed");
    return fail(request, 503, "service_unavailable");
  }
}};
