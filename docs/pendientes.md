# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer

Ideas elegidas por Franco el 2026-11-19, de cara al **lanzamiento público en febrero de 2027** (hoy la usan 4 personas).
El orden es el sugerido: primero lo técnico, porque lo demás se apoya en eso.

### 1. Técnico y seguridad
- [ ] **Seguridad y login:** sacar la contraseña del Admin VIP del código. Todas las tablas tienen la política
      `pub_all` (ALL, `using (true)`): con la clave pública cualquiera puede leer, cambiar y borrar todo, incluidos
      `password_hash`, correos y `reset_token` de `usuarios`. Sacar también el índice duplicado
      `usuarios_email_idx`.
      Ojo con `doLogin`: si una cuenta no tiene `password_hash`, la primera contraseña que alguien escriba queda
      guardada (hoy ninguna cuenta de producción está sin contraseña). Opciones: Supabase Auth, o login en una Edge Function que devuelva un token. Implica
      reescribir las políticas RLS (hoy todo está abierto para `anon`) y migrar las contraseñas actuales.
- [ ] **Proxy de RapidAPI:** Edge Function que guarde la clave como secreto y cachee respuestas para ahorrar cuota.
- [ ] **Partir `index.html`:** separar estilos y componentes en archivos (módulos ES, sin build).

### 2. Funcionalidades
- [ ] **PWA instalable:** `manifest.json`, íconos y service worker. Después, notificaciones push (claves VAPID +
      Edge Function); en iPhone solo funcionan con la app instalada (iOS 16.4 o posterior).
- [ ] **Reacciones en el chat:** tabla nueva (`comentario_id`, `usuario_id`, `emoji`, único por los tres).
- [ ] **Menciones en el chat:** autocompletar `@usuario` al escribir, resaltar la mención y avisar al mencionado.
- [ ] **Panel "estado de la fecha":** quién pronosticó y quién no, por fecha y por grupo, con botón de recordatorio.
- [ ] **Página pública del grupo:** tabla de posiciones de solo lectura con un link difícil de adivinar. La activa
      el admin del grupo (apagada por defecto) y muestra apodos, no nombres reales.
- [ ] **Salón de la fama:** la pestaña de campeones (`temporadas`) ya existe; falta el palmarés por jugador
      (títulos y podios) y una vista más vistosa.
- [ ] **Pozo o premios por grupo (opcional):** el admin del grupo decide si lo activa. Texto libre por puesto
      ("1° se lleva el asado"). La app solo lo muestra: no cobra ni maneja dinero.

## Riesgos y dudas abiertas
- Pozo con dinero real: si la app cobrara entradas o pagara premios podría entrar en la regulación de juegos de azar.
  Por eso solo se registra lo que el grupo acordó por fuera.
- El cambio de login es el más riesgoso: puede dejar a usuarios sin poder entrar. Conviene probarlo en la base de
  pruebas y avisar antes de pasarlo a producción.
- Lanzamiento público: con más usuarios hay que revisar los límites gratis de EmailJS, RapidAPI y Supabase.
