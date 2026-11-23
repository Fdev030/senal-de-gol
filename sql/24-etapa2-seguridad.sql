-- Señal de Gol — Etapa 2 de seguridad: cerrar la base
-- Ejecutar a mano en Supabase → SQL Editor (primero en la base de pruebas).
-- Requiere el SQL 22 (etapa 1) y el 23 (relleno de randoms).
-- Orden del despliegue: 1) este SQL, 2) la función `cuentas` nueva, 3) la página nueva. Entre 1 y 2, los usuarios
-- que todavía no pasaron al login nuevo no pueden entrar; conviene hacer los tres pasos seguidos.
--
-- Qué hace:
--   * Las contraseñas viejas pasan a `claves_viejas`, que solo lee la función `cuentas`. Cada usuario sigue entrando
--     con su contraseña de siempre; al primer ingreso se pasa a Supabase Auth y se borra de esa tabla.
--   * Borra de `usuarios` las columnas password_hash, reset_token y reset_expires y el índice duplicado.
--   * Reemplaza las políticas abiertas (`pub_all`) por reglas por tabla. Sin sesión solo se ven los torneos.
--   * El email de los usuarios solo lo ve el Admin VIP (función usuarios_admin).
--   * Los pronósticos de los demás se ven recién cuando cierra la fecha; después del cierre no se pueden cargar
--     ni cambiar.
--   * Renovar randoms: solo el Admin VIP.

begin;

-- 1. Contraseñas viejas fuera de `usuarios`
create table if not exists public.claves_viejas (
  usuario_id uuid primary key references public.usuarios(id) on delete cascade,
  password_hash text not null
);
alter table public.claves_viejas enable row level security; -- sin políticas: solo la función `cuentas` (service role)
revoke all on public.claves_viejas from anon, authenticated;

insert into public.claves_viejas (usuario_id, password_hash)
select id, password_hash from public.usuarios where password_hash is not null
on conflict (usuario_id) do update set password_hash = excluded.password_hash;

alter table public.usuarios drop column if exists password_hash;
alter table public.usuarios drop column if exists reset_token;
alter table public.usuarios drop column if exists reset_expires;
drop index if exists public.usuarios_email_idx; -- duplicado de usuarios_email_unique (solo existe en producción)

-- 2. Funciones auxiliares para las políticas (security definer: evitan que una política dependa de otra)
create or replace function public.es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select es_admin from usuarios where id = auth.uid()), false)
$$;

create or replace function public.es_miembro(g uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from grupo_miembros where grupo_id = g and usuario_id = auth.uid())
      or exists (select 1 from grupos where id = g and creador_id = auth.uid())
$$;

create or replace function public.es_admin_grupo(g uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from grupos where id = g and creador_id = auth.uid())
      or exists (select 1 from grupo_miembros where grupo_id = g and usuario_id = auth.uid() and is_admin)
$$;

-- Una fecha está cerrada cuando pasó su deadline. Sin deadline, sigue abierta.
create or replace function public.partido_cerrado(p uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select f.deadline <= now() from partidos pa join fechas f on f.id = pa.fecha_id where pa.id = p), false)
$$;

-- 3. Funciones que llama la página
-- Lista de usuarios con email, solo para el Admin VIP.
create or replace function public.usuarios_admin()
returns table (id uuid, nombre text, nombre_real text, email text, equipo_favorito text)
language plpgsql stable security definer set search_path = public as $$
begin
  if not es_admin() then raise exception 'Solo el Admin VIP'; end if;
  return query select u.id, u.nombre, u.nombre_real, u.email, u.equipo_favorito from usuarios u order by u.nombre;
end;
$$;

-- Apaga el cambio obligatorio de contraseña del propio usuario (la columna ya no se puede editar desde la página).
create or replace function public.clave_cambiada() returns void
language sql security definer set search_path = public as $$
  update usuarios set debe_cambiar_clave = false where id = auth.uid()
$$;

revoke execute on function public.usuarios_admin() from public, anon;
revoke execute on function public.clave_cambiada() from public, anon;
revoke execute on function public.rellenar_randoms() from public, anon;
grant execute on function public.usuarios_admin() to authenticated;
grant execute on function public.clave_cambiada() to authenticated;
grant execute on function public.rellenar_randoms() to authenticated;

-- 4. Permisos por columna en `usuarios`: nadie lee el email ni edita es_admin / debe_cambiar_clave desde la página
revoke all on public.usuarios from anon, authenticated;
grant select (id, nombre, nombre_real, equipo_favorito, created_at, es_admin, debe_cambiar_clave) on public.usuarios to authenticated;
grant update (nombre, nombre_real, equipo_favorito) on public.usuarios to authenticated;

-- 5. Fuera todas las políticas anteriores
do $$
declare p record;
begin
  for p in select tablename, policyname from pg_policies
           where schemaname = 'public'
             and tablename in ('autos_usados','chat_lecturas','comentarios','fechas','grupo_miembros','grupos',
                               'partidos','pronosticos','reglamento','temporadas','torneos','usuarios')
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- 6. Políticas nuevas
-- usuarios: todos ven los datos públicos (las columnas de arriba); cada uno edita el suyo.
create policy usuarios_ver on public.usuarios for select to authenticated using (true);
create policy usuarios_editar on public.usuarios for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- torneos: se ven sin sesión (la portada los carga); solo el VIP los cambia.
create policy torneos_ver on public.torneos for select to anon, authenticated using (true);
create policy torneos_vip_crear on public.torneos for insert to authenticated with check (es_admin());
create policy torneos_vip_editar on public.torneos for update to authenticated using (es_admin()) with check (es_admin());
create policy torneos_vip_borrar on public.torneos for delete to authenticated using (es_admin());

-- fechas, partidos, temporadas, reglamento: lectura con sesión; escritura solo VIP.
do $$
declare t text;
begin
  foreach t in array array['fechas','partidos','temporadas','reglamento'] loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t||'_ver', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (es_admin())', t||'_vip_crear', t);
    execute format('create policy %I on public.%I for update to authenticated using (es_admin()) with check (es_admin())', t||'_vip_editar', t);
    execute format('create policy %I on public.%I for delete to authenticated using (es_admin())', t||'_vip_borrar', t);
  end loop;
end $$;

-- pronosticos: los propios siempre; los ajenos cuando cerró la fecha. Se cargan y cambian solo antes del cierre.
create policy pronosticos_ver on public.pronosticos for select to authenticated
  using (usuario_id = auth.uid() or es_admin() or partido_cerrado(partido_id));
create policy pronosticos_crear on public.pronosticos for insert to authenticated
  with check (usuario_id = auth.uid() and not partido_cerrado(partido_id));
create policy pronosticos_editar on public.pronosticos for update to authenticated
  using (usuario_id = auth.uid() and not partido_cerrado(partido_id))
  with check (usuario_id = auth.uid() and not partido_cerrado(partido_id));
create policy pronosticos_vip_borrar on public.pronosticos for delete to authenticated using (es_admin());

-- autos_usados: se ven; los carga la función rellenar_randoms; solo el VIP los renueva (borra).
create policy autos_ver on public.autos_usados for select to authenticated using (true);
create policy autos_vip_renovar on public.autos_usados for delete to authenticated using (es_admin());

-- grupos: cualquiera con sesión crea el suyo; lo borra su creador o el VIP.
create policy grupos_ver on public.grupos for select to authenticated using (true);
create policy grupos_crear on public.grupos for insert to authenticated with check (creador_id = auth.uid());
create policy grupos_borrar on public.grupos for delete to authenticated using (creador_id = auth.uid() or es_admin());

-- grupo_miembros: cada uno se suma a sí mismo (como admin solo en su propio grupo); se va solo,
-- lo saca el admin del grupo o el VIP.
create policy miembros_ver on public.grupo_miembros for select to authenticated using (true);
create policy miembros_sumarse on public.grupo_miembros for insert to authenticated
  with check (usuario_id = auth.uid()
              and (not coalesce(is_admin, false)
                   or exists (select 1 from public.grupos g where g.id = grupo_id and g.creador_id = auth.uid())));
create policy miembros_salir on public.grupo_miembros for delete to authenticated
  using (usuario_id = auth.uid() or es_admin_grupo(grupo_id) or es_admin());

-- comentarios: el chat general lo ven todos; el de un grupo, sus miembros y el VIP.
-- Cada uno escribe con su usuario; el VIP escribe sin usuario (así lo hace la página).
create policy comentarios_ver on public.comentarios for select to authenticated
  using (grupo_id is null or es_miembro(grupo_id) or es_admin());
create policy comentarios_crear on public.comentarios for insert to authenticated
  with check ((usuario_id = auth.uid() or (usuario_id is null and es_admin()))
              and (grupo_id is null or es_miembro(grupo_id) or es_admin()));

-- chat_lecturas: cada uno las suyas.
create policy lecturas_propias on public.chat_lecturas for all to authenticated
  using (usuario_id = auth.uid()) with check (usuario_id = auth.uid());

-- 7. Sin sesión no se toca nada salvo leer torneos
revoke all on public.autos_usados, public.chat_lecturas, public.comentarios, public.fechas, public.grupo_miembros,
              public.grupos, public.partidos, public.pronosticos, public.reglamento, public.temporadas
  from anon;
revoke insert, update, delete on public.torneos from anon;

commit;

-- Verificación
select tablename, policyname, cmd, roles from pg_policies where schemaname = 'public' order by tablename, policyname;
select count(*) as claves_viejas from public.claves_viejas;
