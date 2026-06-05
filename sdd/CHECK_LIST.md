# Check List de Ejecución - SaaS System Guri
**Directorio:** `/sdd/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## FASE 1: Preparación del Entorno Backend (Supabase)

Esta fase debe ejecutarse íntegramente en el SQL Editor de Supabase.

### 1. Esquemas Base de Datos (Schemas)
- [x] Ejecutar `01_saas_core_schema.sql` (Tenants y Suscripciones)
- [x] Ejecutar `02_roles_modulos_permisos_schema.sql` (Roles y Asignaciones)
- [x] Ejecutar `03_operaciones_negocio_schema.sql` (Productos, Mesas, Pedidos)
- [x] Ejecutar `04_reservas_configuracion_schema.sql` (Reservas y Config de Negocio)

### 2. Seguridad (Row Level Security - RLS)
- [x] Ejecutar `01_rls_policies.sql` para habilitar el aislamiento por Tenant.

### 3. Triggers y Funciones Utilitarias
- [x] Crear tabla `audit_log` para registro de auditoría.
- [x] Crear función `set_updated_at()` y `set_fecha_actualizacion()`.
- [x] Crear triggers de Timestamps (`trg_tenants_updated_at`, `productos`, `categorias`).
- [x] Crear triggers de Suscripción (`trg_suscripcion_actualiza_tenant`, `trg_suscripcion_vencida_suspende`).
- [x] Crear triggers de Operativa (`trg_pedido_actualiza_mesa`, `trg_pedido_completado_libera_mesa`, `trg_pedido_items_actualiza_total`, `trg_stock_descuenta_al_pedir`).
- [x] Crear triggers de Reservas (`trg_reserva_bloquea_mesa`, `libera_mesa`, `incrementa_contador`, `decrementa_contador`, `numero_autoincrement`).
- [x] Crear triggers de Auditoría (`trg_audit_pedidos`, `trg_audit_tenants`).

### 4. Funciones Backend (RPC y Auth Hooks)
- [x] Ejecutar `01_funciones_backend.sql` para inyección de JWT.
- [x] Crear función `custom_access_token_hook()` para inyectar `tenant_id` y `rol` en la sesión de Supabase Auth.
- [ ] Configurar el hook en el Dashboard de Supabase (Authentication -> Hooks -> Custom Access Token).

### 5. Configuración de Storage
- [x] Crear bucket `tenant_logos` (Público).
- [x] Crear bucket `productos` (Público).
- [x] Crear bucket `avatars` (Público/Privado).
- [x] Aplicar políticas RLS descritas en `sdd_storage.md` para evitar escrituras de otros tenants.

### 6. Configuración de Webhooks y Edge Functions
- [x] Desplegar Edge Function `notify-nuevo-pedido`.
- [x] Desplegar Edge Function `notify-estado-pedido`.
- [x] Configurar los webhooks en el Dashboard atados a la tabla `pedidos`.

> **Observaciones FASE 1 — pendientes para cierre final (post-Fase 4):**
>
> 1. **Auth Hook (Dashboard):** Activar `custom_access_token_hook` en *Authentication → Hooks → Custom Access Token*. Sin esto, el JWT no incluirá `tenant_id` / `nivel_acceso` y el RLS del frontend fallará en runtime.
> 2. **Firebase / FCM:** Configurar proyecto Firebase y registrar el secret `FCM_SERVER_KEY` en *Edge Functions → Secrets* del Dashboard. Sin esto, las push notifications de `notify-nuevo-pedido` y `notify-estado-pedido` responden OK pero envían `push_sent: 0`.
> 3. **Migraciones versionadas:** SQL aplicado vía `supabase/migrations/` (01–11). Helpers RLS movidos a schema `public` por restricción de permisos en Supabase hosted (`auth.*` no permite funciones custom).
> 4. **Tabla auxiliar:** `usuario_fcm_tokens` creada para soportar el flujo FCM descrito en `sdd_webhooks.md` (Flutter hará upsert en Fase 3).

---

## FASE 2: Preparación del Entorno Frontend (Flutter Monorepo)

### 1. Estructura y Dependencias (Melos)
- [x] Asegurar que `pubspec.yaml` principal tiene las dependencias clave (`supabase_flutter`, `flutter_riverpod`, `go_router`, `get_it`).
- [x] Ejecutar `flutter pub get` en la raíz.
- [x] Configurar archivo `melos.yaml` con scripts básicos de test, build_runner y format.
- [x] Crear la estructura de carpetas de Monorepo: `apps/shell_app`, `core/`, `features/`.

### 2. Configuración Core (`core/`)
- [x] Crear `core_network` (Inicialización de Supabase con `flutter_dotenv`).
- [x] Crear `core_auth` (Proveedores de Riverpod descritos en `sdd_auth_controllers.md`).
- [x] Crear `core_ui` (Componentes base: Botones, ErrorBanner, ResponsiveLayout, ThemeProvider).
- [x] Crear enrutador principal en `apps/shell_app` usando GoRouter con soporte para redirección por Auth State.

---

## FASE 3: Desarrollo de Microapps (Features)

*Cada feature debe implementarse siguiendo el ciclo: Models -> Repositories (GetIt) -> Controllers (Riverpod) -> UI/Screens.*

### 1. Autenticación (`feature_auth`)
- [x] UI de Login genérica.
- [x] Conexión a `core_auth` para validar credenciales.
- [x] Redirección inteligente al escanear QR (`feature_menu_qr`).

### 2. Panel de Administración (`feature_admin`)
- [x] Implementar `AdminShellLayout` con Drawer lateral.
- [x] Pantalla ABM Menú y Categorías.
- [x] Pantalla ABM Mesas y Salas.
- [x] Pantalla ABM Usuarios (Personal del tenant).

### 3. Menú QR Cliente (`feature_menu_qr`)
- [x] Detección dinámica del tenant desde la URL.
- [x] Carga del tema visual (ThemeProvider).
- [x] Grilla de productos con agrupamiento por categorías.
- [x] Carrito de compras flotante y botón de "Pedir/Pagar".

### 4. Operativa de Salón y POS (`feature_pos` y `feature_cocina`)
- [x] Pantalla Vista Comedor (estado de mesas con colores).
- [x] Pantalla Toma de Comandas y Checkout de mesa.
- [x] Kanban de Cocina (StreamProvider conectando a Realtime Supabase).
- [x] Integración de impresión térmica local (solo Windows/Android).

---

## FASE 4: Pulido y Despliegue

### 1. Auditoría de Seguridad y UX
- [x] Comprobar que el `pre-commit` hook de secretos corre bien (`scripts/install-git-hooks.ps1` + `detect-secrets`).
- [x] Testear cambio de estado a "Suspendido" y verificar el bloqueo suave en el frontend (`SuspensionGate` + `/billing`).
- [x] Asegurar responsividad (Móvil vs Tablet/Web) en menú admin y kanban cocina.

### 2. Compilación y Despliegue
- [x] Build Web (`flutter build web`) para el Admin Panel → `apps/shell_app/build/web/`
- [x] Build Windows (`flutter build windows`) para el POS de caja local → `apps/shell_app/build/windows/`
- [x] Build Android (`flutter build apk`) para Mozos → `apps/shell_app/build/app/outputs/flutter-apk/app-release.apk`

> **Observaciones FASE 4 — pendientes manuales:**
>
> 1. **Auth Hook + FCM:** Ver observaciones Fase 1 (Dashboard Supabase).
> 2. **Migración 12:** Aplicar `20260605100012_public_menu_rpc.sql` al remoto si aún no se hizo.
> 3. **iOS:** `flutter build ios` requiere macOS + certificados Apple.
> 4. **Pagos reales:** Botón "Renovar suscripción" en `/billing` es placeholder (MercadoPago/Stripe en release posterior).

---

## FASE 5: Sprints de Detalle de Funcionalidades (Fase Actual)

Esta fase corresponde a la profundización y refinamiento de cada módulo. Basado en los SDD, aquí iremos construyendo la lógica fina.

### Sprint 1: Gestión de Salas y Generación de Códigos QR (`feature_admin`)
- [ ] Implementar UI Maestra-Detalle (`MesasManagerView` con pestañas de Salas).
- [ ] Implementar SlideOver/BottomSheet para ABM de Salas (Crear, Editar, Eliminar).
- [ ] Implementar SlideOver/BottomSheet para ABM de Mesas.
- [ ] Lógica de validación: Impedir nombre de mesa duplicado en una sala.
- [ ] Alerta de Cascada: Aviso visual al eliminar una sala (mesas huérfanas).
- [ ] Generación visual de QR en miniatura en cada mesa (`qr_flutter`).
- [ ] Descarga individual del QR en PDF o Imagen.
- [ ] Generador en lote (Batch): Botón para exportar el catálogo completo de QRs de una sala en un solo archivo PDF (`pdf` + `printing`).

### Sprint 2: Catálogo Vivo (Menú Cliente) (`feature_menu_qr`)
- [ ] Conexión de UI de cliente con URL paramétrica (`/:tenant_slug/:sala_id/:mesa_id`).
- [ ] Carrito de compras flotante (Riverpod Provider).
- [ ] Botón de "Pedir Cuenta" integrado al estado del pedido.

### Sprint 3: Operativa de Salón (`feature_pos` y `feature_cocina`)
- [ ] Vista del Comedor interactiva (Grid por colores según estado).
- [ ] Kanban drag-and-drop de comandas de cocina.
