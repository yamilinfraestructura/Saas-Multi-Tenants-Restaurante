# SDD — Triggers de Base de Datos
**Directorio:** `sdd/PLAN/BASE_DE_DATOS/TRIGGERS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  
**Fecha:** 2026-06-04

---

## 1. Propósito

Este documento especifica todos los **triggers PostgreSQL** que deben crearse en la base de datos del sistema SaaS. Los triggers automatizan lógica de negocio crítica directamente en la capa de datos, garantizando consistencia sin depender de la lógica del cliente Flutter o de las Edge Functions.

**Criterios de uso de trigger vs. webhook:**
| Criterio | Trigger | Webhook (Edge Function) |
|----------|---------|------------------------|
| Lógica que debe ser atómica con la transacción | ✅ | ❌ |
| Actualización de columnas en la misma/otra tabla | ✅ | ❌ |
| Validación y consistencia de datos | ✅ | ❌ |
| Notificaciones externas (push, email) | ❌ | ✅ |
| Llamadas a APIs externas | ❌ | ✅ |

---

## 2. Convención de nombres

```
-- Funciones trigger:
trg_fn_<tabla>_<descripcion>()

-- Triggers:
trg_<tabla>_<descripcion>
```

---

## 3. Tabla de resumen de triggers

| # | Trigger | Tabla | Evento | Timing | Propósito |
|---|---------|-------|--------|--------|-----------|
| 1 | `trg_tenants_updated_at` | `tenants` | UPDATE | BEFORE | Actualiza `fecha_actualizacion` automáticamente |
| 2 | `trg_productos_updated_at` | `productos` | UPDATE | BEFORE | Actualiza `updated_at` automáticamente |
| 3 | `trg_categorias_updated_at` | `categorias` | UPDATE | BEFORE | Actualiza `updated_at` automáticamente |
| 4 | `trg_suscripcion_actualiza_tenant` | `tenant_suscripciones` | INSERT | AFTER | Sincroniza `tenants.plan_actual` y reactiva tenant |
| 5 | `trg_suscripcion_vencida_suspende` | `tenant_suscripciones` | UPDATE | AFTER | Suspende tenant cuando suscripción vence |
| 6 | `trg_pedido_actualiza_mesa` | `pedidos` | INSERT | AFTER | Pone mesa en estado `en_curso` al crear pedido |
| 7 | `trg_pedido_completado_libera_mesa` | `pedidos` | UPDATE | AFTER | Libera la mesa cuando pedido pasa a `completado` |
| 8 | `trg_pedido_items_actualiza_total` | `pedido_items` | INSERT/UPDATE/DELETE | AFTER | Recalcula `pedidos.total` al modificar ítems |
| 9 | `trg_stock_descuenta_al_pedir` | `pedido_items` | INSERT | AFTER | Descuenta stock de productos al crear ítem |
| 10 | `trg_reserva_bloquea_mesa` | `reservas` | UPDATE | AFTER | Marca mesa como `reservada` al confirmar reserva |
| 11 | `trg_reserva_libera_mesa` | `reservas` | UPDATE | AFTER | Libera mesa al cancelar o completar reserva |
| 12 | `trg_reserva_incrementa_contador` | `reservas` | INSERT | AFTER | Incrementa `reservas_calendario_horarios.reservas` |
| 13 | `trg_reserva_decrementa_contador` | `reservas` | UPDATE | AFTER | Decrementa contador al cancelar reserva |
| 14 | `trg_asignaciones_valida_expiracion` | `asignaciones` | INSERT/UPDATE | BEFORE | Valida que `fecha_expiracion` sea futura |
| 15 | `trg_audit_pedidos` | `pedidos` | INSERT/UPDATE/DELETE | AFTER | Registra cambios en tabla `audit_log` |
| 16 | `trg_audit_tenants` | `tenants` | UPDATE | AFTER | Registra cambios de estado del tenant |
| 17 | `trg_numero_reserva_autoincrement` | `reservas` | INSERT | BEFORE | Genera `numero_reserva` secuencial por tenant |

---

## 4. Función utilitaria compartida: `set_updated_at()`

Esta función es reutilizada por todos los triggers de `updated_at`.

```sql
-- ============================================================
-- FUNCIÓN UTILITARIA: set_updated_at
-- Propósito: Actualiza automáticamente la columna de timestamp
--            de última modificación en cualquier tabla.
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Variante para columnas llamadas fecha_actualizacion (tabla tenants)
CREATE OR REPLACE FUNCTION set_fecha_actualizacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 5. Triggers detallados

---

### 5.1 `trg_tenants_updated_at` — Timestamp automático en tenants

```sql
CREATE TRIGGER trg_tenants_updated_at
BEFORE UPDATE ON tenants
FOR EACH ROW
EXECUTE FUNCTION set_fecha_actualizacion();
```

**Propósito:** Garantiza que `tenants.fecha_actualizacion` refleje siempre la última modificación sin requerir lógica en el cliente.

---

### 5.2 `trg_productos_updated_at` — Timestamp automático en productos

```sql
CREATE TRIGGER trg_productos_updated_at
BEFORE UPDATE ON productos
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
```

---

### 5.3 `trg_categorias_updated_at` — Timestamp automático en categorias

```sql
CREATE TRIGGER trg_categorias_updated_at
BEFORE UPDATE ON categorias
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
```

---

### 5.4 `trg_suscripcion_actualiza_tenant` — Sincroniza plan del tenant al pagar

**Tabla:** `tenant_suscripciones` | **Evento:** INSERT AFTER

```sql
CREATE OR REPLACE FUNCTION trg_fn_suscripcion_actualiza_tenant()
RETURNS TRIGGER AS $$
BEGIN
    -- Al insertarse una nueva suscripción activa,
    -- actualizar el plan y reactivar el tenant si estaba suspendido.
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
```

**Coherencia:** Relacionado con `wh_tenant_suscripciones_insert` (webhook). El trigger maneja la DB; el webhook maneja la notificación externa.

---

### 5.5 `trg_suscripcion_vencida_suspende` — Suspende tenant al vencer suscripción

**Tabla:** `tenant_suscripciones` | **Evento:** UPDATE AFTER

```sql
CREATE OR REPLACE FUNCTION trg_fn_suscripcion_vencida_suspende()
RETURNS TRIGGER AS $$
BEGIN
    -- Cuando una suscripción pasa a 'vencida',
    -- verificar si el tenant tiene otra activa. Si no, suspenderlo.
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
```

---

### 5.6 `trg_pedido_actualiza_mesa` — Mesa pasa a `en_curso` al crear pedido

**Tabla:** `pedidos` | **Evento:** INSERT AFTER

```sql
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
```

**Coherencia:** Al insertar un pedido, la mesa refleja `en_curso` instantáneamente. El `contador` registra cuántos turnos tuvo esa mesa.

---

### 5.7 `trg_pedido_completado_libera_mesa` — Libera mesa al completar pedido

**Tabla:** `pedidos` | **Evento:** UPDATE AFTER

```sql
CREATE OR REPLACE FUNCTION trg_fn_pedido_completado_libera_mesa()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo liberar si NO hay otros pedidos activos en la misma mesa
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
```

---

### 5.8 `trg_pedido_items_actualiza_total` — Recalcula total del pedido

**Tabla:** `pedido_items` | **Evento:** INSERT/UPDATE/DELETE AFTER

```sql
CREATE OR REPLACE FUNCTION trg_fn_recalcula_total_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id UUID;
    v_nuevo_total NUMERIC(10,2);
BEGIN
    -- Obtener el pedido_id del registro modificado
    IF TG_OP = 'DELETE' THEN
        v_pedido_id := OLD.pedido_id;
    ELSE
        v_pedido_id := NEW.pedido_id;
    END IF;

    -- Sumar ítems + agregados
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

    -- Actualizar el total en pedidos
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
```

**Nota:** El total en `pedidos.total` es siempre la fuente de verdad, calculado automáticamente. El cliente Flutter no necesita calcular ni enviar el total.

---

### 5.9 `trg_stock_descuenta_al_pedir` — Descuenta stock al agregar ítem

**Tabla:** `pedido_items` | **Evento:** INSERT AFTER

```sql
CREATE OR REPLACE FUNCTION trg_fn_descuenta_stock()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo descontar si el producto existe y tiene stock controlado
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
```

**Nota:** `GREATEST(..., 0)` previene stock negativo a nivel de DB como capa de seguridad adicional. La validación de stock disponible debe hacerse **antes** en la lógica de la app.

---

### 5.10 `trg_reserva_bloquea_mesa` — Bloquea mesa al confirmar reserva

**Tabla:** `reservas` | **Evento:** UPDATE AFTER

```sql
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
```

---

### 5.11 `trg_reserva_libera_mesa` — Libera mesa al cancelar/completar reserva

**Tabla:** `reservas` | **Evento:** UPDATE AFTER

```sql
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
```

---

### 5.12 `trg_reserva_incrementa_contador` — Incrementa disponibilidad al reservar

**Tabla:** `reservas` | **Evento:** INSERT AFTER

```sql
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
```

---

### 5.13 `trg_reserva_decrementa_contador` — Decrementa contador al cancelar

**Tabla:** `reservas` | **Evento:** UPDATE AFTER

```sql
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
```

---

### 5.14 `trg_asignaciones_valida_expiracion` — Valida permisos temporales

**Tabla:** `asignaciones` | **Evento:** INSERT/UPDATE BEFORE

```sql
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
```

---

### 5.15 `trg_audit_pedidos` — Auditoría de cambios en pedidos

**Requiere tabla `audit_log` (ver sección 6).**

```sql
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
```

---

### 5.16 `trg_audit_tenants` — Auditoría de cambios de estado del tenant

```sql
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
```

---

### 5.17 `trg_numero_reserva_autoincrement` — Número de reserva secuencial por tenant

**Tabla:** `reservas` | **Evento:** INSERT BEFORE

```sql
CREATE OR REPLACE FUNCTION trg_fn_genera_numero_reserva()
RETURNS TRIGGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Contar reservas existentes del tenant y generar número correlativo
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
```

**Ejemplo de salida:** `RES-000001`, `RES-000042`, `RES-001337`

---

## 6. Tabla de auditoría: `audit_log`

Los triggers de auditoría (#15 y #16) requieren esta tabla. Debe crearse **antes** que los triggers.

```sql
-- ============================================================
-- TABLA: audit_log
-- Propósito: Registro de auditoría centralizado para cambios
--            en tablas críticas del sistema.
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
```

---

## 7. Orden de creación en producción

Para evitar errores de dependencia, ejecutar en este orden:

```
1. audit_log table               ← Necesaria para triggers de auditoría
2. set_updated_at()              ← Función utilitaria compartida
3. set_fecha_actualizacion()     ← Función utilitaria compartida
4. trg_tenants_updated_at        ← Tabla: tenants
5. trg_productos_updated_at      ← Tabla: productos
6. trg_categorias_updated_at     ← Tabla: categorias
7. trg_suscripcion_actualiza_tenant
8. trg_suscripcion_vencida_suspende
9. trg_pedido_actualiza_mesa
10. trg_pedido_completado_libera_mesa
11. trg_pedido_items_actualiza_total
12. trg_stock_descuenta_al_pedir
13. trg_reserva_bloquea_mesa
14. trg_reserva_libera_mesa
15. trg_reserva_incrementa_contador
16. trg_reserva_decrementa_contador
17. trg_asignaciones_valida_expiracion
18. trg_audit_pedidos
19. trg_audit_tenants
20. trg_numero_reserva_autoincrement
```

---

## 8. Coherencia con otros SDDs

| Referencia | Documento |
|-----------|-----------|
| `tenants`, `tenant_suscripciones` | `SCHEMAS/01_saas_core_schema.sql` |
| `asignaciones`, `permisos_modulo` | `SCHEMAS/02_roles_modulos_permisos_schema.sql` |
| `pedidos`, `pedido_items`, `mesas`, `productos` | `SCHEMAS/03_operaciones_negocio_schema.sql` |
| `reservas`, `reservas_calendario_horarios` | `SCHEMAS/04_reservas_configuracion_schema.sql` |
| Webhooks (notificaciones externas) | `WEB_HOOKS/sdd_webhooks.md` |
| RLS (seguridad por tenant) | `RLS/01_rls_policies.sql` |
| Excepciones del sistema | `UI/EXCEPCIONES/sdd_excepciones.md` |
