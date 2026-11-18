import { createClient } from "jsr:@supabase/supabase-js@2";

type WebhookPayload = {
  type?: string;
  table?: string;
  schema?: string;
  record?: {
    texto?: string;
    usuario_id?: string | null;
    grupo_id?: string | null;
  } | null;
  old_record?: unknown;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

function constantTimeEqual(a: string, b: string): boolean {
  const encoder = new TextEncoder();
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  let difference = left.length ^ right.length;
  const length = Math.max(left.length, right.length);
  for (let i = 0; i < length; i++) {
    difference |= (left[i] ?? 0) ^ (right[i] ?? 0);
  }
  return difference === 0;
}

async function fetchWithTimeout(
  input: string | URL,
  init: RequestInit,
): Promise<Response> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);
  try {
    return await fetch(input, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

function errorText(error: unknown): string {
  if (error instanceof DOMException && error.name === "AbortError") {
    return "timeout (10 s)";
  }
  if (error instanceof Error) return error.message.slice(0, 180);
  return "falló el envío";
}

Deno.serve(async (request) => {
  const expectedSecret = Deno.env.get("WEBHOOK_SECRET") ?? "";
  const suppliedSecret = request.headers.get("x-webhook-secret") ?? "";
  if (!expectedSecret || !constantTimeEqual(suppliedSecret, expectedSecret)) {
    return json({ error: "unauthorized" }, 401);
  }
  if (request.method !== "POST") return json({ error: "method not allowed" }, 405);

  let payload: WebhookPayload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: "invalid JSON" }, 400);
  }
  if (payload.type !== "INSERT" || payload.table !== "comentarios") {
    return json({ ok: true, skipped: "evento no compatible" });
  }

  const record = payload.record;
  if (!record || record.usuario_id == null) {
    return json({ ok: true, skipped: "mensaje del VIP" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("aviso-chat: faltan variables de Supabase");
    return json({ ok: true, whatsapp: "skipped", email: "skipped" });
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: usuario, error: usuarioError } = await supabase
    .from("usuarios")
    .select("nombre")
    .eq("id", record.usuario_id)
    .maybeSingle();
  if (usuarioError) console.error("aviso-chat: no se pudo buscar el usuario");
  const senderName = usuarioError ? "?" : usuario?.nombre || "?";

  let chatName = "General";
  if (record.grupo_id) {
    const { data: grupo, error: grupoError } = await supabase
      .from("grupos")
      .select("nombre")
      .eq("id", record.grupo_id)
      .maybeSingle();
    if (grupoError) console.error("aviso-chat: no se pudo buscar el grupo");
    chatName = grupoError ? "un grupo" : grupo?.nombre || "un grupo";
  }

  const messageText = (record.texto ?? "").slice(0, 500) +
    ((record.texto ?? "").length > 500 ? "…" : "");
  const avisoTexto = `⚽ Señal de Gol — nuevo mensaje en ${chatName} de ${senderName}:\n${messageText}`;

  const phone = Deno.env.get("CALLMEBOT_PHONE");
  const callmebotKey = Deno.env.get("CALLMEBOT_APIKEY");
  const whatsappPromise: Promise<string> = phone && callmebotKey
    ? (async () => {
      const params = new URLSearchParams({ phone, text: avisoTexto, apikey: callmebotKey });
      try {
        const response = await fetchWithTimeout(
          `https://api.callmebot.com/whatsapp.php?${params}`,
          { method: "GET" },
        );
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        // CallMeBot puede responder 200 con un error en el texto (p. ej. apikey inválida)
        const body = (await response.text()).replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
        if (!/queued|sent/i.test(body)) throw new Error(`CallMeBot: ${body.slice(0, 150)}`);
        return "ok";
      } catch (error) {
        throw new Error(errorText(error));
      }
    })()
    : Promise.resolve("skipped");

  const emailEnv = {
    serviceId: Deno.env.get("EMAILJS_SERVICE_ID"),
    templateId: Deno.env.get("EMAILJS_TEMPLATE_ID"),
    userId: Deno.env.get("EMAILJS_PUBLIC_KEY"),
    accessToken: Deno.env.get("EMAILJS_PRIVATE_KEY"),
    recipients: (Deno.env.get("AVISO_EMAIL") ?? "").split(",").map((v) => v.trim()).filter(Boolean),
  };
  const emailReady = emailEnv.serviceId && emailEnv.templateId && emailEnv.userId &&
    emailEnv.accessToken && emailEnv.recipients.length > 0;
  const emailPromise: Promise<string> = emailReady
    ? (async () => {
      const results = await Promise.allSettled(emailEnv.recipients.map(async (toEmail) => {
        const response = await fetchWithTimeout("https://api.emailjs.com/api/v1.0/email/send", {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            service_id: emailEnv.serviceId,
            template_id: emailEnv.templateId,
            user_id: emailEnv.userId,
            accessToken: emailEnv.accessToken,
            template_params: {
              to_email: toEmail,
              sender_name: senderName,
              chat_name: chatName,
              message_text: messageText,
            },
          }),
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
      }));
      const failures = results.filter((result) => result.status === "rejected");
      if (failures.length) {
        const first = failures[0] as PromiseRejectedResult;
        throw new Error(`${failures.length}/${results.length} envíos fallaron: ${errorText(first.reason)}`);
      }
      return "ok";
    })()
    : Promise.resolve("skipped");

  const [whatsappResult, emailResult] = await Promise.allSettled([
    whatsappPromise,
    emailPromise,
  ]);
  const summary = {
    whatsapp: whatsappResult.status === "fulfilled"
      ? whatsappResult.value
      : `error: ${errorText(whatsappResult.reason)}`,
    email: emailResult.status === "fulfilled"
      ? emailResult.value
      : `error: ${errorText(emailResult.reason)}`,
  };
  if (summary.whatsapp === "ok" || summary.email === "ok") {
    console.log("aviso-chat resultado", summary);
  } else {
    console.error("aviso-chat resultado", summary);
  }
  return json(summary);
});
