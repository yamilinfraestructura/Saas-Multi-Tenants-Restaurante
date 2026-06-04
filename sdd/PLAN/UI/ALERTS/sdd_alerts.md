# SDD – Alerts (Flutter Web)

## Propósito
Definir el componente **Alert** que muestra mensajes de feedback (error, warning, info, success) en la aplicación SaaS. Adaptado para Flutter Web, iOS, Android y Desktop.

## Diseño visual
- **Colores** (definidos en `themes_color_font.md`):
  - Error: `#E53935`
  - Warning: `#FFB300`
  - Info: `#1976D2`
  - Success: `#43A047`
- **Tipografía**: Inter (Google Fonts).
- **Iconografía**: Font Awesome (faExclamationTriangle, faInfoCircle, faCheckCircle, faTimesCircle).
- **Animación**: Fade‑in 200 ms con desplazamiento suave.

## API del componente
```dart
enum SaasAlertType { error, warning, info, success }

class SaasAlert extends StatelessWidget {
  final String title;
  final String message;
  final SaasAlertType type;
  final VoidCallback? onClose;
  const SaasAlert({
    required this.title,
    required this.message,
    required this.type,
    this.onClose,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // implementación que elige colores e íconos según `type`
  }
}
```

## Accesibilidad
- Role `alertdialog` para lectores de pantalla.
- Contraste ≥ 4.5:1.
- Focus automático al mostrarse y retorno al cerrar.

## Uso típico
```dart
Sa​asAlert(
  title: 'Error de conexión',
  message: 'No se pudo conectar al servidor.',
  type: SaasAlertType.error,
  onClose: () => setState(() => _showAlert = false),
);
```

## Integración
- Archivo: `ui/alerts/saas_alert.dart`.
- Exportado desde `core_ui/alerts/` para uso en cualquier feature.

## Tests
- Widget test verifica colores e íconos según `type`.
- Golden test para cada variante.

---
*Este SDD forma parte del conjunto modular bajo `sdd/PLAN/UI/ALERTS`.*
