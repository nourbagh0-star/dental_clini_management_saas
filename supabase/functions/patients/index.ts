import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  assertClinicRead,
  enforceLease,
  patientReadScope,
  securityFailure,
} from "../_shared/security.ts";

type Action = "create" | "update_demographics" | "update_contacts" | "upsert_medical" | "set_archived" | "search" | "medical_profile";
type BirthPrecision = "exact" | "approximate" | "unknown";

const jsonHeaders = {"Content-Type": "application/json"};
const precisions = new Set<BirthPrecision>(["exact", "approximate", "unknown"]);
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const phonePattern = /^[0-9+(). -]{3,32}$/;

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
function localDate(value: unknown): string | null {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day
    ? value
    : null;
}
function nullableText(value: unknown, maximum: number): string | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed.length <= maximum ? trimmed : undefined;
}
function optionalPhone(value: unknown): string | null | undefined {
  const result = nullableText(value, 32);
  return result === undefined || result === null || phonePattern.test(result) ? result : undefined;
}
function optionalEmail(value: unknown): string | null | undefined {
  const result = nullableText(value, 320);
  if (result === undefined || result === null) return result;
  return emailPattern.test(result) ? result.toLowerCase() : undefined;
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
function demographic(value: unknown): Record<string, unknown> | null {
  const data = record(value);
  const firstName = nullableText(data?.firstName, 120);
  const lastName = nullableText(data?.lastName, 120);
  const middleName = nullableText(data?.middleName, 120);
  const phone = optionalPhone(data?.phone);
  const email = optionalEmail(data?.email);
  const guardianName = nullableText(data?.guardianName, 240);
  const guardianPhone = optionalPhone(data?.guardianPhone);
  const guardianEmail = optionalEmail(data?.guardianEmail);
  const address = nullableText(data?.address, 2000);
  const gender = nullableText(data?.gender, 80);
  const emergencyContact = nullableText(data?.emergencyContact, 1000);
  const administrativeNotes = nullableText(data?.administrativeNotes, 5000);
  const precision = data?.birthDatePrecision;
  const birthDate = data?.birthDate === null || data?.birthDate === undefined || data?.birthDate === ""
    ? null : localDate(data?.birthDate);
  const ageAssessedAt = data?.ageAssessedAt === null || data?.ageAssessedAt === undefined || data?.ageAssessedAt === ""
    ? null : localDate(data?.ageAssessedAt);
  const age = data?.approximateAgeYears;
  const approximateAgeYears = age === null || age === undefined || age === ""
    ? null : typeof age === "number" && Number.isInteger(age) && age >= 0 && age <= 130 ? age : undefined;
  const isMinorDeclared = data?.isMinorDeclared;
  if (!data || !firstName || !lastName || middleName === undefined || phone === undefined || email === undefined ||
      guardianName === undefined || guardianPhone === undefined || guardianEmail === undefined || address === undefined ||
      gender === undefined || emergencyContact === undefined || administrativeNotes === undefined ||
      typeof precision !== "string" || !precisions.has(precision as BirthPrecision) ||
      birthDate === undefined || ageAssessedAt === undefined || approximateAgeYears === undefined ||
      (isMinorDeclared !== undefined && typeof isMinorDeclared !== "boolean")) {
    console.error("patient_demographic_shape_invalid", {
      hasData: data !== null,
      hasFirstName: Boolean(firstName),
      hasLastName: Boolean(lastName),
      contactTypesValid: phone !== undefined && email !== undefined,
      guardianTypesValid: guardianName !== undefined && guardianPhone !== undefined && guardianEmail !== undefined,
      administrativeTypesValid: address !== undefined && gender !== undefined && emergencyContact !== undefined && administrativeNotes !== undefined,
      precisionValid: typeof precision === "string" && precisions.has(precision as BirthPrecision),
      dateTypesValid: birthDate !== undefined && ageAssessedAt !== undefined && approximateAgeYears !== undefined,
      minorFlagValid: isMinorDeclared === undefined || typeof isMinorDeclared === "boolean",
    });
    return null;
  }
  if (!phone && !email && !guardianPhone && !guardianEmail) {
    console.error("patient_demographic_contact_missing");
    return null;
  }
  if ((precision === "exact" && (!birthDate || approximateAgeYears !== null || ageAssessedAt !== null)) ||
      (precision === "approximate" && (birthDate !== null || approximateAgeYears === null || !ageAssessedAt)) ||
      (precision === "unknown" && (birthDate !== null || approximateAgeYears !== null || ageAssessedAt !== null))) {
    console.error("patient_demographic_birth_information_invalid", {precision});
    return null;
  }
  if (isMinorDeclared === true && (!guardianName || (!guardianPhone && !guardianEmail))) {
    console.error("patient_demographic_guardian_missing");
    return null;
  }
  return {firstName, lastName, middleName, phone, email, address, gender, birthDate, birthDatePrecision: precision,
    approximateAgeYears, ageAssessedAt, isMinorDeclared: isMinorDeclared ?? false, guardianName, guardianPhone,
    guardianEmail, emergencyContact, administrativeNotes};
}
function contacts(value: unknown): Record<string, unknown> | null {
  const data = record(value);
  const phone = optionalPhone(data?.phone);
  const email = optionalEmail(data?.email);
  const address = nullableText(data?.address, 2000);
  const guardianName = nullableText(data?.guardianName, 240);
  const guardianPhone = optionalPhone(data?.guardianPhone);
  const guardianEmail = optionalEmail(data?.guardianEmail);
  const emergencyContact = nullableText(data?.emergencyContact, 1000);
  return !data || phone === undefined || email === undefined || address === undefined || guardianName === undefined ||
      guardianPhone === undefined || guardianEmail === undefined || emergencyContact === undefined
    ? null : {phone, email, address, guardianName, guardianPhone, guardianEmail, emergencyContact};
}
function medical(value: unknown): Record<string, unknown> | null {
  const data = record(value);
  const allergies = nullableText(data?.allergies, 5000);
  const currentMedications = nullableText(data?.currentMedications, 5000);
  const chronicConditions = nullableText(data?.chronicConditions, 5000);
  const importantMedicalNotes = nullableText(data?.importantMedicalNotes, 10000);
  return !data || allergies === undefined || currentMedications === undefined || chronicConditions === undefined ||
      importantMedicalNotes === undefined
    ? null : {allergies, currentMedications, chronicConditions, importantMedicalNotes};
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
  if (code === "patient_unavailable") return fail(request, 404, code);
  if (code === "patient_edit_forbidden") return fail(request, 403, code);
  return fail(request, 422, "invalid_patient_input");
}

export default {fetch: async (request: Request) => {
  if (request.method === "OPTIONS") return new Response(null, {status: 204, headers: corsHeaders(request)});
  if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
  const body = record(await request.json().catch(() => null));
  const user = await authenticatedUser(request).catch(() => null);
  const action = body?.action as Action | undefined;
  if (!body || !user || !action) return fail(request, 401, "authentication_required");
  try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
  try {
    const client = server();
    if (action === "search") {
      const clinicId = uuid(body.clinicId);
      const query = typeof body.query === "string" ? body.query.trim() : null;
      const offset = Number.isInteger(body.offset) ? body.offset as number : -1;
      const limit = Number.isInteger(body.limit) ? body.limit as number : 0;
      if (!clinicId || query === null || query.length > 200 || offset < 0 || offset > 10000 || limit < 1 || limit > 50) {
        return fail(request, 400, "invalid_request");
      }
      await assertClinicRead(client, user.id, clinicId);
      let selection = client.from("patients").select(
        "id, clinic_id, patient_number, first_name, last_name, middle_name, phone, email, birth_date, birth_date_precision, approximate_age_years, age_assessed_at, is_minor_declared, guardian_name, guardian_phone, guardian_email, administrative_notes, archived_at",
      ).eq("clinic_id", clinicId);
      if (query.length > 0) {
        const escaped = query.replaceAll("%", "\\%").replaceAll(",", "\\,");
        const pattern = `%${escaped}%`;
        selection = selection.or(`first_name.ilike.${pattern},last_name.ilike.${pattern},phone.ilike.${pattern},email.ilike.${pattern},patient_number.ilike.${pattern}`);
      }
      const {data, error} = await selection.order("last_name").order("first_name")
        .range(offset, offset + limit - 1);
      if (error) return fail(request, 503, "service_unavailable");
      const {error: auditError} = await client.rpc("audit_record_access", {
        actor_user_id: user.id, target_clinic_id: clinicId,
        access_intent: "patient_search", target_subject_id: clinicId,
        target_request_id: crypto.randomUUID(), result_count: data?.length ?? 0,
        requested_page_size: limit, search_present: query.length > 0,
      });
      return auditError ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
    }
    if (action === "medical_profile") {
      const patientId = uuid(body.patientId);
      if (!patientId) return fail(request, 400, "invalid_request");
      const clinicId = await patientReadScope(client, user.id, patientId, true);
      const {data, error} = await client.from("patient_medical_profiles")
        .select("allergies, current_medications, chronic_conditions, important_medical_notes")
        .eq("patient_id", patientId).maybeSingle();
      const {error: auditError} = await client.rpc("audit_record_access", {
        actor_user_id: user.id, target_clinic_id: clinicId,
        access_intent: "medical_record", target_subject_id: patientId,
        target_request_id: crypto.randomUUID(),
      });
      return error || auditError ? fail(request, 503, "service_unavailable") : reply(request, {row: data});
    }
    if (action === "create") {
      const clinicId = uuid(body.clinicId); const input = demographic(body.demographic);
      if (!clinicId) return fail(request, 400, "invalid_clinic_id");
      if (!input) return fail(request, 400, "invalid_patient_input");
      const {data, error} = await client.rpc("patient_create", {actor_user_id: user.id, target_clinic_id: clinicId, demographic: input});
      return error || !uuid(data) ? databaseFailure(request, error?.message) : reply(request, {patientId: data}, 201);
    }
    const patientId = uuid(body.patientId);
    if (!patientId) return fail(request, 400, "invalid_request");
    if (action === "update_demographics") {
      const input = demographic(body.demographic); if (!input) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("patient_update_demographics", {actor_user_id: user.id, target_patient_id: patientId, demographic: input});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "update_contacts") {
      const input = contacts(body.contact); if (!input) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("patient_update_contacts", {actor_user_id: user.id, target_patient_id: patientId, contact: input});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "upsert_medical") {
      const input = medical(body.medical); if (!input) return fail(request, 400, "invalid_request");
      const {error} = await client.rpc("patient_upsert_medical_profile", {actor_user_id: user.id, target_patient_id: patientId, medical: input});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    if (action === "set_archived" && typeof body.isArchived === "boolean") {
      const {error} = await client.rpc("patient_set_archived", {actor_user_id: user.id, target_patient_id: patientId, next_archived: body.isArchived});
      return error ? databaseFailure(request, error.message) : reply(request, {ok: true});
    }
    return fail(request, 400, "invalid_request");
  } catch (_) {
    console.error("patient_workflow_failed");
    return fail(request, 503, "service_unavailable");
  }
}};
