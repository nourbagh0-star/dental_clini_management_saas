import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { enforceLease, patientReadScope, securityFailure } from "../_shared/security.ts";

type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
type Input = Record<string, unknown>;
const jsonHeaders = { "Content-Type": "application/json" };
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const categories = new Set([
  "x_ray", "clinical_photo", "consent", "referral", "laboratory_result", "other",
]);
const mimeByExtension: Record<string, string> = {
  jpg: "image/jpeg", jpeg: "image/jpeg", png: "image/png", pdf: "application/pdf",
};

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
  if (value === null || value === undefined || value === "") return null;
  if (typeof value !== "string") return undefined;
  const normalized = value.trim();
  if (normalized.length === 0) return null;
  return normalized.length <= maxLength ? normalized : undefined;
}
function requiredText(value: unknown, maxLength: number): string | null {
  const normalized = optionalText(value, maxLength);
  return typeof normalized === "string" ? normalized : null;
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
function serverConfig() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) throw new Error("server_configuration");
  return { url, key };
}
function serverClient() {
  const { url, key } = serverConfig();
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
  if (code === "patient_file_forbidden") return fail(request, 403, code);
  if ([
    "patient_file_unavailable", "patient_unavailable", "appointment_unavailable",
    "clinical_session_unavailable", "replacement_file_unavailable",
    "patient_file_upload_missing",
  ].includes(code ?? "")) return fail(request, 404, code!);
  if (code === "patient_file_too_large") return fail(request, 413, code);
  if (["patient_file_type_not_allowed", "patient_file_signature_mismatch"].includes(code ?? "")) {
    return fail(request, 415, code!);
  }
  if ([
    "patient_archived", "patient_file_upload_expired", "patient_file_pending_only",
    "patient_file_available_only", "patient_file_archived_only", "patient_file_immutable",
    "patient_file_identity_immutable", "invalid_patient_file_transition",
  ].includes(code ?? "")) return fail(request, 409, code!);
  return fail(
    request,
    422,
    code?.startsWith("patient_file_") === true || code === "invalid_patient_file_input"
      ? code!
      : "invalid_patient_file_input",
  );
}
function rpcRow(value: unknown): Input | null {
  if (Array.isArray(value) && value.length > 0) return record(value[0]);
  return record(value);
}
function detectedMime(bytes: Uint8Array): string | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return "image/jpeg";
  }
  if (bytes.length >= 8 && bytes[0] === 0x89 && bytes[1] === 0x50 &&
    bytes[2] === 0x4e && bytes[3] === 0x47 && bytes[4] === 0x0d &&
    bytes[5] === 0x0a && bytes[6] === 0x1a && bytes[7] === 0x0a) return "image/png";
  if (bytes.length >= 5 && bytes[0] === 0x25 && bytes[1] === 0x50 &&
    bytes[2] === 0x44 && bytes[3] === 0x46 && bytes[4] === 0x2d) {
    return "application/pdf";
  }
  return null;
}

function externallyReachableUrl(rawUrl: string): string {
  const signed = new URL(rawUrl);
  if (signed.hostname.endsWith(".supabase.co")) return signed.toString();
  return `${signed.pathname}${signed.search}`;
}

async function inspectObject(bucket: string, path: string) {
  const client = serverClient();
  const parts = path.split("/");
  const filename = parts.pop();
  if (!filename) throw new Error("storage_path");
  const { data: listed, error: listError } = await client.storage
    .from(bucket).list(parts.join("/"), { search: filename, limit: 10 });
  if (listError) throw new Error("storage_list");
  const object = listed?.find((item) => item.name === filename && item.id !== null);
  const size = object?.metadata?.size;
  if (!object || typeof size !== "number") return null;
  const { url, key } = serverConfig();
  const encoded = path.split("/").map(encodeURIComponent).join("/");
  const response = await fetch(
    `${url}/storage/v1/object/authenticated/${encodeURIComponent(bucket)}/${encoded}`,
    { headers: {
      "Authorization": `Bearer ${key}`,
      "apikey": key,
      "Range": "bytes=0-15",
      "Cache-Control": "no-store",
    } },
  );
  if (!response.ok || !response.body) return null;
  const reader = response.body.getReader();
  const first = await reader.read();
  await reader.cancel().catch(() => undefined);
  return { size, mime: first.value ? detectedMime(first.value) : null };
}
async function rejectAndRemove(
  userId: string, fileId: string, bucket: string, path: string, code: string,
) {
  const client = serverClient();
  const { error: removalError } = await client.storage.from(bucket).remove([path]);
  if (removalError) throw new Error("storage_remove");
  const { error: rejectionError } = await client.rpc("patient_file_reject_upload", {
    actor_user_id: userId,
    target_file_id: fileId,
    supplied_rejection_code: code,
  });
  if (rejectionError) throw new Error("patient_file_reject");
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
      if (action === "read_files") {
        const patientId = uuid(body.patientId);
        const includeArchived = body.includeArchived === true;
        const category = body.category === null || body.category === undefined
          ? null : typeof body.category === "string" && categories.has(body.category)
          ? body.category : undefined;
        const offset = Number.isInteger(body.offset) ? body.offset as number : -1;
        const limit = Number.isInteger(body.limit) ? body.limit as number : 0;
        if (!patientId || category === undefined || offset < 0 || offset > 10000 || limit < 1 || limit > 100) {
          return fail(request, 400, "invalid_request");
        }
        const clinicId = await patientReadScope(client, user.id, patientId, true);
        let query = client.from("patient_files").select(
          "id, clinic_id, patient_id, appointment_id, clinical_session_id, replaces_file_id, category, description, original_filename, detected_mime_type, size_bytes, status, uploaded_by, available_at, archived_at, archived_by, archive_reason, created_at",
        ).eq("patient_id", patientId).in("status", includeArchived ? ["available", "archived"] : ["available"]);
        if (category !== null) query = query.eq("category", category);
        const {data, error} = await query.order("created_at", {ascending: false})
          .order("id", {ascending: false}).range(offset, offset + limit - 1);
        const {error: auditError} = await client.rpc("audit_record_access", {
          actor_user_id: user.id, target_clinic_id: clinicId,
          access_intent: "patient_files", target_subject_id: patientId,
          target_request_id: crypto.randomUUID(),
        });
        return error || auditError ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (action === "create_upload") {
        const patientId = uuid(body.patientId);
        const appointmentId = optionalUuid(body.appointmentId);
        const sessionId = optionalUuid(body.clinicalSessionId);
        const replacementId = optionalUuid(body.replacesFileId);
        const category = typeof body.category === "string" && categories.has(body.category)
          ? body.category
          : null;
        const description = optionalText(body.description, 1000);
        const originalFilename = requiredText(body.originalFilename, 255);
        const extension = typeof body.extension === "string"
          ? body.extension.trim().toLowerCase().replace(/^\./, "")
          : "";
        const mimeType = typeof body.mimeType === "string"
          ? body.mimeType.trim().toLowerCase()
          : "";
        const sizeBytes = body.sizeBytes;
        if (!patientId || appointmentId === undefined || sessionId === undefined ||
          replacementId === undefined || !category || description === undefined ||
          !originalFilename || mimeByExtension[extension] !== mimeType ||
          typeof sizeBytes !== "number" || !Number.isInteger(sizeBytes) || sizeBytes < 1) {
          return fail(request, 400, "invalid_request");
        }
        if (sizeBytes > 15728640) return fail(request, 413, "patient_file_too_large");
        const { data, error } = await client.rpc("patient_file_create_upload", {
          actor_user_id: user.id,
          target_patient_id: patientId,
          target_appointment_id: appointmentId,
          target_clinical_session_id: sessionId,
          target_replaces_file_id: replacementId,
          target_category: category,
          supplied_description: description,
          supplied_original_filename: originalFilename,
          supplied_extension: extension,
          supplied_mime_type: mimeType,
        });
        if (error) return databaseFailure(request, error.message);
        const row = rpcRow(data);
        return row
          ? reply(request, {
            fileId: row.file_id as string,
            bucket: "patient-files",
            objectPath: row.object_path as string,
            expiresAt: row.expires_at as string,
          }, 201)
          : fail(request, 503, "service_unavailable");
      }
      const fileId = uuid(body.fileId);
      if (action === "complete_upload" && fileId) {
        const { data: pendingData, error: pendingError } = await client.rpc(
          "patient_file_authorize_pending",
          { actor_user_id: user.id, target_file_id: fileId },
        );
        if (pendingError) return databaseFailure(request, pendingError.message);
        const pending = rpcRow(pendingData);
        if (!pending) return fail(request, 503, "service_unavailable");
        if (pending.file_status === "available") return reply(request, { status: "available" });
        const bucket = pending.bucket_id as string;
        const path = pending.object_path as string;
        const expectedMime = pending.declared_mime_type as string;
        const inspected = await inspectObject(bucket, path);
        if (!inspected) return fail(request, 404, "patient_file_upload_missing");
        let rejection: string | null = null;
        if (inspected.size < 1) rejection = "patient_file_empty";
        else if (inspected.size > 15728640) rejection = "patient_file_too_large";
        else if (inspected.mime !== expectedMime) rejection = "patient_file_signature_mismatch";
        if (rejection) {
          await rejectAndRemove(user.id, fileId, bucket, path, rejection);
          return databaseFailure(request, rejection);
        }
        const { error } = await client.rpc("patient_file_complete_upload", {
          actor_user_id: user.id,
          target_file_id: fileId,
          actual_mime_type: inspected.mime,
          actual_size_bytes: inspected.size,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { status: "available" });
      }
      if (action === "cancel_upload" && fileId) {
        const { data, error } = await client.rpc("patient_file_authorize_pending", {
          actor_user_id: user.id, target_file_id: fileId,
        });
        if (error) return databaseFailure(request, error.message);
        const pending = rpcRow(data);
        if (!pending || pending.file_status !== "pending_upload") {
          return fail(request, 409, "patient_file_pending_only");
        }
        const { error: removalError } = await client.storage
          .from(pending.bucket_id as string)
          .remove([pending.object_path as string]);
        if (removalError) return fail(request, 503, "patient_file_storage_unavailable");
        const { error: rejectError } = await client.rpc("patient_file_reject_upload", {
          actor_user_id: user.id,
          target_file_id: fileId,
          supplied_rejection_code: "patient_file_upload_cancelled",
        });
        return rejectError ? databaseFailure(request, rejectError.message) : reply(request, { status: "rejected" });
      }
      if (action === "create_read_url" && fileId) {
        const accessIntent = body.accessIntent === "preview"
          ? "file_preview"
          : body.accessIntent === "download"
          ? "file_download"
          : null;
        const accessRequestId = uuid(body.requestId);
        if (!accessIntent || !accessRequestId) {
          return fail(request, 400, "invalid_request");
        }
        const { data, error } = await client.rpc("patient_file_authorize_read", {
          actor_user_id: user.id, target_file_id: fileId,
        });
        if (error) return databaseFailure(request, error.message);
        const target = rpcRow(data);
        if (!target) return fail(request, 503, "service_unavailable");
        const { data: fileRow, error: fileError } = await client
          .from("patient_files").select("clinic_id").eq("id", fileId).single();
        if (fileError || !fileRow?.clinic_id) {
          return fail(request, 503, "service_unavailable");
        }
        const { error: auditError } = await client.rpc("audit_record_access", {
          actor_user_id: user.id,
          target_clinic_id: fileRow.clinic_id,
          access_intent: accessIntent,
          target_subject_id: fileId,
          target_request_id: accessRequestId,
        });
        if (auditError) return databaseFailure(request, auditError.message);
        const { data: signed, error: signingError } = await client.storage
          .from(target.bucket_id as string).createSignedUrl(target.object_path as string, 60);
        return signingError || !signed?.signedUrl
          ? fail(request, 503, "patient_file_storage_unavailable")
          : reply(request, {
            url: externallyReachableUrl(signed.signedUrl),
            mimeType: target.mime_type as string,
            filename: target.download_name as string,
            expiresIn: 60,
          });
      }
      if (action === "archive_file" && fileId) {
        const reason = requiredText(body.reason, 1000);
        if (!reason) return fail(request, 400, "invalid_request");
        const { error } = await client.rpc("patient_file_archive", {
          actor_user_id: user.id, target_file_id: fileId, supplied_reason: reason,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { ok: true });
      }
      if (action === "restore_file" && fileId) {
        const { error } = await client.rpc("patient_file_restore", {
          actor_user_id: user.id, target_file_id: fileId,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { ok: true });
      }
      if (action === "reconcile_pending_uploads") {
        const clinicId = uuid(body.clinicId);
        if (!clinicId) return fail(request, 400, "invalid_request");
        const { data, error } = await client.rpc("patient_file_expire_uploads", {
          actor_user_id: user.id, target_clinic_id: clinicId, batch_limit: 20,
        });
        if (error) return databaseFailure(request, error.message);
        const rows = Array.isArray(data) ? data : [];
        for (const value of rows) {
          const row = record(value);
          if (row && typeof row.object_path === "string") {
            const { error: removalError } = await client.storage
              .from("patient-files")
              .remove([row.object_path]);
            if (removalError) console.error("patient_file_expired_object_cleanup_failed");
          }
        }
        return reply(request, { reconciled: rows.length });
      }
      return fail(request, 400, "invalid_request");
    } catch (_) {
      console.error("patient_files_workflow_failed");
      return fail(request, 503, "service_unavailable");
    }
  },
};
