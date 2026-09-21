import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { assertClinicRead, enforceLease, securityFailure } from "../_shared/security.ts";

type Action = "replace_weekly" | "create_exception" | "update_exception" | "delete_exception" | "preview_exception_impact" | "preview_weekly_impact" | "list_versions" | "list_exceptions" | "list_dentists";
type ExceptionKind = "leave" | "unavailable";
type WeeklyBreak = {startsAt: string; endsAt: string};
type WeeklyPeriod = {weekday: number; startsAt: string; endsAt: string; breaks: WeeklyBreak[]};

const jsonHeaders = {"Content-Type": "application/json"};
const exceptionKinds = new Set<ExceptionKind>(["leave", "unavailable"]);

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
function time(value: unknown): string | null {
  return typeof value === "string" && /^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value) ? value : null;
}
function localDate(value: unknown): string | null {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const [year, month, day] = value.split("-").map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day
    ? value
    : null;
}
function utcInstant(value: unknown): string | null {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(value)) {
    return null;
  }
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : date.toISOString();
}
function weeklyPeriods(value: unknown): WeeklyPeriod[] | null {
  if (!Array.isArray(value) || value.length > 14) return null;
  const periods: WeeklyPeriod[] = [];
  for (const raw of value) {
    const item = record(raw);
    const weekday = item?.weekday;
    const startsAt = time(item?.startsAt);
    const endsAt = time(item?.endsAt);
    if (!Number.isInteger(weekday) || typeof weekday !== "number" || weekday < 1 || weekday > 7 ||
        !startsAt || !endsAt || startsAt >= endsAt || !Array.isArray(item?.breaks) || item.breaks.length > 4) {
      return null;
    }
    const breaks: WeeklyBreak[] = [];
    for (const rawBreak of item.breaks) {
      const pause = record(rawBreak);
      const pauseStartsAt = time(pause?.startsAt);
      const pauseEndsAt = time(pause?.endsAt);
      if (!pauseStartsAt || !pauseEndsAt || pauseStartsAt >= pauseEndsAt ||
          pauseStartsAt < startsAt || pauseEndsAt > endsAt) return null;
      breaks.push({startsAt: pauseStartsAt, endsAt: pauseEndsAt});
    }
    periods.push({weekday, startsAt, endsAt, breaks});
  }
  return periods;
}
function exceptionKind(value: unknown): ExceptionKind | null {
  return typeof value === "string" && exceptionKinds.has(value as ExceptionKind)
    ? value as ExceptionKind
    : null;
}
function reason(value: unknown): string | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed.length <= 1000 ? trimmed : undefined;
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
function memberDirectoryClient(request: Request) {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const authorization = request.headers.get("authorization");
  if (!url || !key || !authorization) throw new Error("authentication_required");
  return createClient(url, key, {
    global: {headers: {Authorization: authorization}},
    auth: {autoRefreshToken: false, persistSession: false},
  });
}
async function authenticatedUser(request: Request) {
  const match = request.headers.get("authorization")?.match(/^Bearer (.+)$/i);
  if (!match) return null;
  const {data, error} = await publicAuthClient().auth.getUser(match[1]);
  return error === null ? data.user : null;
}
function mappedDatabaseFailure(request: Request, code: string | undefined) {
  if (code === "schedule_exception_unavailable") return fail(request, 404, code);
  if (code === "schedule_edit_forbidden" || code === "active_dentist_required") return fail(request, 403, code);
  if (code === "schedule_change_affects_appointments") return fail(request, 409, code);
  if (code === "schedule_effective_date_invalid") return fail(request, 422, code);
  return fail(request, 422, "invalid_schedule_request");
}

export default {
  fetch: async (request: Request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, {status: 204, headers: corsHeaders(request)});
    }
    if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
    const body = record(await request.json().catch(() => null));
    const action = body?.action as Action | undefined;
    const user = await authenticatedUser(request).catch(() => null);
    if (!body || !action || !user) return fail(request, 401, "authentication_required");
    try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }

    try {
      const client = server();
      if (action === "list_versions" || action === "list_exceptions" || action === "list_dentists") {
        const clinicId = uuid(body.clinicId);
        if (!clinicId) return fail(request, 400, "invalid_request");
        await assertClinicRead(client, user.id, clinicId);
        if (action === "list_dentists") {
          const {data, error} = await memberDirectoryClient(request).rpc("doctor_schedule_readable_dentists", {
            target_clinic_id: clinicId,
          });
          return error ? mappedDatabaseFailure(request, error.message) : reply(request, {rows: data ?? []});
        }
        const query = action === "list_versions"
          ? client.from("doctor_schedule_versions")
            .select("id, clinic_id, dentist_member_id, effective_from, doctor_working_hours(id, weekday, starts_at, ends_at, doctor_schedule_breaks(id, starts_at, ends_at))")
            .eq("clinic_id", clinicId).order("effective_from", {ascending: false}).limit(250)
          : client.from("doctor_schedule_exceptions")
            .select("id, clinic_id, dentist_member_id, kind, starts_at, ends_at, reason")
            .eq("clinic_id", clinicId).order("starts_at").limit(250);
        const {data, error} = await query;
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (action === "replace_weekly") {
        const dentistMemberId = uuid(body.dentistMemberId);
        const effectiveFrom = localDate(body.effectiveFrom);
        const periods = weeklyPeriods(body.periods);
        const confirmAffectedAppointments = body.confirmAffectedAppointments === true;
        const appointmentImpactReason = reason(body.appointmentImpactReason);
        if (!dentistMemberId || !effectiveFrom || !periods) return fail(request, 400, "invalid_request");
        if (appointmentImpactReason === undefined) return fail(request, 400, "invalid_request");
        const {data, error} = await client.rpc("doctor_schedule_replace_weekly_with_impact", {
          actor_user_id: user.id,
          target_dentist_member_id: dentistMemberId,
          target_effective_from: effectiveFrom,
          working_periods: periods,
          confirm_affected_appointments: confirmAffectedAppointments,
          appointment_impact_reason: appointmentImpactReason,
        });
        return error || !uuid(data)
          ? mappedDatabaseFailure(request, error?.message)
          : reply(request, {scheduleVersionId: data});
      }

      if (action === "preview_weekly_impact") {
        const dentistMemberId = uuid(body.dentistMemberId);
        const effectiveFrom = localDate(body.effectiveFrom);
        const periods = weeklyPeriods(body.periods);
        if (!dentistMemberId || !effectiveFrom || !periods) return fail(request, 400, "invalid_request");
        const {data, error} = await client.rpc("doctor_schedule_preview_weekly_impact", {
          actor_user_id: user.id, target_dentist_member_id: dentistMemberId,
          target_effective_from: effectiveFrom, working_periods: periods,
        });
        const preview = record(data);
        return error || typeof preview?.count !== "number"
          ? mappedDatabaseFailure(request, error?.message)
          : reply(request, {count: preview.count});
      }

      if (action === "create_exception") {
        const dentistMemberId = uuid(body.dentistMemberId);
        const kind = exceptionKind(body.kind);
        const startsAt = utcInstant(body.startsAt);
        const endsAt = utcInstant(body.endsAt);
        const exceptionReason = reason(body.reason);
        const confirmAffectedAppointments = body.confirmAffectedAppointments === true;
        const appointmentImpactReason = reason(body.appointmentImpactReason);
        if (!dentistMemberId || !kind || !startsAt || !endsAt || startsAt >= endsAt || exceptionReason === undefined) {
          return fail(request, 400, "invalid_request");
        }
        if (appointmentImpactReason === undefined) return fail(request, 400, "invalid_request");
        const {data, error} = await client.rpc("doctor_schedule_create_exception_with_impact", {
          actor_user_id: user.id, target_dentist_member_id: dentistMemberId,
          exception_kind: kind, exception_starts_at: startsAt, exception_ends_at: endsAt,
          exception_reason: exceptionReason,
          confirm_affected_appointments: confirmAffectedAppointments,
          appointment_impact_reason: appointmentImpactReason,
        });
        return error || !uuid(data)
          ? mappedDatabaseFailure(request, error?.message)
          : reply(request, {exceptionId: data}, 201);
      }

      if (action === "preview_exception_impact") {
        const dentistMemberId = uuid(body.dentistMemberId);
        const startsAt = utcInstant(body.startsAt);
        const endsAt = utcInstant(body.endsAt);
        if (!dentistMemberId || !startsAt || !endsAt || startsAt >= endsAt) {
          return fail(request, 400, "invalid_request");
        }
        const {data, error} = await client.rpc("doctor_schedule_preview_exception_impact", {
          actor_user_id: user.id, target_dentist_member_id: dentistMemberId,
          exception_starts_at: startsAt, exception_ends_at: endsAt,
        });
        const preview = record(data);
        return error || typeof preview?.count !== "number"
          ? mappedDatabaseFailure(request, error?.message)
          : reply(request, {count: preview.count});
      }

      if (action === "update_exception") {
        const exceptionId = uuid(body.exceptionId);
        const kind = exceptionKind(body.kind);
        const startsAt = utcInstant(body.startsAt);
        const endsAt = utcInstant(body.endsAt);
        const exceptionReason = reason(body.reason);
        const confirmAffectedAppointments = body.confirmAffectedAppointments === true;
        const appointmentImpactReason = reason(body.appointmentImpactReason);
        if (!exceptionId || !kind || !startsAt || !endsAt || startsAt >= endsAt || exceptionReason === undefined) {
          return fail(request, 400, "invalid_request");
        }
        if (appointmentImpactReason === undefined) return fail(request, 400, "invalid_request");
        const {error} = await client.rpc("doctor_schedule_update_exception_with_impact", {
          actor_user_id: user.id, target_exception_id: exceptionId,
          exception_kind: kind, exception_starts_at: startsAt, exception_ends_at: endsAt,
          exception_reason: exceptionReason,
          confirm_affected_appointments: confirmAffectedAppointments,
          appointment_impact_reason: appointmentImpactReason,
        });
        return error ? mappedDatabaseFailure(request, error.message) : reply(request, {ok: true});
      }

      if (action === "delete_exception") {
        const exceptionId = uuid(body.exceptionId);
        if (!exceptionId) return fail(request, 400, "invalid_request");
        const {error} = await client.rpc("doctor_schedule_delete_exception", {
          actor_user_id: user.id, target_exception_id: exceptionId,
        });
        return error ? mappedDatabaseFailure(request, error.message) : reply(request, {ok: true});
      }
      return fail(request, 400, "invalid_request");
    } catch (error) {
      console.error("doctor_schedule_workflow_failed");
      return fail(request, 503, "service_unavailable");
    }
  },
};
