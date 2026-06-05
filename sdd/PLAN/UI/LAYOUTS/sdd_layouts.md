# SDD UI - Layouts Base
**Directorio:** `sdd/PLAN/UI/LAYOUTS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Este documento define los **Layouts (Envoltorios) principales** de la aplicación Flutter. En lugar de repetir código de AppBar y Drawers en cada pantalla, los Layouts actúan como "Shells" que envuelven el contenido de las microapps.

## 2. ShellRoute (GoRouter) y Layouts

En Flutter, utilizaremos `ShellRoute` de GoRouter para mantener la barra de navegación persistente mientras el contenido cambia. Esto es equivalente al patrón `<Outlet />` de react-router-dom en el proyecto Menu QR original.

### 2.1 AdminShellLayout
**Uso:** Envuelve todas las pantallas de administración (`feature_admin`, `feature_pos`, `feature_billing`).
- **Desktop/Tablet:** Drawer lateral persistente a la izquierda (Expandido o Colapsado).
- **Móvil:** Drawer oculto con botón de menú tipo hamburguesa en el `AppBar`.
- **Componentes que incluye:** `AdminDrawer`, `TopAppBar` (con notificaciones y Avatar del usuario logueado).

### 2.2 CocinaShellLayout
**Uso:** Envuelve las pantallas operativas de cocina y bar (`feature_cocina`).
- **Características:** No tiene Drawer lateral para maximizar el espacio de las comandas. Usa un `AppBar` superior fijo con botones grandes (ideal para tablets) para filtrar por estados (Pendiente, En Preparación, Listo).
- **UX Adaptado:** Fondos oscuros (Dark Mode) sugeridos para reducir la fatiga visual en ambientes cerrados como una cocina.

### 2.3 ClienteMenuLayout
**Uso:** Envuelve el menú interactivo para los clientes del restaurante (`feature_menu_qr`).
- **Características:** 
  - `AppBar` colapsable (SliverAppBar) que muestra la imagen del restaurante y hace efecto parallax al hacer scroll hacia arriba.
  - `BottomNavigationBar` o `FloatingActionButton` flotante que muestra el total del carrito y permite ir al "Resumen del Pedido".
- **Comportamiento Flutter:** Se usará `CustomScrollView` con `SliverPersistentHeader` para las categorías, garantizando un rendimiento de 60fps en web móvil, algo muy superior al scroll de React DOM estándar.

## 3. Manejo de Responsividad (ResponsiveBuilder)

Se creará un widget base en `core_ui/layouts/responsive_layout.dart` para evaluar los breakpoints.

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    required this.desktop,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

**Implementación de la Regla de los Tiers:**
- `Mobile` (< 600px): Listas verticales de una columna. Botoneras inferiores.
- `Tablet` (600px - 1024px): Grids de 2 columnas, menús laterales colapsables.
- `Desktop` (> 1024px): Grids densos, tablas de datos extensas, sidebars expansivos.
