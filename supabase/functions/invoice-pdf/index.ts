import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import { enforceLease, securityFailure } from "../_shared/security.ts";
import PDFDocument from "npm:pdfkit@0.17.2";

type Json = Record<string, unknown>;
type Locale = "en" | "ru" | "ar";
const jsonHeaders = { "Content-Type": "application/json" };
const locales = new Set(["en", "ru", "ar"]);
const labels = {
  en: {
    invoice: "Invoice",
    patient: "Patient",
    patientNumber: "Patient number",
    date: "Date",
    item: "Procedure",
    qty: "Qty",
    unit: "Unit price",
    total: "Total",
    subtotal: "Subtotal",
    discount: "Discount",
    tax: "Tax",
    paid: "Paid",
    due: "Amount due",
  },
  ru: {
    invoice: "Счёт",
    patient: "Пациент",
    patientNumber: "Номер пациента",
    date: "Дата",
    item: "Процедура",
    qty: "Кол-во",
    unit: "Цена",
    total: "Сумма",
    subtotal: "Промежуточный итог",
    discount: "Скидка",
    tax: "Налог",
    paid: "Оплачено",
    due: "К оплате",
  },
  ar: {
    invoice: "فاتورة",
    patient: "المريض",
    patientNumber: "رقم المريض",
    date: "التاريخ",
    item: "الإجراء",
    qty: "الكمية",
    unit: "سعر الوحدة",
    total: "الإجمالي",
    subtotal: "المجموع الفرعي",
    discount: "الخصم",
    tax: "الضريبة",
    paid: "المدفوع",
    due: "المبلغ المستحق",
  },
} as const;

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
async function digest(bytes: Uint8Array) {
  const hash = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(hash))
    .map((byte) => byte.toString(16).padStart(2, "0")).join("");
}
function money(value: unknown, currency: string) {
  return `${String(value)} ${currency}`;
}

async function renderInvoice(
  invoice: Json,
  items: Json[],
  locale: Locale,
): Promise<Uint8Array> {
  const fontName = locale === "ar" ? "NotoSansArabic.ttf" : "NotoSans.ttf";
  const font = await Deno.readFile(new URL(`./fonts/${fontName}`, import.meta.url));
  const l = labels[locale];
  const rtl = locale === "ar";
  const align = rtl ? "right" : "left";
  const chunks: Uint8Array[] = [];
  const completed = new Promise<Uint8Array>((resolve, reject) => {
    const document = new PDFDocument({
      size: "A4",
      margin: 48,
      info: { Title: `${l.invoice} ${invoice.invoice_number}` },
    });
    document.on("data", (chunk: Uint8Array) => chunks.push(chunk));
    document.on("error", reject);
    document.on("end", () => {
      const length = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
      const bytes = new Uint8Array(length);
      let offset = 0;
      for (const chunk of chunks) {
        bytes.set(chunk, offset);
        offset += chunk.length;
      }
      resolve(bytes);
    });
    document.font(font);
    document.fontSize(22).text(String(invoice.clinic_name_snapshot), { align });
    document.moveDown(0.35);
    document.fontSize(18).text(`${l.invoice} ${invoice.invoice_number}`, { align });
    document.moveDown(0.8);
    document.fontSize(10);
    document.text(`${l.patient}: ${invoice.patient_name_snapshot}`, { align });
    document.text(`${l.patientNumber}: ${invoice.patient_number_snapshot}`, { align });
    document.text(
      `${l.date}: ${new Date(String(invoice.finalized_at)).toLocaleDateString(locale)}`,
      { align },
    );
    document.moveDown(1);
    document.fontSize(11).text(`${l.item} / ${l.qty} / ${l.unit} / ${l.total}`, {
      align,
      underline: true,
    });
    document.moveDown(0.4);
    for (const item of items) {
      const detail = item.tooth_number_snapshot == null
        ? String(item.procedure_name_snapshot)
        : `${item.procedure_name_snapshot} (#${item.tooth_number_snapshot})`;
      document.text(
        `${detail} / ${item.quantity} / ${money(item.unit_price, String(invoice.currency_code))} / ${money(item.line_total, String(invoice.currency_code))}`,
        { align },
      );
      if (item.description_snapshot) {
        document.fontSize(9).text(String(item.description_snapshot), { align });
        document.fontSize(11);
      }
      document.moveDown(0.35);
    }
    document.moveDown(0.8);
    document.text(`${l.subtotal}: ${money(invoice.subtotal, String(invoice.currency_code))}`, { align });
    document.text(`${l.discount}: ${money(invoice.discount_amount, String(invoice.currency_code))}`, { align });
    document.text(`${l.tax}: ${money(invoice.tax_amount, String(invoice.currency_code))}`, { align });
    document.fontSize(13).text(`${l.total}: ${money(invoice.total, String(invoice.currency_code))}`, { align });
    document.fontSize(11).text(`${l.paid}: ${money(invoice.paid_amount, String(invoice.currency_code))}`, { align });
    document.text(`${l.due}: ${money(invoice.outstanding_balance, String(invoice.currency_code))}`, { align });
    document.end();
  });
  return await completed;
}

export default {
  fetch: async (request: Request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(request) });
    }
    if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
    const body = record(await request.json().catch(() => null));
    const user = await authenticatedUser(request).catch(() => null);
    const invoiceId = uuid(body?.invoiceId);
    const locale = typeof body?.locale === "string" && locales.has(body.locale)
      ? body.locale as Locale
      : null;
    if (!user || !invoiceId || !locale) return fail(request, 400, "invalid_request");
    try { await enforceLease(request, user.id); } catch (error) { return securityFailure(request, error); }
    const client = server();
    let documentId: string | null = null;
    try {
      const claimed = await client.rpc("billing_invoice_document_claim", {
        actor_user_id: user.id,
        target_invoice_id: invoiceId,
        supplied_locale: locale,
      });
      if (claimed.error) {
        const status = claimed.error.message === "billing_forbidden" ? 403 :
          claimed.error.message === "invoice_pdf_pending" ? 409 : 422;
        return fail(request, status, claimed.error.message);
      }
      const claim = record(claimed.data);
      documentId = uuid(claim?.documentId);
      const bucket = typeof claim?.bucket === "string" ? claim.bucket : null;
      const objectPath = typeof claim?.objectPath === "string" ? claim.objectPath : null;
      if (!documentId || !bucket || !objectPath) throw new Error("invalid_claim");

      if (claim?.status !== "available") {
        const invoiceResult = await client.from("invoices").select("*").eq("id", invoiceId).single();
        const itemResult = await client.from("invoice_items").select("*").eq("invoice_id", invoiceId).order("sort_order");
        if (invoiceResult.error || itemResult.error || !invoiceResult.data) {
          throw new Error("invoice_pdf_source_unavailable");
        }
        const bytes = await renderInvoice(
          invoiceResult.data as Json,
          (itemResult.data ?? []) as Json[],
          locale,
        );
        if (bytes.length === 0 || bytes.length > 2097152) {
          throw new Error("invoice_pdf_size_invalid");
        }
        const uploaded = await client.storage.from(bucket).upload(objectPath, bytes, {
          contentType: "application/pdf",
          upsert: true,
        });
        if (uploaded.error) throw new Error("invoice_pdf_storage_failed");
        const completed = await client.rpc("billing_invoice_document_complete", {
          actor_user_id: user.id,
          target_document_id: documentId,
          supplied_sha256: await digest(bytes),
          supplied_size_bytes: bytes.length,
        });
        if (completed.error) throw new Error("invoice_pdf_completion_failed");
      }

      const authorized = await client.rpc("billing_invoice_document_authorize", {
        actor_user_id: user.id,
        target_document_id: documentId,
      });
      const target = Array.isArray(authorized.data) ? authorized.data[0] : null;
      if (authorized.error || !target) return fail(request, 403, "billing_forbidden");
      const signed = await client.storage.from(String(target.bucket_id)).createSignedUrl(
        String(target.object_path),
        300,
        { download: `${invoiceId}.pdf` },
      );
      if (signed.error) throw new Error("invoice_pdf_signing_failed");
      const audited = await client.rpc("billing_invoice_document_exported", {
        actor_user_id: user.id,
        target_document_id: documentId,
      });
      if (audited.error) throw new Error("invoice_pdf_audit_failed");
      const signedUrl = new URL(signed.data.signedUrl);
      return reply(request, {
        documentId,
        url: `${signedUrl.pathname}${signedUrl.search}`,
        expiresIn: 300,
      });
    } catch (error) {
      if (documentId) {
        try {
          await client.rpc("billing_invoice_document_fail", {
            actor_user_id: user.id,
            target_document_id: documentId,
            supplied_failure_code: "invoice_pdf_generation_failed",
          });
        } catch (_) {
          console.error("invoice_pdf_failure_state_update_failed");
        }
      }
      console.error("invoice_pdf_generation_failed", error instanceof Error ? error.message : "unknown");
      return fail(request, 503, "invoice_pdf_generation_failed");
    }
  },
};
