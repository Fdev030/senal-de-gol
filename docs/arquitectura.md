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
index.html   toda la aplicación (estilos, credenciales públicas, componentes)
_headers     Netlify: sin caché
*.sql        scripts que se ejecutan a mano en Supabase → SQL Editor
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
- No hay build ni dependencias: servir la carpeta (`python -m http.server`) y abrir `index.html`.
- Ojo: local usa la base **de producción**.
- Publicar: a mano, arrastrando a Netlify (Deploys) una carpeta con solo `index.html` y `_headers`. No está enlazado a GitHub.
