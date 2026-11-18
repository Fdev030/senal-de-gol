# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer
- [ ] WhatsApp: la función responde `whatsapp: "ok"` (CallMeBot acepta clave y número y encola), pero el mensaje no le
      llega al papá. Revisar si el número de CallMeBot quedó bloqueado (se borró el chat), probar el enlace de prueba
      de CallMeBot y, si hace falta, volver a activarlo y actualizar `CALLMEBOT_APIKEY`.
- [ ] Publicar en Netlify (después de que la función ande, porque la página ya no manda el aviso).

## Riesgos y dudas abiertas
- Seguridad: la contraseña del Admin VIP y la clave de RapidAPI están en el código público; la tabla `usuarios`
  se puede leer con la clave pública (hashes y correos). Arreglarlo implica cambiar el login.
- Cómo se publica en Netlify (¿manual o enlazado a GitHub?).
