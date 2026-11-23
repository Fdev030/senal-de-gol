-- Señal de Gol — Códigos de grupo privados
-- Ejecutar a mano en Supabase → SQL Editor (primero en la base de pruebas). Requiere el SQL 24.
--
-- Antes, con sesión se podían listar todos los grupos con su código y sumarse a cualquiera.
-- Ahora:
--   * El código no se puede leer de la tabla. Lo ven el admin del grupo y el VIP (función codigos_grupos).
--   * Para sumarse hay que pasar nombre y código a la función unirse_grupo, que los verifica en el servidor.
--   * Nadie puede agregarse a un grupo directamente; solo el creador se agrega como admin al crearlo.

begin;

-- 1. El código queda fuera de lo que se puede leer
revoke select, insert, update on public.grupos from authenticated;
grant select (id, nombre, descripcion, creador_id, created_at) on public.grupos to authenticated;
grant insert (nombre, descripcion, codigo, creador_id) on public.grupos to authenticated;

-- 2. Códigos de los grupos que administra quien pregunta (todos, si es el VIP)
create or replace function public.codigos_grupos()
returns table (id uuid, codigo text)
language sql stable security definer set search_path = public as $$
  select g.id, g.codigo from grupos g where es_admin() or es_admin_grupo(g.id)
$$;

-- 3. Sumarse a un grupo con nombre y código.
-- Devuelve {ok, nombre}, {error: 'no_encontrado' | 'ya_miembro'} o, si hay varios grupos con el mismo nombre y
-- código, {candidatos: [{id, nombre, descripcion, creador}]} para elegir y volver a llamar con p_grupo.
create or replace function public.unirse_grupo(p_nombre text, p_codigo text, p_grupo uuid default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  n integer;
  g record;
begin
  if auth.uid() is null then raise exception 'Sin sesión'; end if;

  select count(*) into n from grupos
   where lower(nombre) = lower(trim(p_nombre)) and codigo = upper(trim(p_codigo))
     and (p_grupo is null or id = p_grupo);
  if n = 0 then return jsonb_build_object('error', 'no_encontrado'); end if;

  if n > 1 then
    return jsonb_build_object('candidatos', (
      select jsonb_agg(jsonb_build_object('id', gr.id, 'nombre', gr.nombre, 'descripcion', gr.descripcion,
                                          'creador', coalesce(u.nombre, 'señaldegol (Admin)')))
      from grupos gr left join usuarios u on u.id = gr.creador_id
      where lower(gr.nombre) = lower(trim(p_nombre)) and gr.codigo = upper(trim(p_codigo))));
  end if;

  select id, nombre into g from grupos
   where lower(nombre) = lower(trim(p_nombre)) and codigo = upper(trim(p_codigo))
     and (p_grupo is null or id = p_grupo);
  if exists (select 1 from grupo_miembros where grupo_id = g.id and usuario_id = auth.uid()) then
    return jsonb_build_object('error', 'ya_miembro');
  end if;

  insert into grupo_miembros (grupo_id, usuario_id, is_admin) values (g.id, auth.uid(), false);
  return jsonb_build_object('ok', true, 'nombre', g.nombre);
end;
$$;

revoke execute on function public.codigos_grupos() from public, anon;
revoke execute on function public.unirse_grupo(text, text, uuid) from public, anon;
grant execute on function public.codigos_grupos() to authenticated;
grant execute on function public.unirse_grupo(text, text, uuid) to authenticated;

-- 4. Sumarse directo a la tabla: solo el creador, como admin, al crear su grupo
drop policy if exists miembros_sumarse on public.grupo_miembros;
create policy miembros_creador on public.grupo_miembros for insert to authenticated
  with check (usuario_id = auth.uid() and is_admin
              and exists (select 1 from public.grupos g where g.id = grupo_id and g.creador_id = auth.uid()));

commit;

-- Verificación: tiene que listar miembros_creador y no miembros_sumarse
select policyname, cmd from pg_policies where schemaname = 'public' and tablename = 'grupo_miembros' order by policyname;
