# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer

Ideas elegidas por Franco el 2026-11-19, de cara al **lanzamiento público en febrero de 2027** (hoy la usan 4 personas).
El orden es el sugerido: primero lo técnico, porque lo demás se apoya en eso.

### 1. Técnico y seguridad
- [ ] **Etapa 2 de seguridad y login:** borrar `password_hash`, `reset_token` y `reset_expires`; proteger `es_admin` y
      `debe_cambiar_clave`; reescribir/cerrar `pub_all` y sacar el índice duplicado `usuarios_email_idx`. La producción
      se migra junto con el cierre de RLS: mientras las políticas sigan abiertas cualquiera puede ponerse `es_admin`.
      Antes de migrar producción: el `password_hash` del VIP en `usuarios` NO es el de la vieja `VIP_PASS`, así que hay
      que darle una contraseña inicial desde el SQL Editor (sin guardarla en el repo):
      `update usuarios set password_hash = encode(extensions.digest('<clave>' || 'prode_salt_2025', 'sha256'), 'hex') where id = '00000000-0000-0000-0000-000000000001';`
      Al primer ingreso la página obliga a cambiarla (`debe_cambiar_clave`).
- [x] **Etapa 1 de login en la base de pruebas** (2026-11-20, ver progreso). En producción se ejecuta junto con la etapa 2.
- [ ] **Etapa 2: cambio obligatorio de contraseña.** Hoy `updateForcedPassword` apaga `debe_cambiar_clave` con un update
      desde el navegador. Al proteger esa columna va a quedar bloqueado, así que hay que moverlo a la función `cuentas`
      (o a una función de Postgres que solo apague el propio flag).
- [ ] **Limpieza de la base de pruebas:** borrar el usuario `Diagclave` (diagnóstico del 2026-11-20), desde
      Authentication → Users y la tabla `usuarios`.
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
