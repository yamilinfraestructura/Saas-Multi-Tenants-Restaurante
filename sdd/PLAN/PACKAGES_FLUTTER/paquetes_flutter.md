# Análisis y Decisión de Paquetes Flutter — SaaS Multi-Tenant

> **Tipo de documento:** Decisiones técnicas de dependencias  
> **Última revisión:** 2026-06-04  
> **Estado:** Aprobado para Fase 1

---

## 🔍 Metodología de Análisis

Cada paquete fue evaluado contra tres criterios:
1. **¿Es relevante para el sistema de restaurantes?**
2. **¿Entra en conflicto con otra dependencia ya elegida?**
3. **¿Es necesario en Fase 1 o puede diferirse?**

**Leyenda de decisiones:**
- ✅ `INCLUIR` — Confirmado para el proyecto
- ⏳ `DIFERIR` — Válido pero no en Fase 1
- ❌ `ELIMINAR` — Innecesario, duplicado o conflictivo
- ⚠️ `REEMPLAZAR` — Existe una alternativa mejor

---

## 🚫 Decisión sobre GetX vs Riverpod

Esta es la decisión más importante del documento. **La respuesta corta: NO usar GetX junto a Riverpod.**

### ¿Por qué no GetX en una arquitectura de Microapps?

GetX es un framework monolítico que unifica routing + state + DI en un solo paquete. Esto es exactamente lo opuesto a lo que necesita una arquitectura modular con Melos:

| Problema de GetX | Impacto en nuestro Monorepo |
| :--- | :--- |
| `Get.put()` y `Get.find()` usan singletons globales | Un feature puede accidentalmente acceder al estado de otro módulo. Rompe el aislamiento. |
| El routing de GetX es global y centralizado | Imposible exportar rutas modulares desde cada microapp. Conflicto directo con GoRouter. |
| `GetxController` no es compilación-segura | Errores de "controller not found" solo aparecen en runtime, no en compilación. |
| Estado de GetX no es testeable sin la app completa | Los tests unitarios de una microapp dependerían del estado global de GetX. |

### La alternativa: Riverpod + GetIt + GoRouter

Cada uno reemplaza una pieza de GetX, pero de forma desacoplada:

```
GetX todo-en-uno           →    Nuestra arquitectura modular
───────────────────────────────────────────────────
Get.put() / Get.find()     →    get_it (Service Locator)
GetxController / Obx       →    flutter_riverpod (StateNotifier/AsyncNotifier)
Get.to() / GetMaterialApp  →    go_router (Navegación declarativa)
GetX utils / extensions    →    dart nativo + utils propios
```

### ¿Y si el equipo prefiere la ergonomía de GetX?

Si hay familiaridad con GetX, el puente mental es directo:

| GetX | Equivalente en Riverpod |
| :--- | :--- |
| `GetxController` | `StateNotifier` / `AsyncNotifier` |
| `Obx(() => ...)` | `Consumer` / `ref.watch()` |
| `Get.put(MyController())` | `locator.registerLazySingleton<MyRepo>()` en GetIt |
| `Get.to('/ruta')` | `context.go('/ruta')` en GoRouter |
| `Get.find<MyController>()` | `locator<MyRepo>()` en GetIt |
| `RxString` / `.obs` | `StateProvider<String>` en Riverpod |

**Conclusión: Eliminar `get: ^4.7.3` del proyecto.**

> ⚠️ **Importante:** No confundir `get` (GetX) con `get_it` (Service Locator). Son paquetes completamente diferentes. Vamos a usar `get_it`, NO `get`.

---

## 📦 Tabla de Decisión de Paquetes

### Dependencias Principales (pubspec.yaml → dependencies)

| Paquete | Versión | Decisión | Justificación |
| :--- | :--- | :--- | :--- |
| `supabase_flutter` | `^2.12.0` | ✅ INCLUIR | Cliente principal. Incluye Auth, Realtime y Storage. |
| `flutter_riverpod` | `^2.6.0` | ✅ INCLUIR | Gestión de estado principal. Reemplaza GetX. |
| `riverpod_annotation` | `^2.6.0` | ✅ INCLUIR | Anotaciones para generación de código con Riverpod. |
| `get_it` | `^8.0.0` | ✅ INCLUIR | Service Locator para inyección de dependencias. ≠ GetX. |
| `go_router` | `^14.0.0` | ✅ INCLUIR | Navegación declarativa y modular. |
| `google_fonts` | `^6.2.1` | ✅ INCLUIR | Fuente Inter (definida en el design system). |
| `font_awesome_flutter` | `^10.7.0` | ✅ INCLUIR | Iconografía del sistema (definido en design system). |
| `intl` | `^0.19.0` | ✅ INCLUIR | Fechas, monedas y localización en español. |
| `flutter_localizations` | SDK | ✅ INCLUIR | Integrado con Flutter SDK, habilita localización. |
| `cached_network_image` | `^3.4.1` | ✅ INCLUIR | Cache de imágenes de productos (Cloudinary/Supabase Storage). |
| `flutter_dotenv` | `^5.2.1` | ✅ INCLUIR | Variables de entorno (.env) para URL de Supabase. |
| `flutter_secure_storage` | `^9.2.4` | ✅ INCLUIR | Almacenamiento seguro del JWT y tokens sensibles. |
| `shared_preferences` | `^2.3.2` | ✅ INCLUIR | Preferencias ligeras (tema, último tenant, etc.). |
| `connectivity_plus` | `^6.1.4` | ✅ INCLUIR | Detectar estado de red. Crítico para app offline-aware. |
| `permission_handler` | `^12.0.1` | ✅ INCLUIR | Permisos de cámara y ubicación (geofencing). |
| `image_picker` | `^1.1.2` | ✅ INCLUIR | Subir fotos de productos desde galería/cámara. |
| `google_maps_flutter` | `^2.9.0` | ✅ INCLUIR | Mapa para configurar el geofencing del negocio. |
| `location` | `^7.0.0` | ✅ INCLUIR | Obtener ubicación del dispositivo para geofencing. |
| `flutter_local_notifications` | `^18.0.0` | ✅ INCLUIR | Notificaciones locales (pedido listo, alerta de stock). |
| `firebase_core` | `^3.13.0` | ✅ INCLUIR | Requerido por FCM para push notifications. Solo esto. |
| `firebase_messaging` | `^15.2.5` | ✅ INCLUIR | Push Notifications (nuevo pedido, cuenta solicitada). |
| `url_launcher` | `^6.3.1` | ✅ INCLUIR | Abrir links, email o teléfono desde la app. |
| `app_links` | `^6.3.2` | ✅ INCLUIR | Deep links desde QR codes (`/menu/sala/mesa`). |
| `share_plus` | `^10.1.4` | ✅ INCLUIR | Compartir PDF de reportes o ticket de pedido. |
| `path_provider` | `^2.1.5` | ✅ INCLUIR | Acceso al sistema de archivos (para PDFs y cache). |
| `path` | `^1.9.1` | ✅ INCLUIR | Manipulación de rutas de archivos. |
| `freezed_annotation` | `^2.4.4` | ✅ INCLUIR | Modelos inmutables (DTOs, estados de Riverpod). |
| `json_annotation` | `^4.9.0` | ✅ INCLUIR | Serialización JSON de modelos. |
| `flutter_native_splash` | `^2.4.3` | ✅ INCLUIR | Splash screen nativo. |
| `smooth_page_indicator` | `^1.2.0+3` | ⏳ DIFERIR | Solo para onboarding. Agregar cuando se diseñe ese flujo. |
| `local_auth` | `^2.3.0` | ⏳ DIFERIR | Biometría para login. Útil para admin en tablet. Fase 2. |
| `in_app_purchase` | `^3.2.0` | ⏳ DIFERIR | B2B SaaS: los pagos se gestionan desde el web admin. Fase 2. |
| `purchases_flutter` | `^10.0.1` | ⏳ DIFERIR | RevenueCat. Evaluar solo si se hace billing in-app. Fase 2. |
| `purchases_ui_flutter` | `^10.0.1` | ⏳ DIFERIR | UI de RevenueCat. Junto con el anterior. Fase 2. |
| `flutter_colorpicker` | `^1.1.0` | ⏳ DIFERIR | Solo si se permite personalización del tema por tenant. Fase 2. |
| `get` | `^4.7.3` | ❌ ELIMINAR | GetX. Reemplazado totalmente por Riverpod + GetIt + GoRouter. |
| `supabase_auth` | `^2.6.0` | ❌ ELIMINAR | No existe como paquete separado. Auth está incluido en `supabase_flutter`. |
| `flutter_fa` | `^2.0.0` | ❌ ELIMINAR | Nombre incorrecto/inexistente. Reemplazado por `font_awesome_flutter`. |
| `bluebird` | `^1.3.0` | ⚠️ REEMPLAZAR | No existe en pub.dev. Ver alternativa de impresión abajo. |
| `drift_dev` | `^2.40.0` | ❌ ELIMINAR | ORM para SQLite local. No necesario: usamos Supabase online. |
| `drift_common` | `^2.40.0` | ❌ ELIMINAR | Ídem anterior. |
| `sqflite` | `^2.4.2` | ❌ ELIMINAR | Si usamos Supabase Realtime, no necesitamos DB local. |
| `just_audio` | `^0.9.40` | ❌ ELIMINAR | Reproducción de audio. No aplica a un sistema de restaurante. |
| `audio_service` | `^0.18.12` | ❌ ELIMINAR | Audio en background. No aplica. |
| `just_audio_background` | `^0.0.1-beta.17` | ❌ ELIMINAR | Ídem. |
| `video_player` | `^2.9.2` | ❌ ELIMINAR | Reproductor de video. No aplica. |
| `dio` | `^5.9.0` | ❌ ELIMINAR | Supabase maneja HTTP internamente. Redundante. |

---

### Dependencias de Desarrollo (pubspec.yaml → dev_dependencies)

| Paquete | Versión | Decisión | Justificación |
| :--- | :--- | :--- | :--- |
| `riverpod_generator` | `^2.6.0` | ✅ INCLUIR | Genera providers de Riverpod desde anotaciones. |
| `freezed` | `^2.5.7` | ✅ INCLUIR | Genera modelos inmutables (copyWith, equality, etc.). |
| `json_serializable` | `^6.8.0` | ✅ INCLUIR | Genera `fromJson`/`toJson` para los modelos. |
| `build_runner` | `^2.4.13` | ✅ INCLUIR | Motor de generación de código para Freezed + Riverpod. |
| `flutter_launcher_icons` | `^0.14.4` | ✅ INCLUIR | Generar ícono de la app en todas las plataformas. |
| `flutter_native_splash` | `^2.4.3` | ✅ INCLUIR | Config en dev_dependencies para la generación del splash. |

---

### ⚠️ Paquete de Impresión Térmica (Reemplazar `bluebird`)

`bluebird` no existe en pub.dev. Para la impresión de comandas/tickets en impresoras térmicas (ESC/POS):

| Paquete | Descripción |
| :--- | :--- |
| `esc_pos_utils_plus` | Generación de comandos ESC/POS para impresoras térmicas. |
| `flutter_thermal_printer` | Conexión Wi-Fi/BT con impresoras. Recomendado como alternativa moderna. |

**Decisión:** Agregar `esc_pos_utils_plus` como dependencia en Fase 1 (está en el schema `CONFIG_IMPRESORAS`). La conexión a la impresora física se implementa en Fase 2.

---

## 📋 pubspec.yaml Consolidado (Fase 1)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # ── BACKEND & AUTH ─────────────────────────────────
  supabase_flutter: ^2.12.0          # Cliente Supabase (Auth + DB + Realtime + Storage)
  firebase_core: ^3.13.0             # Requerido solo para FCM
  firebase_messaging: ^15.2.5        # Push notifications

  # ── ESTADO & NAVEGACIÓN ────────────────────────────
  flutter_riverpod: ^2.6.0           # Gestión de estado
  riverpod_annotation: ^2.6.0        # Anotaciones para code gen
  get_it: ^8.0.0                     # Service Locator / DI (≠ GetX)
  go_router: ^14.0.0                 # Navegación declarativa modular

  # ── UI & DISEÑO ────────────────────────────────────
  google_fonts: ^6.2.1               # Fuente Inter
  font_awesome_flutter: ^10.7.0      # Iconografía del design system
  cached_network_image: ^3.4.1       # Cache de imágenes de productos
  flutter_native_splash: ^2.4.3      # Splash screen

  # ── LOCALIZACIÓN ───────────────────────────────────
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

  # ── ALMACENAMIENTO & SEGURIDAD ─────────────────────
  flutter_secure_storage: ^9.2.4     # JWT y tokens sensibles
  shared_preferences: ^2.3.2         # Preferencias del usuario
  flutter_dotenv: ^5.2.1             # Variables de entorno

  # ── PERMISOS & MEDIA ───────────────────────────────
  permission_handler: ^12.0.1        # Permisos de cámara/ubicación
  image_picker: ^1.1.2               # Subir fotos de productos

  # ── GEOFENCING ─────────────────────────────────────
  google_maps_flutter: ^2.9.0        # Mapa para configurar geofencing
  location: ^7.0.0                   # Ubicación del dispositivo

  # ── NOTIFICACIONES ─────────────────────────────────
  flutter_local_notifications: ^18.0.0

  # ── NETWORKING & UTILS ─────────────────────────────
  connectivity_plus: ^6.1.4          # Estado de red
  url_launcher: ^6.3.1               # Abrir URLs, email, teléfono
  app_links: ^6.3.2                  # Deep links / QR code links
  share_plus: ^10.1.4                # Compartir reportes/tickets
  path_provider: ^2.1.5
  path: ^1.9.1

  # ── MODELOS ────────────────────────────────────────
  freezed_annotation: ^2.4.4        # Modelos inmutables
  json_annotation: ^4.9.0           # Serialización JSON

  # ── IMPRESIÓN ──────────────────────────────────────
  esc_pos_utils_plus: ^3.1.0         # Comandos ESC/POS para tickets

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.0
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.3      # Config de splash (también en dev)
```

---

## 📦 Paquetes Diferidos (Backlog Fase 2)

Estos paquetes son válidos para el proyecto pero **no forman parte del MVP**.

| Paquete | Caso de uso futuro |
| :--- | :--- |
| `smooth_page_indicator` | Pantalla de onboarding para nuevos tenants |
| `local_auth` + plataformas | Login biométrico para admin en tablet |
| `in_app_purchase` | Billing in-app si se abre a consumidores directos |
| `purchases_flutter` | RevenueCat para gestión de suscripciones móviles |
| `flutter_colorpicker` | Personalización de tema/colores por tenant |
| `flutter_thermal_printer` | Conexión física a impresoras (Fase 2 de impresión) |
