import { createClient } from "npm:@supabase/supabase-js@2.49.1";
import {
  commandDigest,
  assertClinicRead,
  enforceLease,
  proofDigest,
  securityFailure,
} from "../_shared/security.ts";

type Role = "owner" | "dentist" | "assistant" | "receptionist";
type Action = "create_account" | "create" | "resend" | "revoke" | "accept" | "replace_roles" | "set_active" | "list_members" | "list_invitations";

const roleValues = new Set<Role>(["owner", "dentist", "assistant", "receptionist"]);
const jsonHeaders = {"Content-Type": "application/json"};

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
function protectedCommandFailure(
  request: Request,
  error: {message?: string} | null,
  unavailableCode: string,
) {
  if (error?.message === "owner_proof_required" ||
      error?.message === "owner_proof_forbidden") {
    return fail(request, 403, "owner_reauthentication_required");
  }
  return fail(request, 403, unavailableCode);
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
function roleList(value: unknown): Role[] | null {
  if (!Array.isArray(value) || value.length === 0) return null;
  const result = value.filter((v): v is Role => typeof v === "string" && roleValues.has(v as Role));
  return result.length === value.length ? [...new Set(result)] : null;
}
function hasOwner(value: readonly Role[]) {
  return value.includes("owner");
}
function hex(bytes: Uint8Array) {
  return [...bytes].map((v) => v.toString(16).padStart(2, "0")).join("");
}
function tokenString(bytes: Uint8Array) {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}
function tokenBytes(value: string): Uint8Array | null {
  if (!/^[A-Za-z0-9_-]{40,}$/.test(value)) return null;
  try {
    const padded = value.replaceAll("-", "+").replaceAll("_", "/") + "=".repeat((4 - value.length % 4) % 4);
    return Uint8Array.from(atob(padded), (c) => c.charCodeAt(0));
  } catch (_) {
    return null;
  }
}
async function digest(bytes: Uint8Array) {
  const hash = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
  return "\\x" + hex(hash);
}
async function freshToken() {
  const raw = crypto.getRandomValues(new Uint8Array(32));
  return {token: tokenString(raw), digest: await digest(raw)};
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
function noCrLf(value: string) {
  return !value.includes("\r") && !value.includes("\n");
}

class Smtp {
  constructor(private readonly connection: Deno.Conn) {}
  private buffered = new Uint8Array();
  private readonly decoder = new TextDecoder();
  private readonly encoder = new TextEncoder();
  async readResponse(): Promise<string> {
    let result = "";
    while (true) {
      const nextLine = this.buffered.indexOf(10);
      if (nextLine >= 0) {
        const line = this.decoder.decode(this.buffered.slice(0, nextLine + 1));
        this.buffered = this.buffered.slice(nextLine + 1);
        result += line;
        if (/^\d{3} /.test(line)) return result;
        continue;
      }
      const chunk = new Uint8Array(1024);
      const count = await this.connection.read(chunk);
      if (count === null) throw new Error("smtp_closed");
      const joined = new Uint8Array(this.buffered.length + count);
      joined.set(this.buffered);
      joined.set(chunk.slice(0, count), this.buffered.length);
      this.buffered = joined;
    }
  }
  async command(value: string) {
    await this.connection.write(this.encoder.encode(value + "\r\n"));
    const result = await this.readResponse();
    const finalLine = result.trimEnd().split(/\r?\n/).at(-1) ?? "";
    if (!/^[23]\d\d /.test(finalLine)) throw new Error("smtp_rejected");
  }
  close() {
    this.connection.close();
  }
}

async function sendInvitation(to: string, link: string): Promise<void> {
  if (!noCrLf(to) || !noCrLf(link)) throw new Error("smtp_input");
  if (!localInvitationDelivery()) throw new Error("invitation_email_unavailable");
  await sendLocalInvitation(to, link);
}

function localInvitationDelivery(): boolean {
  try {
    const url = new URL(Deno.env.get("SUPABASE_URL") ?? "");
    return url.protocol === "http:" &&
      ["kong", "127.0.0.1", "localhost"].includes(url.hostname);
  } catch (_) {
    return false;
  }
}

function invitationText(link: string) {
  return [
    "You have been invited to a DentaFlow clinic.",
    "Open this one-time link, sign in with this email address, and accept the invitation:",
    link,
    "The link expires in 7 days. If you did not expect it, ignore this message.",
    "",
    "Вас пригласили в клинику DentaFlow.",
    "Откройте одноразовую ссылку, войдите с этим адресом электронной почты и примите приглашение:",
    link,
    "Ссылка действует 7 дней. Если вы не ожидали приглашения, проигнорируйте это письмо.",
    "",
    "تمت دعوتك إلى عيادة على DentaFlow.",
    "افتح الرابط الصالح لمرة واحدة، وسجّل الدخول باستخدام هذا البريد الإلكتروني، ثم اقبل الدعوة:",
    link,
    "تنتهي صلاحية الرابط خلال 7 أيام. إذا لم تكن تتوقع هذه الدعوة، فتجاهل الرسالة.",
  ].join("\n");
}


async function sendLocalInvitation(to: string, link: string): Promise<void> {
  // Supabase's local function runtime shares a Docker network with Inbucket.
  const host = Deno.env.get("DENTAFLOW_INVITATION_SMTP_HOST") ?? "inbucket";
  const port = Number(Deno.env.get("DENTAFLOW_INVITATION_SMTP_PORT") ?? "1025");
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("smtp_configuration");
  let connection: Deno.Conn;
  try {
    connection = await Deno.connect({hostname: host, port});
  } catch (_) {
    throw new Error("smtp_connection_failed");
  }
  const smtp = new Smtp(connection);
  try {
    await smtp.readResponse();
    await smtp.command("EHLO dentaflow.local");
    await smtp.command("MAIL FROM:<no-reply@dentaflow.local>");
    await smtp.command("RCPT TO:<" + to + ">");
    await smtp.command("DATA");
    const content = [
      "From: DentaFlow <no-reply@dentaflow.local>",
      "To: <" + to + ">",
      "Subject: DentaFlow staff invitation / Приглашение / دعوة فريق العمل",
      "MIME-Version: 1.0",
      "Content-Type: text/plain; charset=UTF-8",
      "",
      invitationText(link),
    ].join("\r\n").replace(/^\./gm, "..");
    await smtp.command(content + "\r\n.");
    await smtp.command("QUIT");
  } catch (_) {
    throw new Error("smtp_delivery_failed");
  } finally {
    smtp.close();
  }
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
  const match = request.headers.get("authorization")?.match(/^Bearer (.+)$/i);
  if (!match) return null;
  const {data, error} = await publicAuthClient().auth.getUser(match[1]);
  return error === null && data.user?.email ? data.user : null;
}
async function passwordIsValid(userId: string, email: string, password: unknown): Promise<boolean> {
  if (typeof password !== "string" || password.length === 0) return false;
  let auth: ReturnType<typeof publicAuthClient>;
  try {
    auth = publicAuthClient();
  } catch (_) {
    return false;
  }
  try {
    const {data, error} = await auth.auth.signInWithPassword({email, password});
    return error === null && data.user?.id === userId;
  } finally {
    // This client exists only inside the request. Revoke its temporary
    // verification session without affecting the caller's browser session.
    await auth.auth.signOut({scope: "local"}).catch(() => undefined);
  }
}
async function rolesFor(client: ReturnType<typeof server>, table: "clinic_invitation_roles" | "clinic_member_roles", field: string, id: string): Promise<Role[] | null> {
  const {data, error} = await client.from(table).select("role").eq(field, id);
  if (error || !data) {
    console.error(`staff_role_lookup_failed:${error?.code ?? "unknown"}`);
    return null;
  }
  return roleList(data.map((row) => row.role));
}
async function ownerPassword(
  request: Request,
  userId: string,
  email: string,
  password: unknown,
) {
  return await passwordIsValid(userId, email, password)
    ? null
    : fail(request, 403, "owner_reauthentication_required");
}
function invitationLink(origin: string, token: string) {
  return origin + "/invitations/accept#token=" + token;
}

export default {
  fetch: async (request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, {status: 204, headers: corsHeaders(request)});
    }
    if (request.method !== "POST") return fail(request, 405, "method_not_allowed");
    const raw = await request.text();
    if (new TextEncoder().encode(raw).length > 16384) return fail(request, 413, "invalid_request");
    const body = record((() => { try { return JSON.parse(raw); } catch (_) { return null; } })());
    const action = body?.action as Action | undefined;
    const user = await authenticatedUser(request).catch(() => null);
    const userId = user?.id ?? null;
    if (!userId) return fail(request, 401, "authentication_required");
    if (!body || !action) return fail(request, 400, "invalid_request");
    // Supabase's built-in Auth sender cannot send custom clinic invitation
    // emails. Fail before creating or rotating a token that cannot be delivered.
    if ((action === "create" || action === "resend") && !localInvitationDelivery()) {
      return fail(request, 503, "invitation_email_unavailable");
    }
    let sessionId: string;
    try { sessionId = await enforceLease(request, userId); } catch (error) { return securityFailure(request, error); }
    const client = server();
    try {
      if (action === "create_account") {
        const clinicId = uuid(body.clinicId);
        const displayName = typeof body.displayName === "string" ? body.displayName.trim() : "";
        const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
        const roles = roleList(body.roles);
        const password = body.temporaryPassword;
        if (!clinicId || !roles || displayName.length < 2 || displayName.length > 120 ||
            email.length > 320 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
            typeof password !== "string" || password.length < 15 || password.length > 128 ||
            typeof body.ownerPassword !== "string" || body.ownerPassword.length > 1024) {
          return fail(request, 400, "invalid_request");
        }
        const { error: scopeError } = await client.rpc("staff_account_create_assert", {
          actor_user_id: userId, target_session_id: sessionId, target_clinic_id: clinicId,
        });
        if (scopeError) return fail(request, 403, "staff_creation_unavailable");
        if (!await passwordIsValid(userId, user!.email!, body.ownerPassword)) {
          return fail(request, 403, "owner_reauthentication_required");
        }
        // Auth insertion and clinic membership are one transaction via the
        // provisioning trigger. Existing users are never updated or reassigned.
        const { data, error } = await client.auth.admin.createUser({
          email, password, email_confirm: true,
          app_metadata: { staff_setup: { owner_id: userId, clinic_id: clinicId, session_id: sessionId, roles, display_name: displayName } },
        });
        if (error || !data.user) {
          return fail(request, 409, "staff_creation_unavailable");
        }
        return reply(request, { ok: true }, 201);
      }
      if (action === "list_members" || action === "list_invitations") {
        const clinicId = uuid(body.clinicId);
        if (!clinicId) return fail(request, 400, "invalid_request");
        await assertClinicRead(client, userId, clinicId);
        const query = action === "list_members"
          ? client.from("clinic_members")
            .select("id, user_id, display_name, email, is_active, deactivated_at, clinic_member_roles(role)")
            .eq("clinic_id", clinicId).order("display_name").limit(100)
          : client.from("clinic_invitations")
            .select("id, clinic_id, email, status, created_at, expires_at, last_sent_at, resend_count, accepted_at, revoked_at, clinic_invitation_roles(role)")
            .eq("clinic_id", clinicId).order("created_at", {ascending: false}).limit(100);
        const {data, error} = await query;
        return error ? fail(request, 503, "service_unavailable") : reply(request, {rows: data ?? []});
      }
      if (action === "create") {
        const clinicId = uuid(body.clinicId);
        const invitedEmail = typeof body.email === "string" ? body.email : null;
        const invitedRoles = roleList(body.roles);
        const origin = validOrigin(body.appOrigin);
        if (!clinicId || !invitedEmail || !invitedRoles || !origin) return fail(request, 400, "invalid_request");
        const command = {
          clinicId,
          email: invitedEmail.trim().toLowerCase(),
          roles: invitedRoles,
        };
        const proof = await proofDigest(body.proof);
        const token = await freshToken();
        const {data, error} = await client.rpc("security_staff_create_invitation", {
          actor_user_id: userId, target_clinic_id: clinicId, invited_email: invitedEmail,
          raw_token_digest: token.digest, invited_roles: invitedRoles,
          target_session_id: sessionId,
          target_input_digest: await commandDigest(command),
          target_proof_digest: proof,
        }).single();
        if (error || !data) {
          return protectedCommandFailure(
            request,
            error,
            "invitation_unavailable",
          );
        }
        const id = uuid(data.invitation_id);
        if (!id) return fail(request, 500, "server_error");
        await sendInvitation(invitedEmail.trim().toLowerCase(), invitationLink(origin, token.token));
        return reply(request, {invitationId: id, expiresAt: data.expires_at}, 201);
      }

      if (action === "resend" || action === "revoke") {
        const invitationId = uuid(body.invitationId);
        if (!invitationId) return fail(request, 400, "invalid_request");
        const invitationRoles = await rolesFor(client, "clinic_invitation_roles", "clinic_invitation_id", invitationId);
        if (!invitationRoles) return fail(request, 404, "invitation_unavailable");
        const command = {invitationId};
        const proof = await proofDigest(body.proof);
        if (action === "revoke") {
          const {error} = await client.rpc("security_staff_revoke_invitation", {
            actor_user_id: userId, target_invitation_id: invitationId,
            target_session_id: sessionId,
            target_input_digest: await commandDigest(command),
            target_proof_digest: proof,
          });
          return error
            ? protectedCommandFailure(request, error, "invitation_unavailable")
            : reply(request, {ok: true});
        }
        const origin = validOrigin(body.appOrigin);
        if (!origin) return fail(request, 400, "invalid_request");
        const token = await freshToken();
        const {data, error} = await client.rpc("security_staff_resend_invitation", {
          actor_user_id: userId, target_invitation_id: invitationId, raw_token_digest: token.digest,
          target_session_id: sessionId,
          target_input_digest: await commandDigest(command),
          target_proof_digest: proof,
        }).single();
        if (error || !data) {
          return protectedCommandFailure(
            request,
            error,
            "invitation_unavailable",
          );
        }
        const {data: invitation, error: lookupError} = await client
          .from("clinic_invitations").select("email").eq("id", invitationId).single();
        if (lookupError || !invitation) {
          console.error(`staff_invitation_email_lookup_failed:${lookupError?.code ?? "unknown"}`);
          return fail(request, 500, "server_error");
        }
        await sendInvitation(invitation.email, invitationLink(origin, token.token));
        return reply(request, {invitationId, expiresAt: data.expires_at});
      }

      if (action === "accept") {
        const raw = typeof body.token === "string" ? tokenBytes(body.token) : null;
        if (!raw || raw.length !== 32) return fail(request, 403, "invitation_unavailable");
        const {data, error} = await client.rpc("staff_accept_invitation", {
          actor_user_id: userId, raw_token_digest: await digest(raw),
        });
        return error || !uuid(data)
          ? fail(request, 403, "invitation_unavailable")
          : reply(request, {clinicId: data});
      }

      if (action === "replace_roles") {
        const memberId = uuid(body.memberId);
        const nextRoles = roleList(body.roles);
        if (!memberId || !nextRoles) return fail(request, 400, "invalid_request");
        const currentRoles = await rolesFor(client, "clinic_member_roles", "clinic_member_id", memberId);
        if (!currentRoles) return fail(request, 404, "member_unavailable");
        const command = {memberId, roles: nextRoles};
        const {error} = await client.rpc("security_staff_replace_member_roles", {
          actor_user_id: userId, target_member_id: memberId, replacement_roles: nextRoles,
          target_session_id: sessionId,
          target_input_digest: await commandDigest(command),
          target_proof_digest: await proofDigest(body.proof),
        });
        return error
          ? protectedCommandFailure(request, error, "member_unavailable")
          : reply(request, {ok: true});
      }

      if (action === "set_active") {
        const memberId = uuid(body.memberId);
        if (!memberId || typeof body.isActive !== "boolean") return fail(request, 400, "invalid_request");
        const currentRoles = await rolesFor(client, "clinic_member_roles", "clinic_member_id", memberId);
        if (!currentRoles) return fail(request, 404, "member_unavailable");
        const command = {memberId, isActive: body.isActive};
        const {error} = await client.rpc("security_staff_set_member_active", {
          actor_user_id: userId, target_member_id: memberId, next_is_active: body.isActive,
          target_session_id: sessionId,
          target_input_digest: await commandDigest(command),
          target_proof_digest: await proofDigest(body.proof),
        });
        return error
          ? protectedCommandFailure(request, error, "member_unavailable")
          : reply(request, {ok: true});
      }
      return fail(request, 400, "invalid_request");
    } catch (error) {
      const reason = error instanceof Error &&
          (error.message === "smtp_connection_failed" ||
            error.message === "smtp_delivery_failed")
        ? error.message
        : "unexpected";
      console.error(`staff_invitation_workflow_failed:${reason}`);
      return fail(request, 503, "service_unavailable");
    }
  },
};
