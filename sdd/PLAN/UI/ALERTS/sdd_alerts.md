# SDD UI - Sistema de Alertas y Notificaciones
**Directorio:** `sdd/PLAN/UI/ALERTS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Estandarizar cómo la aplicación se comunica de forma pasiva o activa con el usuario. Las alertas incluyen feedback tras una acción (Toast/SnackBar), errores fatales (Error Screens), modales de confirmación (Dialogs), y push notifications.

## 2. Tipos de Alertas y sus Componentes en Flutter

### 2.1 Notificaciones de Feedback (SnackBar)
**Uso:** Informar que una acción se completó con éxito (ej. "Producto guardado", "Mesa cobrada").
- **Componente Base:** `ScaffoldMessenger.of(context).showSnackBar()`.
- **Regla UX:** No deben interrumpir el flujo. Deben flotar (`SnackBarBehavior.floating`), tener un `duration` corto (2 a 3 segundos) y permitir ser descartadas (swipe down/right).

### 2.2 Diálogos de Confirmación Peligrosa (AlertDialog)
**Uso:** Antes de eliminar un producto, cancelar una cuenta, o acciones destructivas.
- **Componente Base:** `showDialog` con `AlertDialog`.
- **Regla UX:** 
  - El botón destructivo debe ser explícitamente rojo o del color de error del Theme.
  - El botón de "Cancelar" debe ser el principal por defecto o tener un outline claro.
  - El título debe hacer una pregunta directa: "¿Eliminar Hamburguesa Completa?".

### 2.3 Bottom Sheets de Acciones Contextuales
**Uso:** Alternativa moderna a los menú contextuales. Útil en móviles para elegir acciones sobre una fila de tabla o producto (Ej: "Editar", "Pausar Venta", "Eliminar").
- **Componente Base:** `showModalBottomSheet`.
- **Regla UX:** Es más fácil de alcanzar con el pulgar en un smartphone que un pop-up central. Ideal para la app de los Mozos.

### 2.4 Error Banners a Nivel Pantalla (Inline Errors)
**Uso:** Cuando un formulario falla o no se pudo cargar un componente por falta de conexión, no se debe usar un diálogo. Se debe insertar un Banner rojo o amarillo en el contenido mismo de la vista para mantener el contexto.
- **Componente Base:** Implementación custom `ErrorBannerWidget` detallado en `sdd_components.md`.

## 3. Notificaciones Locales / Push (Foreground)
Dado que el sistema tiene Webhooks y FCM (Firebase Cloud Messaging), si la app está abierta en pantalla (Foreground) y recibe un push de "Nuevo Pedido", NO debe usar un push notification nativo ruidoso. En su lugar:
- Mostrar un `in-app notification` custom que deslice desde la parte superior (usando un paquete ligero o un `OverlayEntry` custom) para que el equipo lo vea y pueda clickear para abrir la comanda.
