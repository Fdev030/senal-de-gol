# Pendientes — Señal de Gol

> Marcar con [x] al completar y mover a progreso.md con su verificación.

## Por hacer

Ideas elegidas por Franco el 2026-11-19, de cara al **lanzamiento público en febrero de 2027** (hoy la usan 4 personas).
El orden es el sugerido: primero lo técnico, porque lo demás se apoya en eso.

### 1. Técnico y seguridad
- [x] **Etapa 2 de seguridad y login** (2026-11-23, en producción; ver progreso).
- [ ] **Randoms por grupo:** que el admin de cada grupo renueve randoms solo dentro de su grupo. Requiere que el
      relleno cargue siempre aleatorios y que cada tabla (general y de cada grupo) aplique su propio límite de 3,
      con las renovaciones de su admin. Mientras tanto, solo el VIP renueva (se sacó el botón de los grupos).
- [x] **Códigos de grupo privados** (2026-11-23, en producción; D-011).
- [x] **Etapa 1 de login** (pruebas 2026-11-20; producción 2026-11-23 junto con la etapa 2).
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
