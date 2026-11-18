# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer
- [ ] Aviso de mensajes nuevos al Admin VIP por WhatsApp (CallMeBot desde una Edge Function de Supabase).
- [ ] Correo de aviso: las claves de EmailJS son correctas (un envío por API desde fuera del navegador salió OK
      el 2026-11-18), pero los envíos desde el navegador de los usuarios no llegan. Se pasa a la Edge Function.
- [ ] Publicar en Netlify la versión con el contador arreglado.

## Riesgos y dudas abiertas
- Seguridad: la contraseña del Admin VIP y la clave de RapidAPI están en el código público; la tabla `usuarios`
  se puede leer con la clave pública (hashes y correos). Arreglarlo implica cambiar el login.
- Cómo se publica en Netlify (¿manual o enlazado a GitHub?).
