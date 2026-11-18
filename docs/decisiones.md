# Registro de decisiones — Señal de Gol

> Una entrada por decisión. No editar decisiones pasadas: si cambian, agregar una nueva que las reemplace.

### D-001 — Repositorio local fuera de la agencia
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** proyecto personal, no va al GitLab de Endianness.
- **Decisión:** vive en `~/Proyectos/senal-de-gol` (repo `Fdev030/senal-de-gol` en GitHub). Se trabaja con el
  mismo método de la agencia (Claude Code orquesta, Codex programa, `docs/` como memoria).

### D-002 — La versión publicada en Netlify es la fuente
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** GitHub tenía un `index.html` viejo (2026-09-10); Netlify tenía ~90 líneas más nuevas.
- **Decisión:** se tomó el `index.html` de `senaldegol.netlify.app` (sin el comentario que inyecta Netlify) como base.

### D-003 — Políticas RLS para `chat_lecturas`
- **Fecha:** 2026-11-18
- **Estado:** Aceptada
- **Contexto:** la tabla tenía RLS activado sin políticas: la página no podía leer ni guardar lecturas y el
  contador volvía a contar todos los mensajes cada 30 s.
- **Decisión:** políticas `select`/`insert`/`update` para `anon, authenticated` (`sql/21-chat-lecturas-politicas.sql`),
  igual de abiertas que el resto de la app porque el login es propio.
