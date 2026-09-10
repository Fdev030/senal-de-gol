-- ═══════════════════════════════════════════════════════
-- Señal de Gol — SQL: Mostrar/Ocultar torneos
-- Ejecutá en Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════

-- Agrega una columna "visible" a la tabla "torneos". Por defecto
-- todos quedan visibles (true), así ningún torneo existente
-- desaparece del menú de nadie al correr este script.
--
-- El Admin VIP va a poder ocultar el torneo que quiera para los
-- usuarios normales desde el Panel Admin; VIP va a seguir viendo
-- siempre todos los torneos, estén ocultos o no.

alter table torneos add column if not exists visible boolean not null default true;

-- Verificación
select clave, nombre, visible from torneos order by orden;
