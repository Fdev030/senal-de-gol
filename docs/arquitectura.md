# Arquitectura — Señal de Gol

> Documentar solo lo que esté confirmado. Lo que no se sepa todavía se marca como *Por definir*.

## Objetivo del proyecto
Prode (pronósticos de partidos de fútbol) para un grupo de usuarios. Proyecto personal de Franco para su papá
(el **Admin VIP** de la página). No es un proyecto de la agencia Endianness.

## Stack tecnológico
| Capa | Tecnología | Versión | Estado |
|------|------------|---------|--------|
| Frontend | Un solo `index.html` con React 18.2 UMD (sin JSX: `h()` = `React.createElement`) | 18.2.0 (cdnjs) | En uso |
| Base de datos | Supabase (PostgREST) con la clave `anon` | supabase-js@2 (jsdelivr) | En uso |
| Correo | EmailJS: recuperación desde el navegador; avisos del chat desde la Edge Function | @emailjs/browser@3 / API REST | En uso |
| WhatsApp | CallMeBot desde la Edge Function `aviso-chat` | — | En uso (puede tardar unos minutos) |
| Hosting | Netlify, sitio `senaldegol.netlify.app` | — | En uso |
| Datos de partidos | RapidAPI | — | En uso |

## Estructura de carpetas
```
public/index.html   toda la aplicación (estilos, credenciales públicas, componentes)
public/_headers     Netlify: sin caché
netlify.toml        Netlify publica solo public/
supabase/functions/ Edge Functions (aviso-chat)
sql/         scripts que se ejecutan a mano en Supabase → SQL Editor (00-esquema.sql = estructura completa)
scripts/     herramientas de Node (sembrar-pruebas.mjs)
docs/        memoria del proyecto
```

## Login
Propio, **no** usa Supabase Auth: tabla `usuarios` con `password_hash` = SHA-256(contraseña + sal fija) calculado
en el navegador. Todas las consultas llegan a Supabase con el rol `anon`, así que cada tabla con RLS necesita
políticas para `anon`. El Admin VIP entra con usuario y contraseña escritos en el código (`VIP_USER`, id
`00000000-0000-0000-0000-000000000001`, que existe en `usuarios`).

## Chat
- Tabla `comentarios`. Chat general: `torneo_clave='general'` y `grupo_id` nulo. Chat de grupo: `grupo_id=<id>`
  y `torneo_clave` nulo. Los mensajes del VIP tienen `usuario_id` nulo.
- Contador de no leídos: tabla `chat_lecturas` (`usuario_id`, `chat_key`, `last_read_at`, `read_count`; único
  `(usuario_id, chat_key)`; FK a `usuarios` con borrado en cascada). `chat_key` = `'general'` o el id del grupo.
- Aviso al Admin VIP de mensajes nuevos: **Edge Function `aviso-chat`** (`supabase/functions/aviso-chat/`), disparada
  por un Database Webhook en INSERT de `comentarios` (protegido con el header `x-webhook-secret`). Manda WhatsApp por
  CallMeBot y correo por la API REST de EmailJS (plantilla `template_1a7qpdd`). Claves y teléfono solo como secretos
  de Supabase. Ignora los mensajes del VIP. La página ya no manda el aviso.

## Cómo ejecutar y probar
- No hay build ni dependencias: `python -m http.server 8080 --directory public` y abrir http://localhost:8080.
- En `localhost`, `127.0.0.1`, la red de casa (`192.168.x.x`, `10.x.x.x`) o abriendo el archivo directo, la página usa
  la **base de pruebas** (proyecto Supabase `ptdovhnxremcssitgchk`) y muestra la etiqueta naranja "BASE DE PRUEBAS".
  En Netlify usa producción (`fimnnijbommaskdgulbg`). La elección es la constante `ES_PRUEBAS` de `index.html`.
- Base de pruebas: estructura en `sql/00-esquema.sql`, datos con `scripts/sembrar-pruebas.mjs`. Usuarios `Prueba1`,
  `Prueba2`, `Prueba3` (contraseña `prueba123`) en el "Grupo de prueba" (código `PRUEBA`). No tiene el webhook del chat.
- Ojo: RapidAPI y EmailJS son los reales también en local.
- Publicar: Netlify enlazado a GitHub (rama `main`), publica `public/` según `netlify.toml`. Hasta enlazarlo: arrastrar la carpeta `public/` en Deploys.
