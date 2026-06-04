-- ============================================================
-- RLS 01: POLÍTICAS DE ROW LEVEL SECURITY
-- Descripción: Implementa el aislamiento multi-tenant a nivel
--              de base de datos mediante RLS de Supabase/PostgreSQL.
--
-- FUNDAMENTO TÉCNICO:
--   Supabase almacena el tenant_id en el JWT del usuario autenticado
--   como un claim personalizado. La función auth.jwt() permite leerlo
--   directamente en las políticas SQL sin necesidad de una query extra.
--
--   El claim se inyecta en el JWT durante el proceso de login mediante
--   una función PostgreSQL hook (ver BACKEND/01_auth_hooks.sql).
--
-- NIVELES DE PROTECCIÓN:
--   1. RLS Tenant: Ningún usuario ve datos de otro restaurante.
--   2. RLS Rol:    Filtra adicionalmente por nivel de rol del usuario.
--   3. Supabase Auth: Solo usuarios autenticados acceden a la API.
--
-- IMPORTANTE: Las políticas RLS son el ÚLTIMO firewall de seguridad.
--             No reemplazan la validación en la capa de aplicación Flutter,
--             pero garantizan que aunque el código falle, los datos estén protegidos.
--
-- Autor: SaasSystemGuri
-- ============================================================

-- ============================================================
-- HELPERS: Funciones auxiliares para las políticas
-- ============================================================

-- Retorna el tenant_id del usuario autenticado desde el JWT
CREATE OR REPLACE FUNCTION auth.get_tenant_id()
RETURNS UUID AS $$
  SELECT (auth.jwt() ->> 'tenant_id')::UUID;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Retorna el nivel del rol del usuario autenticado desde el JWT
CREATE OR REPLACE FUNCTION auth.get_user_nivel()
RETURNS TEXT AS $$
  SELECT auth.jwt() ->> 'nivel_acceso';
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- Verifica si el usuario tiene un nivel de acceso mínimo
CREATE OR REPLACE FUNCTION auth.tiene_nivel_minimo(nivel_requerido nivel_acceso_sistema)
RETURNS BOOLEAN AS $$
DECLARE
  orden_requerido INT;
  orden_actual    INT;
  nivel_usuario   TEXT;
BEGIN
  nivel_usuario := auth.get_user_nivel();
  
  -- Tabla de jerarquía de roles (mayor = más privilegio)
  orden_requerido := CASE nivel_requerido
    WHEN 'superadmin'  THEN 100
    WHEN 'admin'       THEN 80
    WHEN 'supervisor'  THEN 60
    WHEN 'cocina'      THEN 40
    WHEN 'bar'         THEN 35
    WHEN 'mozo'        THEN 30
    WHEN 'general'     THEN 10
    ELSE 0
  END;
  
  orden_actual := CASE nivel_usuario
    WHEN 'superadmin'  THEN 100
    WHEN 'admin'       THEN 80
    WHEN 'supervisor'  THEN 60
    WHEN 'cocina'      THEN 40
    WHEN 'bar'         THEN 35
    WHEN 'mozo'        THEN 30
    WHEN 'general'     THEN 10
    ELSE 0
  END;
  
  RETURN orden_actual >= orden_requerido;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Verifica si el usuario tiene una asignación activa para un permiso específico
CREATE OR REPLACE FUNCTION auth.tiene_permiso(codigo_permiso TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM asignaciones a
    JOIN permisos_modulo pm ON a.permiso_modulo_id = pm.id
    WHERE a.usuario_id    = auth.uid()::TEXT
      AND a.tenant_id     = auth.get_tenant_id()
      AND pm.codigo       = codigo_permiso
      AND a.activo        = TRUE
      AND (a.fecha_expiracion IS NULL OR a.fecha_expiracion > NOW())
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

-- ============================================================
-- ACTIVAR RLS EN TODAS LAS TABLAS DEL SISTEMA
-- ============================================================
ALTER TABLE tenants                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_suscripciones              ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles_sistema                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE modulos                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE permisos_modulo                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE asignaciones                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE salas                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE mesas                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE producto_ingredientes_opcionales  ENABLE ROW LEVEL SECURITY;
ALTER TABLE producto_agregados                ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredientes                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_items                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_item_ingredientes_removidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_item_agregados             ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas_config                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE reserva_horarios_disponibles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas_calendario               ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas_calendario_horarios      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracion_negocio             ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLÍTICAS: TENANTS
-- Solo el superadmin puede ver y gestionar todos los tenants.
-- Un admin solo puede ver y editar SU propio tenant.
-- ============================================================
CREATE POLICY "tenants_select"
  ON tenants FOR SELECT
  USING (
    auth.get_user_nivel() = 'superadmin'
    OR id = auth.get_tenant_id()
  );

CREATE POLICY "tenants_update"
  ON tenants FOR UPDATE
  USING (
    auth.get_user_nivel() = 'superadmin'
    OR (id = auth.get_tenant_id() AND auth.tiene_nivel_minimo('admin'))
  );

CREATE POLICY "tenants_insert"
  ON tenants FOR INSERT
  WITH CHECK (auth.get_user_nivel() = 'superadmin');

-- ============================================================
-- POLÍTICAS: TENANT_SUSCRIPCIONES
-- Solo superadmin gestiona suscripciones.
-- Admin puede VER la suscripción de su tenant.
-- ============================================================
CREATE POLICY "suscripciones_select"
  ON tenant_suscripciones FOR SELECT
  USING (
    auth.get_user_nivel() = 'superadmin'
    OR tenant_id = auth.get_tenant_id()
  );

CREATE POLICY "suscripciones_all"
  ON tenant_suscripciones FOR ALL
  USING (auth.get_user_nivel() = 'superadmin');

-- ============================================================
-- POLÍTICAS: MÓDULOS Y PERMISOS (lectura global, escritura superadmin)
-- Los módulos son el catálogo del sistema, todos pueden verlos.
-- Solo el superadmin puede modificar el catálogo de módulos.
-- ============================================================
CREATE POLICY "modulos_select_all"
  ON modulos FOR SELECT
  USING (TRUE); -- Todos los autenticados pueden ver el catálogo

CREATE POLICY "modulos_write_superadmin"
  ON modulos FOR ALL
  USING (auth.get_user_nivel() = 'superadmin');

CREATE POLICY "permisos_modulo_select_all"
  ON permisos_modulo FOR SELECT
  USING (TRUE);

CREATE POLICY "permisos_modulo_write_superadmin"
  ON permisos_modulo FOR ALL
  USING (auth.get_user_nivel() = 'superadmin');

-- ============================================================
-- POLÍTICAS: ROLES_SISTEMA
-- Todos los autenticados pueden leer roles.
-- Solo admin puede gestionar roles de SU tenant.
-- Superadmin gestiona todo.
-- ============================================================
CREATE POLICY "roles_select"
  ON roles_sistema FOR SELECT
  USING (
    tenant_id IS NULL                           -- Roles globales del sistema
    OR tenant_id = auth.get_tenant_id()         -- Roles del propio tenant
    OR auth.get_user_nivel() = 'superadmin'
  );

CREATE POLICY "roles_write"
  ON roles_sistema FOR ALL
  USING (
    auth.get_user_nivel() = 'superadmin'
    OR (
      tenant_id = auth.get_tenant_id()
      AND auth.tiene_nivel_minimo('admin')
      AND es_sistema = FALSE  -- Solo puede editar roles NO de sistema
    )
  );

-- ============================================================
-- POLÍTICAS: ASIGNACIONES
-- Admin del tenant gestiona asignaciones de SU tenant.
-- Usuarios solo ven sus propias asignaciones.
-- ============================================================
CREATE POLICY "asignaciones_select"
  ON asignaciones FOR SELECT
  USING (
    tenant_id = auth.get_tenant_id()
    AND (
      auth.tiene_nivel_minimo('supervisor')     -- Supervisores ven todas
      OR usuario_id = auth.uid()::TEXT          -- Empleados ven las suyas
    )
  );

CREATE POLICY "asignaciones_write"
  ON asignaciones FOR ALL
  USING (
    tenant_id = auth.get_tenant_id()
    AND auth.tiene_nivel_minimo('admin')
  );

-- ============================================================
-- POLÍTICAS: USUARIOS
-- Cada usuario del tenant puede verse a sí mismo.
-- Admin puede gestionar usuarios de su tenant.
-- ============================================================
CREATE POLICY "usuarios_select"
  ON usuarios FOR SELECT
  USING (
    tenant_id = auth.get_tenant_id()
    AND (
      auth.tiene_nivel_minimo('supervisor')
      OR id = auth.uid()::TEXT
    )
  );

CREATE POLICY "usuarios_insert"
  ON usuarios FOR INSERT
  WITH CHECK (
    tenant_id = auth.get_tenant_id()
    AND auth.tiene_nivel_minimo('admin')
  );

CREATE POLICY "usuarios_update"
  ON usuarios FOR UPDATE
  USING (
    tenant_id = auth.get_tenant_id()
    AND (
      auth.tiene_nivel_minimo('admin')
      OR id = auth.uid()::TEXT   -- El propio usuario puede editar su perfil
    )
  );

CREATE POLICY "usuarios_delete"
  ON usuarios FOR DELETE
  USING (
    tenant_id = auth.get_tenant_id()
    AND auth.tiene_nivel_minimo('admin')
    AND id <> auth.uid()::TEXT   -- No puede auto-eliminarse
  );

-- ============================================================
-- POLÍTICA GENÉRICA: AISLAMIENTO POR TENANT (tablas operativas)
-- Se aplica a todas las tablas que tienen tenant_id:
-- salas, mesas, categorias, productos, ingredientes,
-- pedidos, reservas, configuracion, etc.
-- REGLA BASE: Solo ves/operas datos de TU tenant.
-- ============================================================

-- SALAS
CREATE POLICY "salas_tenant" ON salas FOR ALL
  USING (tenant_id = auth.get_tenant_id());

-- MESAS
CREATE POLICY "mesas_tenant" ON mesas FOR ALL
  USING (tenant_id = auth.get_tenant_id());

-- CATEGORIAS
CREATE POLICY "categorias_tenant" ON categorias FOR ALL
  USING (tenant_id = auth.get_tenant_id());

-- PRODUCTOS (lectura abierta para clientes del menú QR vía función anon)
CREATE POLICY "productos_tenant_auth" ON productos FOR ALL
  USING (tenant_id = auth.get_tenant_id());

-- Los ingredientes heredan el tenant del producto, política directa:
CREATE POLICY "ingredientes_tenant" ON ingredientes FOR ALL
  USING (tenant_id = auth.get_tenant_id());

-- PEDIDOS: Acceso diferenciado por rol dentro del tenant
CREATE POLICY "pedidos_tenant_select" ON pedidos FOR SELECT
  USING (
    tenant_id = auth.get_tenant_id()
    -- Mozo: solo ve pedidos de sus mesas asignadas
    -- Cocina/Bar: ve todos los pedidos del tenant
    -- Regla de mozo se aplica en la capa de aplicación Flutter
    -- (RLS cubre aislamiento de tenant, lógica fina va en el backend)
  );

CREATE POLICY "pedidos_tenant_write" ON pedidos FOR ALL
  USING (tenant_id = auth.get_tenant_id());

-- PEDIDO_ITEMS y sub-tablas: heredan aislamiento vía JOIN con pedidos
CREATE POLICY "pedido_items_tenant" ON pedido_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM pedidos p
      WHERE p.id = pedido_id
        AND p.tenant_id = auth.get_tenant_id()
    )
  );

CREATE POLICY "ingredientes_removidos_tenant"
  ON pedido_item_ingredientes_removidos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM pedido_items pi
      JOIN pedidos p ON pi.pedido_id = p.id
      WHERE pi.id = pedido_item_id
        AND p.tenant_id = auth.get_tenant_id()
    )
  );

CREATE POLICY "agregados_pedido_tenant"
  ON pedido_item_agregados FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM pedido_items pi
      JOIN pedidos p ON pi.pedido_id = p.id
      WHERE pi.id = pedido_item_id
        AND p.tenant_id = auth.get_tenant_id()
    )
  );

-- PRODUCTO_INGREDIENTES_OPCIONALES y PRODUCTO_AGREGADOS (heredan del producto)
CREATE POLICY "prod_ingredientes_tenant"
  ON producto_ingredientes_opcionales FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM productos pr
      WHERE pr.id = producto_id
        AND pr.tenant_id = auth.get_tenant_id()
    )
  );

CREATE POLICY "prod_agregados_tenant"
  ON producto_agregados FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM productos pr
      WHERE pr.id = producto_id
        AND pr.tenant_id = auth.get_tenant_id()
    )
  );

-- RESERVAS
CREATE POLICY "reservas_tenant" ON reservas FOR ALL
  USING (tenant_id = auth.get_tenant_id());

CREATE POLICY "reservas_config_tenant" ON reservas_config FOR ALL
  USING (tenant_id = auth.get_tenant_id());

CREATE POLICY "horarios_tenant" ON reserva_horarios_disponibles FOR ALL
  USING (tenant_id = auth.get_tenant_id());

CREATE POLICY "calendario_tenant" ON reservas_calendario FOR ALL
  USING (tenant_id = auth.get_tenant_id());

CREATE POLICY "calendario_horarios_tenant" ON reservas_calendario_horarios FOR ALL
  USING (tenant_id = auth.get_tenant_id());

CREATE POLICY "config_negocio_tenant" ON configuracion_negocio FOR ALL
  USING (tenant_id = auth.get_tenant_id());
