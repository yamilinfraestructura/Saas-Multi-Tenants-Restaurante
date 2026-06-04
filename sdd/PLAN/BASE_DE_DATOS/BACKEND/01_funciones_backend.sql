-- ============================================================
-- BACKEND 01: AUTH HOOKS Y FUNCIONES DE SUPABASE
-- Descripción: Funciones PostgreSQL que se ejecutan durante
--              el ciclo de autenticación y operaciones críticas.
--
--   01. Hook JWT: Inyecta tenant_id y nivel_acceso en el token
--       para que las políticas RLS puedan leerlo.
--   02. Verificación de permisos granulares (para el frontend)
--   03. Auto-configuración inicial del tenant (onboarding)
--   04. Funciones de reportes y analytics (evitan cálculos en Flutter)
--
-- Autor: SaasSystemGuri
-- ============================================================

-- ============================================================
-- 01. HOOK JWT: ENRIQUECER EL TOKEN CON DATOS DEL TENANT
--
-- Este hook se registra en Supabase Dashboard:
--   Authentication → Hooks → Custom Access Token Hook
--
-- Al hacer login, Supabase llama a esta función y agrega
-- el resultado al payload del JWT. Flutter lo recibe automáticamente
-- y las políticas RLS pueden leerlo con auth.jwt() ->> 'tenant_id'.
-- ============================================================
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  claims         JSONB;
  v_usuario      usuarios%ROWTYPE;
  v_rol          roles_sistema%ROWTYPE;
BEGIN
  -- Leer el payload actual del JWT
  claims := event -> 'claims';

  -- Buscar el usuario en la tabla usuarios
  SELECT * INTO v_usuario
  FROM usuarios
  WHERE id = (event ->> 'user_id');

  IF FOUND THEN
    -- Buscar el rol del usuario
    SELECT * INTO v_rol
    FROM roles_sistema
    WHERE id = v_usuario.rol_id;

    -- Inyectar datos del tenant y rol en el JWT
    claims := jsonb_set(claims, '{tenant_id}',    to_jsonb(v_usuario.tenant_id::TEXT));
    claims := jsonb_set(claims, '{nivel_acceso}', to_jsonb(v_rol.nivel::TEXT));
    claims := jsonb_set(claims, '{user_name}',    to_jsonb(v_usuario.user_name));
    claims := jsonb_set(claims, '{tenant_activo}', (
      SELECT to_jsonb(t.estado = 'activo')
      FROM tenants t WHERE t.id = v_usuario.tenant_id
    ));
  END IF;

  -- Retornar el evento con los claims enriquecidos
  RETURN jsonb_set(event, '{claims}', claims);
END;
$$;

-- ============================================================
-- 02. FUNCIÓN: VERIFICAR ACCESO COMPLETO DE UN USUARIO
--
-- Retorna un JSONB con toda la información de acceso del usuario:
-- - Datos del rol de sistema
-- - Lista de módulos accesibles (filtrados por nivel mínimo)
-- - Lista de permisos activos (asignaciones)
--
-- Esta función es llamada desde Flutter al iniciar sesión
-- para construir el menú dinámico de la app.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_acceso_usuario(p_usuario_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_usuario     usuarios%ROWTYPE;
  v_rol         roles_sistema%ROWTYPE;
  v_tenant      tenants%ROWTYPE;
  v_modulos     JSONB;
  v_permisos    JSONB;
  resultado     JSONB;
BEGIN
  -- Obtener usuario y validar que pertenezca al tenant del llamador
  SELECT * INTO v_usuario FROM usuarios
  WHERE id = p_usuario_id
    AND tenant_id = auth.get_tenant_id();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Usuario no encontrado en este tenant.');
  END IF;

  -- Obtener rol
  SELECT * INTO v_rol FROM roles_sistema WHERE id = v_usuario.rol_id;

  -- Obtener tenant
  SELECT * INTO v_tenant FROM tenants WHERE id = v_usuario.tenant_id;

  -- Verificar que el tenant esté activo
  IF v_tenant.estado = 'suspendido' THEN
    RETURN jsonb_build_object('error', 'Tenant suspendido. Contacte al administrador del SaaS.');
  END IF;

  -- Obtener módulos accesibles según el nivel del rol
  SELECT jsonb_agg(
    jsonb_build_object(
      'id',          m.id,
      'codigo',      m.codigo,
      'nombre',      m.nombre,
      'icono',       m.icono,
      'categoria',   m.categoria,
      'orden',       m.orden
    )
  ) INTO v_modulos
  FROM modulos m
  WHERE m.activo_globalmente = TRUE
    AND public.nivel_orden(m.nivel_minimo_requerido) <= public.nivel_orden(v_rol.nivel);

  -- Obtener permisos activos del usuario (asignaciones)
  SELECT jsonb_agg(pm.codigo) INTO v_permisos
  FROM asignaciones a
  JOIN permisos_modulo pm ON a.permiso_modulo_id = pm.id
  WHERE a.usuario_id   = p_usuario_id
    AND a.tenant_id    = v_usuario.tenant_id
    AND a.activo       = TRUE
    AND (a.fecha_expiracion IS NULL OR a.fecha_expiracion > NOW());

  -- Construir respuesta completa
  resultado := jsonb_build_object(
    'usuario', jsonb_build_object(
      'id',        v_usuario.id,
      'nombre',    v_usuario.user_name,
      'email',     v_usuario.email,
      'img',       v_usuario.user_img
    ),
    'tenant', jsonb_build_object(
      'id',       v_tenant.id,
      'nombre',   v_tenant.nombre_negocio,
      'slug',     v_tenant.dominio_slug,
      'plan',     v_tenant.plan_actual,
      'estado',   v_tenant.estado
    ),
    'rol', jsonb_build_object(
      'nivel',       v_rol.nivel,
      'label',       v_rol.label,
      'descripcion', v_rol.descripcion
    ),
    'modulos_accesibles', COALESCE(v_modulos, '[]'::JSONB),
    'permisos_activos',   COALESCE(v_permisos, '[]'::JSONB)
  );

  RETURN resultado;
END;
$$;

-- Helper: Convierte nivel a número para comparación
CREATE OR REPLACE FUNCTION public.nivel_orden(nivel nivel_acceso_sistema)
RETURNS INTEGER AS $$
  SELECT CASE nivel
    WHEN 'superadmin' THEN 100
    WHEN 'admin'      THEN 80
    WHEN 'supervisor' THEN 60
    WHEN 'cocina'     THEN 40
    WHEN 'bar'        THEN 35
    WHEN 'mozo'       THEN 30
    WHEN 'general'    THEN 10
    ELSE 0
  END;
$$ LANGUAGE SQL IMMUTABLE;

-- ============================================================
-- 03. FUNCIÓN: ONBOARDING - INICIALIZAR NUEVO TENANT
--
-- Se llama una sola vez cuando se registra un nuevo restaurante.
-- Crea las configuraciones por defecto y el primer usuario admin.
-- ============================================================
CREATE OR REPLACE FUNCTION public.inicializar_tenant(
  p_tenant_id        UUID,
  p_admin_user_id    TEXT,
  p_admin_nombre     VARCHAR,
  p_admin_email      VARCHAR
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rol_admin_id UUID;
BEGIN
  -- Obtener el ID del rol admin global
  SELECT id INTO v_rol_admin_id
  FROM roles_sistema
  WHERE nivel = 'admin' AND tenant_id IS NULL;

  -- Crear el usuario administrador
  INSERT INTO usuarios (id, tenant_id, user_name, email, rol_id)
  VALUES (p_admin_user_id, p_tenant_id, p_admin_nombre, p_admin_email, v_rol_admin_id)
  ON CONFLICT (id) DO NOTHING;

  -- Crear configuración de negocio por defecto
  INSERT INTO configuracion_negocio (tenant_id, moneda_codigo, zona_horaria)
  VALUES (p_tenant_id, 'ARS', 'America/Argentina/Buenos_Aires')
  ON CONFLICT (tenant_id) DO NOTHING;

  -- Crear configuración de reservas por defecto
  INSERT INTO reservas_config (tenant_id, mensaje_confirmacion)
  VALUES (p_tenant_id, '¡Tu reserva ha sido confirmada! Te esperamos.')
  ON CONFLICT (tenant_id) DO NOTHING;

  -- Asignar TODOS los permisos al admin inicial del tenant
  INSERT INTO asignaciones (tenant_id, usuario_id, permiso_modulo_id, asignado_por_id)
  SELECT p_tenant_id, p_admin_user_id, pm.id, p_admin_user_id
  FROM permisos_modulo pm
  JOIN modulos m ON pm.modulo_id = m.id
  WHERE m.codigo <> 'SAAS_BILLING' -- El admin del tenant no gestiona la facturación del SaaS
  ON CONFLICT (tenant_id, usuario_id, permiso_modulo_id) DO NOTHING;

  RAISE NOTICE 'Tenant % inicializado correctamente.', p_tenant_id;
END;
$$;

-- ============================================================
-- 04. FUNCIÓN: REPORTES - RESUMEN DE VENTAS DEL DÍA
--
-- Ejecutada desde Flutter para obtener los KPIs diarios.
-- El RLS garantiza que solo retorne datos del tenant del usuario.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_resumen_ventas(
  p_fecha_desde TIMESTAMPTZ,
  p_fecha_hasta TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE resultado JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_pedidos',       COUNT(id),
    'total_ventas',        COALESCE(SUM(total), 0),
    'ticket_promedio',     COALESCE(AVG(total), 0),
    'pedidos_cobrados',    COUNT(CASE WHEN cobro_pago = 'Cobrado' THEN 1 END),
    'pedidos_cerrados',    COUNT(CASE WHEN cobro_pago = 'Cobrado_Cerrado' THEN 1 END),
    'tasa_cobro_pct',      ROUND(
                             (COUNT(CASE WHEN cobro_pago != 'Sin Cobrar' THEN 1 END)::NUMERIC
                             / NULLIF(COUNT(id), 0)) * 100, 2
                           )
  ) INTO resultado
  FROM pedidos
  WHERE tenant_id   = auth.get_tenant_id()
    AND fecha_creacion BETWEEN p_fecha_desde AND p_fecha_hasta;

  RETURN resultado;
END;
$$;

-- ============================================================
-- 05. FUNCIÓN: REPORTES - TOP PRODUCTOS VENDIDOS
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_top_productos(
  p_fecha_desde TIMESTAMPTZ,
  p_fecha_hasta TIMESTAMPTZ,
  p_limite      INTEGER DEFAULT 10
)
RETURNS TABLE (
  nombre_item      TEXT,
  tipo             tipo_producto,
  cantidad_vendida BIGINT,
  ingresos         NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pi.nombre_item::TEXT,
    pr.tipo,
    SUM(pi.cantidad)::BIGINT                         AS cantidad_vendida,
    SUM(pi.cantidad * pi.precio_unitario)::NUMERIC   AS ingresos
  FROM pedido_items pi
  JOIN pedidos ped ON pi.pedido_id = ped.id
  LEFT JOIN productos pr ON pi.producto_id = pr.id
  WHERE ped.tenant_id    = auth.get_tenant_id()
    AND ped.fecha_creacion BETWEEN p_fecha_desde AND p_fecha_hasta
    AND ped.cobro_pago   <> 'Sin Cobrar'
  GROUP BY pi.nombre_item, pr.tipo
  ORDER BY cantidad_vendida DESC
  LIMIT p_limite;
END;
$$;

-- ============================================================
-- 06. TRIGGER: ACTUALIZAR updated_at AUTOMÁTICAMENTE
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_productos_updated_at
  BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_categorias_updated_at
  BEFORE UPDATE ON categorias
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
