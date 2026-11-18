# Progreso — Señal de Gol

> Registro cronológico (lo más reciente arriba).

## Historial

### 2026-11-18 — Contador de mensajes no leídos
- **Responsable:** Codex (implementación), Claude Code (revisión y ajuste del orden del sondeo)
- **Hecho:** el conteo usa `created_at > last_read_at`; `markChatRead` guarda el `created_at` más reciente del chat
  (hora del servidor) sin retroceder; filtros de chat unificados en `filterChatQuery` (el conteo de grupos no filtraba
  `torneo_clave`); errores de `chat_lecturas` a la consola; con el chat abierto, el sondeo de 30 s recarga y marca leído.
- **Archivos:** `index.html`
- **Verificación:** `node --check` del script; Franco lo probó en localhost contra producción: los contadores
  desaparecen y no vuelven; `chat_lecturas` pasó a tener filas.

### 2026-11-18 — Alta del proyecto y diagnóstico del chat
- **Responsable:** Claude Code
- **Hecho:** clon de GitHub, reemplazo por la versión de Netlify, `AGENTS.md` y `docs/`. Diagnóstico: `chat_lecturas`
  con RLS sin políticas (0 filas). Franco ejecutó las políticas en Supabase.
- **Verificación:** consulta al catálogo de Postgres hecha por Franco en el SQL Editor.
