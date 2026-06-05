-- Migración 05: Asignaciones (permisos granulares por usuario)
-- Fuente: sdd/PLAN/BASE_DE_DATOS/SCHEMAS/02_roles_modulos_permisos_schema.sql
-- Reordenada: requiere tabla usuarios (migración 03).

CREATE TABLE asignaciones (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usuario_id        VARCHAR(128) NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    permiso_modulo_id UUID NOT NULL REFERENCES permisos_modulo(id) ON DELETE CASCADE,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    asignado_por_id   VARCHAR(128) REFERENCES usuarios(id) ON DELETE SET NULL,
    fecha_asignacion  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_expiracion  TIMESTAMP WITH TIME ZONE,
    notas             TEXT,
    CONSTRAINT uq_asignacion_usuario_permiso UNIQUE (tenant_id, usuario_id, permiso_modulo_id)
);

COMMENT ON TABLE asignaciones IS
    'Tabla de intersección central. Conecta usuarios con permisos de módulo específicos dentro de un tenant.
     Es el segundo nivel de control de acceso después del rol de sistema.
     Permite permisos temporales mediante fecha_expiracion.';

CREATE INDEX idx_asignaciones_usuario ON asignaciones(usuario_id);
CREATE INDEX idx_asignaciones_tenant  ON asignaciones(tenant_id);
CREATE INDEX idx_asignaciones_activo  ON asignaciones(activo);
CREATE INDEX idx_asignaciones_expira  ON asignaciones(fecha_expiracion);
