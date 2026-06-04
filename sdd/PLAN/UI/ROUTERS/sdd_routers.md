# SDD - Routing (UI/ROUTERS)

## Propósito
Este documento describe la arquitectura de rutas del proyecto **SaaS System Guri**. Se basa en **GoRouter** y está optimizada para **Flutter Web**, garantizando URLs amigables, deep linking y carga diferida de micro‑apps.

## Principios de diseño
- **Declarativo**: todas las rutas se declaran en estructuras estáticas.
- **Modular**: cada *feature* exporta su propio archivo `routes.dart`.
- **Escalable**: el `router` principal combina rutas mediante spreads (`...FeatureX.routes`).
- **Web‑friendly**: habilita `urlPathStrategy: UrlPathStrategy.path` para URLs sin `#`.

## Estructura de carpetas
```
ui/ROUTERS/
│   sdd_routers.md          # Este documento
│   app_router.dart        # Router global del shell_app
│   auth_routes.dart       # Rutas de autenticación
│   admin_routes.dart      # Rutas del módulo admin
│   ...
```

## Implementación típica (ejemplo)
```dart
// ui/ROUTERS/app_router.dart
import 'package:go_router/go_router.dart';
import 'auth_routes.dart';
import 'admin_routes.dart';

final router = GoRouter(
  urlPathStrategy: UrlPathStrategy.path,
  routes: [
    ...AuthRoutes.routes,
    ...AdminRoutes.routes,
    // ... otras rutas de features
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);
```

## Consideraciones Flutter Web
- **Redirección de trailing slash**: configurada en `GoRouter` con `redirect`.
- **Prefetching**: usar `FutureBuilder` en `ShellRoute` para cargar datos críticos antes de renderizar.
- **SEO**: cada ruta importante debe mapear a una página estática usando `flutter build web --web-renderer html` y el plugin `go_router` soporta `router.neglectsHistory`.

## Dependencias
- `go_router` (v14) – ya incluido en `pubspec.yaml`.
- `flutter_riverpod` – para exponer `routerProvider`.
- `flutter_secure_storage` – para almacenar tokens y validar autenticación antes de entrar a rutas protegidas.

## Tests
- **Unitarios**: verificar que `router.routes` contenga todas las rutas esperadas.
- **Widget tests**: simular navegación con `tester.pumpWidget(MaterialApp.router(routerConfig: router))` y comprobar que cada pantalla se renderiza.
- **Web tests**: usar `flutter test --platform chrome` para validar que la URL cambie correctamente.

---
*Este documento forma parte del conjunto SDD modular bajo `sdd/PLAN/UI`. Cada sub‑directorio sigue este esquema.*
