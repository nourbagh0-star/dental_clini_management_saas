import { createClient, type User } from "npm:@supabase/supabase-js@2.49.1";

export type SecurityContext = {
  user: User;
  userId: string;
  email: string;
  sessionId: string;
  token: string;
};

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function uuid(value: unknown): string | null {
  return typeof value === "string" && uuidPattern.test(value) ? value : null;
}

export function record(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

export function validOrigin(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value);
    const local = url.protocol === "http:" &&
      (url.hostname === "localhost" || url.hostname === "127.0.0.1");
    const configured = Deno.env.get("DENTAFLOW_PUBLIC_ORIGIN");
    return (local || url.origin === configured) && url.pathname === "/" &&
        !url.search && !url.hash
      ? url.origin
      : null;
  } catch (_) {
    return null;
  }
}

export function corsHeaders(request: Request): HeadersInit {
  const origin = validOrigin(request.headers.get("origin"));
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "no-referrer",
  };
  if (origin) {
    headers["Access-Control-Allow-Origin"] = origin;
    headers["Access-Control-Allow-Headers"] =
      "authorization, x-client-info, apikey, content-type";
    headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS";
    headers["Vary"] = "Origin";
  }
  return headers;
}

export function reply(
  request: Request,
  body: Record<string, unknown>,
  status = 200,
): Response {
  return Response.json(body, { status, headers: corsHeaders(request) });
}

export function fail(
  request: Request,
  status: number,
  error: string,
): Response {
  return reply(request, { error }, status);
}

function settings() {
  const url = Deno.env.get("SUPABASE_URL");
  const publicKey = Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
  const secretKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !publicKey || !secretKey) throw new Error("server_configuration");
  return { url, publicKey, secretKey };
}

export function serviceClient() {
  const value = settings();
  return createClient(value.url, value.secretKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export async function assertClinicRead(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  clinicId: string,
  clinical = false,
): Promise<void> {
  const { error } = await client.rpc("security_clinic_read_assert", {
    actor_user_id: userId,
    target_clinic_id: clinicId,
    clinical_access: clinical,
  });
  if (error) throw new Error(error.message);
}

export async function patientReadScope(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  patientId: string,
  clinical = false,
): Promise<string> {
  const { data, error } = await client.rpc("security_patient_read_scope", {
    actor_user_id: userId,
    target_patient_id: patientId,
    clinical_access: clinical,
  });
  const clinicId = uuid(data);
  if (error || !clinicId) throw new Error(error?.message ?? "patient_unavailable");
  return clinicId;
}

export function isolatedAuthClient() {
  const value = settings();
  return createClient(value.url, value.publicKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

function decodeClaims(token: string): Record<string, unknown> | null {
  try {
    const part = token.split(".")[1];
    if (!part) return null;
    const padded = part.replaceAll("-", "+").replaceAll("_", "/") +
      "=".repeat((4 - part.length % 4) % 4);
    return record(JSON.parse(atob(padded)));
  } catch (_) {
    return null;
  }
}

export async function authenticate(
  request: Request,
  requireLease = true,
): Promise<SecurityContext | null> {
  const match = request.headers.get("authorization")?.match(/^Bearer (.+)$/i);
  if (!match) return null;
  const token = match[1];
  const auth = isolatedAuthClient();
  const { data, error } = await auth.auth.getUser(token);
  const claims = decodeClaims(token);
  const userId = uuid(claims?.sub);
  const sessionId = uuid(claims?.session_id);
  if (error || !data.user?.email || !userId || !sessionId ||
      data.user.id !== userId) return null;
  if (requireLease) {
    const { error: leaseError } = await serviceClient().rpc(
      "security_session_assert",
      { actor_user_id: userId, target_session_id: sessionId },
    );
    if (leaseError) throw new Error(leaseError.message);
  }
  return { user: data.user, userId, email: data.user.email, sessionId, token };
}

/// Adds the live-session and lease checks to handlers that already verified
/// the bearer with Auth `getUser`. This is temporary compatibility glue while
/// each feature adopts the full shared gateway.
export async function enforceLease(
  request: Request,
  verifiedUserId: string,
): Promise<string> {
  const match = request.headers.get("authorization")?.match(/^Bearer (.+)$/i);
  const claims = match ? decodeClaims(match[1]) : null;
  const userId = uuid(claims?.sub);
  const sessionId = uuid(claims?.session_id);
  if (!userId || !sessionId || userId !== verifiedUserId) {
    throw new Error("security_session_revoked");
  }
  const { error } = await serviceClient().rpc("security_session_assert", {
    actor_user_id: userId,
    target_session_id: sessionId,
  });
  if (error) throw new Error(error.message);
  return sessionId;
}

export function securityFailure(request: Request, error: unknown): Response {
  const message = error instanceof Error ? error.message : "";
  if (message.includes("security_session_locked")) {
    return fail(request, 423, "session_locked");
  }
  if (message.includes("security_session_revoked")) {
    return fail(request, 401, "authentication_required");
  }
  if (message.includes("owner_proof_forbidden") ||
      message.includes("owner_proof_required")) {
    return fail(request, 403, "owner_reauthentication_required");
  }
  return fail(request, 503, "service_unavailable");
}

function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical);
  const item = record(value);
  if (!item) return value;
  return Object.fromEntries(
    Object.keys(item).sort().map((key) => [key, canonical(item[key])]),
  );
}

function hex(bytes: Uint8Array): string {
  return [...bytes].map((value) => value.toString(16).padStart(2, "0")).join("");
}

export async function commandDigest(value: unknown): Promise<string> {
  const encoded = new TextEncoder().encode(JSON.stringify(canonical(value)));
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", encoded));
  return "\\x" + hex(digest);
}

export async function proofToken(): Promise<{ raw: string; digest: string }> {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  const raw = btoa(binary).replaceAll("+", "-").replaceAll("/", "_")
    .replace(/=+$/, "");
  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  return { raw, digest: "\\x" + hex(digest) };
}

export async function proofDigest(raw: unknown): Promise<string | null> {
  if (typeof raw !== "string" || !/^[A-Za-z0-9_-]{43}$/.test(raw)) return null;
  try {
    const padded = raw.replaceAll("-", "+").replaceAll("_", "/") +
      "=".repeat((4 - raw.length % 4) % 4);
    const bytes = Uint8Array.from(atob(padded), (value) => value.charCodeAt(0));
    if (bytes.length !== 32) return null;
    const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
    return "\\x" + hex(digest);
  } catch (_) {
    return null;
  }
}
