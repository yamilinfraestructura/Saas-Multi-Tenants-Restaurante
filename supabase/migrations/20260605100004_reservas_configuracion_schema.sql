-- Migración 04: Reservas y Configuración del Negocio
-- Fuente: sdd/PLAN/BASE_DE_DATOS/SCHEMAS/04_reservas_configuracion_schema.sql

CREATE TABLE reservas_config (
    tenant_id                UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    capacidad_maxima_por_dia INTEGER NOT NULL DEFAULT 50
                               CHECK (capacidad_maxima_por_dia > 0),
    senia_requerida          NUMERIC(10, 2) NOT NULL DEFAULT 0.00
                               CHECK (senia_requerida >= 0),
    mensaje_confirmacion     TEXT NOT NULL DEFAULT 'Su reserva ha sido confirmada.',
    estado_sistema           VARCHAR(20) NOT NULL DEFAULT 'activo'
                               CHECK (estado_sistema IN ('activo', 'inactivo')),
    anticipacion_minima_hs   INTEGER NOT NULL DEFAULT 2 CHECK (anticipacion_minima_hs >= 0),
    cancelacion_limite_hs    INTEGER NOT NULL DEFAULT 24 CHECK (cancelacion_limite_hs >= 0)
);

COMMENT ON TABLE reservas_config IS
    'Configuración 1:1 por tenant del sistema de reservas.
     anticipacion_minima_hs: cuántas horas antes se puede reservar.
     cancelacion_limite_hs: hasta cuántas horas antes se acepta cancelación.';

CREATE TABLE reserva_horarios_disponibles (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nombre    VARCHAR(100) NOT NULL,
    inicio    TIME NOT NULL,
    fin       TIME NOT NULL,
    activo    BOOLEAN NOT NULL DEFAULT TRUE,
    capacidad_maxima INTEGER NOT NULL DEFAULT 20 CHECK (capacidad_maxima > 0),
    CONSTRAINT chk_horario_valido CHECK (fin > inicio),
    CONSTRAINT uq_tenant_horario UNIQUE (tenant_id, nombre)
);

CREATE TABLE reservas_calendario (
    tenant_id        UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    fecha            DATE NOT NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'activo'
                       CHECK (estado IN ('activo', 'inactivo', 'completo')),
    capacidad_maxima INTEGER NOT NULL CHECK (capacidad_maxima >= 0),
    notas_especiales TEXT,
    PRIMARY KEY (tenant_id, fecha)
);

CREATE TABLE reservas_calendario_horarios (
    tenant_id  UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    fecha      DATE NOT NULL,
    horario_id UUID NOT NULL REFERENCES reserva_horarios_disponibles(id) ON DELETE RESTRICT,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    reservas   INTEGER NOT NULL DEFAULT 0 CHECK (reservas >= 0),
    capacidad  INTEGER NOT NULL CHECK (capacidad >= 0),
    PRIMARY KEY (tenant_id, fecha, horario_id),
    FOREIGN KEY (tenant_id, fecha) REFERENCES reservas_calendario(tenant_id, fecha) ON DELETE CASCADE
);

CREATE TABLE reservas (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id               UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    numero_reserva          VARCHAR(50) NOT NULL,
    fecha_reserva           DATE NOT NULL,
    horario_id              UUID NOT NULL REFERENCES reserva_horarios_disponibles(id) ON DELETE RESTRICT,
    nombre_cliente          VARCHAR(100) NOT NULL,
    email_cliente           VARCHAR(150) NOT NULL,
    telefono_cliente        VARCHAR(50) NOT NULL,
    cantidad_personas       INTEGER NOT NULL CHECK (cantidad_personas > 0),
    estado                  estado_reserva NOT NULL DEFAULT 'pendiente',
    senia_pagada            BOOLEAN NOT NULL DEFAULT FALSE,
    monto_senia             NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (monto_senia >= 0),
    notas_cliente           TEXT,
    fecha_creacion          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_confirmacion      TIMESTAMP WITH TIME ZONE,
    administrador_id        VARCHAR(128) REFERENCES usuarios(id) ON DELETE SET NULL,
    mesa_asignada_id        UUID REFERENCES mesas(id) ON DELETE SET NULL,
    CONSTRAINT uq_numero_reserva_tenant UNIQUE (tenant_id, numero_reserva)
);

CREATE TABLE configuracion_negocio (
    tenant_id               UUID PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    nombre_mostrar          VARCHAR(150),
    direccion               TEXT,
    telefono_contacto       VARCHAR(50),
    geofencing_activado     BOOLEAN NOT NULL DEFAULT FALSE,
    geofencing_latitud      DOUBLE PRECISION,
    geofencing_longitud     DOUBLE PRECISION,
    geofencing_radio        DOUBLE PRECISION CHECK (geofencing_radio > 0),
    geofencing_estado       VARCHAR(20) NOT NULL DEFAULT 'inactivo'
                              CHECK (geofencing_estado IN ('activo', 'inactivo')),
    impresora_ip            VARCHAR(50),
    impresora_puerto        INTEGER DEFAULT 9100,
    impresora_activada      BOOLEAN NOT NULL DEFAULT FALSE,
    moneda_codigo           VARCHAR(10) NOT NULL DEFAULT 'ARS',
    zona_horaria            VARCHAR(80) NOT NULL DEFAULT 'America/Argentina/Buenos_Aires',
    logo_menu_url           VARCHAR(500)
);

COMMENT ON TABLE configuracion_negocio IS
    'Configuración 1:1 por tenant. Centraliza todos los parámetros operacionales del negocio.';

CREATE INDEX idx_reservas_tenant       ON reservas(tenant_id);
CREATE INDEX idx_reservas_fecha        ON reservas(fecha_reserva);
CREATE INDEX idx_reservas_estado       ON reservas(estado);
CREATE INDEX idx_reservas_cliente      ON reservas(nombre_cliente);
CREATE INDEX idx_cal_horarios_tenant   ON reservas_calendario_horarios(tenant_id);
CREATE INDEX idx_cal_horarios_fecha    ON reservas_calendario_horarios(fecha);
CREATE INDEX idx_calendario_tenant     ON reservas_calendario(tenant_id);
CREATE INDEX idx_horarios_tenant       ON reserva_horarios_disponibles(tenant_id);
