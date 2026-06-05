-- Seed: Usuario admin de prueba para tenant demo-guri
-- Ejecutar DESPUÉS de supabase/seeds/01_demo_tenant.sql
--
-- Credenciales de login:
--   Email:    admin@demo-guri.com
--   Password: DemoGuri2026!
--
-- Requiere extensión pgcrypto (habitual en Supabase hosted).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_tenant_id UUID;
  v_user_id   UUID := 'b1000000-0000-4000-8000-000000000001';
  v_email     TEXT := 'admin@demo-guri.com';
  v_password  TEXT := 'DemoGuri2026!';
  v_nombre    TEXT := 'Admin Demo';
BEGIN
  SELECT id INTO v_tenant_id
  FROM tenants
  WHERE dominio_slug = 'demo-guri';

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Tenant demo-guri no encontrado. Ejecutá 01_demo_tenant.sql primero.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = v_user_id) THEN
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      confirmation_token,
      recovery_token,
      email_change,
      email_change_token_new,
      email_change_token_current,
      reauthentication_token,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      is_sso_user
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      crypt(v_password, gen_salt('bf')),
      NOW(),
      '',
      '',
      '',
      '',
      '',
      '',
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', v_nombre),
      NOW(),
      NOW(),
      FALSE
    );
  ELSE
    UPDATE auth.users
    SET
      email = v_email,
      encrypted_password = crypt(v_password, gen_salt('bf')),
      email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
      confirmation_token = COALESCE(confirmation_token, ''),
      recovery_token = COALESCE(recovery_token, ''),
      email_change = COALESCE(email_change, ''),
      email_change_token_new = COALESCE(email_change_token_new, ''),
      email_change_token_current = COALESCE(email_change_token_current, ''),
      reauthentication_token = COALESCE(reauthentication_token, ''),
      updated_at = NOW()
    WHERE id = v_user_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM auth.identities
    WHERE user_id = v_user_id AND provider = 'email'
  ) THEN
    INSERT INTO auth.identities (
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      v_user_id::text,
      v_user_id,
      jsonb_build_object(
        'sub', v_user_id::text,
        'email', v_email,
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      NOW(),
      NOW(),
      NOW()
    );
  END IF;

  PERFORM public.inicializar_tenant(
    v_tenant_id,
    v_user_id::text,
    v_nombre,
    v_email
  );

  RAISE NOTICE 'Admin demo listo → % / %', v_email, v_password;
END $$;

-- Verificación: usuario operativo + rol admin
SELECT
  u.id,
  u.user_name,
  u.email,
  r.nivel AS rol,
  t.dominio_slug,
  t.estado AS tenant_estado
FROM usuarios u
JOIN roles_sistema r ON r.id = u.rol_id
JOIN tenants t ON t.id = u.tenant_id
WHERE u.email = 'admin@demo-guri.com';

-- URL menú QR (reemplazá sala_id si hace falta)
SELECT
  t.dominio_slug,
  s.id AS sala_id,
  m.id AS mesa_id,
  '/menu/' || t.dominio_slug || '/' || s.id || '/' || m.id AS ruta_menu_qr
FROM tenants t
JOIN mesas m ON m.tenant_id = t.id
JOIN salas s ON s.id = m.sala_id
WHERE t.dominio_slug = 'demo-guri'
  AND m.valor_mesa = '1';
