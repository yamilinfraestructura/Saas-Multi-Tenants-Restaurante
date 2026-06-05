# Índice Maestro de Diseño de Software (SDD)
**Directorio:** `sdd/PLAN/`  
**Proyecto:** SaaS System Guri (Flutter + Supabase)

---

## 🧭 ¿Cómo leer esta documentación?
Si eres un agente de IA encargado de ejecutar este desarrollo, **DEBES** leer los documentos en el orden estructurado a continuación antes de escribir código. El proyecto utiliza un monorepo (Melos), arquitectura de microapps, Riverpod, GoRouter, y Supabase (con RLS riguroso).

---

## 1. Visión General y Arquitectura
Aquí se define el porqué de la migración, la estructura del monorepo y las dependencias permitidas.
*   📄 `sdd/PLAN/INICIO_ENTRADA/migracion_a_nuevo_sistema.md` (Contexto general).
*   📄 `sdd/PLAN/INICIO_ENTRADA/sdd_arquitectura_flutter.md` (**CRÍTICO**: Define la arquitectura de Microapps y Melos).
*   📄 `sdd/PLAN/PACKAGES_FLUTTER/paquetes_flutter.md` (Lista exhaustiva de paquetes permitidos. Prohíbe GetX).

---

## 2. Base de Datos y Backend (Supabase)
Todo el ecosistema de Postgres. Debes ejecutar esto en el SQL Editor de Supabase antes de tocar código Flutter.
*   **Schemas y Tablas:**
    *   🗄️ `sdd/PLAN/BASE_DE_DATOS/SCHEMAS/01_saas_core_schema.sql`
    *   🗄️ `sdd/PLAN/BASE_DE_DATOS/SCHEMAS/02_roles_modulos_permisos_schema.sql`
    *   🗄️ `sdd/PLAN/BASE_DE_DATOS/SCHEMAS/03_operaciones_negocio_schema.sql`
    *   🗄️ `sdd/PLAN/BASE_DE_DATOS/SCHEMAS/04_reservas_configuracion_schema.sql`
*   **Seguridad y Lógica:**
    *   🔒 `sdd/PLAN/BASE_DE_DATOS/RLS/01_rls_policies.sql` (Políticas de aislamiento Tenant).
    *   ⚙️ `sdd/PLAN/BASE_DE_DATOS/BACKEND/01_funciones_backend.sql` (Funciones RPC y JWT Hooks).
    *   ⚡ `sdd/PLAN/BASE_DE_DATOS/TRIGGERS/sdd_triggers.md` (Lógica transaccional automatizada).
    *   🌐 `sdd/PLAN/BASE_DE_DATOS/WEB_HOOKS/sdd_webhooks.md` (Edge functions y notificaciones push).
    *   📦 `sdd/PLAN/BASE_DE_DATOS/STORAGE/sdd_storage.md` (Buckets e imágenes).

---

## 3. Arquitectura de Estado y Servicios (Flutter)
Define la capa de conexión entre Supabase y la UI usando Riverpod y GetIt.
*   📄 `sdd/PLAN/PROVIDERS_AND_SERVICES/SUPABASE_CONTROLLERS/sdd_supabase_controllers.md` (Patrón Repositorio y StreamProviders).
*   📄 `sdd/PLAN/PROVIDERS_AND_SERVICES/AUTH_CONTROLLERS/sdd_auth_controllers.md` (Redirección reactiva por AuthState).
*   📄 `sdd/PLAN/PROVIDERS_AND_SERVICES/STYLE_CONTROLLERS/sdd_style_controllers.md` (Theming dinámico por Tenant).

---

## 4. Experiencia de Usuario (UX)
Reglas de interacción, flujos asíncronos y soporte táctil vs escritorio.
*   📄 `sdd/PLAN/UX/MULTI_TENNET_UX/sdd_multi_tenant_ux.md` (Cambios de contexto entre restaurantes).
*   📄 `sdd/PLAN/UX/LOGIN_UX/sdd_login_ux.md` (Flujos sin parpadeos y animaciones de error).
*   📄 `sdd/PLAN/UX/ADMIN_SCREEN_UX/sdd_admin_ux.md` (Uso de SlideOvers y DataTables).
*   📄 `sdd/PLAN/UX/MESAS_UX/sdd_mesas_ux.md` (Reglas táctiles para la operativa rápida del salón).

---

## 5. Interfaz de Usuario (UI)
Estructura y reglas para los Widgets de Flutter.
*   📄 `sdd/PLAN/UI/themes/themes_color_font.md` (Paleta base y tipografía Inter).
*   📄 `sdd/PLAN/UI/LAYOUTS/sdd_layouts.md` (ShellRoutes y breakpoints responsivos).
*   📄 `sdd/PLAN/UI/SCREENS_VIEWS/sdd_screens_views.md` (Diferencia estructural entre Screen y View).
*   📄 `sdd/PLAN/UI/COMPONENTS/sdd_components.md` (Widgets core compartidos).
*   📄 `sdd/PLAN/UI/ALERTS/sdd_alerts.md` (Uso correcto de SnackBars, Dialogs y Banners).

---

## ✅ Plan de Ejecución
El documento maestro para rastrear el progreso de desarrollo.
*   📋 `sdd/CHECK_LIST.md` (Utiliza este archivo para marcar el progreso Fase por Fase).

---

## 🛠️ Comandos Útiles del Proyecto
*   **Supabase CLI:** `supabase status` (estado de conexión), `supabase db pull` (sincronizar tipos remotos).
*   **Melos (Monorepo):** `melos bootstrap` (instala todas las dependencias), `melos run build:all` (ejecuta build_runner en todo el ecosistema).
*   **Secretos:** El proyecto contiene un `.git/hooks/pre-commit` con `detect-secrets`. NUNCA hacer commit de variables en duro.
