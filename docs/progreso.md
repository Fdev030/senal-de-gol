# Progreso — Señal de Gol

> Registro cronológico (lo más reciente arriba).

## Historial

### 2026-11-20 — Etapa 1 del login desplegada y probada en la base de pruebas
- **Responsable:** Franco (SQL 22, función `cuentas`, secretos y ajustes de Auth en el panel; pruebas en el navegador),
  Claude Code (verificación por la API y diagnóstico del servidor local)
- **Hecho:** etapa 1 funcionando en `ptdovhnxremcssitgchk`. Producción sin tocar: se migra junto con la etapa 2.
- **Verificación:**
  - Por la API: columnas `es_admin`/`debe_cambiar_clave` (VIP en true), tabla `recuperaciones`, la función responde sin
    JWT, `disable_signup = true`.
  - Migración progresiva: Prueba1, Prueba2 y Prueba3 entraron con `prueba123` y quedaron con `password_hash` en null.
  - Registro nuevo: Prueba4 y FrancoPrueba.
  - VIP: le pidió el cambio obligatorio de contraseña al entrar.
  - Recuperación: el mail llegó por EmailJS y el link permitió poner una clave nueva.
- **Observaciones:** el link del mail llegaba como texto plano; se ajusta en la plantilla `template_rqic4mv` de EmailJS
  con un `<a href="{{reset_link}}">`.
- **VIP y cambio obligatorio:** después de la primera prueba, el VIP seguía con `debe_cambiar_clave = true` y su clave no
  entraba. Con un usuario descartable (`Diagclave`), Claude Code repitió el recorrido por la API (login → `PUT /auth/v1/user` →
  update del flag con el token del usuario → login con la clave nueva) y todo respondió 200. Franco reseteó la clave del
  VIP en `auth.users` con `extensions.crypt(..., gen_salt('bf'))`, entró, completó el cambio, la pantalla se cerró y no
  volvió a aparecer, y el flag quedó en false. Conclusión: la primera vez el cambio no se había completado; el código funciona.
- **Ojo:** desde que el VIP tiene cuenta en Auth, la consulta sobre `usuarios.password_hash` ya no sirve para darle
  clave. Hay que usar la de `auth.users`.

### 2026-11-19 — Etapa 1: login con Supabase Auth implementada en código
- **Responsable:** Codex (implementación), Claude Code (revisión: los errores 4xx/5xx de la función se leen de `error.context`,
  porque supabase-js no los pone en `data`; mensaje en español si la contraseña nueva es igual a la actual)
- **Hecho:** login y migración progresiva de hashes a Auth, alta y recuperación vía Edge Function `cuentas`; sesión basada en Auth; eliminación de `VIP_PASS` y del EmailJS de recuperación en el navegador; cambio de contraseña por Auth y cambio obligatorio al VIP; SQL 22 y guía de despliegue.
- **Archivos:** `public/index.html`, `supabase/functions/cuentas/`, `sql/22-login-supabase-auth.sql`, `docs/`
- **Verificación:** `node --check` del script inline; todavía no se probó contra Supabase porque la función y el SQL no están desplegados.



### 2026-11-19 — Login: una cuenta sin contraseña ya no se puede reclamar
- **Responsable:** Claude Code
- **Hecho:** antes, si una cuenta no tenía `password_hash`, `doLogin` guardaba la primera contraseña que alguien
  escribiera y lo dejaba entrar. Ahora muestra un aviso y manda a «¿Olvidaste tu contraseña?». Registro y cambio de
  contraseña siempre guardan una, así que solo afectaba a cuentas viejas (en producción no queda ninguna así).
- **Archivos:** `public/index.html`
- **Verificación:** `node --check`; Franco lo probó en el navegador con una cuenta sin contraseña (no entra con ninguna) y con `Prueba1` (entra).

### 2026-11-19 — Base de pruebas separada; limpieza de usuarios
- **Responsable:** Franco (proyecto nuevo en Supabase, exportación y ejecución del esquema), Claude Code (scripts y cambio en la página)
- **Hecho:** proyecto Supabase de pruebas con la misma estructura que producción (`sql/00-esquema.sql`, exportada con
  `sql/exportar-esquema.sql`) y datos de `scripts/sembrar-pruebas.mjs` (26 torneos, 86 fechas, 375 partidos, reglamento,
  VIP + 3 usuarios falsos, 1 grupo, 1125 pronósticos). La página usa la base de pruebas en local (`ES_PRUEBAS`).
  En producción se borraron los usuarios de prueba Juan y Paula (sin datos asociados); copia en
  `~/Proyectos/senal-de-gol-respaldos/`. FranAA y Juan_ac77 quedan porque están en el podio de "Apertura 2026".
- **Archivos:** `public/index.html`, `sql/00-esquema.sql`, `sql/exportar-esquema.sql`, `scripts/sembrar-pruebas.mjs`, `docs/`
- **Verificación:** las 12 tablas responden en la base de pruebas; la clave `sb_publishable_…` funciona con los mismos
  encabezados que manda supabase-js; `node --check` del script de la página. Franco entró con `Prueba1` en el navegador.

### 2026-11-18 — Netlify enlazado con GitHub
- **Responsable:** Franco (enlace en Netlify), Claude Code (`public/` + `netlify.toml`)
- **Hecho:** Netlify publica `public/` desde la rama `main`. Se borró la carpeta de deploy manual.
- **Verificación:** la página publicada es idéntica a `public/index.html`; `netlify.toml`, `docs/`, `sql/` y
  `AGENTS.md` dan 404 en el sitio.

### 2026-11-18 — Publicado en Netlify; WhatsApp confirmado
- **Responsable:** Franco (deploy manual), Claude Code (verificación)
- **Hecho:** subida de `index.html` + `_headers` a Netlify. El WhatsApp de CallMeBot llegó al papá (con demora).
- **Verificación:** el HTML de senaldegol.netlify.app es idéntico al `index.html` del repo.

### 2026-11-18 — Función `aviso-chat` configurada en Supabase
- **Responsable:** Franco (configuración en el panel), Claude Code (guía y diagnóstico)
- **Hecho:** función desplegada, 8 secretos cargados, webhook en INSERT de `comentarios` (Integrations → Database Webhooks).
- **Verificación:** mensajes de prueba desde localhost: log `aviso-chat resultado { whatsapp: "ok", email: "ok" }`;
  el correo llegó a senaldegol@gmail.com; el WhatsApp todavía no (ver pendientes).

### 2026-11-18 — Avisos del chat por WhatsApp y correo desde Supabase
- **Responsable:** Codex (implementación), Claude Code (revisión; validación del texto de respuesta de CallMeBot)
- **Hecho:** Edge Function `aviso-chat` con README de configuración; se quitó `notifyVipNewMessage` de `index.html`.
- **Archivos:** `supabase/functions/aviso-chat/index.ts`, `supabase/functions/aviso-chat/README.md`, `index.html`
- **Verificación:** `node --check` del script de la página y `tsc --noEmit` de la función. Falta la prueba real en Supabase.

### 2026-11-18 — Contador de mensajes no leídos
- **Responsable:** Codex (implementación), Claude Code (revisión y ajuste del orden del sondeo)
- **Hecho:** el conteo usa `created_at > last_read_at`; `markChatRead` guarda el `created_at` más reciente del chat
  (hora del servidor) sin retroceder; filtros de chat unificados en `filterChatQuery` (el conteo de grupos no filtraba
  `torneo_clave`); errores de `chat_lecturas` a la consola; con el chat abierto, el sondeo de 30 s recarga y marca leído.
- **Archivos:** `index.html`
- **Verificación:** `node --check` del script; Franco lo probó en localhost contra producción: los contadores
  desaparecen y no vuelven; `chat_lecturas` pasó a tener filas.

### 2026-11-18 — Alta del proyecto y diagnóstico del chat
- **Responsable:** Claude Code
- **Hecho:** clon de GitHub, reemplazo por la versión de Netlify, `AGENTS.md` y `docs/`. Diagnóstico: `chat_lecturas`
  con RLS sin políticas (0 filas). Franco ejecutó las políticas en Supabase.
- **Verificación:** consulta al catálogo de Postgres hecha por Franco en el SQL Editor.
