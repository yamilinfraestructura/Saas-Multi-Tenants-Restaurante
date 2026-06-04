-- ============================================================
-- SCHEMA 01: NÚCLEO SAAS - TENANTS Y SUSCRIPCIONES
-- Descripción: Define las tablas base del sistema multi-tenant.
--              Cada restaurante/negocio es un "Tenant".
-- Autor: SaasSystemGuri
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABLA: tenants
-- Propósito: Representa cada negocio/restaurante registrado
--            en el SaaS. Es la raíz de toda la jerarquía.
-- ============================================================
CREATE TABLE tenants (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_negocio    VARCHAR(150) NOT NULL,
    dominio_slug      VARCHAR(100) UNIQUE NOT NULL,  -- Ej: 'solo-food-rio'
    logo_url          VARCHAR(500),
    email_contacto    VARCHAR(255) NOT NULL,
    telefono          VARCHAR(50),
    plan_actual       VARCHAR(50) NOT NULL DEFAULT 'basico'
                        CHECK (plan_actual IN ('basico', 'premium', 'enterprise')),
    estado            VARCHAR(20) NOT NULL DEFAULT 'activo'
                        CHECK (estado IN ('activo', 'suspendido', 'inactivo')),
    fecha_creacion    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE tenants IS 'Raíz del sistema multi-tenant. Cada fila representa un restaurante cliente del SaaS.';
COMMENT ON COLUMN tenants.dominio_slug IS 'Identificador URL amigable del negocio. Usado para subdominios o paths.';
COMMENT ON COLUMN tenants.estado IS 'activo = operando | suspendido = impago/bloqueado | inactivo = dado de baja.';

-- ============================================================
-- TABLA: tenant_suscripciones
-- Propósito: Historial de pagos/planes de cada tenant.
--            Permite múltiples registros a lo largo del tiempo.
-- ============================================================
CREATE TABLE tenant_suscripciones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan_nombre     VARCHAR(50) NOT NULL
                      CHECK (plan_nombre IN ('basico', 'premium', 'enterprise')),
    monto           NUMERIC(10, 2) NOT NULL CHECK (monto >= 0),
    moneda          VARCHAR(10) NOT NULL DEFAULT 'ARS',
    fecha_inicio    TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_fin       TIMESTAMP WITH TIME ZONE NOT NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'activa'
                      CHECK (estado IN ('activa', 'vencida', 'cancelada')),
    referencia_pago VARCHAR(255)   -- ID externo (MercadoPago, Stripe, etc.)
);

COMMENT ON TABLE tenant_suscripciones IS 'Historial de suscripciones y pagos por tenant. Cuando vence, el tenant pasa a suspendido.';

-- ============================================================
-- ÍNDICES DE RENDIMIENTO
-- ============================================================
CREATE INDEX idx_tenants_slug   ON tenants(dominio_slug);
CREATE INDEX idx_tenants_estado ON tenants(estado);
CREATE INDEX idx_suscripciones_tenant  ON tenant_suscripciones(tenant_id);
CREATE INDEX idx_suscripciones_estado  ON tenant_suscripciones(estado);
CREATE INDEX idx_suscripciones_fecha   ON tenant_suscripciones(fecha_fin);
