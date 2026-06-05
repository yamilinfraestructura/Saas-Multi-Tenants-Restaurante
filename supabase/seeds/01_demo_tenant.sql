-- Seed: Tenant demo #1 para pruebas (menú QR, admin, POS)
-- Ejecutar en Supabase SQL Editor cuando la tabla tenants esté vacía.
-- Idempotente: usa dominio_slug = 'demo-guri' como clave lógica.

DO $$
DECLARE
  v_tenant_id   UUID;
  v_sala_id     UUID;
  v_mesa_id     UUID;
  v_cat_comida  UUID;
  v_cat_bebida  UUID;
BEGIN
  SELECT id INTO v_tenant_id FROM tenants WHERE dominio_slug = 'demo-guri';

  IF v_tenant_id IS NULL THEN
    INSERT INTO tenants (
      nombre_negocio,
      dominio_slug,
      email_contacto,
      telefono,
      plan_actual,
      estado
    ) VALUES (
      'Restaurante Demo Guri',
      'demo-guri',
      'admin@demo-guri.com',
      '+54 11 0000-0000',
      'basico',
      'activo'
    )
    RETURNING id INTO v_tenant_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM tenant_suscripciones WHERE tenant_id = v_tenant_id AND estado = 'activa'
  ) THEN
    INSERT INTO tenant_suscripciones (
      tenant_id,
      plan_nombre,
      monto,
      moneda,
      fecha_fin,
      estado
    ) VALUES (
      v_tenant_id,
      'basico',
      15000.00,
      'ARS',
      NOW() + INTERVAL '365 days',
      'activa'
    );
  END IF;

  INSERT INTO configuracion_negocio (
    tenant_id,
    nombre_mostrar,
    direccion,
    telefono_contacto,
    moneda_codigo,
    zona_horaria
  ) VALUES (
    v_tenant_id,
    'Demo Guri',
    'Av. Demo 123, CABA',
    '+54 11 0000-0000',
    'ARS',
    'America/Argentina/Buenos_Aires'
  )
  ON CONFLICT (tenant_id) DO UPDATE SET
    nombre_mostrar = EXCLUDED.nombre_mostrar;

  INSERT INTO reservas_config (tenant_id, mensaje_confirmacion)
  VALUES (v_tenant_id, '¡Tu reserva ha sido confirmada! Te esperamos.')
  ON CONFLICT (tenant_id) DO NOTHING;

  SELECT id INTO v_sala_id
  FROM salas
  WHERE tenant_id = v_tenant_id AND nombre_sala = 'Salón principal';

  IF v_sala_id IS NULL THEN
    INSERT INTO salas (tenant_id, nombre_sala, numero_posicion, estado_sala)
    VALUES (v_tenant_id, 'Salón principal', 1, 'activa')
    RETURNING id INTO v_sala_id;
  END IF;

  SELECT id INTO v_mesa_id
  FROM mesas
  WHERE tenant_id = v_tenant_id AND sala_id = v_sala_id AND valor_mesa = '1';

  IF v_mesa_id IS NULL THEN
    INSERT INTO mesas (tenant_id, sala_id, valor_mesa, estado)
    VALUES (v_tenant_id, v_sala_id, '1', 'activa')
    RETURNING id INTO v_mesa_id;
  END IF;

  SELECT id INTO v_cat_comida
  FROM categorias
  WHERE tenant_id = v_tenant_id AND nombre_categoria = 'Platos principales';

  IF v_cat_comida IS NULL THEN
    INSERT INTO categorias (
      tenant_id, nombre_categoria, posicion, status, tipo, emoji
    ) VALUES (
      v_tenant_id, 'Platos principales', 1, 'activo', 'comida', '🍽️'
    )
    RETURNING id INTO v_cat_comida;
  END IF;

  SELECT id INTO v_cat_bebida
  FROM categorias
  WHERE tenant_id = v_tenant_id AND nombre_categoria = 'Bebidas';

  IF v_cat_bebida IS NULL THEN
    INSERT INTO categorias (
      tenant_id, nombre_categoria, posicion, status, tipo, emoji
    ) VALUES (
      v_tenant_id, 'Bebidas', 2, 'activo', 'bebida', '🥤'
    )
    RETURNING id INTO v_cat_bebida;
  END IF;

  INSERT INTO productos (tenant_id, nombre, precio, tipo, categoria_id, estado, stock)
  SELECT v_tenant_id, 'Hamburguesa clásica', 8500.00, 'comida', v_cat_comida, 'activo', 50
  WHERE NOT EXISTS (
    SELECT 1 FROM productos
    WHERE tenant_id = v_tenant_id AND nombre = 'Hamburguesa clásica'
  );

  INSERT INTO productos (tenant_id, nombre, precio, tipo, categoria_id, estado, stock)
  SELECT v_tenant_id, 'Pizza muzzarella', 7200.00, 'comida', v_cat_comida, 'activo', 40
  WHERE NOT EXISTS (
    SELECT 1 FROM productos
    WHERE tenant_id = v_tenant_id AND nombre = 'Pizza muzzarella'
  );

  INSERT INTO productos (tenant_id, nombre, precio, tipo, categoria_id, estado, stock)
  SELECT v_tenant_id, 'Coca-Cola 500ml', 2500.00, 'bebida', v_cat_bebida, 'activo', 100
  WHERE NOT EXISTS (
    SELECT 1 FROM productos
    WHERE tenant_id = v_tenant_id AND nombre = 'Coca-Cola 500ml'
  );

  RAISE NOTICE 'Tenant demo listo. slug=demo-guri tenant_id=% mesa_id=%',
    v_tenant_id, v_mesa_id;
END $$;

-- Verificación
SELECT id, nombre_negocio, dominio_slug, estado FROM tenants;

SELECT public.get_public_menu('demo-guri');

SELECT m.id AS mesa_id, m.valor_mesa, s.nombre_sala
FROM mesas m
JOIN salas s ON s.id = m.sala_id
JOIN tenants t ON t.id = m.tenant_id
WHERE t.dominio_slug = 'demo-guri';
