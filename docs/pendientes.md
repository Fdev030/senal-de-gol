# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer
- [ ] Configurar en Supabase la función `aviso-chat`, sus secretos y el webhook (ver su README) y probarla.
- [ ] Publicar en Netlify (después de que la función ande, porque la página ya no manda el aviso).

## Riesgos y dudas abiertas
- Seguridad: la contraseña del Admin VIP y la clave de RapidAPI están en el código público; la tabla `usuarios`
  se puede leer con la clave pública (hashes y correos). Arreglarlo implica cambiar el login.
- Cómo se publica en Netlify (¿manual o enlazado a GitHub?).
