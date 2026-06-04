# Índice del SDD — Base de Datos

## Descripción General
Este directorio contiene todos los documentos de diseño de software (SDD) 
relacionados con la base de datos del sistema SaaS Multi-Tenant de Restaurantes.

El sistema utiliza **Supabase (PostgreSQL)** como motor de base de datos, 
aprovechando **Row Level Security (RLS)** para el aislamiento multi-tenant y 
un sistema de permisos granular de dos niveles.

---

## 📁 Estructura de Archivos

```
BASE_DE_DATOS/
├── SCHEMAS/
│   ├── 01_saas_core_schema.sql             ← Tenants y Suscripciones
│   ├── 02_roles_modulos_permisos_schema.sql ← Sistema de Control de Acceso (ACL)
│   ├── 03_operaciones_negocio_schema.sql    ← Usuarios, Mesas, Productos, Pedidos
│   └── 04_reservas_configuracion_schema.sql ← Reservas y Configuración del Negocio
│
├── RLS/
│   └── 01_rls_policies.sql                 ← Políticas de Row Level Security
│
├── BACKEND/
│   └── 01_funciones_backend.sql            ← Funciones PostgreSQL (Hooks, Reportes)
│
└── POLICES/
    └── 01_documentacion_acl_sistema.md     ← Documentación completa del ACL
```

---

## 🚀 Orden de Ejecución en Supabase

**Importante:** Los scripts deben ejecutarse en este orden exacto para respetar las dependencias de claves foráneas.

| Paso | Archivo | Descripción |
| :--: | :--- | :--- |
| 1 | `SCHEMAS/01_saas_core_schema.sql` | Crear tablas base: `tenants`, `tenant_suscripciones` |
| 2 | `SCHEMAS/02_roles_modulos_permisos_schema.sql` | Crear `roles_sistema`, `modulos`, `permisos_modulo`, `asignaciones` + datos semilla |
| 3 | `SCHEMAS/03_operaciones_negocio_schema.sql` | Crear tablas operativas: `usuarios`, `salas`, `mesas`, `productos`, `pedidos` |
| 4 | `SCHEMAS/04_reservas_configuracion_schema.sql` | Crear tablas de reservas y configuración |
| 5 | `BACKEND/01_funciones_backend.sql` | Crear funciones PostgreSQL y triggers |
| 6 | `RLS/01_rls_policies.sql` | Activar RLS y crear políticas de seguridad |

---

## 🏗️ Arquitectura del Sistema de Permisos

```
┌─────────────────────────────────────────────────┐
│              NIVEL 1: MACROFILTRO                │
│           tabla: roles_sistema                   │
│  superadmin > admin > supervisor > cocina >      │
│  bar > mozo > general                           │
│                                                  │
│  Define el TECHO máximo de acceso del usuario.  │
└──────────────────────┬──────────────────────────┘
                       │ si pasa el filtro de rol
                       ▼
┌─────────────────────────────────────────────────┐
│           NIVEL 2: MICROFILTRO GRANULAR          │
│    tablas: modulos + permisos_modulo             │
│                  + asignaciones                  │
│                                                  │
│  Define QUÉ módulos y QUÉ acciones específicas  │
│  puede ejecutar el usuario dentro de su rol.    │
│                                                  │
│  Ejemplos:                                       │
│  ✅ MENU_VER       → puede ver el catálogo       │
│  ❌ MENU_ELIMINAR  → no puede borrar productos   │
│  ✅ REPORTES_VER   → puede ver ventas            │
│  ❌ REPORTES_EXPORTAR → no puede exportar PDFs   │
└─────────────────────────────────────────────────┘
```

---

## 🔑 Conceptos Clave

### Multi-Tenant con RLS
Cada tabla operativa tiene `tenant_id`. Las políticas RLS validan automáticamente que el `tenant_id` de la fila coincida con el `tenant_id` del JWT del usuario autenticado. 
**Resultado:** Un usuario de "Restaurante A" nunca puede ver datos de "Restaurante B", ni por error de código.

### JWT Enriquecido
Al hacer login, un **PostgreSQL Hook** inyecta `tenant_id` y `nivel_acceso` directamente en el JWT de Supabase. Las políticas RLS leen estos valores con `auth.jwt() ->> 'tenant_id'`, sin necesidad de queries adicionales.

### Asignaciones Temporales
La tabla `asignaciones` soporta `fecha_expiracion`, permitiendo delegar permisos por un turno, un día o un período específico. Al vencer, el permiso se desactiva automáticamente sin intervención manual.
