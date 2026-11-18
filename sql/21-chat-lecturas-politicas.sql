-- Señal de Gol — Políticas de chat_lecturas (ejecutado en Supabase el 2026-11-18)
-- La tabla tenía RLS activado sin políticas: nadie podía leer ni guardar lecturas.
create policy "chat_lecturas leer" on public.chat_lecturas
  for select to anon, authenticated using (true);
create policy "chat_lecturas crear" on public.chat_lecturas
  for insert to anon, authenticated with check (true);
create policy "chat_lecturas actualizar" on public.chat_lecturas
  for update to anon, authenticated using (true) with check (true);
