begin;
-- Estructura completa de la base de Señal de Gol (esquema public, sin datos).
-- Exportada de producción el 2026-11-19 con sql/exportar-esquema.sql.
-- Uso: proyecto de Supabase NUEVO y vacío → SQL Editor → pegar todo → Run (si avisa de RLS: "Run without RLS";
-- el RLS se activa más abajo en este mismo script).
-- Las extensiones de producción (pgcrypto, uuid-ossp, etc.) ya vienen en todo proyecto nuevo; gen_random_uuid() es
-- nativa de Postgres. No incluye el Database Webhook del chat (ver supabase/functions/aviso-chat/README.md).
-- Las políticas son las mismas de producción: abiertas para anon (ver docs/pendientes.md, seguridad).


-- Tablas
create table public.autos_usados (
  id uuid default gen_random_uuid() not null,
  usuario_id uuid,
  torneo_clave text not null,
  fecha_numero integer not null
);
create table public.chat_lecturas (
  id uuid default gen_random_uuid() not null,
  usuario_id uuid not null,
  chat_key text not null,
  last_read_at timestamp with time zone default now() not null,
  read_count integer default 0 not null
);
create table public.comentarios (
  id uuid default gen_random_uuid() not null,
  usuario_id uuid,
  torneo_clave text,
  grupo_id uuid,
  texto text not null,
  created_at timestamp with time zone default now(),
  reply_to text
);
create table public.fechas (
  id uuid default gen_random_uuid() not null,
  torneo_id uuid,
  numero integer not null,
  deadline timestamp with time zone,
  created_at timestamp with time zone default now()
);
create table public.grupo_miembros (
  id uuid default gen_random_uuid() not null,
  grupo_id uuid,
  usuario_id uuid,
  joined_at timestamp with time zone default now(),
  is_admin boolean default false
);
create table public.grupos (
  id uuid default gen_random_uuid() not null,
  nombre text not null,
  descripcion text,
  codigo text not null,
  creador_id uuid,
  created_at timestamp with time zone default now()
);
create table public.partidos (
  id uuid default gen_random_uuid() not null,
  fecha_id uuid,
  posicion integer default 0,
  equipo_local text not null,
  equipo_visitante text not null,
  goles_local integer,
  goles_visitante integer,
  created_at timestamp with time zone default now(),
  horario timestamp with time zone
);
create table public.pronosticos (
  id uuid default gen_random_uuid() not null,
  usuario_id uuid,
  partido_id uuid,
  torneo_clave text not null,
  goles_local integer not null,
  goles_visitante integer not null,
  es_auto boolean default false,
  es_blanco boolean default false,
  created_at timestamp with time zone default now()
);
create table public.reglamento (
  id uuid default gen_random_uuid() not null,
  contenido text default ''::text not null,
  updated_at timestamp with time zone default now(),
  updated_by text default ''::text
);
create table public.temporadas (
  id uuid default gen_random_uuid() not null,
  nombre text not null,
  torneo_id uuid,
  primer_id uuid,
  segundo_id uuid,
  tercer_id uuid,
  primer_pts integer default 0,
  segundo_pts integer default 0,
  tercer_pts integer default 0,
  created_at timestamp with time zone default now(),
  anio integer,
  grupo_id uuid
);
create table public.torneos (
  id uuid default gen_random_uuid() not null,
  clave text not null,
  nombre text not null,
  icono text default '⚽'::text,
  total_fechas integer default 14,
  label_fecha text default 'Fecha'::text,
  orden integer default 0,
  created_at timestamp with time zone default now(),
  visible boolean default true not null
);
create table public.usuarios (
  id uuid default gen_random_uuid() not null,
  nombre text not null,
  created_at timestamp with time zone default now(),
  password_hash text,
  equipo_favorito text,
  email text default ''::text,
  nombre_real text default ''::text,
  reset_token text,
  reset_expires timestamp with time zone
);

-- Claves primarias y únicas
alter table public.autos_usados add constraint autos_usados_pkey PRIMARY KEY (id);
alter table public.autos_usados add constraint autos_usados_usuario_torneo_fecha_key UNIQUE (usuario_id, torneo_clave, fecha_numero);
alter table public.chat_lecturas add constraint chat_lecturas_pkey PRIMARY KEY (id);
alter table public.chat_lecturas add constraint chat_lecturas_usuario_id_chat_key_key UNIQUE (usuario_id, chat_key);
alter table public.comentarios add constraint comentarios_pkey PRIMARY KEY (id);
alter table public.fechas add constraint fechas_pkey PRIMARY KEY (id);
alter table public.fechas add constraint fechas_torneo_id_numero_key UNIQUE (torneo_id, numero);
alter table public.grupo_miembros add constraint grupo_miembros_grupo_id_usuario_id_key UNIQUE (grupo_id, usuario_id);
alter table public.grupo_miembros add constraint grupo_miembros_pkey PRIMARY KEY (id);
alter table public.grupos add constraint grupos_pkey PRIMARY KEY (id);
alter table public.partidos add constraint partidos_pkey PRIMARY KEY (id);
alter table public.pronosticos add constraint pronosticos_pkey PRIMARY KEY (id);
alter table public.pronosticos add constraint pronosticos_usuario_id_partido_id_key UNIQUE (usuario_id, partido_id);
alter table public.reglamento add constraint reglamento_pkey PRIMARY KEY (id);
alter table public.temporadas add constraint temporadas_pkey PRIMARY KEY (id);
alter table public.torneos add constraint torneos_clave_key UNIQUE (clave);
alter table public.torneos add constraint torneos_pkey PRIMARY KEY (id);
alter table public.usuarios add constraint usuarios_nombre_key UNIQUE (nombre);
alter table public.usuarios add constraint usuarios_pkey PRIMARY KEY (id);

-- Claves foráneas
alter table public.autos_usados add constraint autos_usados_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;
alter table public.chat_lecturas add constraint chat_lecturas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;
alter table public.comentarios add constraint comentarios_grupo_id_fkey FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE;
alter table public.comentarios add constraint comentarios_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;
alter table public.fechas add constraint fechas_torneo_id_fkey FOREIGN KEY (torneo_id) REFERENCES torneos(id) ON DELETE CASCADE;
alter table public.grupo_miembros add constraint grupo_miembros_grupo_id_fkey FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE CASCADE;
alter table public.grupo_miembros add constraint grupo_miembros_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;
alter table public.grupos add constraint grupos_creador_id_fkey FOREIGN KEY (creador_id) REFERENCES usuarios(id);
alter table public.partidos add constraint partidos_fecha_id_fkey FOREIGN KEY (fecha_id) REFERENCES fechas(id) ON DELETE CASCADE;
alter table public.pronosticos add constraint pronosticos_partido_id_fkey FOREIGN KEY (partido_id) REFERENCES partidos(id) ON DELETE CASCADE;
alter table public.pronosticos add constraint pronosticos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE;
alter table public.temporadas add constraint temporadas_grupo_id_fkey FOREIGN KEY (grupo_id) REFERENCES grupos(id) ON DELETE SET NULL;
alter table public.temporadas add constraint temporadas_primer_id_fkey FOREIGN KEY (primer_id) REFERENCES usuarios(id);
alter table public.temporadas add constraint temporadas_segundo_id_fkey FOREIGN KEY (segundo_id) REFERENCES usuarios(id);
alter table public.temporadas add constraint temporadas_tercer_id_fkey FOREIGN KEY (tercer_id) REFERENCES usuarios(id);
alter table public.temporadas add constraint temporadas_torneo_id_fkey FOREIGN KEY (torneo_id) REFERENCES torneos(id);

-- Índices
-- En producción hay además usuarios_email_idx, idéntico a este (duplicado).
CREATE UNIQUE INDEX usuarios_email_unique ON public.usuarios USING btree (email) WHERE (email <> ''::text);

-- Row Level Security
alter table public.autos_usados enable row level security;
alter table public.chat_lecturas enable row level security;
alter table public.comentarios enable row level security;
alter table public.fechas enable row level security;
alter table public.grupo_miembros enable row level security;
alter table public.grupos enable row level security;
alter table public.partidos enable row level security;
alter table public.pronosticos enable row level security;
alter table public.reglamento enable row level security;
alter table public.temporadas enable row level security;
alter table public.torneos enable row level security;
alter table public.usuarios enable row level security;

-- Políticas
create policy pub_all on public.autos_usados as PERMISSIVE for ALL to public using (true) with check (true);
create policy "chat_lecturas actualizar" on public.chat_lecturas as PERMISSIVE for UPDATE to anon, authenticated using (true) with check (true);
create policy "chat_lecturas crear" on public.chat_lecturas as PERMISSIVE for INSERT to anon, authenticated with check (true);
create policy "chat_lecturas leer" on public.chat_lecturas as PERMISSIVE for SELECT to anon, authenticated using (true);
create policy pub_all on public.comentarios as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.fechas as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.grupo_miembros as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.grupos as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.partidos as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.pronosticos as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.reglamento as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.temporadas as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.torneos as PERMISSIVE for ALL to public using (true) with check (true);
create policy pub_all on public.usuarios as PERMISSIVE for ALL to public using (true) with check (true);

commit;
