import { createClient } from "jsr:@supabase/supabase-js@2";

const CORS = { "access-control-allow-origin": "*", "access-control-allow-headers": "authorization, apikey, x-client-info, content-type", "access-control-allow-methods": "POST, OPTIONS", "content-type": "application/json; charset=utf-8" };
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), { status, headers: CORS });
const EMAIL_DOMAIN = "cuentas.senaldegol.netlify.app";
const SALT = "prode_salt_2025";
const VIP_ID = "00000000-0000-0000-0000-000000000001";
const norm = (s: string) => s.trim().charAt(0).toUpperCase() + s.trim().slice(1);
const internalEmail = (id: string) => `${id}@${EMAIL_DOMAIN}`;
async function sha256(value: string) {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(bytes), (b) => b.toString(16).padStart(2, "0")).join("");
}
function constantTimeEqual(a: string, b: string) {
  let diff = a.length ^ b.length;
  for (let i = 0; i < Math.max(a.length, b.length); i++) diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  return diff === 0;
}
function validUrlBase(value: unknown) {
  if (typeof value !== "string") return "https://senaldegol.netlify.app";
  try {
    const u = new URL(value);
    if (u.origin === "https://senaldegol.netlify.app" && (u.pathname === "/" || u.pathname === "")) return u.origin;
    if (["http:"].includes(u.protocol) && /^(localhost|127\.0\.0\.1|192\.168\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3})$/.test(u.hostname) && u.port && (u.pathname === "/" || u.pathname === "")) return u.origin;
  } catch { /* fallback */ }
  return "https://senaldegol.netlify.app";
}
const err = (message: string, status = 400) => json({ error: message }, status);
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (request.method !== "POST") return err("Método no permitido.", 405);
  let b: Record<string, unknown>;
  try { b = await request.json(); } catch { return err("Solicitud inválida."); }
  const url = Deno.env.get("SUPABASE_URL"), key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) { console.error("cuentas: faltan secretos de Supabase"); return err("Servicio no disponible.", 500); }
  const supabase = createClient(url, key);
  const authAdmin = supabase.auth.admin;
  const createAuth = async (id: string, password: string) => authAdmin.createUser({ id, email: internalEmail(id), password, email_confirm: true });
  try {
    if (b.accion === "login") {
      const usuario = typeof b.usuario === "string" ? b.usuario.trim() : "";
      const password = typeof b.password === "string" ? b.password : "";
      if (!usuario || !password) return err("Completá usuario y contraseña.");
      let row = (await supabase.from("usuarios").select("id,nombre,email,password_hash").eq("nombre", usuario).maybeSingle()).data;
      if (!row) row = (await supabase.from("usuarios").select("id,nombre,email,password_hash").eq("nombre", norm(usuario)).maybeSingle()).data;
      if (!row && usuario.includes("@")) row = (await supabase.from("usuarios").select("id,nombre,email,password_hash").eq("email", usuario.toLowerCase()).maybeSingle()).data;
      if (!row) return err("Usuario o email no encontrado.", 404);
      const existing = await authAdmin.getUserById(row.id);
      if (existing.data?.user) return json({ email_interno: internalEmail(row.id) });
      if (!row.password_hash) return err("Esta cuenta no tiene contraseña. Usá «¿Olvidaste tu contraseña?» o pedile ayuda al administrador.");
      if (!constantTimeEqual(await sha256(password + SALT), row.password_hash)) return err("Contraseña incorrecta.");
      if (password.length < 6) {
        const token = Array.from(crypto.getRandomValues(new Uint8Array(32)), (x) => x.toString(16).padStart(2, "0")).join("");
        const { error } = await supabase.from("recuperaciones").insert({ usuario_id: row.id, token_hash: await sha256(token), expira: new Date(Date.now() + 3600000).toISOString() });
        if (error) throw error;
        return json({ clave_corta: true, token });
      }
      const { error } = await createAuth(row.id, password); if (error) throw error;
      const { error: updateError } = await supabase.from("usuarios").update({ password_hash: null }).eq("id", row.id); if (updateError) throw updateError;
      return json({ email_interno: internalEmail(row.id) });
    }
    if (b.accion === "registro") {
      const nombre = typeof b.nombre === "string" ? b.nombre.trim() : "", real = typeof b.nombre_real === "string" ? b.nombre_real.trim() : "", email = typeof b.email === "string" ? b.email.trim().toLowerCase() : "", password = typeof b.password === "string" ? b.password : "";
      if (nombre.length < 2) return err("El usuario debe tener al menos 2 caracteres.");
      if (real.split(/\s+/).filter(Boolean).length < 2) return err("Ingresá tu nombre Y apellido real (ej: Juan García).");
      if (!email.includes("@")) return err("Ingresá un email válido.");
      if (password.length < 6) return err("La contraseña debe tener al menos 6 caracteres.");
      const n = norm(nombre);
      const { data: duplicateName } = await supabase.from("usuarios").select("id").eq("nombre", n).maybeSingle(); if (duplicateName) return err("Ese nombre de usuario ya existe. Elegí otro.");
      const { data: duplicateEmail } = await supabase.from("usuarios").select("id").eq("email", email).maybeSingle(); if (duplicateEmail) return err("Ese email ya está registrado.");
      const { data: row, error } = await supabase.from("usuarios").insert({ nombre: n, nombre_real: real, email }).select("id").single(); if (error || !row) throw error;
      const created = await createAuth(row.id, password);
      if (created.error) { await supabase.from("usuarios").delete().eq("id", row.id); throw created.error; }
      return json({ id: row.id, email_interno: internalEmail(row.id) });
    }
    if (b.accion === "recuperar") {
      const email = typeof b.email === "string" ? b.email.trim().toLowerCase() : "";
      const { data: row } = await supabase.from("usuarios").select("id,nombre,nombre_real,email").eq("email", email).maybeSingle();
      if (!row) return err("No hay ninguna cuenta con ese email.", 404);
      const token = Array.from(crypto.getRandomValues(new Uint8Array(32)), (x) => x.toString(16).padStart(2, "0")).join("");
      const { error } = await supabase.from("recuperaciones").insert({ usuario_id: row.id, token_hash: await sha256(token), expira: new Date(Date.now() + 3600000).toISOString() }); if (error) throw error;
      const serviceId = Deno.env.get("EMAILJS_SERVICE_ID"), templateId = Deno.env.get("EMAILJS_TEMPLATE_RECUPERO"), publicKey = Deno.env.get("EMAILJS_PUBLIC_KEY"), privateKey = Deno.env.get("EMAILJS_PRIVATE_KEY");
      if (!serviceId || !templateId || !publicKey || !privateKey) throw new Error("Faltan secretos de EmailJS");
      const response = await fetch("https://api.emailjs.com/api/v1.0/email/send", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ service_id: serviceId, template_id: templateId, user_id: publicKey, accessToken: privateKey, template_params: { to_email: row.email, to_name: row.nombre_real || row.nombre, reset_token: token, reset_link: `${validUrlBase(b.url_base)}?reset=${token}` } }) });
      if (!response.ok) throw new Error(`EmailJS HTTP ${response.status}`);
      return json({ ok: true });
    }
    if (b.accion === "restablecer") {
      const token = typeof b.token === "string" ? b.token : "", password = typeof b.password === "string" ? b.password : "";
      if (!token || password.length < 6) return err("La contraseña debe tener al menos 6 caracteres.");
      const { data: reset } = await supabase.from("recuperaciones").select("id,usuario_id").eq("token_hash", await sha256(token)).gt("expira", new Date().toISOString()).maybeSingle();
      if (!reset) return err("El enlace venció o ya fue usado. Pedí uno nuevo.");
      const existing = await authAdmin.getUserById(reset.usuario_id);
      const result = existing.data?.user ? await authAdmin.updateUserById(reset.usuario_id, { password }) : await createAuth(reset.usuario_id, password);
      if (result.error) throw result.error;
      const { error } = await supabase.from("usuarios").update({ password_hash: null, debe_cambiar_clave: false }).eq("id", reset.usuario_id); if (error) throw error;
      await supabase.from("recuperaciones").delete().eq("usuario_id", reset.usuario_id);
      return json({ email_interno: internalEmail(reset.usuario_id) });
    }
    return err("Acción no válida.");
  } catch (e) {
    console.error("cuentas error", e);
    return err("No se pudo completar la operación. Intentá de nuevo o contactá al administrador.", 500);
  }
});
