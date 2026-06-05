# SDD UX - Experiencia de Usuario Multi-Tenant
**Directorio:** `sdd/PLAN/UX/MULTI_TENNET_UX/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Este documento define la experiencia de usuario (UX) central del modelo SaaS Multi-Tenant. Aborda cómo un usuario interactúa con el sistema dependiendo de a qué restaurante (Tenant) pertenece y cómo se maneja la transición entre diferentes contextos de negocio.

## 2. Flujo de Identificación del Tenant (Restaurante)

A diferencia del proyecto React original, en Flutter Web/Mobile la identificación del Tenant se maneja de forma híbrida:

### 2.1 Flujo Público (Cliente que escanea QR)
- **Deep Links (App Links):** El cliente escanea un QR físico en la mesa.
- **Ruta:** `https://app.guri.com/menu/:tenant_slug/:sala_id/:mesa_id`
- **UX:** El sistema detecta el `tenant_slug`, hace fetch del `logo` y `colores` del Tenant desde Supabase y adapta el tema visual de la app en **menos de 500ms**. Se muestra un `SkeletonLoader` con el layout del menú mientras cargan los productos.

### 2.2 Flujo Privado (Personal / Admin)
- **Login Unificado:** El empleado ingresa a la app genérica (`/login`).
- **Resolución de Tenant:** Al autenticarse, Supabase devuelve en el JWT el `tenant_id` al que pertenece el usuario.
- **Redirección Automática:** El sistema inyecta el `tenant_id` en las cabeceras (mediante un Interceptor o global state de Riverpod) y redirige al dashboard correspondiente según el rol del usuario (Ej. Mozo va a `/mesas`, Admin va a `/admin`).

## 3. Estados de Suscripción (Billing UX)

La experiencia del usuario cambia drásticamente si el restaurante no ha pagado su suscripción:

| Estado del Tenant | Experiencia UX (Admin) | Experiencia UX (Cliente QR) |
|-------------------|-------------------------|-----------------------------|
| **Activo** | Acceso total. | Acceso al menú y pedidos. |
| **Suspendido** | Bloqueo tipo "Soft Wall". Aparece un modal a pantalla completa pidiendo renovar la suscripción. Solo puede navegar a la sección de pagos (`feature_billing`). | Redirección a pantalla de "Servicio Temporalmente No Disponible" con logo genérico. |
| **Inactivo** | Login bloqueado. Mensaje de error: "Cuenta desactivada. Contacte soporte". | Error 404 estético. |

## 4. Personalización del Tenant (White-label)

Para dar la sensación de que el restaurante tiene "su propia app":
1. **Dynamic Theming (Riverpod):** Se usará un `ThemeProvider` que escuche los datos del `configuracion_negocio`.
2. **Logo y Branding:** El Drawer y el AppBar mostrarán siempre el `logo_url` del restaurante.
3. **Tipografía:** Se mantiene `Inter` como estándar para asegurar legibilidad, pero los colores primarios se extraen de la configuración del Tenant.

## 5. Arquitectura de Estado UX (Flutter)
- En Flutter, el cambio de Tenant o la invalidación de la sesión se maneja observando el estado de autenticación.
- Al hacer *logout* o cambiar de estado (ej: Suspensión), Riverpod invalidará los providers dependientes (`ref.invalidate()`), lo que forzará a GoRouter a redirigir al usuario al `/login` de forma reactiva y fluida, sin necesidad de llamadas imperativas como `Navigator.push()`.
