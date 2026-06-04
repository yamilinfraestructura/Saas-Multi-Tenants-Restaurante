-- ============================================================
-- SCHEMA 03: OPERACIONES DEL NEGOCIO
-- Descripción: Tablas operativas del restaurante.
--              Usuarios, Salas, Mesas, Categorías, Productos y Pedidos.
--              Todas las tablas incluyen tenant_id para aislamiento.
-- Autor: SaasSystemGuri
-- ============================================================

-- ============================================================
-- ENUMS OPERACIONALES
-- ============================================================
CREATE TYPE estado_mesa AS ENUM (
    'activa',       -- Mesa libre y disponible para pedidos.
    'inactiva',     -- Mesa deshabilitada temporalmente.
    'espera1',      -- Primer turno de espera (clientes esperando mesa).
    'espera2',      -- Segundo turno de espera.
    'en_curso',     -- Mesa ocupada con pedido activo.
    'reservada'     -- Mesa bloqueada para una reserva específica.
);

CREATE TYPE estado_pedido AS ENUM (
    'pendiente',        -- Recibido, aún no tomado por cocina.
    'en_preparacion',   -- Cocina comenzó la preparación.
    'listo',            -- Listo para ser entregado al mozo.
    'entregado',        -- Entregado en la mesa.
    'completado'        -- Ciclo cerrado (cobrado).
);

CREATE TYPE estado_cobro AS ENUM (
    'Sin Cobrar',       -- Pedido activo, pendiente de pago.
    'Cobrado',          -- Pagado, pero la cuenta sigue abierta.
    'Cobrado_Cerrado'   -- Pagado y cerrado definitivamente.
);

CREATE TYPE tipo_producto AS ENUM ('comida', 'bebida');

CREATE TYPE estado_reserva AS ENUM (
    'pendiente',    -- Solicitud recibida, sin confirmar.
    'confirmada',   -- Aceptada por el establecimiento.
    'cancelada',    -- Rechazada o cancelada.
    'completada'    -- El cliente se presentó y fue atendido.
);

-- ============================================================
-- TABLA: usuarios
-- Propósito: Empleados y usuarios del sistema de cada tenant.
--            El 'id' se sincroniza con Supabase Auth (UUID del JWT).
-- ============================================================
CREATE TABLE usuarios (
    id              VARCHAR(128) PRIMARY KEY, -- Supabase Auth UUID
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    rol_id          UUID NOT NULL REFERENCES roles_sistema(id) ON DELETE RESTRICT,
    user_dni        VARCHAR(20),
    telefono        VARCHAR(50),
    user_img        VARCHAR(500),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_tenant_email UNIQUE (tenant_id, email)
);

COMMENT ON TABLE usuarios IS 
    'Usuarios del sistema de cada tenant. rol_id vincula al macrofiltro de acceso (roles_sistema).
     Los permisos granulares se gestionan en la tabla asignaciones.';

-- ============================================================
-- TABLA: salas
-- Propósito: Espacios físicos del restaurante (salón, terraza, etc.)
-- ============================================================
CREATE TABLE salas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nombre_sala     VARCHAR(100) NOT NULL,
    numero_posicion INTEGER NOT NULL DEFAULT 0,
    estado_sala     VARCHAR(20) NOT NULL DEFAULT 'activa'
                      CHECK (estado_sala IN ('activa', 'inactiva')),
    reserva_sala    VARCHAR(255),  -- Nombre del evento o empresa reservante (opcional)
    CONSTRAINT uq_tenant_sala UNIQUE (tenant_id, nombre_sala)
);

-- ============================================================
-- TABLA: mesas
-- Propósito: Mesas físicas, cada una vinculada a una sala.
-- ============================================================
CREATE TABLE mesas (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id             UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    valor_mesa            VARCHAR(50) NOT NULL,
    estado                estado_mesa NOT NULL DEFAULT 'activa',
    sala_id               UUID NOT NULL REFERENCES salas(id) ON DELETE RESTRICT,
    personal_asignado_id  VARCHAR(128) REFERENCES usuarios(id) ON DELETE SET NULL,
    reservado_por         VARCHAR(100),
    qr_code_data          TEXT,
    contador              INTEGER NOT NULL DEFAULT 0 CHECK (contador >= 0),
    ultimo_pedido         TIMESTAMP WITH TIME ZONE,
    -- Horario de operación por mesa (opcional)
    open_close_activo     BOOLEAN NOT NULL DEFAULT FALSE,
    open_close_apertura   TIME,
    open_close_cierre     TIME,
    CONSTRAINT uq_sala_mesa UNIQUE (sala_id, valor_mesa)
);

-- ============================================================
-- TABLA: categorias
-- Propósito: Clasificación del catálogo de productos del tenant.
-- ============================================================
CREATE TABLE categorias (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id        UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nombre_categoria VARCHAR(100) NOT NULL,
    posicion         INTEGER NOT NULL DEFAULT 0,
    status           VARCHAR(20) NOT NULL DEFAULT 'activo'
                       CHECK (status IN ('activo', 'inactivo')),
    tipo             VARCHAR(50) NOT NULL,  -- 'comida' o 'bebida'
    emoji            VARCHAR(10),
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT uq_tenant_categoria UNIQUE (tenant_id, nombre_categoria)
);

-- ============================================================
-- TABLA: productos
-- Propósito: Catálogo unificado de comidas y bebidas del tenant.
-- ============================================================
CREATE TABLE productos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nombre          VARCHAR(150) NOT NULL,
    precio          NUMERIC(10, 2) NOT NULL CHECK (precio >= 0),
    precio_original NUMERIC(10, 2) CHECK (precio_original >= 0),
    estado          VARCHAR(20) NOT NULL DEFAULT 'activo'
                      CHECK (estado IN ('activo', 'inactivo')),
    tipo            tipo_producto NOT NULL,
    categoria_id    UUID NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
    stock           INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    stock_minimo    INTEGER NOT NULL DEFAULT 0 CHECK (stock_minimo >= 0),
    img             VARCHAR(500),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================
-- TABLA: producto_ingredientes_opcionales
-- Propósito: Ingredientes que el cliente puede solicitar quitar
-- ============================================================
CREATE TABLE producto_ingredientes_opcionales (
    id                  SERIAL PRIMARY KEY,
    producto_id         UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    nombre_ingrediente  VARCHAR(100) NOT NULL,
    CONSTRAINT uq_producto_ingrediente UNIQUE (producto_id, nombre_ingrediente)
);

-- ============================================================
-- TABLA: producto_agregados
-- Propósito: Extras opcionales que el cliente puede agregar al precio.
-- ============================================================
CREATE TABLE producto_agregados (
    id          SERIAL PRIMARY KEY,
    producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    nombre      VARCHAR(100) NOT NULL,
    precio      NUMERIC(10, 2) NOT NULL CHECK (precio >= 0),
    CONSTRAINT uq_producto_agregado UNIQUE (producto_id, nombre)
);

-- ============================================================
-- TABLA: ingredientes (Materia prima - Control de Stock)
-- ============================================================
CREATE TABLE ingredientes (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nombre    VARCHAR(100) NOT NULL,
    stock     NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (stock >= 0),
    unidad    VARCHAR(20) NOT NULL, -- 'gr', 'ml', 'unidades'
    CONSTRAINT uq_tenant_ingrediente UNIQUE (tenant_id, nombre)
);

-- ============================================================
-- TABLA: pedidos (Maestro de Comandas y Cuentas)
-- ============================================================
CREATE TABLE pedidos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    mesa_id         UUID NOT NULL REFERENCES mesas(id) ON DELETE RESTRICT,
    nombre_cliente  VARCHAR(100) NOT NULL,
    estado          estado_pedido NOT NULL DEFAULT 'pendiente',
    cobro_pago      estado_cobro NOT NULL DEFAULT 'Sin Cobrar',

    -- Control de cuenta
    cuenta_solicitada           BOOLEAN NOT NULL DEFAULT FALSE,
    cuenta_id                   VARCHAR(100),
    timestamp_cuenta_solicitada TIMESTAMP WITH TIME ZONE,
    cuenta_procesada            BOOLEAN NOT NULL DEFAULT FALSE,
    timestamp_procesada         TIMESTAMP WITH TIME ZONE,
    procesado_por_id            VARCHAR(128) REFERENCES usuarios(id) ON DELETE SET NULL,
    timestamp_cobrada           TIMESTAMP WITH TIME ZONE,
    cobrado_por_id              VARCHAR(128) REFERENCES usuarios(id) ON DELETE SET NULL,
    motivo_cobro                VARCHAR(255),

    -- Pedidos programados
    programado       BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_programada DATE,
    hora_programada  TIME,

    -- Datos financieros
    total           NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (total >= 0),
    fecha_creacion  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- ============================================================
-- TABLAS DE DETALLE DE PEDIDO
-- ============================================================
CREATE TABLE pedido_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_id       UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id     UUID REFERENCES productos(id) ON DELETE SET NULL,
    -- SET NULL: Al borrar un producto del menú, no se pierde el historial.
    nombre_item     VARCHAR(150) NOT NULL,   -- Snapshot histórico del nombre.
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    categoria       VARCHAR(100)              -- Snapshot histórico de la categoría.
);

CREATE TABLE pedido_item_ingredientes_removidos (
    id              SERIAL PRIMARY KEY,
    pedido_item_id  UUID NOT NULL REFERENCES pedido_items(id) ON DELETE CASCADE,
    nombre_ingrediente VARCHAR(100) NOT NULL
);

CREATE TABLE pedido_item_agregados (
    id              SERIAL PRIMARY KEY,
    pedido_item_id  UUID NOT NULL REFERENCES pedido_items(id) ON DELETE CASCADE,
    nombre_agregado VARCHAR(100) NOT NULL,
    precio          NUMERIC(10, 2) NOT NULL CHECK (precio >= 0)
);

-- ============================================================
-- ÍNDICES DE RENDIMIENTO
-- ============================================================
CREATE INDEX idx_usuarios_tenant    ON usuarios(tenant_id);
CREATE INDEX idx_usuarios_rol       ON usuarios(rol_id);
CREATE INDEX idx_usuarios_activo    ON usuarios(activo);
CREATE INDEX idx_salas_tenant       ON salas(tenant_id);
CREATE INDEX idx_mesas_tenant       ON mesas(tenant_id);
CREATE INDEX idx_mesas_sala         ON mesas(sala_id);
CREATE INDEX idx_mesas_estado       ON mesas(estado);
CREATE INDEX idx_categorias_tenant  ON categorias(tenant_id);
CREATE INDEX idx_productos_tenant   ON productos(tenant_id);
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_estado   ON productos(estado);
CREATE INDEX idx_pedidos_tenant     ON pedidos(tenant_id);
CREATE INDEX idx_pedidos_mesa       ON pedidos(mesa_id);
CREATE INDEX idx_pedidos_estado     ON pedidos(estado);
CREATE INDEX idx_pedidos_cobro      ON pedidos(cobro_pago);
CREATE INDEX idx_pedidos_fecha      ON pedidos(fecha_creacion);
CREATE INDEX idx_pedido_items       ON pedido_items(pedido_id);
