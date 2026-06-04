# SDD – Screens & Views (Flutter Web)

## Propósito
Describir los **screens** (vistas) principales de la aplicación SaaS, organizados por micro‑apps (`feature_menu_qr`, `feature_cocina`, `feature_admin`, etc.). Cada screen se basa en los **layouts** y **componentes** definidos en los SDD correspondientes y está pensado para ser **responsive** y accesible en Flutter Web, móvil y desktop.

## Principios de diseño
- **Separación de responsabilidades**: los screens son *stateless* o *ConsumerWidget* que delegan la lógica a *providers* (Riverpod) y a *use‑cases* (ubicados en `core`).
- **Responsividad**: usan `AppScaffold` y `ResponsiveGrid` para adaptarse a diferentes anchos.
- **Accesibilidad**: foco automático en el primer foco interactivo, uso de `Semantics` para lectores de pantalla.
- **Consistencia visual**: tipografía Inter, colores del design system (`themes_color_font.md`).

## Lista de screens principales
| Screen | Micro‑app | Descripción | Ruta (`go_router`) |
|--------|-----------|-------------|-------------------|
| `MenuQrScreen` | feature_menu_qr | Vista principal con listado de productos y botón de escaneo QR. | `/menu_qr` |
| `CocinaDashboardScreen` | feature_cocina | Tablero de cocina con Kanban de pedidos. | `/cocina` |
| `AdminDashboardScreen` | feature_admin | Panel de administración del restaurante. | `/admin` |
| `BillingScreen` | feature_billing | Gestión de suscripción y pagos. | `/billing` |
| `AuthLoginScreen` | feature_auth | Pantalla de login y selección de tenant. | `/login` |

## Implementación típica (ejemplo)
```dart
class MenuQrScreen extends ConsumerWidget {
  const MenuQrScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productos = ref.watch(productosProvider);
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: productos.when(
          data: (list) => ResponsiveGrid(
            children: list.map((p) => ProductCard(producto: p)).toList(),
          ),
          loading: () => const FullScreenLoader(),
          error: (e, _) => SaasAlert(
            title: 'Error',
            message: e.toString(),
            type: SaasAlertType.error,
          ),
        ),
      ),
    );
  }
}
```

## Dependencias
- `flutter_riverpod` (state management).
- `go_router` (navegación).
- `core_ui` (widgets base como `AppScaffold`, `FullScreenLoader`).
- `core_network` (repositorios para datos). 

## Consideraciones Flutter Web
- Evitar `FutureBuilder` anidados; usar `AsyncValue` de Riverpod.
- Los *cards* deben ser `MouseRegion`‑aware para hover effects.
- Implementar **lazy loading** de imágenes con `CachedNetworkImage`.

## Tests
- **Widget test** por cada screen verifica que los providers se consumen sin errores y que el layout se adapta a diferentes tamaños (`MediaQuery`).
- **Integration test** con `flutter_test` y `integration_test` para validar flujo completo (login → selección tenant → pantalla feature).

---
*Este SDD forma parte del conjunto modular bajo `sdd/PLAN/UI/SCREENS_VIEWS`.*
