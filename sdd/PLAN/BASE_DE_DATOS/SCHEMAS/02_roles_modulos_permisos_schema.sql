-- ============================================================
-- SCHEMA 02: SISTEMA DE ROLES, MÓDULOS Y PERMISOS GRANULARES
--
-- Descripción:
--   Este esquema implementa un sistema de control de acceso
--   de dos niveles:
--
--   NIVEL 1 - Roles de Sistema (Macrofiltro Global):
--     Define el alcance máximo de lo que un usuario PUEDE hacer
--     en la plataforma. Son los "techos de permiso". Un mozo
--     NUNCA podrá ver el módulo de Reportes, sin importar qué
--     asignaciones tenga.
--     Tablas: roles_sistema
--
--   NIVEL 2 - Módulos + Permisos por Módulo (Microfiltro Granular):
--     Dentro de lo que permite el Rol, se puede habilitar o
--     deshabilitar funcionalidades específicas para un usuario
--     o grupo. Un admin puede ver Reportes, pero quizás no
--     puede ELIMINAR registros del historial.
--     Tablas: modulos, permisos_modulo, asignaciones
--
--   FLUJO DE EVALUACIÓN:
--     1. ¿El Rol del usuario le da acceso al área?  → NO = Bloqueado
--     2. ¿Tiene una asignación activa para el módulo? → NO = Bloqueado
--     3. ¿Su asignación incluye la acción solicitada? → NO = Bloqueado
--     4. ✅ Acceso Concedido
--
-- Autor: SaasSystemGuri
-- ============================================================

-- ============================================================
-- ENUMS
-- ============================================================
CREATE TYPE nivel_acceso_sistema AS ENUM (
    'superadmin',   -- Solo el equipo del SaaS. Acceso total a todos los tenants.
    'admin',        -- Dueño/gerente del restaurante. Control total de SU tenant.
    'supervisor',   -- Encargado de turno. Puede ver y gestionar operaciones.
    'cocina',       -- Personal de cocina. Solo ve pedidos activos de su área.
    'mozo',         -- Empleado de sala. Solo ve sus mesas/pedidos asignados.
    'bar',          -- Bartender. Solo ve pedidos de bebidas.
    'general'       -- Usuario básico (ej: cliente interno, sin rol definido).
);

-- ============================================================
-- TABLA: roles_sistema
-- Propósito: Define los roles globales del sistema (Macrofiltro).
--            Son los "techos de permiso" que determinan qué
--            módulos existen para un usuario a nivel de sistema.
--            Un tenant puede personalizar el label, pero no
--            puede crear nuevos roles de sistema.
-- ============================================================
CREATE TABLE roles_sistema (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID REFERENCES tenants(id) ON DELETE CASCADE,
    -- NULL = rol global del sistema. 
    -- NOT NULL = sobrescritura del label para ese tenant específico.
    nivel           nivel_acceso_sistema NOT NULL,
    label           VARCHAR(100) NOT NULL,  -- Nombre visible. Ej: "Chef Ejecutivo"
    descripcion     TEXT,
    es_sistema      BOOLEAN NOT NULL DEFAULT TRUE, 
    -- TRUE = definido por el SaaS (no borrable).
    -- FALSE = personalizado por el tenant.
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_rol_tenant_nivel UNIQUE (tenant_id, nivel)
);

COMMENT ON TABLE roles_sistema IS 
    'Define los roles macrofiltro del sistema. Un rol de sistema es el techo de acceso de un usuario.
     La combinación tenant_id NULL indica un rol global del SaaS (ej: superadmin).';

-- Insertar roles predeterminados del sistema (globales)
INSERT INTO roles_sistema (id, tenant_id, nivel, label, descripcion, es_sistema) VALUES
    (gen_random_uuid(), NULL, 'superadmin',  'Super Administrador', 'Acceso total a todos los tenants. Solo para el equipo del SaaS.', TRUE),
    (gen_random_uuid(), NULL, 'admin',       'Administrador',       'Control completo del negocio propio.', TRUE),
    (gen_random_uuid(), NULL, 'supervisor',  'Supervisor de Turno', 'Gestión de operaciones del turno.', TRUE),
    (gen_random_uuid(), NULL, 'cocina',      'Cocina',              'Visualización y gestión de pedidos en cocina.', TRUE),
    (gen_random_uuid(), NULL, 'mozo',        'Mozo / Camarero',     'Atención de mesas y pedidos asignados.', TRUE),
    (gen_random_uuid(), NULL, 'bar',         'Bar',                 'Gestión de pedidos de bebidas.', TRUE),
    (gen_random_uuid(), NULL, 'general',     'General',             'Sin rol operativo definido.', TRUE);

-- ============================================================
-- TABLA: modulos
-- Propósito: Define las funcionalidades/microapps del sistema
--            que pueden ser habilitadas o deshabilitadas por
--            tenant y asignadas a usuarios específicos.
--            Cada módulo corresponde a una "microapp" del monorepo Flutter.
-- ============================================================
CREATE TABLE modulos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo          VARCHAR(80) UNIQUE NOT NULL,  
    -- Ej: 'MENU_QR', 'COCINA', 'ADMIN_MESAS', 'REPORTES', 'RESERVAS'
    nombre          VARCHAR(120) NOT NULL,
    descripcion     TEXT,
    icono           VARCHAR(50),                  -- Nombre del icono FontAwesome
    categoria       VARCHAR(80),                  
    -- Agrupa módulos: 'operaciones', 'gestion', 'reportes', 'configuracion'
    nivel_minimo_requerido nivel_acceso_sistema NOT NULL DEFAULT 'admin',
    -- Nivel mínimo de rol de sistema para que este módulo sea visible.
    -- Un mozo NO verá el módulo de Reportes aunque tenga asignación.
    activo_globalmente BOOLEAN NOT NULL DEFAULT TRUE,
    orden           INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMENT ON TABLE modulos IS 
    'Catálogo global de módulos/funcionalidades del sistema. Cada módulo se mapea a una microapp Flutter.
     nivel_minimo_requerido actúa como primer filtro antes de evaluar asignaciones.';

-- Insertar módulos base del sistema
INSERT INTO modulos (codigo, nombre, descripcion, icono, categoria, nivel_minimo_requerido, orden) VALUES
    -- Módulos de Operaciones
    ('MENU_QR',           'Menú QR Cliente',         'Interfaz pública del menú para escanear QR.',           'fa-qrcode',      'cliente',       'general',    1),
    ('COCINA_KANBAN',     'Panel de Cocina',          'Vista Kanban de pedidos activos para cocina.',          'fa-fire',        'operaciones',   'cocina',     2),
    ('BAR_KANBAN',        'Panel de Bar',             'Vista Kanban de pedidos de bebidas.',                   'fa-martini-glass','operaciones',   'bar',        3),
    ('COMEDOR_VISTA',     'Vista de Comedor',         'Mapa visual del comedor con estado de mesas.',          'fa-chair',       'operaciones',   'supervisor',  4),
    ('PEDIDOS_ACTIVOS',   'Pedidos Activos',          'Dashboard de pedidos en tiempo real.',                  'fa-receipt',     'operaciones',   'cocina',     5),
    -- Módulos de Gestión Admin
    ('ADMIN_MENU',        'Gestión de Menú',          'ABM de productos, bebidas y categorías.',               'fa-utensils',    'gestion',       'admin',      10),
    ('ADMIN_MESAS',       'Gestión de Mesas',         'ABM de salas y mesas del establecimiento.',             'fa-table',       'gestion',       'admin',      11),
    ('ADMIN_USUARIOS',    'Gestión de Usuarios',      'ABM de empleados y asignación de roles.',               'fa-users',       'gestion',       'admin',      12),
    ('ADMIN_RESERVAS',    'Gestión de Reservas',      'Calendarios y configuración de reservas.',              'fa-calendar',    'gestion',       'supervisor',  13),
    ('ADMIN_STOCK',       'Control de Stock',         'Gestión de inventario y alertas de stock.',             'fa-boxes-stacked','gestion',      'supervisor',  14),
    -- Módulos de Reportes
    ('REPORTES_VENTAS',   'Reportes de Ventas',       'Analytics e informes financieros del negocio.',         'fa-chart-line',  'reportes',      'admin',      20),
    ('REPORTES_HISTORIAL','Historial Completo',       'Historial de pedidos cobrados y cerrados.',             'fa-clock-rotate-left','reportes', 'supervisor',  21),
    -- Módulos de Configuración del Tenant
    ('CONFIG_NEGOCIO',    'Configuración del Negocio','Datos del negocio, geofencing y parámetros.',           'fa-gear',        'configuracion', 'admin',      30),
    ('CONFIG_IMPRESORAS', 'Impresoras y Tickets',     'Configuración de impresoras térmicas.',                 'fa-print',       'configuracion', 'admin',      31),
    -- Módulo SaaS (solo superadmin)
    ('SAAS_BILLING',      'Suscripción y Facturación','Gestión del plan y pagos del tenant.',                  'fa-credit-card', 'saas',          'superadmin', 40);

-- ============================================================
-- TABLA: permisos_modulo
-- Propósito: Define las acciones granulares posibles dentro
--            de cada módulo. Son el "qué puedes hacer".
--            Se asignan de forma individual a través de la
--            tabla asignaciones.
-- ============================================================
CREATE TABLE permisos_modulo (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modulo_id       UUID NOT NULL REFERENCES modulos(id) ON DELETE CASCADE,
    codigo          VARCHAR(100) NOT NULL,       
    -- Convención: MODULO_ACCION. Ej: 'ADMIN_MENU_CREATE', 'REPORTES_VENTAS_EXPORT'
    nombre          VARCHAR(120) NOT NULL,
    descripcion     TEXT,
    accion          VARCHAR(30) NOT NULL
                      CHECK (accion IN ('ver', 'crear', 'editar', 'eliminar', 'exportar', 'aprobar', 'configurar')),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_permiso_codigo UNIQUE (modulo_id, codigo)
);

COMMENT ON TABLE permisos_modulo IS 
    'Acciones granulares disponibles dentro de cada módulo. 
     No se asignan directamente a usuarios, sino a través de la tabla asignaciones.';

-- Insertar permisos por módulo
INSERT INTO permisos_modulo (modulo_id, codigo, nombre, accion) 
SELECT m.id, p.codigo, p.nombre, p.accion FROM modulos m
JOIN (VALUES
    -- PEDIDOS_ACTIVOS
    ('PEDIDOS_ACTIVOS', 'PEDIDOS_VER',             'Ver pedidos activos',           'ver'),
    ('PEDIDOS_ACTIVOS', 'PEDIDOS_CAMBIAR_ESTADO',   'Cambiar estado del pedido',     'editar'),
    ('PEDIDOS_ACTIVOS', 'PEDIDOS_ELIMINAR',         'Eliminar pedido',               'eliminar'),
    -- COCINA_KANBAN
    ('COCINA_KANBAN',   'COCINA_VER',               'Ver panel de cocina',           'ver'),
    ('COCINA_KANBAN',   'COCINA_MARCAR_LISTO',      'Marcar pedido como listo',      'editar'),
    -- COMEDOR_VISTA
    ('COMEDOR_VISTA',   'COMEDOR_VER',              'Ver mapa del comedor',          'ver'),
    ('COMEDOR_VISTA',   'COMEDOR_CAMBIAR_ESTADO_MESA','Cambiar estado de mesa',       'editar'),
    -- ADMIN_MENU
    ('ADMIN_MENU',      'MENU_VER',                 'Ver catálogo de productos',     'ver'),
    ('ADMIN_MENU',      'MENU_CREAR',               'Crear producto/bebida',         'crear'),
    ('ADMIN_MENU',      'MENU_EDITAR',              'Editar producto/bebida',        'editar'),
    ('ADMIN_MENU',      'MENU_ELIMINAR',            'Eliminar producto/bebida',      'eliminar'),
    -- ADMIN_MESAS
    ('ADMIN_MESAS',     'MESAS_VER',                'Ver salas y mesas',             'ver'),
    ('ADMIN_MESAS',     'MESAS_CREAR',              'Crear sala/mesa',               'crear'),
    ('ADMIN_MESAS',     'MESAS_EDITAR',             'Editar sala/mesa',              'editar'),
    ('ADMIN_MESAS',     'MESAS_ELIMINAR',           'Eliminar sala/mesa',            'eliminar'),
    -- ADMIN_USUARIOS
    ('ADMIN_USUARIOS',  'USUARIOS_VER',             'Ver listado de usuarios',       'ver'),
    ('ADMIN_USUARIOS',  'USUARIOS_CREAR',           'Crear usuario/empleado',        'crear'),
    ('ADMIN_USUARIOS',  'USUARIOS_EDITAR',          'Editar usuario/empleado',       'editar'),
    ('ADMIN_USUARIOS',  'USUARIOS_ELIMINAR',        'Eliminar usuario/empleado',     'eliminar'),
    -- ADMIN_RESERVAS
    ('ADMIN_RESERVAS',  'RESERVAS_VER',             'Ver reservas',                  'ver'),
    ('ADMIN_RESERVAS',  'RESERVAS_CREAR',           'Crear reserva manual',          'crear'),
    ('ADMIN_RESERVAS',  'RESERVAS_CONFIRMAR',       'Confirmar/rechazar reserva',    'aprobar'),
    ('ADMIN_RESERVAS',  'RESERVAS_CANCELAR',        'Cancelar reserva',              'eliminar'),
    -- ADMIN_STOCK
    ('ADMIN_STOCK',     'STOCK_VER',                'Ver inventario',                'ver'),
    ('ADMIN_STOCK',     'STOCK_AJUSTAR',            'Ajustar stock manualmente',     'editar'),
    -- REPORTES_VENTAS
    ('REPORTES_VENTAS', 'REPORTES_VER',             'Ver reportes de ventas',        'ver'),
    ('REPORTES_VENTAS', 'REPORTES_EXPORTAR',        'Exportar reportes (PDF/Excel)', 'exportar'),
    -- REPORTES_HISTORIAL
    ('REPORTES_HISTORIAL','HISTORIAL_VER',          'Ver historial completo',        'ver'),
    ('REPORTES_HISTORIAL','HISTORIAL_ELIMINAR',     'Eliminar registros del historial','eliminar'),
    -- CONFIG_NEGOCIO
    ('CONFIG_NEGOCIO',  'CONFIG_VER',               'Ver configuración',             'ver'),
    ('CONFIG_NEGOCIO',  'CONFIG_EDITAR',            'Editar configuración del negocio','configurar')
) AS p(modulo_codigo, codigo, nombre, accion) ON m.codigo = p.modulo_codigo;

-- ============================================================
-- TABLA: asignaciones
-- Propósito: Une usuarios con permisos de módulo específicos
--            dentro de un tenant. Es la tabla de intersección
--            que permite la personalización granular.
--
--   ESTRUCTURA DE ACCESO:
--   Usuario → tiene → rol_sistema (macrofiltro)
--   Usuario → tiene → asignaciones → permisos_modulo (microfiltro)
--
--   Un admin del tenant puede:
--     - Asignar módulos completos (ej: "MENU_QR al mozo Juan")
--     - Asignar permisos específicos (ej: "Juan puede VER menú, pero NO EDITAR")
-- ============================================================
CREATE TABLE asignaciones (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id         UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    usuario_id        VARCHAR(128) NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    permiso_modulo_id UUID NOT NULL REFERENCES permisos_modulo(id) ON DELETE CASCADE,
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    asignado_por_id   VARCHAR(128) REFERENCES usuarios(id) ON DELETE SET NULL,
    fecha_asignacion  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_expiracion  TIMESTAMP WITH TIME ZONE,  
    -- NULL = sin expiración. Para permisos temporales (ej: turno nocturno).
    notas             TEXT,
    CONSTRAINT uq_asignacion_usuario_permiso UNIQUE (tenant_id, usuario_id, permiso_modulo_id)
);

COMMENT ON TABLE asignaciones IS 
    'Tabla de intersección central. Conecta usuarios con permisos de módulo específicos dentro de un tenant.
     Es el segundo nivel de control de acceso después del rol de sistema.
     Permite permisos temporales mediante fecha_expiracion.';

-- ============================================================
-- ÍNDICES DE RENDIMIENTO
-- ============================================================
CREATE INDEX idx_roles_nivel          ON roles_sistema(nivel);
CREATE INDEX idx_roles_tenant         ON roles_sistema(tenant_id);
CREATE INDEX idx_modulos_codigo       ON modulos(codigo);
CREATE INDEX idx_modulos_categoria    ON modulos(categoria);
CREATE INDEX idx_modulos_nivel_min    ON modulos(nivel_minimo_requerido);
CREATE INDEX idx_permisos_modulo_id   ON permisos_modulo(modulo_id);
CREATE INDEX idx_permisos_accion      ON permisos_modulo(accion);
CREATE INDEX idx_asignaciones_usuario ON asignaciones(usuario_id);
CREATE INDEX idx_asignaciones_tenant  ON asignaciones(tenant_id);
CREATE INDEX idx_asignaciones_activo  ON asignaciones(activo);
CREATE INDEX idx_asignaciones_expira  ON asignaciones(fecha_expiracion);
