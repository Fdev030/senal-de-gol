# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer
- [ ] Contador de no leídos: guardar la fecha del último mensaje leído en vez de una cantidad y no ignorar errores.
- [ ] Aviso de mensajes nuevos al Admin VIP por WhatsApp (CallMeBot desde una Edge Function de Supabase).
- [ ] Arreglar el correo de EmailJS (ni avisos ni recuperación aparecen en Email History; revisar que las
      claves del código sean de la misma cuenta de EmailJS).

## Riesgos y dudas abiertas
- Seguridad: la contraseña del Admin VIP y la clave de RapidAPI están en el código público; la tabla `usuarios`
  se puede leer con la clave pública (hashes y correos). Arreglarlo implica cambiar el login.
- Cómo se publica en Netlify (¿manual o enlazado a GitHub?).
