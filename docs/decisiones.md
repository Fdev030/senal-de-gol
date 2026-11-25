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

### D-008 — Migración del login a Supabase Auth por etapas
- **Fecha:** 2026-11-19
- **Estado:** Aceptada
- **Contexto:** la sesión propia era falsificable, el VIP tenía su clave en el frontend y la recuperación estaba rota.
- **Decisión:** migrar en la etapa 1 a Auth con el mismo UUID de `usuarios`, email interno derivado del UUID y Edge Function `cuentas` para migración transparente, registro y recuperación. La función conserva `password_hash` solo para migrar cuentas aún no migradas y lo anula al completar la migración. `es_admin` y `debe_cambiar_clave` se agregan para el VIP y el cambio obligatorio de su clave. `recuperaciones` guarda hash del token. No se modifican las políticas RLS en esta etapa. El despliegue y la migración de producción se dejan para después de validar; como RLS sigue abierto, migrar antes de cerrar políticas permitiría alterar privilegios.
- **Consecuencia:** la etapa 2 debe borrar `password_hash`, `reset_token` y `reset_expires`, proteger `es_admin` y `debe_cambiar_clave` y cerrar `pub_all`; correr SQL/función en pruebas antes de producción.

### D-009 — Relleno de randoms en el servidor
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

### D-010 — Etapa 2: base cerrada y contraseñas viejas conservadas
- **Fecha:** 2026-11-23
- **Estado:** Aceptada
- **Contexto:** todas las tablas tenían `pub_all`: con la clave pública cualquiera leía, cambiaba o borraba todo,
  incluidas contraseñas y correos. Borrar las contraseñas viejas obligaba a quien no hubiera entrado a recuperar
  la clave por mail; Franco prefirió conservarlas.
- **Decisión:** `sql/24-etapa2-seguridad.sql`. Las contraseñas viejas pasan a `claves_viejas` (sin políticas, solo
  la lee `cuentas` con service role) y se borran de `usuarios` con `reset_token`/`reset_expires`; la migración
  progresiva sigue indefinidamente. Políticas por tabla: sin sesión solo se leen los torneos; la escritura de
  torneos, fechas, partidos, temporadas y reglamento es solo del VIP (`es_admin()`); los pronósticos ajenos se ven
  al cerrar la fecha y no se aceptan cargas después del cierre; el chat de un grupo lo ven sus miembros y el VIP;
  `chat_lecturas` es de cada uno. El email solo lo ve el VIP (`usuarios_admin()`); `es_admin` y
  `debe_cambiar_clave` no se editan desde la página (`clave_cambiada()`). Solo el VIP renueva randoms; los randoms por
  grupo quedan para después. Los usuarios comunes ya no crean fechas al navegar.

### D-011 — Códigos de grupo privados
- **Fecha:** 2026-11-23
- **Estado:** Aceptada
- **Contexto:** con sesión se podían listar todos los grupos con su código e id, y la política de `grupo_miembros`
  permitía sumarse a cualquier grupo sin código.
- **Decisión:** `sql/25-codigos-grupo.sql`. La columna `codigo` no se puede leer; la ven el admin del grupo y el VIP
  con `codigos_grupos()`. Para sumarse se usa `unirse_grupo(nombre, código, grupo?)`, que verifica en el servidor;
  si hay varios grupos con igual nombre y código devuelve los candidatos con su creador. Directo en la tabla solo se
  agrega el creador como admin de su grupo.

### D-012 — Campeones generales, sin grupos
- **Fecha:** 2026-11-24
- **Estado:** Aceptada
- **Contexto:** la tabla de campeones se podía filtrar por grupo y cada temporada se asignaba a un grupo o a la
  competición general. El papá de Franco quiere un único salón de campeones para todos los usuarios.
- **Decisión:** se quita el filtro por grupo, la etiqueta de grupo de cada tarjeta y el selector del formulario; las
  temporadas se guardan con `grupo_id = null`. La columna `temporadas.grupo_id` queda en la base (no se borra nada);
  las temporadas viejas que tenían grupo se muestran igual, mezcladas con las demás, y al editarlas pasan a generales.
