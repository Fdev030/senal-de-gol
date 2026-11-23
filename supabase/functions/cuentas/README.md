# Función `cuentas`

## Despliegue desde el panel de Supabase

1. Ejecutá en el SQL Editor de la base correspondiente `sql/22-login-supabase-auth.sql` y después `sql/24-etapa2-seguridad.sql` (la función lee las contraseñas viejas de `claves_viejas`, que crea el 24).
2. En **Edge Functions → Deploy a new function → Via Editor**, creá `cuentas` y pegá el contenido de `index.ts`.
3. Apagá **Verify JWT**. La página usa una clave `sb_publishable_…` que no es un JWT; la función maneja OPTIONS/CORS y valida cada acción.
4. En **Edge Functions → Secrets**, cargá:
   - `EMAILJS_SERVICE_ID=service_qol3bpd`
   - `EMAILJS_TEMPLATE_RECUPERO=template_rqic4mv`
   - `EMAILJS_PUBLIC_KEY=VIkcUpC35DekkWCz0`
   - `EMAILJS_PRIVATE_KEY`: la misma Private Key configurada para `aviso-chat`.
   - `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY`: suelen estar disponibles como secretos del sistema en Edge Functions. Si `SUPABASE_SERVICE_ROLE_KEY` no aparece en el entorno, copiá la clave `service_role` desde **Project Settings → API Keys** (o la clave secreta equivalente en el panel de claves nuevas) y cargala como secreto. Nunca la pongas en la página.
5. En **Authentication → Sign In / Providers**, desactivá **Allow new users to sign up**. La función crea las cuentas. Dejá la longitud mínima de contraseña en 6.

No se envían mensajes a la dirección interna de Auth; la recuperación se envía al correo de contacto guardado en `usuarios.email`. No ejecutar contra producción hasta completar las pruebas acordadas.
