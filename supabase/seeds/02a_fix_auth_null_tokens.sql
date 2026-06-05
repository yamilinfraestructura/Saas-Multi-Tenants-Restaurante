-- Fix: usuarios creados manualmente en auth.users con tokens NULL
-- provocan HTTP 500 "Database error querying schema" al hacer login.
-- Ejecutar en SQL Editor si el login falla después de 02_demo_admin_user.sql.
-- Nota: confirmed_at es columna generada; no se puede (ni hay que) actualizar.

UPDATE auth.users
SET
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change = COALESCE(email_change, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  reauthentication_token = COALESCE(reauthentication_token, ''),
  email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change IS NULL
   OR email_change_token_new IS NULL
   OR email_change_token_current IS NULL
   OR reauthentication_token IS NULL
   OR email_confirmed_at IS NULL;
