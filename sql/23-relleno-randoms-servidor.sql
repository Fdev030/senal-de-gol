-- Señal de Gol — Relleno de randoms en el servidor
-- Ejecutar a mano en Supabase → SQL Editor (primero en la base de pruebas).
--
-- Antes el relleno lo hacía el navegador de cada usuario, solo mientras tenía la página abierta.
-- Ahora lo hace la base de datos cada 5 minutos para TODOS los usuarios, entren o no.
--
-- Reglas (las mismas que tenía la página):
--   * Solo fechas cerradas (deadline ya pasado). Las fechas sin deadline no se tocan.
--   * Todos los torneos, aunque el usuario no los juegue. También el admin.
--   * Por cada fecha con partidos sin pronóstico: si el usuario usó menos de 3 randoms en ese torneo,
--     se cargan resultados aleatorios (0 a 4 goles) y se descuenta 1 random; si ya usó 3, quedan en blanco.
--   * Las fechas se recorren de la más vieja a la más nueva.
--   * Si a una fecha ya contada le falta un partido (se agregó después), se rellena sin descontar otro random.

begin;

create extension if not exists pg_cron;

create or replace function public.rellenar_randoms()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  usados integer;
  ya_contada boolean;
  puede_auto boolean;
  filas integer := 0;
  n integer;
begin
  -- Evita que dos ejecuciones al mismo tiempo cuenten mal los randoms.
  perform pg_advisory_xact_lock(hashtext('rellenar_randoms'));

  for r in
    select u.id as usuario_id, t.clave, f.id as fecha_id, f.numero
    from usuarios u
    cross join fechas f
    join torneos t on t.id = f.torneo_id
    where f.deadline < now()
      and t.clave is not null
      and exists (
        select 1 from partidos p
        where p.fecha_id = f.id
          and not exists (select 1 from pronosticos pr where pr.usuario_id = u.id and pr.partido_id = p.id)
      )
    order by u.id, f.deadline, f.numero
  loop
    select count(*) into usados from autos_usados a
      where a.usuario_id = r.usuario_id and a.torneo_clave = r.clave;
    select exists (select 1 from autos_usados a
      where a.usuario_id = r.usuario_id and a.torneo_clave = r.clave and a.fecha_numero = r.numero) into ya_contada;
    puede_auto := ya_contada or usados < 3;

    insert into pronosticos (usuario_id, partido_id, torneo_clave, goles_local, goles_visitante, es_auto, es_blanco)
    select r.usuario_id, p.id, r.clave,
           case when puede_auto then floor(random() * 5)::int else 0 end,
           case when puede_auto then floor(random() * 5)::int else 0 end,
           puede_auto, not puede_auto
    from partidos p
    where p.fecha_id = r.fecha_id
      and not exists (select 1 from pronosticos pr where pr.usuario_id = r.usuario_id and pr.partido_id = p.id)
    on conflict (usuario_id, partido_id) do nothing;
    get diagnostics n = row_count;
    filas := filas + n;

    if puede_auto and not ya_contada then
      insert into autos_usados (usuario_id, torneo_clave, fecha_numero)
      values (r.usuario_id, r.clave, r.numero)
      on conflict (usuario_id, torneo_clave, fecha_numero) do nothing;
    end if;
  end loop;

  return filas;
end;
$$;

-- La página la llama al cerrar una fecha para no esperar al próximo turno del cron.
grant execute on function public.rellenar_randoms() to anon, authenticated;

-- Cada 5 minutos. Si ya existía el trabajo, lo reemplaza.
select cron.unschedule('rellenar-randoms') where exists (select 1 from cron.job where jobname = 'rellenar-randoms');
select cron.schedule('rellenar-randoms', '*/5 * * * *', 'select public.rellenar_randoms()');

commit;

-- Verificación
select jobname, schedule, command, active from cron.job where jobname = 'rellenar-randoms';
