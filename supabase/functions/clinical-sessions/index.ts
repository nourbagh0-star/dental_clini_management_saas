import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { enforceLease, patientReadScope, securityFailure } from "../_shared/security.ts";

type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
type Input = Record<string, unknown>;

const jsonHeaders = { "Content-Type": "application/json" };
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function record(value: unknown): Input | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Input
    : null;
}

function uuid(value: unknown): string | null {
  return typeof value === "string" && uuidPattern.test(value) ? value : null;
}

function optionalUuid(value: unknown): string | null | undefined {
  if (value === null || value === undefined || value === "") return null;
  return uuid(value) ?? undefined;
}

function optionalText(value: unknown, maxLength: number): string | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") return undefined;
  const normalized = value.trim();
  if (normalized.length === 0) return null;
  return normalized.length <= maxLength ? normalized : undefined;
}

function requiredText(value: unknown, maxLength: number): string | null {
  const normalized = optionalText(value, maxLength);
  return typeof normalized === "string" ? normalized : null;
}

function revision(value: unknown): number | null {
  return typeof value === "number" && Number.isInteger(value) && value >= 1
    ? value
    : null;
}

function instant(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.valueOf()) ? null : parsed.toISOString();
}

function validOrigin(value: unknown): string | null {
  if (typeof value !== "string") return null;
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

function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get("origin");
  return !origin || !validOrigin(origin)
    ? jsonHeaders
    : {
      ...jsonHeaders,
      "Access-Control-Allow-Origin": origin,
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Vary": "Origin",
    };
}

function reply(request: Request, body: Json, status = 200) {
  return Response.json(body, { status, headers: corsHeaders(request) });
}

function fail(request: Request, status: number, error: string) {
  return reply(request, { error }, status);
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

function authClient() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) throw new Error("public_auth_configuration");
  return createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function authenticatedUser(request: Request) {
  const token = request.headers.get("authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return null;
  const { data, error } = await authClient().auth.getUser(token);
  return error === null ? data.user : null;
}

function databaseFailure(request: Request, code?: string) {
  if (code === "clinical_session_forbidden") return fail(request, 403, code);
  if ([
    "clinical_session_unavailable",
    "patient_unavailable",
    "appointment_unavailable",
    "dentist_unavailable",
  ].includes(code ?? "")) return fail(request, 404, code!);
  if ([
    "appointment_already_has_session",
    "appointment_not_eligible",
    "assigned_dentist_mismatch",
    "clinical_notes_required",
    "clinical_session_draft_only",
    "clinical_session_finalized_required",
    "clinical_session_revision_conflict",
    "clinical_session_immutable",
    "clinical_session_identity_immutable",
    "clinical_session_amendment_immutable",
    "invalid_clinical_session_transition",
  ].includes(code ?? "")) return fail(request, 409, code!);
  return fail(
    request,
    422,
    code?.startsWith("invalid_") === true
      ? code!
      : "invalid_clinical_session_input",
  );
}

export default {
  fetch: async (request: Request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(request) });
    }
    if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
    const body = record(await request.json().catch(() => null));
    const user = await authenticatedUser(request).catch(() => null);
    const action = body?.action;
    if (!body || !user || typeof action !== "string") {
      return fail(request, 401, "authentication_required");
    }
    try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
    try {
      const client = serverClient();
      if (action === "read_sessions" || action === "read_eligible_appointments") {
        const patientId = uuid(body.patientId);
        const offset = Number.isInteger(body.offset) ? body.offset as number : 0;
        const limit = Number.isInteger(body.limit) ? body.limit as number : 50;
        if (!patientId || offset < 0 || offset > 10000 || limit < 1 || limit > 100) {
          return fail(request, 400, "invalid_request");
        }
        const clinicId = await patientReadScope(client, user.id, patientId, true);
        const query = action === "read_sessions"
          ? client.from("clinical_sessions").select(
            "id, clinic_id, patient_id, appointment_id, dentist_member_id, session_date, clinical_notes, recommendations, status, revision, created_by, updated_by, finalized_by, finalized_at, error_reason, marked_in_error_by, marked_in_error_at, created_at, updated_at",
          ).eq("patient_id", patientId).order("session_date", {ascending: false})
            .order("id", {ascending: false}).range(offset, offset + limit - 1)
          : client.from("appointments").select("id, dentist_member_id, starts_at, status, purpose")
            .eq("patient_id", patientId).in("status", ["scheduled", "confirmed", "in_progress", "completed"])
            .order("starts_at", {ascending: false}).limit(50);
        const {data, error} = await query;
        const {error: auditError} = await client.rpc("audit_record_access", {
          actor_user_id: user.id, target_clinic_id: clinicId,
          access_intent: "clinical_sessions", target_subject_id: patientId,
          target_request_id: crypto.randomUUID(),
        });
        return error || auditError ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (action === "read_amendments") {
        const sessionId = uuid(body.sessionId);
        if (!sessionId) return fail(request, 400, "invalid_request");
        const {data: session, error: sessionError} = await client.from("clinical_sessions")
          .select("patient_id").eq("id", sessionId).single();
        if (sessionError || !uuid(session?.patient_id)) return fail(request, 404, "clinical_session_unavailable");
        await patientReadScope(client, user.id, session.patient_id, true);
        const {data, error} = await client.from("clinical_session_amendments")
          .select("id, clinical_session_id, amendment_text, reason, amended_by, amended_at")
          .eq("clinical_session_id", sessionId).order("amended_at").order("id").limit(250);
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (action === "create_session") {
        const patientId = uuid(body.patientId);
        const appointmentId = optionalUuid(body.appointmentId);
        const dentistId = optionalUuid(body.dentistMemberId);
        const sessionDate = body.sessionDate === null || body.sessionDate === undefined
          ? null
          : instant(body.sessionDate);
        if (!patientId || appointmentId === undefined || dentistId === undefined ||
          (appointmentId === null && (!dentistId || !sessionDate)) ||
          (body.sessionDate !== null && body.sessionDate !== undefined && !sessionDate)) {
          return fail(request, 400, "invalid_request");
        }
        const { data, error } = await client.rpc("clinical_session_create", {
          actor_user_id: user.id,
          target_patient_id: patientId,
          target_appointment_id: appointmentId,
          target_dentist_member_id: dentistId,
          target_session_date: sessionDate,
        });
        return error
          ? databaseFailure(request, error.message)
          : reply(request, { sessionId: data }, 201);
      }
      const sessionId = uuid(body.sessionId);
      if (action === "update_draft_session" && sessionId) {
        const notes = optionalText(body.clinicalNotes, 20000);
        const recommendations = optionalText(body.recommendations, 5000);
        const expectedRevision = revision(body.expectedRevision);
        if (notes === undefined || recommendations === undefined || !expectedRevision) {
          return fail(request, 400, "invalid_request");
        }
        const { error } = await client.rpc("clinical_session_update_draft", {
          actor_user_id: user.id,
          target_session_id: sessionId,
          next_clinical_notes: notes,
          next_recommendations: recommendations,
          expected_revision: expectedRevision,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { ok: true });
      }
      if (action === "finalize_session" && sessionId) {
        const expectedRevision = revision(body.expectedRevision);
        if (!expectedRevision) return fail(request, 400, "invalid_request");
        const { error } = await client.rpc("clinical_session_finalize", {
          actor_user_id: user.id,
          target_session_id: sessionId,
          expected_revision: expectedRevision,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { ok: true });
      }
      if (action === "mark_draft_session_in_error" && sessionId) {
        const expectedRevision = revision(body.expectedRevision);
        const reason = requiredText(body.reason, 1000);
        if (!expectedRevision || !reason) return fail(request, 400, "invalid_request");
        const { error } = await client.rpc("clinical_session_mark_in_error", {
          actor_user_id: user.id,
          target_session_id: sessionId,
          expected_revision: expectedRevision,
          supplied_reason: reason,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { ok: true });
      }
      if (action === "add_session_amendment" && sessionId) {
        const amendmentText = requiredText(body.amendmentText, 10000);
        const reason = requiredText(body.reason, 1000);
        if (!amendmentText || !reason) return fail(request, 400, "invalid_request");
        const { data, error } = await client.rpc("clinical_session_add_amendment", {
          actor_user_id: user.id,
          target_session_id: sessionId,
          next_amendment_text: amendmentText,
          supplied_reason: reason,
        });
        return error
          ? databaseFailure(request, error.message)
          : reply(request, { amendmentId: data }, 201);
      }
      return fail(request, 400, "invalid_request");
    } catch (_) {
      console.error("clinical_sessions_workflow_failed");
      return fail(request, 503, "service_unavailable");
    }
  },
};
