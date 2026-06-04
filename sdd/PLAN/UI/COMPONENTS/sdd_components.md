# SDD - Componentes UI

## Propósito
Este documento describe los componentes reutilizables de UI que forman la base visual del proyecto **SaaS System Guri**. Cada componente sigue el **design system** definido en `sdd/PLAN/UI/themes/themes_color_font.md` y está pensado para ser compatible con **Flutter Web**, **iOS**, **Android** y **Desktop**.

## Principios de diseño
- **Consistencia visual**: colores, tipografía (Inter) y espaciado provienen del design system.
- **Accesibilidad**: contraste minimo 4.5:1, tamaños de fuente ≥ 14 px para web.
- **Responsividad**: los componentes usan `LayoutBuilder` y `MediaQuery` para adaptar su layout.
- **Reusabilidad**: cada componente está aislado, sin dependencia directa de lógica de negocio.

## Lista de componentes principales
| Nombre | Descripción | Uso típico | Comentarios Web |
|--------|-------------|------------|-----------------|
| `PrimaryButton` | Botón con estilo primario (color `#2C687B`). | Acciones principales en formularios. | Usa `ElevatedButton` con `ButtonStyle` que adapta `minimumSize` según ancho de pantalla. |
| `SecondaryButton` | Botón secundario (outline). | Acciones secundarias. | Usa `OutlinedButton` con colores del theme. |
| `InfoCard` | Tarjeta informativa con título, subtítulo y opcional icono. | Mostrar resumen de datos (p.ej., total ventas). | Implementa `ResponsiveGrid` para 1‑4 columnas según break‑point. |
| `LoadingSpinner` | Indicador de carga centralizado. | En cualquier petición asíncrona. | Usa `CircularProgressIndicator` con `size` adaptable. |
| `ErrorBanner` | Banner de error persistente. | Mostrar errores de red o autorización. | Implementa `AnimatedContainer` para desvanecerse al cerrar. |
| `Avatar` | Imagen circular del usuario/restaurant. | Header de barra lateral y perfil. | Usa `CachedNetworkImage` con fallback a `Icons.person`. |

## Implementación típica (ejemplo)
```dart
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({required this.label, required this.onPressed, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Color(0xFF2C687B),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
    );
  }
}
```

## Dependencias
- `flutter_riverpod` para exponer estilos a través de providers (p.ej., `themeProvider`).
- `google_fonts` para cargar la fuente **Inter**.
- `font_awesome_flutter` para iconografía.
- `cached_network_image` para Avatar.

## Consideraciones Flutter Web
- Evitar `Image.asset` con tamaños muy grandes; usar `AssetImage` con `cacheWidth`.
- Los `ElevatedButton` y `OutlinedButton` se renderizan como `<button>` nativos, garantizando accesibilidad.
- Todos los widgets son **stateless** o usan **ConsumerWidget** de Riverpod para evitar re‑renders innecesarios.

## Tests
- Cada componente tiene un test unitario bajo `test/widgets/` que verifica:
  - Renderizado correcto.
  - Respuesta a `onPressed`.
  - Adaptación a diferentes `MediaQuery` sizes.

---
*Este documento es parte del conjunto de SDD modularizados bajo `sdd/PLAN/UI`. Cada sub‑directorio contiene su propio SDD que sigue este mismo esquema.*
