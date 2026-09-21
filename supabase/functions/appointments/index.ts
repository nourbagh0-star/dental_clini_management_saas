import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { assertClinicRead, enforceLease, securityFailure } from "../_shared/security.ts";

type Action =
  | "create"
  | "reschedule"
  | "confirm"
  | "start"
  | "complete"
  | "cancel"
  | "mark_no_show"
  | "save_preparation_note"
  | "list";

const jsonHeaders = {"Content-Type": "application/json"};
const actions = new Set<Action>([
  "create", "reschedule", "confirm", "start", "complete", "cancel", "mark_no_show", "save_preparation_note", "list",
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
function utcInstant(value: unknown): string | null {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(value)) {
    return null;
  }
  const instant = new Date(value);
  return Number.isNaN(instant.valueOf()) ? null : instant.toISOString();
}
function text(value: unknown, maximum: number, required = false): string | null | undefined {
  if (value === null || value === undefined) return required ? undefined : null;
  if (typeof value !== "string") return undefined;
  const result = value.trim();
  if (result.length === 0) return required ? undefined : null;
  return result.length <= maximum ? result : undefined;
}
function validOrigin(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const origin = new URL(value);
    const local = origin.protocol === "http:" &&
      (origin.hostname === "localhost" || origin.hostname === "127.0.0.1");
    const configured = Deno.env.get("DENTAFLOW_PUBLIC_ORIGIN");
    return (local || origin.origin === configured) && origin.pathname === "/" && !origin.search && !origin.hash
      ? origin.origin
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
  if (code === "patient_unavailable" || code === "appointment_unavailable") return fail(request, 404, code);
  if (code === "appointment_action_forbidden" || code === "active_dentist_required") return fail(request, 403, code);
  if (["patient_overlap", "dentist_overlap", "working_hours_conflict", "leave_conflict", "unavailable_conflict"].includes(code ?? "")) {
    return fail(request, 409, code!);
  }
  if (code === "override_reason_required") return fail(request, 422, code);
  return fail(request, 422, "invalid_appointment_request");
}

export default {fetch: async (request: Request) => {
  if (request.method === "OPTIONS") return new Response(null, {status: 204, headers: corsHeaders(request)});
  if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
  const body = record(await request.json().catch(() => null));
  const action = body?.action;
  const user = await authenticatedUser(request).catch(() => null);
if (!body || !user || typeof action !== "string" || !actions.has(action as Action)) {
return fail(request, 401, "authentication_required");
}
try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }

try {
    const client = server();
    if (action === "list") {
      const clinicId = uuid(body.clinicId);
      const from = utcInstant(body.from);
      const until = utcInstant(body.until);
      if (!clinicId || !from || !until || from >= until ||
          Date.parse(until) - Date.parse(from) > 93 * 24 * 60 * 60 * 1000) {
        return fail(request, 400, "invalid_request");
      }
      await assertClinicRead(client, user.id, clinicId);
      const {data, error} = await client.from("appointments").select(
        "id, clinic_id, patient_id, dentist_member_id, starts_at, ends_at, status, purpose, override_reason, patients(id, first_name, last_name, patient_number), clinic_members(id, display_name), appointment_preparation_notes(note)",
      ).eq("clinic_id", clinicId).gte("starts_at", from).lt("starts_at", until)
        .order("starts_at").limit(1000);
      return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
    }
    if (action === "create") {
      const clinicId = uuid(body.clinicId);
      const patientId = uuid(body.patientId);
      const dentistMemberId = uuid(body.dentistMemberId);
      const startsAt = utcInstant(body.startsAt);
      const endsAt = utcInstant(body.endsAt);
      const purpose = text(body.purpose, 240);
      const overrideReason = text(body.overrideReason, 1000);
      if (!clinicId || !patientId || !dentistMemberId || !startsAt || !endsAt || startsAt >= endsAt ||
          purpose === undefined || overrideReason === undefined) return fail(request, 400, "invalid_request");
      const {data, error} = await client.rpc("appointment_create", {
        actor_user_id: user.id, target_clinic_id: clinicId, target_patient_id: patientId,
        target_dentist_member_id: dentistMemberId, target_starts_at: startsAt, target_ends_at: endsAt,
        appointment_purpose: purpose, supplied_override_reason: overrideReason,
      });
      return error || !uuid(data)
        ? databaseFailure(request, error?.message)
        : reply(request, {appointmentId: data}, 201);
    }

    const appointmentId = uuid(body.appointmentId);
    if (!appointmentId) return fail(request, 400, "invalid_request");
    if (action === "reschedule") {
      const startsAt = utcInstant(body.startsAt);
      const endsAt = utcInstant(body.endsAt);
      const overrideReason = text(body.overrideReason, 1000);
      if (!startsAt || !endsAt || startsAt >= endsAt || overrideReason === undefined) {
        return fail(request, 400, "invalid_request");
      }
      const {error} = await client.rpc("appointment_reschedule", {
        actor_user_id: user.id, target_appointment_id: appointmentId,
        target_starts_at: startsAt, target_ends_at: endsAt, supplied_override_reason: overrideReason,
      });
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "save_preparation_note") {
      const note = text(body.note, 2000, true);
      if (note === undefined) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("appointment_upsert_preparation_note", {
        actor_user_id: user.id, target_appointment_id: appointmentId, next_note: note,
      });
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    const status = action === "confirm" ? "confirmed"
      : action === "start" ? "in_progress"
      : action === "complete" ? "completed"
      : action === "cancel" ? "cancelled"
      : "no_show";
    const cancellationReason = action === "cancel" ? text(body.cancellationReason, 1000, true) : null;
    if (cancellationReason === undefined) return fail(request, 400, "invalid_request");
    const {error} = await client.rpc("appointment_transition", {
      actor_user_id: user.id, target_appointment_id: appointmentId,
      next_status: status, supplied_cancellation_reason: cancellationReason,
    });
    return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
  } catch (_) {
    console.error("appointment_workflow_failed");
    return fail(request, 503, "service_unavailable");
  }
}};
