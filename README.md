# SaaS System Guri 🍽️

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![Architecture](https://img.shields.io/badge/Architecture-Monorepo%20(Melos)-blue)

**SaaS System Guri** es una plataforma integral multi-tenant diseñada para la gestión moderna de restaurantes, bares y establecimientos gastronómicos. Desarrollada con **Flutter** y respaldada por **Supabase**, ofrece una solución robusta y escalable bajo un modelo de Software as a Service (SaaS).

---

## ✨ Características Principales

El sistema está compuesto por múltiples módulos independientes (Microapps) que cubren todas las necesidades operativas de un restaurante:

*   📱 **Menú QR Cliente (`feature_menu_qr`):** Interfaz pública optimizada para que los comensales exploren el menú desde sus dispositivos.
*   🔥 **Panel de Cocina/Bar (`feature_cocina`):** Vista Kanban en tiempo real para la gestión eficiente de pedidos activos.
*   ⚙️ **Panel de Administración (`feature_admin`):** Gestión completa del negocio, incluyendo ABM de menú, control de mesas, usuarios, roles y configuración general.
*   🧾 **Punto de Venta (POS) y Cobros (`feature_pos`):** Gestión de cuentas de mesas, cobros y flujos de caja.
*   💳 **Gestión SaaS (`feature_billing`):** Administración de suscripciones, pagos y estado de la cuenta del restaurante (Tenant).

---

## 🏗️ Arquitectura y Tecnologías

El proyecto adopta una arquitectura de **Microapps en Monorepo**, gestionada mediante **Melos**. Esto garantiza el aislamiento del código, previene conflictos entre equipos y mejora drásticamente los tiempos de CI/CD.

### Tech Stack

*   **Frontend:** Flutter (Soporte multiplataforma: Web, iOS, Android).
*   **Backend & Base de Datos:** Supabase (PostgreSQL) con **Row Level Security (RLS)** para un aislamiento seguro de los datos de cada Tenant.
*   **Gestión de Monorepo:** Melos.
*   **Estado e Inyección de Dependencias:** Flutter Riverpod + GetIt.
*   **Enrutamiento:** GoRouter (Navegación modular y declarativa).

---

## 📂 Estructura del Proyecto

```text
saas_system_guri/
├── apps/
│   └── shell_app/          # Aplicación principal que ensambla todos los módulos.
├── core/                   # Paquetes transversales (comunes a todos los módulos).
│   ├── core_network/       # Configuración de Supabase y clientes HTTP.
│   ├── core_ui/            # Design System compartido (UI, temas, assets).
│   ├── core_utils/         # Extensiones y utilidades.
│   └── core_auth/          # Lógica de autenticación y sesión de tenant.
├── features/               # Microapps independientes.
│   ├── feature_menu_qr/
│   ├── feature_cocina/
│   ├── feature_admin/
│   ├── feature_pos/
│   └── feature_billing/
├── sdd/                    # Software Design Documents (Documentación técnica detallada).
└── supabase/               # Configuración local, migraciones y edge functions de Supabase.
```

---

## 🚀 Getting Started

### Prerrequisitos

Asegúrate de tener instalados los siguientes componentes en tu entorno local:

1.  [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión estable actual).
2.  [Dart SDK](https://dart.dev/get-dart).
3.  [Melos](https://melos.invertase.dev/) (`dart pub global activate melos`).
4.  [Supabase CLI](https://supabase.com/docs/guides/cli) (para desarrollo local de backend).

### Instalación y Ejecución

1.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/tu-organizacion/saas_system_guri.git
    cd saas_system_guri
    ```

2.  **Configurar Variables de Entorno:**
    Copia el archivo de ejemplo y configura tus credenciales locales/remotas:
    ```bash
    cp .env.example .env
    ```
    *Edita el archivo `.env` con las URL y Keys correctas de Supabase.*

3.  **Instalar dependencias del Monorepo:**
    Utiliza Melos para sincronizar e instalar los paquetes de todos los módulos:
    ```bash
    melos bootstrap
    ```

4.  **Generar Código (Freezed, Riverpod, etc.):**
    Si hay cambios en los modelos o providers, ejecuta el build runner en todo el proyecto:
    ```bash
    melos run build:all
    ```

5.  **Ejecutar la App Principal:**
    Dirígete a la aplicación shell e inicializa Flutter:
    ```bash
    cd apps/shell_app
    flutter run -d chrome  # O el dispositivo de tu preferencia
    ```

---

## 📚 Documentación

La documentación técnica exhaustiva del sistema, esquemas de bases de datos, políticas de seguridad (RLS), webhooks, triggers y lineamientos de UI se encuentran en el directorio `sdd/`.

Recomendamos leer el documento principal de arquitectura antes de comenzar a desarrollar:
👉 **[Documento de Arquitectura Flutter (SDD)](sdd/PLAN/INICIO_ENTRADA/sdd_arquitectura_flutter.md)**

---

## 🔒 Seguridad y Pre-commits

Este repositorio cuenta con un hook de **pre-commit** basado en `detect-secrets` para prevenir la filtración accidental de claves y variables de entorno. Asegúrate de ejecutar `detect-secrets scan > .secrets.baseline` si modificas la estructura de archivos sensibles y darle permisos de ejecución al hook:
```bash
chmod +x .git/hooks/pre-commit
```
