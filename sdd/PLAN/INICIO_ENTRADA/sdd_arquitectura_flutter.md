# Documento de Diseño de Software (SDD) - Migración a Flutter Multi-Tenant (Microapps)

## 1. Introducción

### 1.1 Propósito
El propósito de este documento es definir la arquitectura de software para la migración del sistema "Menu QR" actual (React + Firebase) a un nuevo sistema **SaaS Multi-tenant** construido con **Flutter** y **Supabase**. 

### 1.2 Objetivos Principales
1. **Multi-tenant SaaS**: Soportar múltiples restaurantes/clientes en una misma base de datos, separados lógicamente de forma segura, bajo un modelo de suscripción (pago inicial + mensualidad).
2. **Escalabilidad y Mantenibilidad**: Adoptar una arquitectura basada en **Microapps (Monorepo)** para evitar conflictos de código, cuellos de botella en el desarrollo y tiempos lentos de CI/CD.
3. **Migración Tecnológica**: Reemplazar React por Flutter (permitiendo apps móviles nativas web/iOS/Android) y Firebase por Supabase (PostgreSQL relacional).

---

## 2. Pila Tecnológica (Tech Stack)

| Componente | Tecnología Seleccionada | Justificación |
| :--- | :--- | :--- |
| **Frontend/App** | Flutter | Soporte multiplataforma real (Web, iOS, Android, Desktop) con un solo código base. |
| **Backend/BaaS** | Supabase (PostgreSQL) | Base de datos relacional robusta perfecta para modelos transaccionales y multi-tenant. |
| **Gestión de Monorepo**| Melos | Herramienta oficial estándar en Flutter para gestionar monorepos y vincular paquetes locales. |
| **Navegación** | GoRouter | Enrutamiento declarativo ideal para la web y para registrar rutas modulares desde distintas microapps. |
| **Estado e Inyección**| Riverpod + GetIt | **Riverpod** provee reactividad segura y testable. **GetIt** maneja la inyección de dependencias (repositorios/casos de uso). *(Ver nota sobre GetX abajo)*. |

### 💡 Nota sobre GetX vs Riverpod/GetIt en Microapps
Aunque es posible utilizar **GetX**, este framework tiende a acoplar fuertemente el ruteo, estado e inyección de dependencias de forma global (Singletons encubiertos). En una arquitectura de **Microapps**, buscamos el *desacoplamiento total*:
* Si un equipo rompe el módulo `cocina_app`, el módulo `admin_app` no debería verse afectado.
* **Riverpod + GoRouter + GetIt** fomenta una separación clara de responsabilidades y es la combinación estándar de la industria hoy en día para escalar monorepos complejos en Flutter. 
* *Recomendación:* Si el equipo domina GetX, se puede usar, pero se debe aplicar una disciplina estricta para no acoplar los paquetes utilizando `Get.put()` de forma descontrolada. Si se quiere preparar el proyecto para el futuro y equipos grandes, **Riverpod es la opción más segura**.

---

## 3. Arquitectura de Microapps (Monorepo con Melos)

El sistema ya no será un proyecto monolítico, sino un **Monorepo** dividido en paquetes locales (`packages`). 

### 3.1 Estructura de Directorios

```text
saas_system_guri/
├── melos.yaml                  # Configuración del monorepo
├── pubspec.yaml                # Dependencias globales de tooling
├── apps/
│   ├── shell_app/              # App principal, importa los submódulos e inicializa el sistema.
├── core/                       # Paquetes transversales (No dependen de ningún feature)
│   ├── core_network/           # Configuración de Supabase, clientes HTTP, interceptores.
│   ├── core_ui/                # Design System: Botones, colores, tipografías, widgets compartidos.
│   ├── core_utils/             # Extensiones, formateadores de fecha/moneda.
│   └── core_auth/              # Lógica de autenticación, sesión y token del tenant.
└── features/                   # Las "Microapps" independientes (Dependen de core, pero no entre sí)
    ├── feature_menu_qr/        # Flujo del cliente final escaneando el QR.
    ├── feature_cocina/         # Interfaz para los cocineros (Kanban de pedidos).
    ├── feature_admin/          # Panel de administración del restaurante.
    ├── feature_pos/            # Punto de venta y cobro.
    └── feature_billing/        # (SaaS) Gestión de la suscripción del tenant (pagos).
```

### 3.2 Reglas de Dependencia
1. **Regla de Oro:** Un `feature_X` **NUNCA** debe depender de `feature_Y`.
2. Todos los `features` pueden depender de los paquetes en `core/`.
3. `apps/shell_app` es el único paquete que importa todos los `features` para ensamblarlos a través de GoRouter y GetIt.

---

## 4. Diseño del Sistema Multi-Tenant (SaaS)

El cambio más grande respecto a Firebase es aislar los datos de cada cliente (restaurante).

### 4.1 Estrategia de Base de Datos (Supabase / PostgreSQL)
Utilizaremos el enfoque de **Esquema Único con Separación Lógica (Row Level Security - RLS)**. 
Cada tabla tendrá una columna `tenant_id`.

```sql
-- Ejemplo de tabla genérica
CREATE TABLE productos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id), -- Identificador del restaurante
    nombre VARCHAR(150) NOT NULL,
    precio NUMERIC(10, 2) NOT NULL
);

-- Políticas de Seguridad de Supabase (RLS)
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Aislamiento por Tenant" ON productos
    FOR ALL
    USING (tenant_id = auth.jwt() ->> 'tenant_id');
```
*Ventaja:* El código Flutter no necesita enviar explícitamente el `tenant_id` en cada petición. Supabase extrae el ID del restaurante directamente del token JWT del usuario logueado.

### 4.2 Arquitectura de Suscripciones (SaaS Billing)
Existirá una tabla `tenants` y `subscriptions`:
* Cuando un restaurante no paga su suscripción, su estado pasa a `suspendido`.
* Supabase RLS rechazará cualquier intento de escritura/lectura si el tenant está suspendido, protegiendo todo el sistema sin tocar código frontend.

---

## 5. Implementación de Navegación Modular (GoRouter)

Al usar microapps, las rutas no deben estar centralizadas en un solo archivo inmenso. Cada `feature` debe exportar sus propias rutas.

**En `feature_admin/routes.dart`:**
```dart
class AdminRoutes {
  static final routes = [
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'mesas',
          builder: (context, state) => const MesasManagerScreen(),
        ),
      ]
    ),
  ];
}
```

**En `apps/shell_app/router.dart` (El ensamblador):**
```dart
final router = GoRouter(
  routes: [
    ...AuthRoutes.routes,
    ...MenuQrRoutes.routes,
    ...AdminRoutes.routes,
    ...CocinaRoutes.routes,
  ],
);
```

---

## 6. Estado Compartido e Inyección (GetIt + Riverpod)

### 6.1 Inyección de Dependencias (GetIt)
Usaremos GetIt para proveer repositorios de Supabase a los diferentes features. Igual que el enrutamiento, cada feature registra sus dependencias.

```dart
// En el módulo core_network
final GetIt locator = GetIt.instance;

// En feature_admin/injection.dart
void setupAdminDependencies() {
  locator.registerLazySingleton<MesasRepository>(
    () => SupabaseMesasRepository(locator<SupabaseClient>())
  );
}
```

### 6.2 Gestión de Estado (Riverpod)
Riverpod manejará la lógica de la UI (Cargar, Éxito, Error) sin contaminar la vista. 
En Flutter, el flujo ideal es:
`UI (Widget) ➔ Riverpod (Notifier/Provider) ➔ GetIt (UseCase/Repository) ➔ Supabase`

---

## 7. Estrategia de Flujo de Trabajo (CI/CD)

Gracias a **Melos**, resolver los problemas de despliegues lentos es sencillo.
En Github Actions (o Gitlab CI), ejecutaremos los tests y builds **solo de los paquetes que han cambiado**, en lugar de construir toda el app gigante.

Comandos clave de Melos para el equipo:
* `melos bootstrap`: Descarga e instala dependencias de todos los micro-paquetes a la vez.
* `melos run test:changed`: Corre los tests solo de los paquetes modificados en el último commit.
* `melos format`: Aplica el linter a todo el monorepo asegurando que todos los desarrolladores escriban código con el mismo formato.

---

## 8. Plan de Acción (Siguientes Pasos)

1. **Configuración Inicial:**
   - Inicializar repositorio Flutter vacío.
   - Instalar Melos (`dart pub global activate melos`).
   - Crear la estructura de carpetas (`apps`, `core`, `features`).
2. **Definición Core:**
   - Configurar `core_ui` (colores principales, botones base).
   - Configurar `core_network` (Conexión a Supabase).
3. **Migración Base de Datos:**
   - Crear el esquema Postgres en Supabase según el documento `MIGRACION_POSTGRES_SCHEMA.md`.
   - Activar RLS (Row Level Security) asociado a Tenant ID.
4. **Desarrollo por Microapps:**
   - Empezar por el `feature_auth` (Logins y selección de restaurante).
   - Continuar con `feature_menu_qr` (Lectura pura de datos).
   - Abordar `feature_cocina` y `feature_admin`.
