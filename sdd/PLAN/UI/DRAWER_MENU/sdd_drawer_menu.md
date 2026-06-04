# SDD - Drawer Menu

## Propósito
Describir la arquitectura y comportamiento del **Drawer Menu** (menú lateral) que permite la navegación entre micro‑apps en la aplicación **SaaS System Guri**. El drawer está optimizado para **Flutter Web**, **iOS**, **Android** y **Desktop**.

## Principios de diseño
- **Consistencia** con el design system (colores, tipografía, iconografía). 
- **Accesibilidad**: contraste ≥ 4.5:1, foco visible y soporte a lectores de pantalla.
- **Responsividad**: colapsa a una barra superior en pantallas < 600 px.
- **Reusabilidad**: el drawer se implementa como widget independiente que recibe una lista de items.

## Componentes principales
| Nombre | Descripción | Uso típico |
|--------|-------------|------------|
| `AppDrawer` | Widget que contiene la lista de `DrawerItem`. | Bar lateral de la aplicación. |
| `DrawerItem` | Representa una opción de navegación (icono + texto). | Cada micro‑app (p.ej., Menú QR, Cocina). |
| `DrawerHeader` | Cabecera con avatar y nombre del tenant. | Parte superior del drawer. |

## Implementación típica (ejemplo)
```dart
class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(tenantProvider);
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Row(
              children: [
                Avatar(url: tenant.logoUrl),
                const SizedBox(width: 12),
                Text(tenant.name, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          const DrawerItem(icon: FontAwesomeIcons.qrcode, label: 'Menu QR', routeName: '/menu_qr'),
          const DrawerItem(icon: FontAwesomeIcons.kitchenSet, label: 'Cocina', routeName: '/cocina'),
          // ...more items
        ],
      ),
    );
  }
}
```

## Dependencias
- `flutter_riverpod` (provee `tenantProvider`).
- `font_awesome_flutter` para los iconos.
- `cached_network_image` para cargar el avatar.
- `go_router` para la navegación (`routeName`).

## Consideraciones Flutter Web
- En web, usa `Scaffold` con `Drawer` que se abre mediante `IconButton` en `AppBar`.
- Evita `AnimatedContainer` pesado; usa `AnimatedOpacity` para transiciones.
- El drawer colapsa automáticamente cuando el ancho de la pantalla es inferior a 600 px, usando `LayoutBuilder`.

## Tests
- **Widget test** que verifica que el drawer contiene los items esperados y que al pulsar un `DrawerItem` se llama a `GoRouter.of(context).go(routeName)`.
- **Responsiveness test** que asegura que el drawer se oculta en tamaños pequeños.

---
*Este SDD forma parte del conjunto modular bajo `sdd/PLAN/UI/DRAWER_MENU`.*
