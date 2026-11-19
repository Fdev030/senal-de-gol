-- Etapa 1 de migración a Supabase Auth. Ejecutar manualmente en SQL Editor.
BEGIN;

ALTER TABLE public.usuarios
  ADD COLUMN IF NOT EXISTS es_admin boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS debe_cambiar_clave boolean NOT NULL DEFAULT false;

UPDATE public.usuarios
SET es_admin = true, debe_cambiar_clave = true
WHERE id = '00000000-0000-0000-0000-000000000001';

CREATE TABLE IF NOT EXISTS public.recuperaciones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expira timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.recuperaciones ENABLE ROW LEVEL SECURITY;
-- Sin políticas: la tabla solo se usa desde la Edge Function con service role.
-- password_hash, reset_token y reset_expires se conservan hasta la etapa 2.

COMMIT;
