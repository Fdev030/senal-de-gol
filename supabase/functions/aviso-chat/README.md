# aviso-chat

## Secretos

Configurá estos secretos en Supabase: `WEBHOOK_SECRET`, `CALLMEBOT_PHONE` (formato `+549...`), `CALLMEBOT_APIKEY`, `EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`, `EMAILJS_PUBLIC_KEY`, `EMAILJS_PRIVATE_KEY` y `AVISO_EMAIL` (una o varias direcciones separadas por coma). Cada canal se saltea si le faltan sus variables.

## Crear la función y el webhook

En Supabase, andá a **Edge Functions → Deploy a new function → Via Editor**, poné el nombre `aviso-chat` y pegá el código de `index.ts`. Desactivá **Verify JWT**: la función se protege con el secreto del webhook.

Después, en **Database → Webhooks**, creá un webhook para la tabla `comentarios`, evento **Insert**, tipo **Supabase Edge Functions**, función `aviso-chat`, método **POST**. Agregá el header `x-webhook-secret` con el mismo valor de `WEBHOOK_SECRET`.

## EmailJS y prueba

En EmailJS, entrá a **Account → Security**, activá **Allow EmailJS API for non-browser applications** y copiá la **Private Key** a `EMAILJS_PRIVATE_KEY`.

Para probar, insertá un mensaje de un usuario en `comentarios` y revisá el resultado en **Edge Functions → aviso-chat → Logs**. Los mensajes del VIP se ignoran.
