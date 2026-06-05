-- Migración 07: Triggers y tabla de auditoría
-- Fuente: sdd/PLAN/BASE_DE_DATOS/TRIGGERS/sdd_triggers.md (secciones 4, 5 y 6)

-- ============================================================
-- TABLA: audit_log
-- ============================================================
CREATE TABLE audit_log (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tabla            VARCHAR(100) NOT NULL,
    operacion        VARCHAR(10) NOT NULL CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id      UUID,
    tenant_id        UUID REFERENCES tenants(id) ON DELETE SET NULL,
    datos_anteriores JSONB,
    datos_nuevos     JSONB,
    usuario_db       VARCHAR(100) DEFAULT current_user,
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE audit_log IS
    'Log de auditoría centralizado. Registra INSERT, UPDATE y DELETE en tablas críticas.
     datos_anteriores y datos_nuevos son snapshots JSON del registro.';

CREATE INDEX idx_audit_tabla      ON audit_log(tabla);
CREATE INDEX idx_audit_tenant     ON audit_log(tenant_id);
CREATE INDEX idx_audit_operacion  ON audit_log(operacion);
CREATE INDEX idx_audit_created_at ON audit_log(created_at);

-- ============================================================
-- FUNCIONES UTILITARIAS
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.set_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TRIGGERS DE TIMESTAMPS
-- ============================================================
CREATE TRIGGER trg_tenants_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION public.set_fecha_actualizacion();

CREATE TRIGGER trg_productos_updated_at
BEFORE UPDATE ON productos
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_categorias_updated_at
BEFORE UPDATE ON categorias
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- TRIGGERS DE SUSCRIPCIÓN
-- ============================================================
CREATE OR REPLACE FUNCTION trg_fn_suscripcion_actualiza_tenant()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'activa' THEN
        UPDATE tenants
        SET
            plan_actual          = NEW.plan_nombre,
            estado               = 'activo',
            fecha_actualizacion  = CURRENT_TIMESTAMP
        WHERE id = NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_suscripcion_actualiza_tenant
AFTER INSERT ON tenant_suscripciones
FOR EACH ROW
EXECUTE FUNCTION trg_fn_suscripcion_actualiza_tenant();

CREATE OR REPLACE FUNCTION trg_fn_suscripcion_vencida_suspende()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'vencida' AND OLD.estado = 'activa' THEN
        IF NOT EXISTS (
            SELECT 1 FROM tenant_suscripciones
            WHERE tenant_id = NEW.tenant_id
              AND estado = 'activa'
              AND id != NEW.id
        ) THEN
            UPDATE tenants
            SET estado              = 'suspendido',
                fecha_actualizacion = CURRENT_TIMESTAMP
            WHERE id = NEW.tenant_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_suscripcion_vencida_suspende
AFTER UPDATE ON tenant_suscripciones
FOR EACH ROW
WHEN (NEW.estado = 'vencida' AND OLD.estado = 'activa')
EXECUTE FUNCTION trg_fn_suscripcion_vencida_suspende();

-- ============================================================
-- TRIGGERS OPERATIVOS (PEDIDOS Y STOCK)
-- ============================================================
CREATE OR REPLACE FUNCTION trg_fn_pedido_actualiza_mesa()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE mesas
    SET
        estado         = 'en_curso',
        ultimo_pedido  = CURRENT_TIMESTAMP,
        contador       = contador + 1
    WHERE id = NEW.mesa_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pedido_actualiza_mesa
AFTER INSERT ON pedidos
FOR EACH ROW
EXECUTE FUNCTION trg_fn_pedido_actualiza_mesa();

CREATE OR REPLACE FUNCTION trg_fn_pedido_completado_libera_mesa()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'completado' AND OLD.estado != 'completado' THEN
        IF NOT EXISTS (
            SELECT 1 FROM pedidos
            WHERE mesa_id = NEW.mesa_id
              AND estado NOT IN ('completado')
              AND id != NEW.id
        ) THEN
            UPDATE mesas
            SET estado = 'activa'
            WHERE id = NEW.mesa_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pedido_completado_libera_mesa
AFTER UPDATE ON pedidos
FOR EACH ROW
WHEN (NEW.estado = 'completado' AND OLD.estado IS DISTINCT FROM 'completado')
EXECUTE FUNCTION trg_fn_pedido_completado_libera_mesa();

CREATE OR REPLACE FUNCTION trg_fn_recalcula_total_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id UUID;
    v_nuevo_total NUMERIC(10,2);
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_pedido_id := OLD.pedido_id;
    ELSE
        v_pedido_id := NEW.pedido_id;
    END IF;

    SELECT COALESCE(
        SUM(
            (pi.cantidad * pi.precio_unitario) +
            COALESCE((
                SELECT SUM(pa.precio)
                FROM pedido_item_agregados pa
                WHERE pa.pedido_item_id = pi.id
            ), 0)
        ), 0
    )
    INTO v_nuevo_total
    FROM pedido_items pi
    WHERE pi.pedido_id = v_pedido_id;

    UPDATE pedidos
    SET total = v_nuevo_total
    WHERE id = v_pedido_id;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_pedido_items_actualiza_total
AFTER INSERT OR UPDATE OR DELETE ON pedido_items
FOR EACH ROW
EXECUTE FUNCTION trg_fn_recalcula_total_pedido();

CREATE OR REPLACE FUNCTION trg_fn_descuenta_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.producto_id IS NOT NULL THEN
        UPDATE productos
        SET stock = GREATEST(stock - NEW.cantidad, 0)
        WHERE id = NEW.producto_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_stock_descuenta_al_pedir
AFTER INSERT ON pedido_items
FOR EACH ROW
EXECUTE FUNCTION trg_fn_descuenta_stock();

-- ============================================================
-- TRIGGERS DE RESERVAS
-- ============================================================
CREATE OR REPLACE FUNCTION trg_fn_reserva_bloquea_mesa()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'confirmada' AND OLD.estado != 'confirmada' THEN
        IF NEW.mesa_asignada_id IS NOT NULL THEN
            UPDATE mesas
            SET estado        = 'reservada',
                reservado_por = NEW.nombre_cliente
            WHERE id = NEW.mesa_asignada_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reserva_bloquea_mesa
AFTER UPDATE ON reservas
FOR EACH ROW
WHEN (NEW.estado = 'confirmada' AND OLD.estado IS DISTINCT FROM 'confirmada')
EXECUTE FUNCTION trg_fn_reserva_bloquea_mesa();

CREATE OR REPLACE FUNCTION trg_fn_reserva_libera_mesa()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado IN ('cancelada', 'completada')
       AND OLD.estado NOT IN ('cancelada', 'completada') THEN

        IF NEW.mesa_asignada_id IS NOT NULL THEN
            UPDATE mesas
            SET estado        = 'activa',
                reservado_por = NULL
            WHERE id = NEW.mesa_asignada_id
              AND estado = 'reservada';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reserva_libera_mesa
AFTER UPDATE ON reservas
FOR EACH ROW
WHEN (NEW.estado IN ('cancelada', 'completada'))
EXECUTE FUNCTION trg_fn_reserva_libera_mesa();

CREATE OR REPLACE FUNCTION trg_fn_reserva_incrementa_contador()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE reservas_calendario_horarios
    SET reservas = reservas + 1
    WHERE tenant_id  = NEW.tenant_id
      AND fecha      = NEW.fecha_reserva
      AND horario_id = NEW.horario_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reserva_incrementa_contador
AFTER INSERT ON reservas
FOR EACH ROW
EXECUTE FUNCTION trg_fn_reserva_incrementa_contador();

CREATE OR REPLACE FUNCTION trg_fn_reserva_decrementa_contador()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'cancelada' AND OLD.estado != 'cancelada' THEN
        UPDATE reservas_calendario_horarios
        SET reservas = GREATEST(reservas - 1, 0)
        WHERE tenant_id  = NEW.tenant_id
          AND fecha      = NEW.fecha_reserva
          AND horario_id = NEW.horario_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reserva_decrementa_contador
AFTER UPDATE ON reservas
FOR EACH ROW
WHEN (NEW.estado = 'cancelada' AND OLD.estado IS DISTINCT FROM 'cancelada')
EXECUTE FUNCTION trg_fn_reserva_decrementa_contador();

CREATE OR REPLACE FUNCTION trg_fn_genera_numero_reserva()
RETURNS TRIGGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) + 1
    INTO v_count
    FROM reservas
    WHERE tenant_id = NEW.tenant_id;

    NEW.numero_reserva := 'RES-' || LPAD(v_count::TEXT, 6, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_numero_reserva_autoincrement
BEFORE INSERT ON reservas
FOR EACH ROW
WHEN (NEW.numero_reserva IS NULL OR NEW.numero_reserva = '')
EXECUTE FUNCTION trg_fn_genera_numero_reserva();

-- ============================================================
-- TRIGGERS DE ASIGNACIONES
-- ============================================================
CREATE OR REPLACE FUNCTION trg_fn_valida_expiracion_asignacion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_expiracion IS NOT NULL
       AND NEW.fecha_expiracion <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'fecha_expiracion debe ser una fecha futura. Valor recibido: %', NEW.fecha_expiracion;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_asignaciones_valida_expiracion
BEFORE INSERT OR UPDATE ON asignaciones
FOR EACH ROW
EXECUTE FUNCTION trg_fn_valida_expiracion_asignacion();

-- ============================================================
-- TRIGGERS DE AUDITORÍA
-- ============================================================
CREATE OR REPLACE FUNCTION trg_fn_audit_pedidos()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log (
        tabla,
        operacion,
        registro_id,
        tenant_id,
        datos_anteriores,
        datos_nuevos,
        created_at
    ) VALUES (
        'pedidos',
        TG_OP,
        COALESCE(NEW.id, OLD.id),
        COALESCE(NEW.tenant_id, OLD.tenant_id),
        CASE WHEN TG_OP != 'INSERT' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW) ELSE NULL END,
        CURRENT_TIMESTAMP
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_pedidos
AFTER INSERT OR UPDATE OR DELETE ON pedidos
FOR EACH ROW
EXECUTE FUNCTION trg_fn_audit_pedidos();

CREATE OR REPLACE FUNCTION trg_fn_audit_tenants()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado IS DISTINCT FROM OLD.estado
       OR NEW.plan_actual IS DISTINCT FROM OLD.plan_actual THEN

        INSERT INTO audit_log (
            tabla,
            operacion,
            registro_id,
            tenant_id,
            datos_anteriores,
            datos_nuevos,
            created_at
        ) VALUES (
            'tenants',
            'UPDATE',
            NEW.id,
            NEW.id,
            row_to_json(OLD),
            row_to_json(NEW),
            CURRENT_TIMESTAMP
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_tenants
AFTER UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION trg_fn_audit_tenants();
