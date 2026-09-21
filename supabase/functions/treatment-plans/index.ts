import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  assertClinicRead,
  enforceLease,
  patientReadScope,
  securityFailure,
} from "../_shared/security.ts";

type Json = Record<string, unknown>;
const jsonHeaders = {"Content-Type": "application/json"};
const planStatuses = new Set(["active", "completed", "cancelled"]);
const itemStatuses = new Set(["approved", "in_progress", "completed", "cancelled"]);

function record(value: unknown): Json | null {
  return typeof value === "object" && value !== null && !Array.isArray(value) ? value as Json : null;
}
function uuid(value: unknown): string | null {
  return typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value) ? value : null;
}
function optionalText(value: unknown, maximum: number): string | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") return undefined;
  const result = value.trim();
  return result.length === 0 ? null : result.length <= maximum ? result : undefined;
}
function requiredText(value: unknown, maximum: number): string | null {
  const result = optionalText(value, maximum);
  return typeof result === "string" ? result : null;
}
function money(value: unknown): string | null | undefined {
  if (value === null || value === undefined || value === "") return null;
  return typeof value === "string" && /^(0|[1-9]\d{0,9})(?:\.\d{1,2})?$/.test(value)
    ? value : undefined;
}
function validFdi(value: number): boolean {
  return (value >= 11 && value <= 18) || (value >= 21 && value <= 28) ||
    (value >= 31 && value <= 38) || (value >= 41 && value <= 48) ||
    (value >= 51 && value <= 55) || (value >= 61 && value <= 65) ||
    (value >= 71 && value <= 75) || (value >= 81 && value <= 85);
}
function procedureInput(value: unknown): Json | null {
  const input = record(value); const name = requiredText(input?.name, 160);
  const category = requiredText(input?.category, 100); const defaultPrice = money(input?.defaultPrice);
  const durationMinutes = input?.durationMinutes;
  return !input || !name || !category || defaultPrice === null || defaultPrice === undefined || typeof durationMinutes !== "number" || !Number.isInteger(durationMinutes) || durationMinutes < 5 || durationMinutes > 720
    ? null : {name, category, defaultPrice, durationMinutes};
}
function itemInput(value: unknown): Json | null {
  const input = record(value); const procedureId = uuid(input?.procedureId);
  const description = optionalText(input?.description, 2000); const estimatedPrice = money(input?.estimatedPrice);
  const rawTooth = input?.toothNumber; const toothNumber = rawTooth === null || rawTooth === undefined || rawTooth === "" ? null : rawTooth;
  const rawDentist = input?.assignedDentistId;
  const assignedDentistId = rawDentist === null || rawDentist === undefined || rawDentist === "" ? null : uuid(rawDentist);
  if (!input || !procedureId || description === undefined || estimatedPrice === undefined ||
      (toothNumber !== null && (typeof toothNumber !== "number" || !Number.isInteger(toothNumber) || !validFdi(toothNumber))) ||
      (rawDentist !== null && rawDentist !== undefined && rawDentist !== "" && assignedDentistId === null)) return null;
  return {procedureId, toothNumber, description, estimatedPrice, assignedDentistId};
}
function validOrigin(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value); const configured = Deno.env.get("DENTAFLOW_PUBLIC_ORIGIN");
    const local = url.protocol === "http:" && (url.hostname === "localhost" || url.hostname === "127.0.0.1");
    return (local || url.origin === configured) && url.pathname === "/" && !url.search && !url.hash ? url.origin : null;
  } catch (_) { return null; }
}
function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get("origin");
  return !origin || !validOrigin(origin) ? jsonHeaders : {...jsonHeaders, "Access-Control-Allow-Origin": origin, "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS", "Vary": "Origin"};
}
function reply(request: Request, body: Json, status = 200) { return Response.json(body, {status, headers: corsHeaders(request)}); }
function fail(request: Request, status: number, error: string) { return reply(request, {error}, status); }
function server() {
  const url = Deno.env.get("SUPABASE_URL"); const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) throw new Error("server_configuration");
  return createClient(url, key, {auth: {autoRefreshToken: false, persistSession: false}});
}
function publicAuthClient() {
  const url = Deno.env.get("SUPABASE_URL"); const key = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  if (!url || !key) throw new Error("public_auth_configuration");
  return createClient(url, key, {auth: {autoRefreshToken: false, persistSession: false}});
}
async function authenticatedUser(request: Request) {
  const token = request.headers.get("authorization")?.match(/^Bearer (.+)$/i)?.[1]; if (!token) return null;
  const {data, error} = await publicAuthClient().auth.getUser(token); return error === null ? data.user : null;
}
function databaseFailure(request: Request, code?: string) {
  if (code === "treatment_plan_edit_forbidden") return fail(request, 403, code);
  if (["patient_unavailable", "procedure_unavailable", "treatment_plan_unavailable", "treatment_plan_item_unavailable", "assigned_dentist_unavailable"].includes(code ?? "")) return fail(request, 404, code!);
  if (["treatment_plan_draft_only", "treatment_plan_active_required", "invalid_treatment_plan_transition", "invalid_treatment_plan_item_transition", "treatment_plan_items_required", "treatment_plan_active_exists"].includes(code ?? "")) return fail(request, 409, code!);
  return fail(request, 422, code?.startsWith("invalid_") === true ? code! : "invalid_treatment_plan_input");
}

export default {fetch: async (request: Request) => {
  if (request.method === "OPTIONS") return new Response(null, {status: 204, headers: corsHeaders(request)});
  if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
  const body = record(await request.json().catch(() => null)); const user = await authenticatedUser(request).catch(() => null); const action = body?.action;
  if (!body || !user || typeof action !== "string") return fail(request, 401, "authentication_required");
  try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
  try {
    const client = server();
    if (action === "read_procedures") {
      const clinicId = uuid(body.clinicId);
      if (!clinicId) return fail(request, 400, "invalid_request");
      await assertClinicRead(client, user.id, clinicId, true);
      const {data, error} = await client.from("procedure_money_rows")
        .select("id, clinic_id, name, category, default_price, duration_minutes, active")
        .eq("clinic_id", clinicId).order("active", {ascending: false}).order("name").limit(500);
      return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
    }
    if (action === "read_plans") {
      const patientId = uuid(body.patientId);
      if (!patientId) return fail(request, 400, "invalid_request");
      const clinicId = await patientReadScope(client, user.id, patientId, true);
      const {data, error} = await client.from("treatment_plan_money_rows")
        .select("id, clinic_id, patient_id, dentist_member_id, status, notes, total_estimated_cost, updated_at")
        .eq("patient_id", patientId).order("updated_at", {ascending: false}).limit(100);
      const {error: auditError} = await client.rpc("audit_record_access", {
        actor_user_id: user.id, target_clinic_id: clinicId,
        access_intent: "treatment_plan", target_subject_id: patientId,
        target_request_id: crypto.randomUUID(),
      });
      return error || auditError ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
    }
    if (action === "read_items") {
      const planId = uuid(body.planId);
      if (!planId) return fail(request, 400, "invalid_request");
      const {data: plan, error: planError} = await client.from("treatment_plans")
        .select("patient_id").eq("id", planId).single();
      if (planError || !uuid(plan?.patient_id)) return fail(request, 404, "treatment_plan_unavailable");
      await patientReadScope(client, user.id, plan.patient_id, true);
      const {data, error} = await client.from("treatment_plan_item_money_rows")
        .select("id, treatment_plan_id, procedure_id, tooth_number, description, estimated_price, status, assigned_dentist_id, sort_order")
        .eq("treatment_plan_id", planId).order("sort_order").limit(250);
      return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
    }
    if (action === "create_procedure" || action === "update_procedure") {
      const input = procedureInput(body.procedure); const clinicId = uuid(body.clinicId); const procedureId = uuid(body.procedureId);
      if (!input || (action === "create_procedure" ? !clinicId : !procedureId)) return fail(request, 400, "invalid_request");
      const {data, error} = action === "create_procedure"
        ? await client.rpc("procedure_create", {actor_user_id: user.id, target_clinic_id: clinicId, input})
        : await client.rpc("procedure_update", {actor_user_id: user.id, target_procedure_id: procedureId, input});
      return error ? databaseFailure(request, error.message) : reply(request, action === "create_procedure" ? {procedureId: data} : {ok: true}, action === "create_procedure" ? 201 : 200);
    }
    if (action === "set_procedure_active") {
      const procedureId = uuid(body.procedureId); if (!procedureId || typeof body.active !== "boolean") return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("procedure_set_active", {actor_user_id: user.id, target_procedure_id: procedureId, next_active: body.active});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "create_plan") {
      const patientId = uuid(body.patientId); const dentistId = uuid(body.dentistMemberId); const notes = optionalText(body.notes, 5000);
      if (!patientId || !dentistId || notes === undefined) return fail(request, 400, "invalid_request");
      const {data, error} = await client.rpc("treatment_plan_create", {actor_user_id: user.id, target_patient_id: patientId, target_dentist_member_id: dentistId, plan_notes: notes});
      return error ? databaseFailure(request, error.message) : reply(request, {planId: data}, 201);
    }
    const planId = uuid(body.planId);
    if (action === "update_draft_plan" && planId) {
      const notes = optionalText(body.notes, 5000); if (notes === undefined) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("treatment_plan_update_draft", {actor_user_id: user.id, target_plan_id: planId, plan_notes: notes});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "transition_plan" && planId && typeof body.status === "string" && planStatuses.has(body.status)) {
      const {error} = await client.rpc("treatment_plan_transition", {actor_user_id: user.id, target_plan_id: planId, next_status: body.status});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "add_plan_item" || action === "update_draft_plan_item") {
      const input = itemInput(body.item); const itemId = uuid(body.itemId);
      if (!input || (action === "add_plan_item" ? !planId : !itemId)) return fail(request, 400, "invalid_request");
      const {data, error} = action === "add_plan_item"
        ? await client.rpc("treatment_plan_item_add", {actor_user_id: user.id, target_plan_id: planId, input})
        : await client.rpc("treatment_plan_item_update_draft", {actor_user_id: user.id, target_item_id: itemId, input});
      return error ? databaseFailure(request, error.message) : reply(request, action === "add_plan_item" ? {itemId: data} : {ok: true}, action === "add_plan_item" ? 201 : 200);
    }
    const itemId = uuid(body.itemId);
    if (action === "transition_plan_item" && itemId && typeof body.status === "string" && itemStatuses.has(body.status)) {
      const {error} = await client.rpc("treatment_plan_item_transition", {actor_user_id: user.id, target_item_id: itemId, next_status: body.status});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "reorder_draft_plan_items" && planId && Array.isArray(body.itemIds) && body.itemIds.length <= 100) {
      const itemIds = body.itemIds.map(uuid); if (itemIds.some((id) => id === null)) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("treatment_plan_items_reorder_draft", {actor_user_id: user.id, target_plan_id: planId, ordered_item_ids: itemIds});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    return fail(request, 400, "invalid_request");
  } catch (_) {
    console.error("treatment_plans_workflow_failed");
    return fail(request, 503, "service_unavailable");
  }
}};
