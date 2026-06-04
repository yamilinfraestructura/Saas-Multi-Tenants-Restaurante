# SDD – Layouts (Flutter Web)

## Propósito
Definir los **layouts** reutilizables que estructuran las vistas de la aplicación SaaS en Flutter Web. Incluye plantillas responsivas que se adaptan a escritorio, tablet y móvil.

## Principios de Diseño
- **Responsive**: Utilizamos `LayoutBuilder` y `MediaQuery` para adaptar columnas/filas.
- **Consistencia**: Todos los layouts usan el *design system* definido en `themes` (colores, tipografía Inter, espaciado).
- **Accesibilidad**: Contrastes adecuados y foco visible para navegabilidad con teclado.

## Componentes Principales
| Layout | Descripción | Uso típico |
|--------|-------------|-----------|
| `AppScaffold` | Scaffold base con `AppBar`, `Drawer` y `BottomNavigationBar`. | En todas las pantallas principales.
| `ResponsiveGrid` | Grid que cambia número de columnas según ancho. | Listados de productos, tickets.
| `CenteredCard` | Card centrado con sombra ligera, usado en formularios. |
| `FullScreenLoader` | Overlay de carga full‑screen para operaciones async. |

## Implementación (Ejemplo)
```dart
class AppScaffold extends StatelessWidget {
  final Widget body;
  const AppScaffold({required this.body, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBar(title: Text('SaaS Guri')),
      drawer: const DrawerMenu(),
      body: SafeArea(child: body),
    );
  }
}
```

## Responsividad
```dart
final isDesktop = MediaQuery.of(context).size.width > 1024;
return isDesktop ? DesktopLayout() : MobileLayout();
```

## Dependencias
- `flutter_riverpod` para controlar estado de carga.
- `go_router` para navegación entre layouts.
- `google_fonts` para tipografía.

## Referencias
- `sdd_arquitectura_flutter.md` – visión global.
- `themes_color_font.md` – tokens de color y tipografía.
