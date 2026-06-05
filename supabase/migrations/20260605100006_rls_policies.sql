-- Migración 06: Row Level Security (RLS)
-- Fuente: sdd/PLAN/BASE_DE_DATOS/RLS/01_rls_policies.sql

CREATE OR REPLACE FUNCTION public.get_tenant_id()
RETURNS UUID AS $$
  SELECT (auth.jwt() ->> 'tenant_id')::UUID;
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_nivel()
RETURNS TEXT AS $$
  SELECT auth.jwt() ->> 'nivel_acceso';
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.tiene_nivel_minimo(nivel_requerido nivel_acceso_sistema)
RETURNS BOOLEAN AS $$
DECLARE
  orden_requerido INT;
  orden_actual    INT;
  nivel_usuario   TEXT;
BEGIN
  nivel_usuario := public.get_user_nivel();

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

CREATE OR REPLACE FUNCTION public.tiene_permiso(codigo_permiso TEXT)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM asignaciones a
    JOIN permisos_modulo pm ON a.permiso_modulo_id = pm.id
    WHERE a.usuario_id    = auth.uid()::TEXT
      AND a.tenant_id     = public.get_tenant_id()
      AND pm.codigo       = codigo_permiso
      AND a.activo        = TRUE
      AND (a.fecha_expiracion IS NULL OR a.fecha_expiracion > NOW())
  );
$$ LANGUAGE SQL STABLE SECURITY DEFINER;

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

CREATE POLICY "tenants_select"
  ON tenants FOR SELECT
  USING (
    public.get_user_nivel() = 'superadmin'
    OR id = public.get_tenant_id()
  );

CREATE POLICY "tenants_update"
  ON tenants FOR UPDATE
  USING (
    public.get_user_nivel() = 'superadmin'
    OR (id = public.get_tenant_id() AND public.tiene_nivel_minimo('admin'))
  );

CREATE POLICY "tenants_insert"
  ON tenants FOR INSERT
  WITH CHECK (public.get_user_nivel() = 'superadmin');

CREATE POLICY "suscripciones_select"
  ON tenant_suscripciones FOR SELECT
  USING (
    public.get_user_nivel() = 'superadmin'
    OR tenant_id = public.get_tenant_id()
  );

CREATE POLICY "suscripciones_all"
  ON tenant_suscripciones FOR ALL
  USING (public.get_user_nivel() = 'superadmin');

CREATE POLICY "modulos_select_all"
  ON modulos FOR SELECT
  USING (TRUE);

CREATE POLICY "modulos_write_superadmin"
  ON modulos FOR ALL
  USING (public.get_user_nivel() = 'superadmin');

CREATE POLICY "permisos_modulo_select_all"
  ON permisos_modulo FOR SELECT
  USING (TRUE);

CREATE POLICY "permisos_modulo_write_superadmin"
  ON permisos_modulo FOR ALL
  USING (public.get_user_nivel() = 'superadmin');

CREATE POLICY "roles_select"
  ON roles_sistema FOR SELECT
  USING (
    tenant_id IS NULL
    OR tenant_id = public.get_tenant_id()
    OR public.get_user_nivel() = 'superadmin'
  );

CREATE POLICY "roles_write"
  ON roles_sistema FOR ALL
  USING (
    public.get_user_nivel() = 'superadmin'
    OR (
      tenant_id = public.get_tenant_id()
      AND public.tiene_nivel_minimo('admin')
      AND es_sistema = FALSE
    )
  );

CREATE POLICY "asignaciones_select"
  ON asignaciones FOR SELECT
  USING (
    tenant_id = public.get_tenant_id()
    AND (
      public.tiene_nivel_minimo('supervisor')
      OR usuario_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "asignaciones_write"
  ON asignaciones FOR ALL
  USING (
    tenant_id = public.get_tenant_id()
    AND public.tiene_nivel_minimo('admin')
  );

CREATE POLICY "usuarios_select"
  ON usuarios FOR SELECT
  USING (
    tenant_id = public.get_tenant_id()
    AND (
      public.tiene_nivel_minimo('supervisor')
      OR id = auth.uid()::TEXT
    )
  );

CREATE POLICY "usuarios_insert"
  ON usuarios FOR INSERT
  WITH CHECK (
    tenant_id = public.get_tenant_id()
    AND public.tiene_nivel_minimo('admin')
  );

CREATE POLICY "usuarios_update"
  ON usuarios FOR UPDATE
  USING (
    tenant_id = public.get_tenant_id()
    AND (
      public.tiene_nivel_minimo('admin')
      OR id = auth.uid()::TEXT
    )
  );

CREATE POLICY "usuarios_delete"
  ON usuarios FOR DELETE
  USING (
    tenant_id = public.get_tenant_id()
    AND public.tiene_nivel_minimo('admin')
    AND id <> auth.uid()::TEXT
  );

CREATE POLICY "salas_tenant" ON salas FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "mesas_tenant" ON mesas FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "categorias_tenant" ON categorias FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "productos_tenant_auth" ON productos FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "ingredientes_tenant" ON ingredientes FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "pedidos_tenant_select" ON pedidos FOR SELECT
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "pedidos_tenant_write" ON pedidos FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "pedido_items_tenant" ON pedido_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM pedidos p
      WHERE p.id = pedido_id
        AND p.tenant_id = public.get_tenant_id()
    )
  );

CREATE POLICY "ingredientes_removidos_tenant"
  ON pedido_item_ingredientes_removidos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM pedido_items pi
      JOIN pedidos p ON pi.pedido_id = p.id
      WHERE pi.id = pedido_item_id
        AND p.tenant_id = public.get_tenant_id()
    )
  );

CREATE POLICY "agregados_pedido_tenant"
  ON pedido_item_agregados FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM pedido_items pi
      JOIN pedidos p ON pi.pedido_id = p.id
      WHERE pi.id = pedido_item_id
        AND p.tenant_id = public.get_tenant_id()
    )
  );

CREATE POLICY "prod_ingredientes_tenant"
  ON producto_ingredientes_opcionales FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM productos pr
      WHERE pr.id = producto_id
        AND pr.tenant_id = public.get_tenant_id()
    )
  );

CREATE POLICY "prod_agregados_tenant"
  ON producto_agregados FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM productos pr
      WHERE pr.id = producto_id
        AND pr.tenant_id = public.get_tenant_id()
    )
  );

CREATE POLICY "reservas_tenant" ON reservas FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "reservas_config_tenant" ON reservas_config FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "horarios_tenant" ON reserva_horarios_disponibles FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "calendario_tenant" ON reservas_calendario FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "calendario_horarios_tenant" ON reservas_calendario_horarios FOR ALL
  USING (tenant_id = public.get_tenant_id());

CREATE POLICY "config_negocio_tenant" ON configuracion_negocio FOR ALL
  USING (tenant_id = public.get_tenant_id());
