# Registro de decisiones — Señal de Gol

> Una entrada por decisión. No editar decisiones pasadas: si cambian, agregar una nueva que las reemplace.

### D-001 — Repositorio local fuera de la agencia
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** proyecto personal, no va al GitLab de Endianness.
- **Decisión:** vive en `~/Proyectos/senal-de-gol` (repo `Fdev030/senal-de-gol` en GitHub). Se trabaja con el
  mismo método de la agencia (Claude Code orquesta, Codex programa, `docs/` como memoria).

### D-002 — La versión publicada en Netlify es la fuente
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** GitHub tenía un `index.html` viejo (2026-09-10); Netlify tenía ~90 líneas más nuevas.
- **Decisión:** se tomó el `index.html` de `senaldegol.netlify.app` (sin el comentario que inyecta Netlify) como base.

### D-003 — Políticas RLS para `chat_lecturas`
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** la tabla tenía RLS activado sin políticas: la página no podía leer ni guardar lecturas y el
  contador volvía a contar todos los mensajes cada 30 s.
- **Decisión:** políticas `select`/`insert`/`update` para `anon, authenticated` (`sql/21-chat-lecturas-politicas.sql`),
  igual de abiertas que el resto de la app porque el login es propio.

### D-004 — Avisos del chat desde Supabase (WhatsApp + correo)
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** el aviso por EmailJS salía del navegador de cada usuario y nunca llegaba (Email History vacío; un envío
  por API desde fuera del navegador sí salió). Franco quiere el aviso también en el WhatsApp personal de su papá.
- **Decisión:** Edge Function `aviso-chat` + Database Webhook; WhatsApp por CallMeBot (gratis, número personal) y correo
  por EmailJS REST con Private Key. Se quita el aviso de `index.html` para no duplicar.
- **Alternativas consideradas:** WhatsApp Cloud API de Meta (exige verificar un negocio); llamar a CallMeBot desde el
  navegador (expone la apikey y depende del navegador del usuario).

### D-005 — Netlify publica solo `public/`
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** al enlazar Netlify con GitHub, publicar la raíz expondría `docs/`, `sql/`, `supabase/` y `AGENTS.md`.
- **Decisión:** la página vive en `public/` y `netlify.toml` fija `publish = "public"` sin comando de build.

### D-006 — Lanzamiento público en febrero de 2027
- **Fecha:** 2026-11-19
- **Estado:** Aceptada
- **Contexto:** hoy la usan 4 personas (el papá de Franco, su hermano y dos amigos del papá, que organizan su prode).
- **Decisión:** abrirla a todo público en febrero de 2027. Sigue siendo un proyecto personal, no un producto de Endianness.
- **Consecuencia:** la seguridad (login, lectura pública de `usuarios`, claves en el código) pasa a ser obligatoria antes
  del lanzamiento.

### D-007 — Base de pruebas elegida por el host
- **Fecha:** 2026-11-19
- **Estado:** Aceptada
- **Contexto:** probar en local escribía en la base de producción.
- **Decisión:** segundo proyecto de Supabase (gratis). `index.html` elige la base según `location.hostname`: local y red de
  casa → pruebas; cualquier otro (Netlify) → producción. Etiqueta visible "BASE DE PRUEBAS" para no confundirse.
- **Alternativas consideradas:** una variable de entorno de Netlify (exige un paso de build, que hoy no hay).

### D-008 — Relleno de randoms en el servidor
- **Fecha:** 2026-11-23
- **Estado:** Aceptada
- **Contexto:** el relleno con aleatorios lo hacía el navegador de cada usuario (`runAutoFill` al abrir la fecha y
  `catchUpMissedFechas` cada 60 s), solo mientras tenía la página abierta. Quien no entraba quedaba sin pronósticos
  y el contador de randoms en pantalla no se actualizaba (Lapavota veía 3 disponibles con 1 usado).
- **Decisión:** función `rellenar_randoms()` en Postgres, ejecutada por `pg_cron` cada 5 minutos
  (`sql/23-relleno-randoms-servidor.sql`). Rellena a todos los usuarios, admin incluido, en todos los torneos, aunque
  no los jueguen. Mantiene las reglas anteriores: 3 randoms por torneo, después en blanco; de la fecha más vieja a la
  más nueva; las fechas sin deadline no se rellenan. Una fecha ya contada que recibe un partido nuevo se rellena sin
  descontar otro random. La página la pide por RPC al entrar, al registrarse y cuando una fecha cierra con la página
  abierta, y refresca contador y pronósticos cada minuto.
