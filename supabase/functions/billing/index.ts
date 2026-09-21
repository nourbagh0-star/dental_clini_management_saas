import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  commandDigest,
  assertClinicRead,
  enforceLease,
  proofDigest,
  patientReadScope,
  securityFailure,
} from "../_shared/security.ts";

type Json = Record<string, unknown>;
const jsonHeaders = { "Content-Type": "application/json" };
const locales = new Set(["en", "ru", "ar"]);
const discountTypes = new Set(["none", "fixed", "percentage"]);
const paymentMethods = new Set(["cash", "card", "bank_transfer", "other"]);

function record(value: unknown): Json | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as Json
    : null;
}

function uuid(value: unknown): string | null {
  return typeof value === "string" &&
      /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
    ? value
    : null;
}

function decimal(value: unknown): string | null {
  return typeof value === "string" &&
      /^(0|[1-9]\d{0,9})(?:\.\d{1,2})?$/.test(value)
    ? value
    : null;
}

function quantity(value: unknown): string | null {
  return typeof value === "string" &&
      /^(?:0\.(?:0[1-9]|[1-9]\d)|[1-9]\d{0,2}(?:\.\d{1,2})?)$/.test(value)
    ? value
    : null;
}

function percentage(value: unknown): string | null {
  const result = decimal(value);
  return result !== null && Number(result) <= 100 ? result : null;
}

function optionalText(value: unknown, maximum: number): string | null | undefined {
  if (value === null || value === undefined) return null;
  if (typeof value !== "string") return undefined;
  const result = value.trim();
  return result.length === 0 ? null : result.length <= maximum ? result : undefined;
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

function server() {
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
  const token = request.headers.get("authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return null;
  const { data, error } = await publicAuthClient().auth.getUser(token);
  return error === null ? data.user : null;
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value !== null && typeof value === "object") {
    return `{${Object.entries(value as Json).sort(([a], [b]) => a.localeCompare(b))
      .map(([key, child]) => `${JSON.stringify(key)}:${canonical(child)}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

async function sha256(value: Json): Promise<string> {
  const bytes = new TextEncoder().encode(canonical(value));
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function databaseFailure(request: Request, code?: string) {
  if (code === "owner_proof_required") {
    return fail(request, 403, "owner_reauthentication_required");
  }
  if (code === "billing_forbidden") return fail(request, 403, code);
  if ([
    "invoice_unavailable",
    "financial_entry_unavailable",
    "patient_unavailable",
    "procedure_unavailable",
    "treatment_plan_item_unavailable",
  ].includes(code ?? "")) return fail(request, 404, code!);
  if ([
    "invoice_revision_conflict",
    "invoice_draft_only",
    "invoice_content_approved",
    "invoice_treatment_item_already_claimed",
    "invoice_clinical_approval_required",
    "invoice_finalized_only",
    "invoice_already_paid",
    "invoice_nonzero_paid_balance",
    "invoice_not_cancellable",
    "billing_command_conflict",
    "financial_entry_not_reversible",
    "financial_reversal_exceeds_available",
    "insufficient_patient_credit",
    "credit_exceeds_invoice_balance",
    "patient_archived",
  ].includes(code ?? "")) return fail(request, 409, code!);
  return fail(
    request,
    422,
    code?.startsWith("invalid_") === true || code === "invoice_items_required"
      ? code!
      : "invalid_billing_input",
  );
}

async function commandHash(action: string, input: Json) {
  return await sha256({ action, ...input });
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
    let sessionId: string;
    try { sessionId = await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
    try {
      const client = server();
      const invoiceId = uuid(body.invoiceId);
      const revision = typeof body.revision === "number" &&
          Number.isInteger(body.revision) && body.revision > 0
        ? body.revision
        : null;

      if (action === "read_invoices") {
        const clinicId = uuid(body.clinicId);
        const patientId = body.patientId === null || body.patientId === undefined
          ? null : uuid(body.patientId);
        if (!clinicId || (body.patientId != null && !patientId)) return fail(request, 400, "invalid_request");
        await assertClinicRead(client, user.id, clinicId);
        let invoices = client.from("billing_invoice_rows").select().eq("clinic_id", clinicId);
        let names = client.from("billing_invoice_list_rows")
          .select("id, patient_display_name, patient_display_number").eq("clinic_id", clinicId);
        if (patientId) {
          invoices = invoices.eq("patient_id", patientId);
          names = names.eq("patient_id", patientId);
        }
        const [invoiceResult, nameResult] = await Promise.all([
          invoices.order("created_at", {ascending: false}).limit(250), names.limit(250),
        ]);
        if (invoiceResult.error || nameResult.error) return fail(request, 503, "service_unavailable");
        const labels = new Map((nameResult.data ?? []).map((row) => [row.id, row]));
        const rows = (invoiceResult.data ?? []).map((row) => ({...row, ...labels.get(row.id)}));
        return reply(request, {rows});
      }

      if (action === "read_items" || action === "read_payments") {
        if (!invoiceId) return fail(request, 400, "invalid_request");
        const {data: invoice, error: invoiceError} = await client.from("invoices")
          .select("clinic_id").eq("id", invoiceId).single();
        const clinicId = uuid(invoice?.clinic_id);
        if (invoiceError || !clinicId) return fail(request, 404, "invoice_unavailable");
        await assertClinicRead(client, user.id, clinicId);
        const query = action === "read_items"
          ? client.from("billing_invoice_item_rows").select().eq("invoice_id", invoiceId)
            .order("sort_order").limit(250)
          : client.from("billing_payment_rows").select().eq("received_for_invoice_id", invoiceId)
            .order("received_at", {ascending: false}).limit(250);
        const {data, error} = await query;
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }

      if (action === "read_procedures") {
        const clinicId = uuid(body.clinicId);
        if (!clinicId) return fail(request, 400, "invalid_request");
        await assertClinicRead(client, user.id, clinicId);
        const {data, error} = await client.from("procedure_money_rows").select()
          .eq("clinic_id", clinicId).eq("active", true).order("name").limit(500);
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }

      if (action === "read_credit") {
        const patientId = uuid(body.patientId);
        const currency = typeof body.currencyCode === "string" && /^[A-Z]{3}$/.test(body.currencyCode)
          ? body.currencyCode : null;
        if (!patientId || !currency) return fail(request, 400, "invalid_request");
        await patientReadScope(client, user.id, patientId);
        const {data, error} = await client.from("billing_credit_rows").select()
          .eq("patient_id", patientId).eq("currency_code", currency).maybeSingle();
        return error ? fail(request, 503, "service_unavailable") : reply(request, {row: data});
      }

      if (action === "eligible_treatment_items") {
        const patientId = uuid(body.patientId);
        if (!patientId) return fail(request, 400, "invalid_request");
        const { data, error } = await client.rpc("billing_eligible_treatment_items", {
          actor_user_id: user.id,
          target_patient_id: patientId,
        });
        return error ? databaseFailure(request, error.message) : reply(request, {
          items: data ?? [],
        });
      }

      if (action === "financial_entries") {
        if (!invoiceId) return fail(request, 400, "invalid_request");
        const { data, error } = await client.rpc("billing_financial_entries", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
        });
        return error ? databaseFailure(request, error.message) : reply(request, {
          entries: data ?? [],
        });
      }

      if (action === "create_invoice_draft") {
        const patientId = uuid(body.patientId);
        const locale = typeof body.locale === "string" && locales.has(body.locale)
          ? body.locale
          : null;
        const commandId = uuid(body.commandId);
        if (!patientId || !locale || !commandId) return fail(request, 400, "invalid_request");
        const input = { patientId, locale };
        const { data, error } = await client.rpc("billing_invoice_create_draft", {
          actor_user_id: user.id,
          target_patient_id: patientId,
          supplied_locale: locale,
          target_command_id: commandId,
          target_input_hash: await commandHash(action, input),
        });
        return error ? databaseFailure(request, error.message) : reply(request, data, 201);
      }

      if (action === "add_invoice_item") {
        const procedureId = uuid(body.procedureId);
        const treatmentItemId = body.treatmentPlanItemId === null ||
            body.treatmentPlanItemId === undefined
          ? null
          : uuid(body.treatmentPlanItemId);
        const suppliedQuantity = quantity(body.quantity);
        if (!invoiceId || !procedureId || !suppliedQuantity || !revision ||
          (body.treatmentPlanItemId != null && !treatmentItemId)) {
          return fail(request, 400, "invalid_request");
        }
        const { data, error } = await client.rpc("billing_invoice_item_add", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          target_procedure_id: procedureId,
          target_treatment_plan_item_id: treatmentItemId,
          supplied_quantity: suppliedQuantity,
          expected_revision: revision,
        });
        return error ? databaseFailure(request, error.message) : reply(request, data, 201);
      }

      if (action === "update_invoice_item") {
        const itemId = uuid(body.itemId);
        const suppliedQuantity = quantity(body.quantity);
        if (!itemId || !suppliedQuantity || !revision) return fail(request, 400, "invalid_request");
        const { data, error } = await client.rpc("billing_invoice_item_update", {
          actor_user_id: user.id,
          target_item_id: itemId,
          supplied_quantity: suppliedQuantity,
          expected_revision: revision,
        });
        return error ? databaseFailure(request, error.message) : reply(request, {
          revision: data,
        });
      }

      if (action === "remove_invoice_item") {
        const itemId = uuid(body.itemId);
        if (!itemId || !revision) return fail(request, 400, "invalid_request");
        const { data, error } = await client.rpc("billing_invoice_item_remove", {
          actor_user_id: user.id,
          target_item_id: itemId,
          expected_revision: revision,
        });
        return error ? databaseFailure(request, error.message) : reply(request, {
          revision: data,
        });
      }

      if (action === "approve_invoice_content") {
        if (!invoiceId || !revision || typeof body.approved !== "boolean") {
          return fail(request, 400, "invalid_request");
        }
        const { data, error } = await client.rpc("billing_invoice_content_approval", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          expected_revision: revision,
          approved: body.approved,
        });
        return error ? databaseFailure(request, error.message) : reply(request, {
          revision: data,
        });
      }

      if (action === "set_invoice_financials") {
        const discountType = typeof body.discountType === "string" &&
            discountTypes.has(body.discountType)
          ? body.discountType
          : null;
        const discountValue = decimal(body.discountValue);
        const taxRate = percentage(body.taxRate);
        const locale = typeof body.locale === "string" && locales.has(body.locale)
          ? body.locale
          : null;
        const rawPrices = Array.isArray(body.itemPrices) && body.itemPrices.length <= 100
          ? body.itemPrices
          : null;
        const itemPrices = rawPrices?.map((value) => {
          const price = record(value);
          const itemId = uuid(price?.itemId);
          const unitPrice = decimal(price?.unitPrice);
          return itemId && unitPrice ? { itemId, unitPrice } : null;
        });
        if (!invoiceId || !revision || !discountType || discountValue === null ||
          taxRate === null || !locale || !itemPrices || itemPrices.some((value) => value === null)) {
          return fail(request, 400, "invalid_request");
        }
        const { data, error } = await client.rpc("billing_invoice_set_financials", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          supplied_item_prices: itemPrices,
          supplied_discount_type: discountType,
          supplied_discount_value: discountValue,
          supplied_tax_rate: taxRate,
          supplied_locale: locale,
          expected_revision: revision,
        });
        return error ? databaseFailure(request, error.message) : reply(request, {
          revision: data,
        });
      }

      if (action === "finalize_invoice") {
        const commandId = uuid(body.commandId);
        if (!invoiceId || !revision || !commandId) return fail(request, 400, "invalid_request");
        const input = { invoiceId, revision };
        const { data, error } = await client.rpc("billing_invoice_finalize", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          expected_revision: revision,
          target_command_id: commandId,
          target_input_hash: await commandHash(action, input),
        });
        return error ? databaseFailure(request, error.message) : reply(request, data);
      }

      if (action === "cancel_invoice") {
        const reason = optionalText(body.reason, 1000);
        if (!invoiceId || !revision || typeof reason !== "string") {
          return fail(request, 400, "invalid_request");
        }
        const { error } = await client.rpc("billing_invoice_cancel", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          expected_revision: revision,
          supplied_reason: reason,
        });
        return error ? databaseFailure(request, error.message) : reply(request, { ok: true });
      }

      if (action === "record_payment") {
        const amount = decimal(body.amount);
        const method = typeof body.method === "string" && paymentMethods.has(body.method)
          ? body.method
          : null;
        const reference = optionalText(body.reference, 200);
        const receivedAt = typeof body.receivedAt === "string" &&
            Number.isFinite(Date.parse(body.receivedAt))
          ? new Date(body.receivedAt).toISOString()
          : null;
        const commandId = uuid(body.commandId);
        if (!invoiceId || !amount || amount === "0" || amount === "0.00" ||
          !method || reference === undefined || !receivedAt || !commandId) {
          return fail(request, 400, "invalid_request");
        }
        const input = { invoiceId, amount, method, reference, receivedAt };
        const { data, error } = await client.rpc("billing_payment_record", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          supplied_amount: amount,
          supplied_method: method,
          supplied_reference: reference,
          supplied_received_at: receivedAt,
          target_command_id: commandId,
          target_input_hash: await commandHash(action, input),
        });
        return error ? databaseFailure(request, error.message) : reply(request, data, 201);
      }

      if (action === "apply_patient_credit") {
        const amount = decimal(body.amount);
        const commandId = uuid(body.commandId);
        if (!invoiceId || !amount || amount === "0" || amount === "0.00" || !commandId) {
          return fail(request, 400, "invalid_request");
        }
        const input = { invoiceId, amount };
        const { data, error } = await client.rpc("billing_credit_apply", {
          actor_user_id: user.id,
          target_invoice_id: invoiceId,
          supplied_amount: amount,
          target_command_id: commandId,
          target_input_hash: await commandHash(action, input),
        });
        return error ? databaseFailure(request, error.message) : reply(request, data);
      }

      if (action === "reverse_financial_entry") {
        const entryId = uuid(body.entryId);
        const amount = decimal(body.amount);
        const reversalAction = body.reversalAction === "refund" ||
            body.reversalAction === "correction"
          ? body.reversalAction
          : null;
        const reason = optionalText(body.reason, 1000);
        const commandId = uuid(body.commandId);
        if (!entryId || !amount || amount === "0" || amount === "0.00" ||
          !reversalAction || typeof reason !== "string" || !commandId) {
          return fail(request, 400, "invalid_request");
        }
        const input = { entryId, amount, reversalAction, reason };
        const { data, error } = await client.rpc("security_billing_financial_entry_reverse", {
          actor_user_id: user.id,
          target_entry_id: entryId,
          supplied_amount: amount,
          reversal_action: reversalAction,
          supplied_reason: reason,
          target_command_id: commandId,
          target_input_hash: await commandHash(action, input),
          target_session_id: sessionId,
          target_input_digest: await commandDigest(input),
          target_proof_digest: await proofDigest(body.proof),
        });
        return error ? databaseFailure(request, error.message) : reply(request, data);
      }

      return fail(request, 400, "invalid_request");
    } catch (_) {
      console.error("billing_workflow_failed");
      return fail(request, 503, "service_unavailable");
    }
  },
};
