# Progreso — Señal de Gol

> Registro cronológico (lo más reciente arriba).

## Historial

### 2026-11-23 — Relleno de randoms en el servidor (rama `arreglo-randoms`)
- **Responsable:** Claude Code (código y verificación por la API), Franco (SQL en la base de pruebas)
- **Hecho:** el relleno con aleatorios pasa a la función `rellenar_randoms()` con `pg_cron` cada 5 minutos
  (D-008). La página ya no rellena desde el navegador: llama a la función por RPC y refresca contador y pronósticos
  cada minuto. Causa del aviso de Lapavota: el relleno de fondo cargaba la fecha 17 pero no actualizaba el contador
  (la base tenía 1 random usado; la pantalla mostraba 3 disponibles).
- **Archivos:** `sql/23-relleno-randoms-servidor.sql`, `public/index.html`, `docs/decisiones.md`
- **Verificación (base de pruebas):** la primera llamada completó 700 pronósticos; después no quedaron partidos sin
  pronóstico en fechas cerradas, nadie pasó de 3 randoms por torneo y toda fecha aleatoria quedó contada. Prueba con
  una fecha cerrada nueva: quien tenía cupo recibió aleatorios y gastó 1 random, quien no, quedó en blanco; dos
  llamadas en paralelo contaron una sola vez; un partido agregado después se rellenó igual que el resto sin
  descontar otro random. Las filas de la prueba se borraron. `node --check` del script de la página.
- **Falta:** confirmar que el cron corre solo (`cron.job_run_details`), probar la página en el navegador y pasarlo
  a producción.

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
